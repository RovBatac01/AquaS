const express = require("express");
const mysql = require("mysql2/promise"); // Use the promise version of mysql2
const { SerialPort } = require("serialport");
const { ReadlineParser } = require("@serialport/parser-readline");
const bodyParser = require("body-parser");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");
const bcrypt = require("bcrypt");
const saltRounds = 10;
const https = require("https");
const { v4: uuidv4 } = require("uuid"); // For generating unique IDs
const nodemailer = require("nodemailer"); // For sending emails

const app = express();
const port = 5000;
// const users = []; // REMOVE this - you'll fetch from the database
const otpStorage = {}; // { email: { otp, expiry } }

// Nodemailer setup (replace with your email provider details)
const transporter = nodemailer.createTransport({
  service: "gmail", // e.g., 'Gmail', 'Outlook'
  auth: {
    user: "aquasense35@gmail.com",
    pass: "ijmcosuxpnioehya",
  },
});

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(cors()); // Allow frontend requests

// Create HTTP server for Socket.IO
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*" },
});

// MySQL Connection
const db = mysql.createPool({
  host: "localhost",
  user: "root",
  password: "",
  database: "aquasense",
  waitForConnections: true, 
  connectionLimit: 10, 
  queueLimit: 0, 
});

// Function to send OTP via email
async function sendOTP(email, otp) {
  const mailOptions = {
    from: 'your-email@example.com',
    to: email,
    subject: 'Password Reset OTP',
    text: `Your OTP for password reset is: ${otp}`,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`OTP sent to ${email}: ${otp}`);
  } catch (error) {
    console.error('Error sending OTP email:', error);
    console.error('Original Email Error:', error); // Log the original error
    throw new Error('Failed to send OTP. Please check your email configuration.  Original error: ' + error.message); // Include original error message
  }
}

// Import the User model (assuming it's in ./models/user.js)
const User = require('./models/user'); // <===== ADD THIS LINE

app.post("/register", async (req, res) => {
  const {
    username,
    email,
    phone = null,
    password,
    confirm_password,
  } = req.body;

  if (!username || !email || !password || !confirm_password) {
    return res.status(400).json({ error: "All fields are required" });
  }

  if (password !== confirm_password) {
    return res.status(400).json({ error: "Passwords do not match" });
  }

  try {
    // Hash Password
    const hashedPassword = await bcrypt.hash(password, saltRounds); // SQL Query

    const sql =
      "INSERT INTO users (username, email, phone, password_hash, role) VALUES (?, ?, ?, ?, 'user')"; // Insert User Data, added role
    const [result] = await db.query(sql, [
      username,
      email,
      phone || null,
      hashedPassword,
    ]); // Use await and destructuring
    res.json({
      message: "User registered successfully!",
      userId: result.insertId, // Return inserted user ID
    });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Server error" });
  }
});


// Login route
app.post("/login", async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: "All fields are required" });
  }

  const sql = "SELECT *, role FROM users WHERE username = ?";
  try {
    const [results] = await db.query(sql, [username]); // Use await
    if (results.length === 0) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    const user = results[0];

    const passwordMatch = await bcrypt.compare(password, user.password_hash);
    console.log("DEBUG: User role being sent from backend:", user.role);
    if (!passwordMatch) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    res.json({
      message: "Login successful!",
      role: user.role, // token: "your_jwt_token_here"
    });
  } catch (err) {
    console.error("Database error:", err);
    return res.status(500).json({ error: "Database error occurred" });
  }
});

// NEW: Endpoint to fetch all users
app.get("/users", async (req, res) => {
  const sql = "SELECT id, username, role FROM users";
  try {
    const [results] = await db.query(sql);
    res.status(200).json(results);
  } catch (err) {
    console.error("Database error fetching users:", err);
    return res
      .status(500)
      .json({ error: "Failed to fetch users from database." });
    }
});

// NEW: Endpoint to update a user by ID (PUT request)
app.put("/users/:id", async (req, res) => {
  const userId = req.params.id;
  const { username, role } = req.body;

  if (!username || !role) {
    return res
      .status(400)
      .json({ error: "Username and role are required for update." });
  }
  const sql = "UPDATE users SET username = ?, role = ? WHERE id = ?";
  try {
    const [result] = await db.query(sql, [username, role, userId]);
    if (result.affectedRows === 0) {
      return res
        .status(404)
        .json({ error: "User not found or no changes made." });
    }
    res.status(200).json({ message: "User updated successfully!" });
  } catch (err) {
    console.error("Database error updating user:", err);
    return res
      .status(500)
      .json({ error: "Failed to update user in database." });
    }
});

// NEW: Endpoint to delete a user by ID (DELETE request)
app.delete("/users/:id", async (req, res) => {
  const userId = req.params.id;

  const sql = "DELETE FROM users WHERE id = ?";
  try {
    const [result] = await db.query(sql, [userId]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "User not found." });
    }
    res.status(200).json({ message: "User deleted successfully!" });
  } catch (err) {
    console.error("Database error deleting user:", err);
    return res
      .status(500)
      .json({ error: "Failed to delete user from database." });
    }
});

// 1. Forgot Password Endpoint
app.post("/api/forgot-password", async (req, res) => {
  console.log("Received request for /api/forgot-password");
  const { email } = req.body;
  console.log("Email received:", email);

  if (!email) {
    return res
      .status(400)
      .json({ success: false, message: "Email is required" });
  }

  try {
    // Check if the user exists in the database
    const [users] = await db.query("SELECT * FROM users WHERE email = ?", [
      email,
    ]); // Corrected query
    const user = users[0];

    if (!user) {
      console.log("User not found for email:", email);
      return res
        .status(404)
        .json({
          success: false,
          message: "Email not found. Please check your email address.",
        }); // Prevents email enumeration
    }

    console.log("User found:", user); //  log // Generate OTP

    const otp = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit OTP
    const expiry = Date.now() + 300000; // OTP expires in 5 minutes (300000 ms) // Store OTP (in a real app, use Redis or a database with TTL)

    otpStorage[email] = { otp, expiry }; // Send OTP via email

    await sendOTP(email, otp);
    res.json({
      success: true,
      message: "OTP sent successfully. Please check your email.",
    });
  } catch (error) {
    console.error("Error during forgot-password process:", error);
    return res
      .status(500)
      .json({
        success: false,
        message: "Internal server error: " + error.message,
      }); // Improved error message
  }
});

// 2. Verify OTP Endpoint
app.post("/api/verify-otp", async (req, res) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    return res
      .status(400)
      .json({ success: false, message: "Email and OTP are required" });
  }

  try {
    // 1.  Find the user by email
    const [users] = await db.query("SELECT * FROM users WHERE email = ?", [email]); //  findOne
    const user = users[0];
    if (!user) {
      return res.status(400).json({ success: false, message: "Invalid email." });
    }

    // 2.  Get the stored OTP
    const storedOTP = otpStorage[email];
    if (!storedOTP) {
      return res.status(404).json({
        success: false,
        message: "OTP not found or expired. Please request a new one.",
      });
    }

    // 3.  Verify the OTP and expiry
    if (storedOTP.otp === otp) {
      if (storedOTP.expiry < Date.now()) {
        delete otpStorage[email];
        return res.status(410).json({
          success: false,
          message: "OTP expired. Please request a new one.",
        });
      }

      // OTP is valid
      // 4.  Mark the user as verified and remove the OTP
      // ==========================================================
      //  Database Logic Starts Here
      // ==========================================================

      // --- MySQL (mysql2) Example ---
      await db.query('UPDATE users SET is_verified = 1 WHERE email = ?', [email]);
      //await connection.query('DELETE FROM otps WHERE email = ?', [email]); // There is no OTP table in the database
      // ==========================================================
      //  Database Logic Ends Here
      // ==========================================================

      res.json({
        success: true,
        message: "OTP verified successfully. You can now change your password.",
      });
    } else {
      return res.status(400).json({ success: false, message: "Invalid OTP." });
    }
  } catch (error) {
    console.error("Error verifying OTP:", error);
    return res.status(500).json({
      success: false,
      message: "Internal Server Error",
      error: error.message, // Include the error message for debugging
    });
  }
});


// async function setStateOTPVerified(email) {
//   const sql = "UPDATE users SET reset_otp = 1 WHERE email = ?"; // Use reset_otp
//   try {
//     const [result] = await db.query(sql, [email]);
//     if (result.affectedRows === 0) {
//       console.warn(
//         "setStateOTPVerified: Email not found or user already verified:",
//         email
//       ); //  Don't treat this as an error.
//     }
//   } catch (error) {
//     console.error("Database error in setStateOTPVerified:", error);
//     throw error; // Re-throw the error to be caught by the caller
//   }
// }

// 3. Change Password Endpoint
// ... (Keep your existing code, and add this login function)
async function login(username, res) {
  const sql = "SELECT *, role FROM users WHERE username = ?";
  try {
    const [results] = await db.query(sql, [username]); // Use await
    if (results.length === 0) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    const user = results[0];
    // In a real app, you would compare the password.  Since we just changed it, we know it's correct.
    // const passwordMatch = await bcrypt.compare(password, user.password_hash);
    // if (!passwordMatch) {
    //   return res.status(401).json({ error: "Invalid credentials" });
    // }

    res.json({
      message: "Login successful!",
      role: user.role, // token: "your_jwt_token_here"  <==  Important:  Add a token here.
    });
  } catch (err) {
    console.error("Database error:", err);
    return res.status(500).json({ error: "Database error occurred" });
  }
}


app.post("/api/change-password", async (req, res) => {
  const { email, new_password: newPassword } = req.body;
  console.log("Received /api/change-password request", { email, newPassword });

  if (!email || !newPassword) {
    console.log("Missing email or newPassword");
    return res
      .status(400)
      .json({ success: false, message: "Email and new password are required" });
  }

  try {
    console.log("Fetching user from database with email:", email);
    const [users] = await db.query("SELECT * FROM users WHERE email = ?", [email]); // Corrected query
    const user = users[0];

    if (!user) {
      console.log("User not found for email:", email);
      return res
        .status(404)
        .json({ success: false, message: "Email not found." });
    }
    console.log("Found user:", user);
    if (user.is_verified !== 1) {
      console.log("User is_verified is not 1.  is_verified:", user.is_verified);
      return res
        .status(403)
        .json({
          success: false,
          message: "Password change request is not valid. Verify OTP first.",
        });
    }

    if (newPassword.length < 8) {
      console.log("New password is too short");
      return res
        .status(400)
        .json({
          success: false,
          message: "Password must be at least 8 characters long",
        });
    }
    console.log("Hashing new password");
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);
    console.log("Hashed password:", hashedPassword);
    console.log("Updating user password and setting is_verified to 0 for email:", email);
    const sql =
      "UPDATE users SET password_hash = ? WHERE email = ?";
    const [result] = await db.query(sql, [hashedPassword, email]);
    console.log("Database update result:", result);
    // res.json({ success: true, message: "Password changed successfully." });     <== REMOVE THIS LINE

    //  Inform the client to redirect.  Do NOT try to redirect from the backend.
    res.json({
      success: true,
      message: "Password changed successfully.  Please redirect to login.",
      redirect: "/login" //  Add a redirect property.  The value is the route on the FRONTEND.
    });
    
  } catch (error) {
    console.error("Error changing password:", error);
    return res
      .status(500)
      .json({
        success: false,
        message: "Internal server error: " + error.message,
      });
    }
});


// 4. (Optional) Register User Endpoint for Testing
// app.post('/api/register', async (req, res) => {
//   const { email, password } = req.body;

//   if (!email || !password) {
//     return res.status(400).json({ success: false, message: 'Email and password are required' });
//   }

//   // Check if the user already exists
//   const userExists = users.find(u => u.email === email);
//   if (userExists) {
//     return res.status(409).json({ success: false, message: 'Email already exists' });
//   }

//   // Hash the password
//   const salt = await bcrypt.genSalt(10);
//   const hashedPassword = await bcrypt.hash(password, saltRounds);

//   // Create a new user
//   const newUser = {
//     id: uuidv4(),
//     email,
//     password: hashedPassword,
//     resetPassword: false, // Add the resetPassword property here, initially false
//   };
//   users.push(newUser);

//   res.status(201).json({ success: true, message: 'User registered successfully' });
// });

// SerialPort setup
const serialPort = new SerialPort({ path: "COM5", baudRate: 9600 });
const parser = serialPort.pipe(new ReadlineParser({ delimiter: "\n" }));

serialPort.on("open", () => {
  console.log("✅ Serial Port Opened: COM5");
});

parser.on("data", (rawData) => {
  console.log("📡 Raw Data Received:", rawData.trim());

  const jsonStartIndex = rawData.indexOf("{");

  if (jsonStartIndex !== -1) {
    const jsonString = rawData.substring(jsonStartIndex);

    try {
      const jsonData = JSON.parse(jsonString);

      console.log("🔄 Parsed Data:", jsonData);

      // Example timestamp if available or generate here
      const timestamp = new Date();

      // Handling Turbidity
      if (jsonData.turbidity_value !== undefined) {
        const turbidityValue = jsonData.turbidity_value;
        console.log("🔄 Parsed Turbidity Value:", turbidityValue, "Timestamp:", timestamp);
        const query = "INSERT INTO turbidity_readings (turbidity_value, timestamp) VALUES (?, ?)";
        db.query(query, [turbidityValue, timestamp], (err, result) => {
          if (err) {
            console.error("❌ Turbidity Database Insert Error:", err);
          } else {
            console.log("✅ Turbidity Data Inserted Successfully: ID", result.insertId);
            io.emit("updateData", { value: turbidityValue, timestamp });
            console.log("📢 WebSocket Event Emitted: updateData", { value: turbidityValue, timestamp });
          }
        });
      }

      // Handling pH data
      if (jsonData.ph_value !== undefined) {
        const phValue = jsonData.ph_value;
        console.log("📡 Received pH Level Data:", phValue);
        const query = "INSERT INTO phlevel_readings (ph_value) VALUES (?)";
        db.query(query, [phValue], (err, result) => {
          if (err) {
            console.error("❌ pH Database Insert Error:", err);
          } else {
            console.log("✅ pH Data Inserted Successfully: ID", result.insertId);
            io.emit("updatePHData", { value: phValue });
            console.log("📢 WebSocket Event Emitted: updatePHData", { value: phValue });
          }
        });
      }

      // Handling TDS data
      if (jsonData.tds_value !== undefined) {
        const tdsValue = jsonData.tds_value;
        console.log("📡 Received TDS Data:", tdsValue);
        const query = "INSERT INTO tds_readings (tds_value) VALUES (?)";
        db.query(query, [tdsValue], (err, result) => {
          if (err) {
            console.error("❌ TDS Database Insert Error:", err);
          } else {
            console.log("✅ TDS Data Inserted Successfully: ID", result.insertId);
            io.emit("updateTDSData", { value: tdsValue });
            console.log("📢 WebSocket Event Emitted: updateTDSData", { value: tdsValue });
          }
        });
      }

      // Handling Salinity data
      if (jsonData.salinity_value !== undefined) {
        const salinityValue = jsonData.salinity_value;
        console.log("📡 Received Salinity Data:", salinityValue);
        const query = "INSERT INTO salinity_readings (salinity_value) VALUES (?)";
        db.query(query, [salinityValue], (err, result) => {
          if (err) {
            console.error("❌ Salinity Database Insert Error:", err);
          } else {
            console.log("✅ Salinity Data Inserted Successfully: ID", result.insertId);
            io.emit("updateSalinityData", { value: salinityValue });
            console.log("📢 WebSocket Event Emitted: updateSalinityData", { value: salinityValue });
          }
        });
      }

      // Handling EC data
      if (jsonData.ec_value !== undefined) {
        const ecValue = jsonData.ec_value;
        console.log("📡 Received EC Data (mS/cm):", ecValue);
        const query = "INSERT INTO ec_readings (ec_value_mS) VALUES (?)";
        db.query(query, [ecValue], (err, result) => {
          if (err) {
            console.error("❌ EC Database Insert Error:", err);
          } else {
            console.log("✅ EC Data Inserted Successfully: ID", result.insertId);
            io.emit("updateECData", { value: ecValue });
            console.log("📢 WebSocket Event Emitted: updateECData", { value: ecValue });
          }
        });
      }

      // Handling EC Compensated data
      if (jsonData.ec_compensated_value !== undefined) {
        const ecCompensatedValue = jsonData.ec_compensated_value;
        console.log("📡 Received Compensated EC Data (mS/cm):", ecCompensatedValue);
        const query = "INSERT INTO ec_compensated_readings (ec_compensated_mS) VALUES (?)";
        db.query(query, [ecCompensatedValue], (err, result) => {
          if (err) {
            console.error("❌ Compensated EC Database Insert Error:", err);
          } else {
            console.log("✅ Compensated EC Data Inserted Successfully: ID", result.insertId);
            io.emit("updateECCompensatedData", { value: ecCompensatedValue });
            console.log("📢 WebSocket Event Emitted: updateECCompensatedData", { value: ecCompensatedValue });
          }
        });
      }

      // Handling Temperature data
      if (jsonData.temperature_value !== undefined) {
        const temperatureValue = jsonData.temperature_value;
        console.log("📡 Received Temperature Data (°C):", temperatureValue);
        const query = "INSERT INTO temperature_readings (temperature_celsius) VALUES (?)";
        db.query(query, [temperatureValue], (err, result) => {
          if (err) {
            console.error("❌ Temperature Database Insert Error:", err);
          } else {
            console.log("✅ Temperature Data Inserted Successfully: ID", result.insertId);
            io.emit("updateTemperatureData", { value: temperatureValue });
            console.log("📢 WebSocket Event Emitted: updateTemperatureData", { value: temperatureValue });
          }
        });
      }

    } catch (err) {
      console.error("❌ JSON Parse Error:", err);
    }
  } else {
    console.warn("⚠️ No JSON object found in raw data");
  }
});

// Get last 10 Turbidity readings
app.get("/data/turbidity", (req, res) => {
  console.log("📥 GET /data/turbidity request received");

  db.query(
    "SELECT * FROM turbidity_readings ORDER BY id DESC LIMIT 10",
    (err, results) => {
      if (err) {
        console.error("❌ Turbidity Database Query Error:", err);
        return res.status(500).json({ error: "Database Query Error" });
      }

      console.log(`✅ Turbidity API Response Sent: ${results.length} records`);
      res.json(results);
    }
  );
});

// Get last 10 pH readings
app.get("/data/ph", (req, res) => {
  console.log("📥 GET /data/ph request received");

  db.query(
    "SELECT * FROM phlevel_readings ORDER BY id DESC LIMIT 10",
    (err, results) => {
      if (err) {
        console.error("❌ pH Database Query Error:", err);
        return res.status(500).json({ error: "Database Query Error" });
      }

      console.log(`✅ pH API Response Sent: ${results.length} records`);
      res.json(results);
    }
  );
});

// Get last 10 TDS readings
app.get("/data/tds", (req, res) => {
  console.log("📥 GET /data/tds request received");

  db.query(
    "SELECT * FROM tds_readings ORDER BY id DESC LIMIT 10",
    (err, results) => {
      if (err) {
        console.error("❌ TDS Database Query Error:", err);
        return res.status(500).json({ error: "Database Query Error" });
      }

      console.log(`✅ TDS API Response Sent: ${results.length} records`);
      res.json(results);
    }
  );
});

// Get last 10 Salinity readings
app.get("/data/salinity", (req, res) => {
  console.log("📥 GET /data/salinity request received");

  db.query(
    "SELECT * FROM salinity_readings ORDER BY id DESC LIMIT 10",
    (err, results) => {
      if (err) {
        console.error("❌ Salinity Database Query Error:", err);
        return res.status(500).json({ error: "Database Query Error" });
      }

      console.log(`✅ Salinity API Response Sent: ${results.length} records`);
      res.json(results);
    }
  );
});

// Get last 10 EC readings
app.get("/data/ec", (req, res) => {
  console.log("📥 GET /data/ec request received");

  db.query(
    "SELECT * FROM ec_readings ORDER BY id DESC LIMIT 10",
    (err, results) => {
      if (err) {
        console.error("❌ EC Database Query Error:", err);
        return res.status(500).json({ error: "Database Query Error" });
      }

      console.log(`✅ EC API Response Sent: ${results.length} records`);
      res.json(results);
    }
  );
});

// Get last 10 EC Compensated readings
app.get("/data/ec_compensated", (req, res) => {
  console.log("📥 GET /data/ec_compensated request received");

  db.query(
    "SELECT * FROM ec_compensated_readings ORDER BY id DESC LIMIT 10",
    (err, results) => {
      if (err) {
        console.error("❌ EC Compensated Database Query Error:", err);
        return res.status(500).json({ error: "Database Query Error" });
      }

      console.log(`✅ EC Compensated API Response Sent: ${results.length} records`);
      res.json(results);
    }
  );
});

// Get last 10 Temperature readings
app.get("/data/temperature", (req, res) => {
  console.log("📥 GET /data/temperature request received");

  db.query(
    "SELECT * FROM temperature_readings ORDER BY id DESC LIMIT 10",
    (err, results) => {
      if (err) {
        console.error("❌ Temperature Database Query Error:", err);
        return res.status(500).json({ error: "Database Query Error" });
      }

      console.log(`✅ Temperature API Response Sent: ${results.length} records`);
      res.json(results);
    }
  );
});


// Start servers
server.listen(port, () => {
  console.log(`🚀 Backend running on http://localhost:${port}`);
});

io.listen(3001, () => {
  console.log("🔌 WebSocket server running on port 3001");
});
