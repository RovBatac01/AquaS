const express = require("express");
const mysql = require('mysql2/promise'); // Use the promise version of mysql2
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
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'my$uper$ecreTKey9876543210strong!';

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

// Middleware to verify JWT and get user ID
// This function needs to be accessible when used in app.get('/api/user/profile', ...)
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token == null) {
        console.log("No token provided.");
        return res.sendStatus(401); // No token, unauthorized
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            console.error("JWT verification error:", err);
            return res.sendStatus(403); // Token invalid or expired
        }
        req.user = user; // Attach user payload from token to request
        next(); // Proceed to the next middleware/route handler
    });
};

// Create HTTP server for Socket.IO
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*" },
});

// MySQL Connection
const db = mysql.createPool({
  host: "aquasense.c10u8c6s49c0.ap-southeast-2.rds.amazonaws.com",
  user: "admin",
  password: "aquasense123",
  database: "aquasense",
  port: 3306, // Default MySQL port
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
    phone,
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

// Login route (public, does not use authenticateToken)
app.post("/login", async (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({ error: "All fields are required" });
    }

    const sql = "SELECT id, username, password_hash, role FROM users WHERE username = ?";
    try {
        const [results] = await db.query(sql, [username]);

        if (results.length === 0) {
            return res.status(401).json({ error: "Invalid credentials" });
        }

        const user = results[0];

        const passwordMatch = await bcrypt.compare(password, user.password_hash);
        console.log("DEBUG: User role being sent from backend:", user.role);

        if (!passwordMatch) {
            return res.status(401).json({ error: "Invalid credentials" });
        }

        const userPayload = {
            id: user.id,
            username: user.username,
            role: user.role
        };

        const accessToken = jwt.sign(userPayload, JWT_SECRET, { expiresIn: '1h' });

        res.json({
            message: "Login successful!",
            role: user.role,
            username: user.username,
            token: accessToken,
            userId: user.id
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

app.get('/api/user/profile', authenticateToken, async (req, res) => {
    const userId = req.user.id;
    const username = req.user.username; // Can often get from token payload

    const query = 'SELECT username FROM users WHERE id = ?';
    try {
        const [rows] = await db.query(query, [userId]);
        if (rows.length > 0) {
            res.json({ username: rows[0].username });
        } else {
            res.status(404).json({ message: 'User not found in DB despite valid token' });
        }
    } catch (error) {
        console.error('Error fetching user profile:', error);
        res.status(500).json({ message: 'Server error' });
    }
});

app.get('/api/events-all', async (req, res) => {
    try {
        // Select all events, ordered by event_date and time
        const [rows] = await db.execute('SELECT * FROM events ORDER BY event_date, time'); // Changed pool to db
        res.json(rows);
    } catch (err) {
        console.error('Error fetching all events:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Endpoint to fetch events for a specific date (if needed for specific date view)

// Example: GET /api/events?date=2024-03-15
app.get('/api/events', async (req, res) => {
    const { date } = req.query; // date should be in 'YYYY-MM-DD' format

    if (!date) {
        return res.status(400).json({ error: 'Date parameter is required.' });
    }

    try {
        const [rows] = await db.execute('SELECT * FROM events WHERE event_date = ? ORDER BY time, id', [date]); // Changed pool to db
        res.json(rows);
    } catch (err) {
        console.error('Error fetching events for date:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/events', async (req, res) => {
    const { title, time, description, event_date } = req.body;

    if (!title || !event_date) {
        return res.status(400).json({ error: 'Title and event_date are required.' });
    }

    try {
        // Using parameterized queries (?) for security against SQL injection
        const [result] = await db.execute( // Changed pool to db
            'INSERT INTO events (title, time, description, event_date) VALUES (?, ?, ?, ?)',
            [title, time || null, description || null, event_date]
        );

        // After insertion, fetch the newly created event to return it (including its ID)
        const [newEventRows] = await db.execute('SELECT * FROM events WHERE id = ?', [result.insertId]); // Changed pool to db
        res.status(201).json(newEventRows[0]); // Return the newly created event
    } catch (err) {
        console.error('Error adding event:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Delete an event
// Example: DELETE /api/events/123
app.delete('/api/events/:id', async (req, res) => {
    const { id } = req.params;

    try {
        const [result] = await db.execute('DELETE FROM events WHERE id = ?', [id]); // Changed pool to db
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Event not found.' });
        }
        res.status(200).json({ message: `Event with ID ${id} deleted successfully.` });
    } catch (err) {
        console.error('Error deleting event:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// GET /api/notifications/superadmin - Fetch all notifications
app.get('/api/notifications/superadmin', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT id, type, title, message, timestamp AS createdAt, is_read AS `read` FROM notif ORDER BY timestamp DESC');

        // Map the results to match the Flutter frontend's expected keys
        const formattedNotifications = rows.map(notif => ({
            id: notif.id.toString(),
            type: notif.type,
            title: notif.title,
            message: notif.message,
            createdAt: notif.createdAt,
            read: notif.read
        }));

        res.json(formattedNotifications);
    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({ message: 'Error fetching notifications', error: error.message });
    }
});

// DELETE /api/notifications/superadmin/:id - Delete a notification
app.delete('/api/notifications/superadmin/:id', async (req, res) => {
    const { id } = req.params;

    try {
        const [result] = await db.query('DELETE FROM notif WHERE id = ?', [id]);

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Notification not found' });
        }

        res.status(200).json({ message: 'Notification deleted successfully' });
    } catch (error) {
        console.error('Error deleting notification:', error);
        res.status(500).json({ message: 'Error deleting notification', error: error.message });
    }
});

// GET /api/notifications/superadmin - Fetch all notifications
app.get('/api/notifications/admin', async (req, res) => {
    try {
        const [rows] = await db.query('SELECT id, type, title, message, timestamp AS createdAt, is_read AS `read` FROM notif ORDER BY timestamp DESC');

        // Map the results to match the Flutter frontend's expected keys
        const formattedNotifications = rows.map(notif => ({
            id: notif.id.toString(),
            type: notif.type,
            title: notif.title,
            message: notif.message,
            createdAt: notif.createdAt,
            read: notif.read
        }));

        res.json(formattedNotifications);
    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({ message: 'Error fetching notifications', error: error.message });
    }
});

// DELETE /api/notifications/superadmin/:id - Delete a notification
app.delete('/api/notifications/admin/:id', async (req, res) => {
    const { id } = req.params;

    try {
        const [result] = await db.query('DELETE FROM notif WHERE id = ?', [id]);

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Notification not found' });
        }

        res.status(200).json({ message: 'Notification deleted successfully' });
    } catch (error) {
        console.error('Error deleting notification:', error);
        res.status(500).json({ message: 'Error deleting notification', error: error.message });
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
// const serialPort = new SerialPort({ path: "COM5", baudRate: 9600 });
// const parser = serialPort.pipe(new ReadlineParser({ delimiter: "\n" }));

// serialPort.on("open", () => {
//   console.log("✅ Serial Port Opened: COM5");
// });

// parser.on("data", (rawData) => {
//   console.log("📡 Raw Data Received:", rawData.trim());

//   const jsonStartIndex = rawData.indexOf("{");

//   if (jsonStartIndex !== -1) {
//     const jsonString = rawData.substring(jsonStartIndex);

//     try {
//       const jsonData = JSON.parse(jsonString);

//       console.log("🔄 Parsed Data:", jsonData);

//       // Example timestamp if available or generate here
//       const timestamp = new Date();

//       // Handling Turbidity
//       if (jsonData.turbidity_value !== undefined) {
//         const turbidityValue = jsonData.turbidity_value;
//         console.log("🔄 Parsed Turbidity Value:", turbidityValue, "Timestamp:", timestamp);
//         const query = "INSERT INTO turbidity_readings (turbidity_value, timestamp) VALUES (?, ?)";
//         db.query(query, [turbidityValue, timestamp], (err, result) => {
//           if (err) {
//             console.error("❌ Turbidity Database Insert Error:", err);
//           } else {
//             console.log("✅ Turbidity Data Inserted Successfully: ID", result.insertId);
//             io.emit("updateData", { value: turbidityValue, timestamp });
//             console.log("📢 WebSocket Event Emitted: updateData", { value: turbidityValue, timestamp });
//           }
//         });
//       }

//       // Handling pH data
//       if (jsonData.ph_value !== undefined) {
//         const phValue = jsonData.ph_value;
//         console.log("📡 Received pH Level Data:", phValue);
//         const query = "INSERT INTO phlevel_readings (ph_value) VALUES (?)";
//         db.query(query, [phValue], (err, result) => {
//           if (err) {
//             console.error("❌ pH Database Insert Error:", err);
//           } else {
//             console.log("✅ pH Data Inserted Successfully: ID", result.insertId);
//             io.emit("updatePHData", { value: phValue });
//             console.log("📢 WebSocket Event Emitted: updatePHData", { value: phValue });
//           }
//         });
//       }

//       // Handling TDS data
//       if (jsonData.tds_value !== undefined) {
//         const tdsValue = jsonData.tds_value;
//         console.log("📡 Received TDS Data:", tdsValue);
//         const query = "INSERT INTO tds_readings (tds_value) VALUES (?)";
//         db.query(query, [tdsValue], (err, result) => {
//           if (err) {
//             console.error("❌ TDS Database Insert Error:", err);
//           } else {
//             console.log("✅ TDS Data Inserted Successfully: ID", result.insertId);
//             io.emit("updateTDSData", { value: tdsValue });
//             console.log("📢 WebSocket Event Emitted: updateTDSData", { value: tdsValue });
//           }
//         });
//       }

//       // Handling Salinity data
//       if (jsonData.salinity_value !== undefined) {
//         const salinityValue = jsonData.salinity_value;
//         console.log("📡 Received Salinity Data:", salinityValue);
//         const query = "INSERT INTO salinity_readings (salinity_value) VALUES (?)";
//         db.query(query, [salinityValue], (err, result) => {
//           if (err) {
//             console.error("❌ Salinity Database Insert Error:", err);
//           } else {
//             console.log("✅ Salinity Data Inserted Successfully: ID", result.insertId);
//             io.emit("updateSalinityData", { value: salinityValue });
//             console.log("📢 WebSocket Event Emitted: updateSalinityData", { value: salinityValue });
//           }
//         });
//       }

//       // Handling EC data
//       if (jsonData.ec_value !== undefined) {
//         const ecValue = jsonData.ec_value;
//         console.log("📡 Received EC Data (mS/cm):", ecValue);
//         const query = "INSERT INTO ec_readings (ec_value_mS) VALUES (?)";
//         db.query(query, [ecValue], (err, result) => {
//           if (err) {
//             console.error("❌ EC Database Insert Error:", err);
//           } else {
//             console.log("✅ EC Data Inserted Successfully: ID", result.insertId);
//             io.emit("updateECData", { value: ecValue });
//             console.log("📢 WebSocket Event Emitted: updateECData", { value: ecValue });
//           }
//         });
//       }

//       // Handling EC Compensated data
//       if (jsonData.ec_compensated_value !== undefined) {
//         const ecCompensatedValue = jsonData.ec_compensated_value;
//         console.log("📡 Received Compensated EC Data (mS/cm):", ecCompensatedValue);
//         const query = "INSERT INTO ec_compensated_readings (ec_compensated_mS) VALUES (?)";
//         db.query(query, [ecCompensatedValue], (err, result) => {
//           if (err) {
//             console.error("❌ Compensated EC Database Insert Error:", err);
//           } else {
//             console.log("✅ Compensated EC Data Inserted Successfully: ID", result.insertId);
//             io.emit("updateECCompensatedData", { value: ecCompensatedValue });
//             console.log("📢 WebSocket Event Emitted: updateECCompensatedData", { value: ecCompensatedValue });
//           }
//         });
//       }

//       // Handling Temperature data
//       if (jsonData.temperature_value !== undefined) {
//         const temperatureValue = jsonData.temperature_value;
//         console.log("📡 Received Temperature Data (°C):", temperatureValue);
//         const query = "INSERT INTO temperature_readings (temperature_celsius) VALUES (?)";
//         db.query(query, [temperatureValue], (err, result) => {
//           if (err) {
//             console.error("❌ Temperature Database Insert Error:", err);
//           } else {
//             console.log("✅ Temperature Data Inserted Successfully: ID", result.insertId);
//             io.emit("updateTemperatureData", { value: temperatureValue });
//             console.log("📢 WebSocket Event Emitted: updateTemperatureData", { value: temperatureValue });
//           }
//         });
//       }

//     } catch (err) {
//       console.error("❌ JSON Parse Error:", err);
//     }
//   } else {
//     console.warn("⚠️ No JSON object found in raw data");
//   }
// });

// API endpoint to get total users
app.get('/api/total-users', async (req, res) => { // Added 'async'
  const querySql = 'SELECT COUNT(*) AS totalUsers FROM users'; // Assuming your user table is named 'users'

  console.log('Attempting to fetch total users from the database...');

  try {
    // Corrected: Use db.query directly (assuming 'db' is your mysql2/promise pool)
    const [results] = await db.query(querySql);

    // Check if results are valid and contain the expected data
    if (results && results.length > 0 && results[0].hasOwnProperty('totalUsers')) {
      const totalUsers = results[0].totalUsers;
      console.log(`Successfully fetched total users: ${totalUsers}`);
      res.json({ totalUsers: totalUsers });
    } else {
      // This case handles unexpected query results (e.g., empty results, or missing 'totalUsers' column)
      console.warn('Query for total users returned an unexpected or empty result set:', results);
      return res.status(500).json({
        error: 'Failed to retrieve total users count; unexpected database response format.',
        details: 'The database query returned an invalid or empty result for total users.'
      });
    }
  } catch (error) { // Changed 'err' to 'error' for consistency and clarity
    console.error('Database query error when fetching total users:', error.message);

    // Log more specific details from the MySQL error object
    if (error.code) {
      console.error(`MySQL Error Code: ${error.code}`);
    }
    if (error.sqlMessage) {
      console.error(`MySQL Error Message: ${error.sqlMessage}`);
    }
    if (error.sql) {
      console.error(`Faulty SQL Query: ${error.sql}`);
    }

    // Send a 500 Internal Server Error response to the client
    return res.status(500).json({
      error: 'Failed to fetch total users due to a server-side database error.',
      details: error.message // Include error message for debugging purposes (consider removing in production)
    });
  }
});

// fetch estab 
app.get('/api/total-establishments', async (req, res) => { // Added 'async'
  const querySql = 'SELECT COUNT(*) AS totalEstablishments FROM estab'; // Changed 'query' to 'querySql' for clarity

  try {
    const [results] = await db.query(querySql); // Use await db.query and destructure

    const total = results[0].totalEstablishments;
    res.json({ totalEstablishments: total });
  } catch (err) {
    console.error('Error fetching total establishments:', err);
    return res.status(500).json({ error: 'Failed to fetch total establishments' });
  }
});

// ✅ Direct endpoint for fetching total sensors
app.get('/api/total-sensors', async (req, res) => { // Added 'async'
  const querySql = 'SELECT COUNT(*) AS totalSensors FROM sensors'; // Changed 'query' to 'querySql' for clarity

  try {
    const [results] = await db.query(querySql); // Use await db.query and destructure

    const total = results[0].totalSensors;
    res.json({ totalSensors: total });
  } catch (err) {
    console.error('Error fetching total sensors:', err);
    return res.status(500).json({ error: 'Failed to fetch total sensors' });
  }
});

// fetch for the modal
app.get('/api/total-sensors', (req, res) => {
  const query = 'SELECT COUNT(*) AS totalSensors FROM sensors'; // Replace 'sensors' with your actual table name

  db.query(query, (err, results) => {
    if (err) {
      console.error('Error fetching total sensors:', err);
      return res.status(500).json({ error: 'Failed to fetch total sensors' });
    }

    const total = results[0].totalSensors;
    res.json({ totalSensors: total });
  });
});

// GET route to fetch establishments
app.get('/api/establishments', async (req, res) => {
  const sql = 'SELECT estab_name FROM estab';
  try {
    const [results] = await db.query(sql);
    const estabNames = results.map(row => row.estab_name);
    res.json(estabNames); // This will send back an array like ["Home Water Tank", "School Water Tank", ...]
  } catch (err) {
    console.error('Error querying database for establishments:', err);
    res.status(500).json({ error: 'Failed to fetch establishments' });
  }
});

/**
 * @route GET /data/turbidity
 * @description Get last 10 Turbidity readings from the database.
 * @returns {Array} An array of turbidity reading objects.
 */
app.get("/data/turbidity", async (req, res) => {
  console.log("📥 GET /data/turbidity request received");
  try {
    // Execute the query using await, which returns a promise
    // The result is an array: [rows, fields]
    const [rows, fields] = await db.query(
      "SELECT * FROM turbidity_readings ORDER BY id DESC LIMIT 10"
    );
    console.log(`✅ Turbidity API Response Sent: ${rows.length} records`);
    res.json(rows); // Send the rows (data) as JSON
  } catch (err) {
    console.error("❌ Turbidity Database Query Error:", err);
    // Send a 500 status code and a JSON error message
    return res.status(500).json({ error: "Database Query Error" });
  }
});

/**
 * @route GET /data/ph
 * @description Get last 10 pH readings from the database.
 * @returns {Array} An array of pH reading objects.
 */
app.get("/data/ph", async (req, res) => {
  console.log("📥 GET /data/ph request received");
  try {
    const [rows, fields] = await db.query(
      "SELECT * FROM phlevel_readings ORDER BY id DESC LIMIT 10"
    );
    console.log(`✅ pH API Response Sent: ${rows.length} records`);
    res.json(rows);
  } catch (err) {
    console.error("❌ pH Database Query Error:", err);
    return res.status(500).json({ error: "Database Query Error" });
  }
});

/**
 * @route GET /data/tds
 * @description Get last 10 TDS readings from the database.
 * @returns {Array} An array of TDS reading objects.
 */
app.get("/data/tds", async (req, res) => {
  console.log("📥 GET /data/tds request received");
  try {
    const [rows, fields] = await db.query(
      "SELECT * FROM tds_readings ORDER BY id DESC LIMIT 10"
    );
    console.log(`✅ TDS API Response Sent: ${rows.length} records`);
    res.json(rows);
  } catch (err) {
    console.error("❌ TDS Database Query Error:", err);
    return res.status(500).json({ error: "Database Query Error" });
  }
});

/**
 * @route GET /data/salinity
 * @description Get last 10 Salinity readings from the database.
 * @returns {Array} An array of Salinity reading objects.
 */
app.get("/data/salinity", async (req, res) => {
  console.log("📥 GET /data/salinity request received");
  try {
    const [rows, fields] = await db.query(
      "SELECT * FROM salinity_readings ORDER BY id DESC LIMIT 10"
    );
    console.log(`✅ Salinity API Response Sent: ${rows.length} records`);
    res.json(rows);
  } catch (err) {
    console.error("❌ Salinity Database Query Error:", err);
    return res.status(500).json({ error: "Database Query Error" });
  }
});

/**
 * @route GET /data/ec
 * @description Get last 10 EC readings from the database.
 * @returns {Array} An array of EC reading objects.
 */
app.get("/data/ec", async (req, res) => {
  console.log("📥 GET /data/ec request received");
  try {
    const [rows, fields] = await db.query(
      "SELECT * FROM ec_readings ORDER BY id DESC LIMIT 10"
    );
    console.log(`✅ EC API Response Sent: ${rows.length} records`);
    res.json(rows);
  } catch (err) {
    console.error("❌ EC Database Query Error:", err);
    return res.status(500).json({ error: "Database Query Error" });
  }
});

/**
 * @route GET /data/ec_compensated
 * @description Get last 10 EC Compensated readings from the database.
 * @returns {Array} An array of EC Compensated reading objects.
 */
app.get("/data/ec_compensated", async (req, res) => {
  console.log("📥 GET /data/ec_compensated request received");
  try {
    const [rows, fields] = await db.query(
      "SELECT * FROM ec_compensated_readings ORDER BY id DESC LIMIT 10"
    );
    console.log(`✅ EC Compensated API Response Sent: ${rows.length} records`);
    res.json(rows);
  } catch (err) {
    console.error("❌ EC Compensated Database Query Error:", err);
    return res.status(500).json({ error: "Database Query Error" });
  }
});

/**
 * @route GET /data/temperature
 * @description Get last 10 Temperature readings from the database.
 * @returns {Array} An array of Temperature reading objects.
 */
app.get("/data/temperature", async (req, res) => {
  console.log("📥 GET /data/temperature request received");
  try {
    const [rows, fields] = await db.query(
      "SELECT * FROM temperature_readings ORDER BY id DESC LIMIT 10"
    );
    console.log(`✅ Temperature API Response Sent: ${rows.length} records`);
    res.json(rows);
  } catch (err) {
    console.error("❌ Temperature Database Query Error:", err);
    return res.status(500).json({ error: "Database Query Error" });
  }
});

// Start servers
server.listen(port, () => {
  console.log(`🚀 Backend running on http://localhost:${port}`);
});

io.listen(3001, () => {
  console.log("🔌 WebSocket server running on port 3001");
});

// Helper function to get the WHERE clause for time filtering
function getTimeFilterClause(period) {
  let timeClause = '';
  switch (period) {
    case '24h':
      // Assumes 'timestamp' or 'created_at' or 'reading_time' is the column name
      timeClause = "WHERE timestamp >= NOW() - INTERVAL 24 HOUR";
      break;
    case '7d':
      timeClause = "WHERE timestamp >= NOW() - INTERVAL 7 DAY";
      break;
    case '30d':
      timeClause = "WHERE timestamp >= NOW() - INTERVAL 30 DAY";
      break;
    default:
      // Default to 24 hours if no valid period is provided
      timeClause = "WHERE timestamp >= NOW() - INTERVAL 24 HOUR";
      break;
  }
  return timeClause;
}

// 5. API Routes (Updated to handle 'period' query parameter)

/**
 * @route GET /data/turbidity
 * @description Get historical Turbidity readings based on the period (24h, 7d, 30d).
 * @queryParam {string} period - '24h', '7d', '30d'
 * @returns {Array} An array of turbidity reading objects.
 */
app.get("/data/turbidity", async (req, res) => {
  console.log("📥 GET /data/turbidity request received");
  const period = req.query.period || '24h'; // Default to 24h if not provided
  const timeFilter = getTimeFilterClause(period);

  // IMPORTANT: Adjust 'timestamp' to your actual timestamp column name (e.g., 'created_at', 'reading_time')
  // For this example, I'm using 'timestamp'. If your table has 'created_at', change the timeFilter function.
  // Also, consider removing 'LIMIT 10' if you want all data for the period.
  // For now, I'm keeping 'LIMIT 10' as per your original request, but it might not show all data for longer periods.
  const query = `SELECT * FROM turbidity_readings ${timeFilter} ORDER BY timestamp DESC LIMIT 100`; // Increased limit for better graph data
  console.log(`Executing query for turbidity: ${query}`);

  try {
    const [rows, fields] = await db.query(query);
    console.log(`✅ Turbidity API Response Sent: ${rows.length} records`);
    res.json(rows);
  } catch (err) {
    console.error("❌ Turbidity Database Query Error:", err);
    return res.status(500).json({ error: "Database Query Error" });
  }
});

/**
 * @route GET /data/ph
 * @description Get historical pH readings based on the period (24h, 7d, 30d).
 * @queryParam {string} period - '24h', '7d', '30d'
 * @returns {Array} An array of pH reading objects.
 */
app.get("/data/ph", async (req, res) => {
  console.log("📥 GET /data/ph request received");
  const period = req.query.period || '24h';
  const timeFilter = getTimeFilterClause(period);
  const query = `SELECT * FROM phlevel_readings ${timeFilter} ORDER BY timestamp DESC LIMIT 100`; // Increased limit

  try {
    const [rows, fields] = await db.query(query);
    console.log(`✅ pH API Response Sent: ${rows.length} records`);
    res.json(rows);
  } catch (err) {
    console.error("❌ pH Database Query Error:", err);
    return res.status(500).json({ error: "Database Query Error" });
  }
});

/**
 * @route GET /data/tds
 * @description Get historical TDS readings based on the period (24h, 7d, 30d).
 * @queryParam {string} period - '24h', '7d', '30d'
 * @returns {Array} An array of TDS reading objects.
 */
app.get("/data/tds", async (req, res) => {
  console.log("📥 GET /data/tds request received");
  const period = req.query.period || '24h';
  const timeFilter = getTimeFilterClause(period);
  const query = `SELECT * FROM tds_readings ${timeFilter} ORDER BY timestamp DESC LIMIT 100`; // Increased limit

  try {
    const [rows, fields] = await db.query(query);
    console.log(`✅ TDS API Response Sent: ${rows.length} records`);
    res.json(rows);
  } catch (err) {
    console.error("❌ TDS Database Query Error:", err);
    return res.status(500).json({ error: "Database Query Error" });
  }
});

/**
 * @route GET /data/salinity
 * @description Get historical Salinity readings based on the period (24h, 7d, 30d).
 * @queryParam {string} period - '24h', '7d', '30d'
 * @returns {Array} An array of Salinity reading objects.
 */
app.get("/data/salinity", async (req, res) => {
  console.log("📥 GET /data/salinity request received");
  const period = req.query.period || '24h';
  const timeFilter = getTimeFilterClause(period);
  const query = `SELECT * FROM salinity_readings ${timeFilter} ORDER BY timestamp DESC LIMIT 100`; // Increased limit

  try {
    const [rows, fields] = await db.query(query);
    console.log(`✅ Salinity API Response Sent: ${rows.length} records`);
    res.json(rows);
  } catch (err) {
    console.error("❌ Salinity Database Query Error:", err);
    return res.status(500).json({ error: "Database Query Error" });
  }
});

/**
 * @route GET /data/ec
 * @description Get historical EC readings based on the period (24h, 7d, 30d).
 * @queryParam {string} period - '24h', '7d', '30d'
 * @returns {Array} An array of EC reading objects.
 */
app.get("/data/ec", async (req, res) => {
  console.log("📥 GET /data/ec request received");
  const period = req.query.period || '24h';
  const timeFilter = getTimeFilterClause(period);
  const query = `SELECT * FROM ec_readings ${timeFilter} ORDER BY timestamp DESC LIMIT 100`; // Increased limit

  try {
    const [rows, fields] = await db.query(query);
    console.log(`✅ EC API Response Sent: ${rows.length} records`);
    res.json(rows);
  } catch (err) {
    console.error("❌ EC Database Query Error:", err);
    return res.status(500).json({ error: "Database Query Error" });
  }
});

/**
 * @route GET /data/ec_compensated
 * @description Get historical EC Compensated readings based on the period (24h, 7d, 30d).
 * @queryParam {string} period - '24h', '7d', '30d'
 * @returns {Array} An array of EC Compensated reading objects.
 */
app.get("/data/ec_compensated", async (req, res) => {
  console.log("📥 GET /data/ec_compensated request received");
  const period = req.query.period || '24h';
  const timeFilter = getTimeFilterClause(period);
  const query = `SELECT * FROM ec_compensated_readings ${timeFilter} ORDER BY timestamp DESC LIMIT 100`; // Increased limit

  try {
    const [rows, fields] = await db.query(query);
    console.log(`✅ EC Compensated API Response Sent: ${rows.length} records`);
    res.json(rows);
  } catch (err) {
    console.error("❌ EC Compensated Database Query Error:", err);
    return res.status(500).json({ error: "Database Query Error" });
  }
});

/**
 * @route GET /data/temperature
 * @description Get historical Temperature readings based on the period (24h, 7d, 30d).
 * @queryParam {string} period - '24h', '7d', '30d'
 * @returns {Array} An array of Temperature reading objects.
 */
app.get("/data/temperature", async (req, res) => {
  console.log("📥 GET /data/temperature request received");
  const period = req.query.period || '24h';
  const timeFilter = getTimeFilterClause(period);
  const query = `SELECT * FROM temperature_readings ${timeFilter} ORDER BY timestamp DESC LIMIT 100`; // Increased limit

  try {
    const [rows, fields] = await db.query(query);
    console.log(`✅ Temperature API Response Sent: ${rows.length} records`);
    res.json(rows);
  } catch (err) {
    console.error("❌ Temperature Database Query Error:", err);
    return res.status(500).json({ error: "Database Query Error" });
  }
});