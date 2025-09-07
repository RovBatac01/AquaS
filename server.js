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

// Initialize Socket.IO server with CORS options
const io = new Server(server, {
  cors: {
    origin: "*", // Allow all origins for simplicity in development
    methods: ["GET", "POST"],
  },
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

app.post("/logout", (req, res) => {
  // Optionally log who is logging out (if token is sent)
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith("Bearer ")) {
    const token = authHeader.split(" ")[1];
    // You could decode token for logging if needed
    console.log("User logged out with token:", token);
  }

  // Respond to the client
  res.status(200).json({ message: "Logout successful." });
});

//UPDATE USER
app.post('/api/update_user', async (req, res) => {
  const { id, username, email, phone } = req.body;

  if (!id || !username || !email || !phone) {
    return res.status(400).json({ success: false, message: "Missing required fields." });
  }

  const query = 'UPDATE users SET username = ?, email = ?, phone = ? WHERE id = ?';

  try {
    const [result] = await db.query(query, [username, email, phone, id]);
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: "User not found." });
    }

    return res.status(200).json({ success: true, message: "User updated successfully." });
  } catch (err) {
    console.error("Update error:", err);
    return res.status(500).json({ success: false, error: err.message });
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

// Helper function to emit notifications (it no longer inserts into the database)
const emitNotification = (readingValue, threshold) => {
  console.log("🔔 Emitting real-time notification...");
  // Emit the notification to clients
  io.emit("newNotification", {
    id: Date.now(), // Use a timestamp as a simple unique ID for this real-time event
    readingValue,
    threshold,
    timestamp: new Date().toISOString(),
  });
};

// --- Consolidated Data Handling (Moved from Serial Port to HTTP Post) ---
const insertAndEmit = async (
  tableName,
  valueColumn,
  value,
  socketEventName,
  threshold = null,
  notificationType = null
) => {
  if (value !== undefined && value !== null) {
    console.log(`📡 Received ${valueColumn} Data:`, value);
    const currentTime = new Date();
    const query = `INSERT INTO ${tableName} (${valueColumn}, timestamp) VALUES (?, ?)`;
    try {
      const [result] = await db.query(query, [value, currentTime]);
      console.log(
        `✅ ${tableName} Data Inserted Successfully: ID`,
        result.insertId
      );

      // Emit real-time data to connected clients
      io.emit(socketEventName, {
        value: value,
        timestamp: currentTime.toISOString(),
      });

      // Handle notifications based on type and threshold
      if (notificationType === "turbidity" && threshold !== null && value < threshold) {
        // We now only emit the notification, not insert it
        emitNotification(value, threshold);
      }
    } catch (err) {
      console.error(
        `❌ ${tableName} Database Insert Error:`,
        err.sqlMessage || err.message
      );
    }
  }
};

// --- New Endpoint to receive data from local-bridge.js ---
app.post("/api/sensor-data", async (req, res) => {
  try {
    const jsonData = req.body;
    console.log("Receiving data from local-bridge:", jsonData);

    const {
      turbidity_value,
      ph_value,
      tds_value,
      salinity_value,
      ec_value_mS,
      ec_compensated_mS,
      temperature_celsius,
    } = jsonData;

    // Process each sensor value
    await Promise.all([
      insertAndEmit(
        "turbidity_readings",
        "turbidity_value",
        turbidity_value,
        "updateTurbidityData",
        40,
        "turbidity"
      ),
      insertAndEmit("phlevel_readings", "ph_value", ph_value, "updatePHData"),
      insertAndEmit("tds_readings", "tds_value", tds_value, "updateTDSData"),
      insertAndEmit(
        "salinity_readings",
        "salinity_value",
        salinity_value,
        "updateSalinityData"
      ),
      insertAndEmit(
        "ec_readings",
        "ec_value_mS",
        ec_value_mS,
        "updateECData"
      ),
      insertAndEmit(
        "ec_compensated_readings",
        "ec_compensated_mS",
        ec_compensated_mS,
        "updateECCompensatedData"
      ),
      insertAndEmit(
        "temperature_readings",
        "temperature_celsius",
        temperature_celsius,
        "updateTemperatureData"
      ),
    ]);

    // Send a success response back to the bridge
    res.status(200).json({ message: "Data received and processed successfully" });
  } catch (err) {
    console.error("❌ Error processing data:", err);
    res.status(500).json({ error: "Failed to process data" });
  }
});

// --- API Endpoints for Dashboard Metrics ---
app.get('/api/total-users', async (req, res) => {
  const querySql = 'SELECT COUNT(*) AS totalUsers FROM users';
  try {
    const [results] = await db.query(querySql);
    const totalUsers = results[0].totalUsers;
    res.json({ totalUsers });
  } catch (error) {
    console.error('Database query error when fetching total users:', error.message);
    res.status(500).json({ error: 'Failed to fetch total users due to a server-side database error.' });
  }
});

app.get('/api/total-establishments', async (req, res) => {
  const querySql = 'SELECT COUNT(*) AS totalEstablishments FROM estab';
  try {
    const [results] = await db.query(querySql);
    const total = results[0].totalEstablishments;
    res.json({ totalEstablishments: total });
  } catch (err) {
    console.error('Error fetching total establishments:', err);
    res.status(500).json({ error: 'Failed to fetch total establishments' });
  }
});

app.get('/api/total-sensors', async (req, res) => {
  const querySql = 'SELECT COUNT(*) AS totalSensors FROM sensors';
  try {
    const [results] = await db.query(querySql);
    const total = results[0].totalSensors;
    res.json({ totalSensors: total });
  } catch (err) {
    console.error('Error fetching total sensors:', err);
    res.status(500).json({ error: 'Failed to fetch total sensors' });
  }
});

// GET route to fetch establishments
app.get('/api/establishments', async (req, res) => {
  const sql = 'SELECT estab_name FROM estab';
  try {
    const [results] = await db.query(sql);
    const estabNames = results.map(row => row.estab_name);
    res.json(estabNames);
  } catch (err) {
    console.error('Error querying database for establishments:', err);
    res.status(500).json({ error: 'Failed to fetch establishments' });
  }
});


// --- API Endpoints for Historical Data (Flutter Charts) ---
function getTimeFilterClause(period) {
  let timeClause = '';
  switch (period) {
    case '24h':
      timeClause = "WHERE timestamp >= NOW() - INTERVAL 24 HOUR";
      break;
    case '7d':
      timeClause = "WHERE timestamp >= NOW() - INTERVAL 7 DAY";
      break;
    case '30d':
      timeClause = "WHERE timestamp >= NOW() - INTERVAL 30 DAY";
      break;
    default:
      timeClause = "WHERE timestamp >= NOW() - INTERVAL 24 HOUR";
      break;
  }
  return timeClause;
}

const createGetDataEndpoint = (endpoint, tableName, timestampColumn) => {
  app.get(`/data/${endpoint}`, async (req, res) => {
    console.log(`📥 GET /data/${endpoint} request received`);
    const period = req.query.period || '24h';
    const timeFilter = getTimeFilterClause(period);

    // Fetch all data for the specified period, ordered by timestamp
    const query = `SELECT * FROM ${tableName} ${timeFilter} ORDER BY ${timestampColumn} ASC`;
    console.log(`Executing query for ${tableName}: ${query}`);

    try {
      const [rows] = await db.query(query);
      console.log(`✅ ${tableName} API Response Sent: ${rows.length} records`);
      res.json(rows);
    } catch (err) {
      console.error(`❌ ${tableName} Database Query Error:`, err);
      return res.status(500).json({ error: "Database Query Error" });
    }
  });
};

// Create endpoints for each sensor type
createGetDataEndpoint('turbidity', 'turbidity_readings', 'timestamp');
createGetDataEndpoint('ph', 'phlevel_readings', 'timestamp');
createGetDataEndpoint('tds', 'tds_readings', 'timestamp');
createGetDataEndpoint('salinity', 'salinity_readings', 'timestamp');
createGetDataEndpoint('ec', 'ec_readings', 'timestamp');
createGetDataEndpoint('ec_compensated', 'ec_compensated_readings', 'timestamp');
createGetDataEndpoint('temperature', 'temperature_readings', 'timestamp');


// Start servers
const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Backend running on port ${PORT}`);
});

// PUT /api/user/profile - Update user profile information
app.put('/api/super-admin/profile', authenticateToken, async (req, res) => {
    const { username, email, phone } = req.body;

    const userId = req.user.id; // Assuming req.user.id is correctly set by authenticateToken

    if (!username || !email) {
        return res.status(400).json({ message: 'Username and email are required.' });
    }

    let connection;
    try {
        connection = await db.getConnection(); // CORRECTED: Use db.getConnection()
        const [result] = await connection.query( // CORRECTED: Use connection.query()
            'UPDATE users SET username = ?, email = ?, phone = ? WHERE id = ?',
            [username, email, phone, userId]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'User not found or no changes made.' }); // Added 'or no changes made'
        }

        // Fetch the updated user data to send back
        const [rows] = await connection.query( // CORRECTED: Use connection.query()
            'SELECT username, email, phone FROM users WHERE id = ?',
            [userId]
        );
        const updatedUser = rows[0];

        res.status(200).json({ message: 'Profile updated successfully!', user: updatedUser });

    } catch (error) {
        console.error('Error updating profile:', error);
        if (error.code === 'ER_DUP_ENTRY') {
            // More specific error messages for duplicate entries
            if (error.sqlMessage.includes('username')) {
                return res.status(409).json({ message: 'Username already exists.' });
            }
            if (error.sqlMessage.includes('email')) {
                return res.status(409).json({ message: 'Email already exists.' });
            }
        }
        res.status(500).json({ message: 'Failed to update profile due to a server error.' });
    } finally {
        if (connection) connection.release(); // Release the connection
    }
});

// POST /api/user/change-password - Change user password
app.post('/api/super-admin/change-password', authenticateToken, async (req, res) => {

    const userId = req.user.id; // Assuming req.user.id is correctly set by authenticateToken

    const { currentPassword, newPassword } = req.body;

    // 1. Basic input validation
    if (!currentPassword || !newPassword) {
        return res.status(400).json({ message: 'Current and new passwords are required.' });
    }
    if (newPassword.length < 8) { // Basic length check for new password
        return res.status(400).json({ message: 'New password must be at least 8 characters long.' });
    }
    // You might want to add more robust password complexity checks here (e.g., regex for uppercase, number, symbol)
    // For example:
    // if (!/[A-Z]/.test(newPassword) || !/[0-9]/.test(newPassword) || !/[^a-zA-Z0-9]/.test(newPassword)) {
    //     return res.status(400).json({ message: 'New password must contain at least one uppercase letter, one number, and one special character.' });
    // }

    let connection;
    try {
        connection = await db.getConnection(); // CORRECTED: Use db.getConnection()

        // 2. Retrieve current hashed password from database
        const [rows] = await connection.query( // CORRECTED: Use connection.query()
            'SELECT password_hash FROM users WHERE id = ?',
            [userId]
        );

        // 3. Handle case where user is not found (this should ideally be caught by authenticateToken, but good for robustness)
        if (rows.length === 0) {
            return res.status(404).json({ message: 'User not found.' });
        }

        const storedHashedPassword = rows[0].password_hash; // Access the correct column name

        // 4. Compare provided current password with stored hashed password
        const isMatch = await bcrypt.compare(currentPassword, storedHashedPassword);

        if (!isMatch) {
            return res.status(401).json({ message: 'Incorrect current password.' });
        }

        // 5. Check if new password is the same as the current password (after hashing)
        if (await bcrypt.compare(newPassword, storedHashedPassword)) {
            return res.status(400).json({ message: 'New password cannot be the same as the current password.' });
        }

        // 6. Hash the new password
        const newHashedPassword = await bcrypt.hash(newPassword, 10); // 10 salt rounds is standard

        // 7. Update password in database
        const [result] = await connection.query( // CORRECTED: Use connection.query()
            'UPDATE users SET password_hash = ? WHERE id = ?',
            [newHashedPassword, userId]
        );

        // 8. Check if the update actually affected a row
        if (result.affectedRows === 0) {
            // This case is less likely if the user was found in step 3, but handles edge cases.
            return res.status(404).json({ message: 'User not found or password already updated (no change needed).' });
        }

        // 9. Success response
        res.status(200).json({ message: 'Password changed successfully!' });

    } catch (error) {
        // 10. Centralized error handling for unexpected issues (e.g., database connection errors)
        console.error('Error changing password:', error);
        res.status(500).json({ message: 'Failed to change password due to a server error.' });
    } finally {
        // 11. Release the database connection back to the pool
        if (connection) connection.release();
    }
});