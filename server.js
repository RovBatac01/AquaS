// Import necessary modules
const express = require("express");
const mysql = require('mysql2/promise');
const bodyParser = require("body-parser");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");
const bcrypt = require("bcrypt");
const saltRounds = 10;
const https = require("https");
const { v4: uuidv4 } = require("uuid");
const nodemailer = require("nodemailer");
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'my$uper$ecreTKey9876543210strong!';

const app = express();
const port = process.env.PORT || 5000;

// Create the HTTP server instance BEFORE the Socket.IO server
const server = http.createServer(app);

const otpStorage = {};

// Nodemailer setup
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "aquasense35@gmail.com",
    pass: "ijmcosuxpnioehya",
  },
});

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(cors());

// Middleware to verify JWT and get user ID
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token == null) {
        console.log("No token provided.");
        return res.sendStatus(401);
    }

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            console.error("JWT verification error:", err);
            return res.sendStatus(403);
        }
        req.user = user;
        next();
    });
};

// Initialize Socket.IO server with CORS options
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
});

// MySQL Connection
const db = mysql.createPool({
  host: "aquasense.c10u8c6s49c0.ap-southeast-2.rds.amazonaws.com",
  user: "admin",
  password: process.env.DB_PASSWORD || "aquasense123", // Use environment variable for password
  database: "aquasense",
  port: 3306,
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
    console.error('Original Email Error:', error);
    throw new Error('Failed to send OTP. Please check your email configuration. Original error: ' + error.message);
  }
}

// Routes
app.post("/register", async (req, res) => {
  const { username, email, phone, password, confirm_password } = req.body;

  if (!username || !email || !password || !confirm_password) {
    return res.status(400).json({ error: "All fields are required" });
  }

  if (password !== confirm_password) {
    return res.status(400).json({ error: "Passwords do not match" });
  }

  try {
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    const sql = "INSERT INTO users (username, email, phone, password_hash, role) VALUES (?, ?, ?, ?, 'user')";
    const [result] = await db.query(sql, [username, email, phone || null, hashedPassword]);
    res.json({
      message: "User registered successfully!",
      userId: result.insertId,
    });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: "Server error" });
  }
});

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
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith("Bearer ")) {
    const token = authHeader.split(" ")[1];
    console.log("User logged out with token:", token);
  }
  res.status(200).json({ message: "Logout successful." });
});

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

app.get("/users", async (req, res) => {
  const sql = "SELECT id, username, role FROM users";
  try {
    const [results] = await db.query(sql);
    res.status(200).json(results);
  } catch (err) {
    console.error("Database error fetching users:", err);
    return res.status(500).json({ error: "Failed to fetch users from database." });
  }
});

app.put("/users/:id", async (req, res) => {
  const userId = req.params.id;
  const { username, role } = req.body;

  if (!username || !role) {
    return res.status(400).json({ error: "Username and role are required for update." });
  }
  const sql = "UPDATE users SET username = ?, role = ? WHERE id = ?";
  try {
    const [result] = await db.query(sql, [username, role, userId]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "User not found or no changes made." });
    }
    res.status(200).json({ message: "User updated successfully!" });
  } catch (err) {
    console.error("Database error updating user:", err);
    return res.status(500).json({ error: "Failed to update user in database." });
  }
});

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
    return res.status(500).json({ error: "Failed to delete user from database." });
  }
});

app.post("/api/forgot-password", async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ success: false, message: "Email is required" });
  }

  try {
    const [users] = await db.query("SELECT * FROM users WHERE email = ?", [email]);
    const user = users[0];

    if (!user) {
      return res.status(404).json({ success: false, message: "Email not found. Please check your email address." });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiry = Date.now() + 300000;
    otpStorage[email] = { otp, expiry };
    await sendOTP(email, otp);
    res.json({ success: true, message: "OTP sent successfully. Please check your email." });
  } catch (error) {
    console.error("Error during forgot-password process:", error);
    return res.status(500).json({ success: false, message: "Internal server error: " + error.message });
  }
});

app.post("/api/verify-otp", async (req, res) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    return res.status(400).json({ success: false, message: "Email and OTP are required" });
  }

  try {
    const [users] = await db.query("SELECT * FROM users WHERE email = ?", [email]);
    const user = users[0];
    if (!user) {
      return res.status(400).json({ success: false, message: "Invalid email." });
    }

    const storedOTP = otpStorage[email];
    if (!storedOTP) {
      return res.status(404).json({ success: false, message: "OTP not found or expired. Please request a new one." });
    }

    if (storedOTP.otp === otp) {
      if (storedOTP.expiry < Date.now()) {
        delete otpStorage[email];
        return res.status(410).json({ success: false, message: "OTP expired. Please request a new one." });
      }

      await db.query('UPDATE users SET is_verified = 1 WHERE email = ?', [email]);
      res.json({ success: true, message: "OTP verified successfully. You can now change your password." });
    } else {
      return res.status(400).json({ success: false, message: "Invalid OTP." });
    }
  } catch (error) {
    console.error("Error verifying OTP:", error);
    return res.status(500).json({ success: false, message: "Internal Server Error", error: error.message });
  }
});

app.post("/api/change-password", async (req, res) => {
  const { email, new_password: newPassword } = req.body;

  if (!email || !newPassword) {
    return res.status(400).json({ success: false, message: "Email and new password are required" });
  }

  try {
    const [users] = await db.query("SELECT * FROM users WHERE email = ?", [email]);
    const user = users[0];

    if (!user) {
      return res.status(404).json({ success: false, message: "Email not found." });
    }

    if (user.is_verified !== 1) {
      return res.status(403).json({ success: false, message: "Password change request is not valid. Verify OTP first." });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({ success: false, message: "Password must be at least 8 characters long" });
    }

    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);
    const sql = "UPDATE users SET password_hash = ? WHERE email = ?";
    const [result] = await db.query(sql, [hashedPassword, email]);

    res.json({
      success: true,
      message: "Password changed successfully. Please redirect to login.",
      redirect: "/login"
    });

  } catch (error) {
    console.error("Error changing password:", error);
    return res.status(500).json({ success: false, message: "Internal server error: " + error.message });
  }
});

app.get('/api/user/profile', authenticateToken, async (req, res) => {
  const userId = req.user.id;
  const username = req.user.username;

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
    const [rows] = await db.execute('SELECT * FROM events ORDER BY event_date, time');
    res.json(rows);
  } catch (err) {
    console.error('Error fetching all events:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/events', async (req, res) => {
  const { date } = req.query;

  if (!date) {
    return res.status(400).json({ error: 'Date parameter is required.' });
  }

  try {
    const [rows] = await db.execute('SELECT * FROM events WHERE event_date = ? ORDER BY time, id', [date]);
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
    const [result] = await db.execute('INSERT INTO events (title, time, description, event_date) VALUES (?, ?, ?, ?)', [title, time || null, description || null, event_date]);
    const [newEventRows] = await db.execute('SELECT * FROM events WHERE id = ?', [result.insertId]);
    res.status(201).json(newEventRows[0]);
  } catch (err) {
    console.error('Error adding event:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.delete('/api/events/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const [result] = await db.execute('DELETE FROM events WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Event not found.' });
    }
    res.status(200).json({ message: `Event with ID ${id} deleted successfully.` });
  } catch (err) {
    console.error('Error deleting event:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/notifications/superadmin', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT id, type, title, message, timestamp AS createdAt, is_read AS `read` FROM notif ORDER BY timestamp DESC');
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

app.get('/api/notifications/admin', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT id, type, title, message, timestamp AS createdAt, is_read AS `read` FROM notif ORDER BY timestamp DESC');
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

// Helper function to emit notifications
const emitNotification = (readingValue, threshold) => {
  console.log("🔔 Emitting real-time notification...");
  io.emit("newNotification", {
    id: Date.now(),
    readingValue,
    threshold,
    timestamp: new Date().toISOString(),
  });
};

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
      console.log(`✅ ${tableName} Data Inserted Successfully: ID`, result.insertId);

      io.emit(socketEventName, {
        value: value,
        timestamp: currentTime.toISOString(),
      });

      if (notificationType === "turbidity" && threshold !== null && value < threshold) {
        emitNotification(value, threshold);
      }
    } catch (err) {
      console.error(`❌ ${tableName} Database Insert Error:`, err.sqlMessage || err.message);
    }
  }
};

app.post("/api/sensor-data", async (req, res) => {
  try {
    const jsonData = req.body;
    console.log("Receiving data from local-bridge:", jsonData);

    const {
      turbidity_value, ph_value, tds_value, salinity_value, ec_value_mS, ec_compensated_mS, temperature_celsius
    } = jsonData;

    await Promise.all([
      insertAndEmit("turbidity_readings", "turbidity_value", turbidity_value, "updateTurbidityData", 40, "turbidity"),
      insertAndEmit("phlevel_readings", "ph_value", ph_value, "updatePHData"),
      insertAndEmit("tds_readings", "tds_value", tds_value, "updateTDSData"),
      insertAndEmit("salinity_readings", "salinity_value", salinity_value, "updateSalinityData"),
      insertAndEmit("ec_readings", "ec_value_mS", ec_value_mS, "updateECData"),
      insertAndEmit("ec_compensated_readings", "ec_compensated_mS", ec_compensated_mS, "updateECCompensatedData"),
      insertAndEmit("temperature_readings", "temperature_celsius", temperature_celsius, "updateTemperatureData"),
    ]);

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

// --- Device-Scoped Endpoints for Admin Dashboard ---

// Helper: derive device_id for a given user id
async function getDeviceIdForUser(userId) {
  try {
    // Check if users table has device_id column
    const [userDeviceCol] = await db.query(
      'SELECT COUNT(*) AS cnt FROM information_schema.columns WHERE table_schema = ? AND table_name = ? AND column_name = ?',
      ['aquasense', 'users', 'device_id']
    );
    if (userDeviceCol[0].cnt > 0) {
      const [rows] = await db.query('SELECT device_id FROM users WHERE id = ?', [userId]);
      if (rows.length > 0 && rows[0].device_id) return rows[0].device_id;
    }

    // Otherwise, check if users has estab_id and estab has device_id
    const [userEstabCol] = await db.query(
      'SELECT COUNT(*) AS cnt FROM information_schema.columns WHERE table_schema = ? AND table_name = ? AND column_name = ?',
      ['aquasense', 'users', 'estab_id']
    );
    if (userEstabCol[0].cnt > 0) {
      const [rows] = await db.query(
        'SELECT e.device_id FROM users u JOIN estab e ON u.estab_id = e.id WHERE u.id = ?',
        [userId]
      );
      if (rows.length > 0 && rows[0].device_id) return rows[0].device_id;
    }

    // Not found
    return null;
  } catch (err) {
    console.error('Error deriving device id for user:', err);
    return null;
  }
}

// Authenticated endpoint: totals scoped to the authenticated user's device
app.get('/api/my/total-users', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const deviceId = await getDeviceIdForUser(userId);
    if (!deviceId) {
      console.warn(`No device mapping found for user ${userId}; returning zero totalUsers.`);
      return res.json({ totalUsers: 0 });
    }

    // Count users associated with this device
    // Try users.estab_id -> estab.device_id first
    try {
      const querySql = `SELECT COUNT(*) AS totalUsers FROM users u JOIN estab e ON u.estab_id = e.id WHERE e.device_id = ?`;
      const [rows] = await db.query(querySql, [deviceId]);
      return res.json({ totalUsers: rows[0].totalUsers || 0 });
    } catch (innerErr) {
      // Fallback to users.device_id
      try {
        const [rows2] = await db.query('SELECT COUNT(*) AS totalUsers FROM users WHERE device_id = ?', [deviceId]);
        return res.json({ totalUsers: rows2[0].totalUsers || 0 });
      } catch (err) {
        console.error('Error fetching my total users:', err);
        return res.status(500).json({ error: 'Failed to fetch my total users' });
      }
    }
  } catch (error) {
    console.error('Error in /api/my/total-users:', error);
    res.status(500).json({ error: 'Server error while fetching my total users' });
  }
});

app.get('/api/my/total-sensors', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const deviceId = await getDeviceIdForUser(userId);
    if (!deviceId) {
      console.warn(`No device mapping found for user ${userId}; returning zero totalSensors.`);
      return res.json({ totalSensors: 0 });
    }

    // Try sensors.device_id first
    const [sensorsDeviceCol] = await db.query(
      'SELECT COUNT(*) AS cnt FROM information_schema.columns WHERE table_schema = ? AND table_name = ? AND column_name = ?',
      ['aquasense', 'sensors', 'device_id']
    );
    if (sensorsDeviceCol[0].cnt > 0) {
      const [rows] = await db.query('SELECT COUNT(*) AS totalSensors FROM sensors WHERE device_id = ?', [deviceId]);
      return res.json({ totalSensors: rows[0].totalSensors || 0 });
    }

    // Fallback: sensors may reference estab_id
    const [sensorsEstabCol] = await db.query(
      'SELECT COUNT(*) AS cnt FROM information_schema.columns WHERE table_schema = ? AND table_name = ? AND column_name = ?',
      ['aquasense', 'sensors', 'estab_id']
    );
    if (sensorsEstabCol[0].cnt > 0) {
      const [rows] = await db.query('SELECT COUNT(*) AS totalSensors FROM sensors s JOIN estab e ON s.estab_id = e.id WHERE e.device_id = ?', [deviceId]);
      return res.json({ totalSensors: rows[0].totalSensors || 0 });
    }

    // If no mapping, return 0
    return res.json({ totalSensors: 0 });
  } catch (error) {
    console.error('Error in /api/my/total-sensors:', error);
    res.status(500).json({ error: 'Server error while fetching my total sensors' });
  }
});

// GET device-scoped total users by deviceId (public endpoint)
app.get('/api/total-users-by-device/:deviceId', async (req, res) => {
  const { deviceId } = req.params;

  if (!deviceId) {
    return res.status(400).json({ error: 'deviceId parameter is required' });
  }

  try {
    // Check for presence of columns in users table to determine mapping
    const [estabIdColumn] = await db.query(
      'SELECT COUNT(*) AS cnt FROM information_schema.columns WHERE table_schema = ? AND table_name = ? AND column_name = ?',
      ['aquasense', 'users', 'estab_id']
    );

    const [userDeviceIdColumn] = await db.query(
      'SELECT COUNT(*) AS cnt FROM information_schema.columns WHERE table_schema = ? AND table_name = ? AND column_name = ?',
      ['aquasense', 'users', 'device_id']
    );

    const hasEstabId = estabIdColumn[0].cnt > 0;
    const hasUserDeviceId = userDeviceIdColumn[0].cnt > 0;

    let querySql;
    let params = [deviceId];

    if (hasEstabId) {
      // users.estab_id -> estab.id, filter estab.device_id = deviceId
      querySql = `SELECT COUNT(*) AS totalUsers FROM users u JOIN estab e ON u.estab_id = e.id WHERE e.device_id = ?`;
    } else if (hasUserDeviceId) {
      // users.device_id directly references device
      querySql = `SELECT COUNT(*) AS totalUsers FROM users WHERE device_id = ?`;
    } else {
      return res.status(400).json({ error: 'Unable to determine user-to-device mapping. Please ensure users table has either estab_id or device_id column.' });
    }

    const [rows] = await db.query(querySql, params);
    const totalUsers = rows[0].totalUsers || 0;
    res.json({ totalUsers });
  } catch (error) {
    console.error('Error fetching device-scoped total users:', error);
    res.status(500).json({ error: 'Failed to fetch total users for device due to a server-side database error.' });
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
    const period = req.query.period || '24h';
    const timeFilter = getTimeFilterClause(period);
    const query = `SELECT * FROM ${tableName} ${timeFilter} ORDER BY ${timestampColumn} ASC`;
    try {
      const [rows] = await db.query(query);
      res.json(rows);
    } catch (err) {
      console.error(`❌ ${tableName} Database Query Error:`, err);
      return res.status(500).json({ error: "Database Query Error" });
    }
  });
};

createGetDataEndpoint('turbidity', 'turbidity_readings', 'timestamp');
createGetDataEndpoint('ph', 'phlevel_readings', 'timestamp');
createGetDataEndpoint('tds', 'tds_readings', 'timestamp');
createGetDataEndpoint('salinity', 'salinity_readings', 'timestamp');
createGetDataEndpoint('ec', 'ec_readings', 'timestamp');
createGetDataEndpoint('ec_compensated', 'ec_compensated_readings', 'timestamp');
createGetDataEndpoint('temperature', 'temperature_readings', 'timestamp');

// Listen on the assigned port
server.listen(port, () => {
  console.log(`🚀 Backend running on port ${port}`);
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