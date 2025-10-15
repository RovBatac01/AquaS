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

// Initialize database tables for device access system
async function initializeDeviceAccessTables() {
  let connection;
  try {
    connection = await db.getConnection();
    
    // Create devices table if it doesn't exist
    await connection.query(`
      CREATE TABLE IF NOT EXISTS devices (
        id INT AUTO_INCREMENT PRIMARY KEY,
        device_id VARCHAR(100) UNIQUE NOT NULL,
        device_name VARCHAR(255),
        admin_id INT NOT NULL,
        location VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    // Create device_access_requests table
    await connection.query(`
      CREATE TABLE IF NOT EXISTS device_access_requests (
        id VARCHAR(36) PRIMARY KEY,
        user_id INT NOT NULL,
        device_id VARCHAR(100) NOT NULL,
        admin_id INT NOT NULL,
        message TEXT,
        status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
        response_message TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        responded_at TIMESTAMP NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_admin_status (admin_id, status),
        INDEX idx_user_device (user_id, device_id)
      )
    `);

    // Create user_device_access table (matching existing structure)
    await connection.query(`
      CREATE TABLE IF NOT EXISTS user_device_access (
        user_id INT NOT NULL,
        device_id VARCHAR(100) NOT NULL,
        access_granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (user_id, device_id),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    // Create notifications table if it doesn't exist
    await connection.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id VARCHAR(36) PRIMARY KEY,
        user_id INT NOT NULL,
        type VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        INDEX idx_user_read (user_id, is_read),
        INDEX idx_created (created_at DESC)
      )
    `);

    console.log('✅ Device access tables initialized successfully');
    
    // Add some sample devices for testing (only if devices table is empty)
    const [deviceCount] = await connection.query('SELECT COUNT(*) as count FROM devices');
    if (deviceCount[0].count === 0) {
      // Get admin users (role = 'Admin')
      const [adminUsers] = await connection.query('SELECT id FROM users WHERE role = "Admin" LIMIT 3');
      
      if (adminUsers.length > 0) {
        const sampleDevices = [
          { device_id: 'AQS001', device_name: 'Main Water Tank Sensor', location: 'Building A - Rooftop' },
          { device_id: 'AQS002', device_name: 'Pool Water Monitor', location: 'Swimming Pool Area' },
          { device_id: 'AQS003', device_name: 'Laboratory Water Tester', location: 'Research Lab 1' }
        ];

        for (let i = 0; i < sampleDevices.length && i < adminUsers.length; i++) {
          await connection.query(
            'INSERT INTO devices (device_id, device_name, admin_id, location) VALUES (?, ?, ?, ?)',
            [sampleDevices[i].device_id, sampleDevices[i].device_name, adminUsers[i].id, sampleDevices[i].location]
          );
        }
        console.log('✅ Sample devices added for testing');
      }
    }

  } catch (error) {
    console.error('❌ Error initializing device access tables:', error);
  } finally {
    if (connection) connection.release();
  }
}

// Initialize tables on startup
initializeDeviceAccessTables();

// Add device_id columns to sensor tables for device-specific filtering
async function initializeSensorDeviceColumns() {
  let connection;
  try {
    connection = await db.getConnection();
    
    const sensorTables = [
      'turbidity_readings',
      'phlevel_readings',
      'tds_readings',
      'salinity_readings',
      'ec_readings',
      'ec_compensated_readings',
      'temperature_readings'
    ];
    
    for (const table of sensorTables) {
      try {
        // Check if device_id column exists
        const [columns] = await connection.query(`SHOW COLUMNS FROM ${table} LIKE 'device_id'`);
        
        if (columns.length === 0) {
          // Add device_id column if it doesn't exist
          await connection.query(`ALTER TABLE ${table} ADD COLUMN device_id VARCHAR(100) DEFAULT NULL`);
          console.log(`✅ Added device_id column to ${table}`);
          
          // Add index for better performance
          await connection.query(`ALTER TABLE ${table} ADD INDEX idx_device_id (device_id)`);
        }
        
        // Update existing records to have device_id (for demonstration, let's assign some to device 31767)
        if (table === 'turbidity_readings' || table === 'temperature_readings') {
          await connection.query(`UPDATE ${table} SET device_id = '31767' WHERE device_id IS NULL LIMIT 100`);
        }
        
      } catch (tableError) {
        console.log(`Error updating ${table}:`, tableError.message);
      }
    }
    
    console.log('✅ Sensor device columns initialized');
  } catch (error) {
    console.log('Failed to initialize sensor device columns:', error);
  } finally {
    if (connection) connection.release();
  }
}

initializeSensorDeviceColumns();

// Fix: Change admin 429 back to regular Admin and assign device request to them
async function fixAdminAndDeviceRequest() {
  let connection;
  try {
    connection = await db.getConnection();
    
    // Change admin 429 back to regular Admin
    await connection.query('UPDATE users SET role = "Admin" WHERE id = 429');
    console.log('✅ Changed admin 429 back to regular Admin');
    
    // Update the device request to be assigned to admin 429 (who manages device 31767)
    await connection.query('UPDATE device_access_requests SET admin_id = 429 WHERE device_id = "31767"');
    console.log('✅ Assigned device 31767 request to admin 429');
    
  } catch (error) {
    console.log('Failed to fix admin and device request:', error);
  } finally {
    if (connection) connection.release();
  }
}
fixAdminAndDeviceRequest();

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

// Function to send signup OTP via email
async function sendSignupOTP(email, otp) {
  const mailOptions = {
    from: 'aquasense35@gmail.com',
    to: email,
    subject: 'AquaSense - Verify Your Email',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f5f5f5;">
        <div style="background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
          <div style="text-align: center; margin-bottom: 30px;">
            <h1 style="color: #2563eb; margin: 0;">AquaSense</h1>
            <p style="color: #666; margin: 5px 0;">Water Quality Monitoring System</p>
          </div>
          
          <h2 style="color: #333; text-align: center;">Verify Your Email Address</h2>
          
          <p style="color: #666; font-size: 16px; line-height: 1.5;">
            Welcome to AquaSense! To complete your account setup, please verify your email address using the verification code below:
          </p>
          
          <div style="background-color: #f8fafc; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;">
            <p style="color: #666; margin: 0 0 10px 0;">Your verification code is:</p>
            <h1 style="color: #2563eb; font-size: 32px; letter-spacing: 4px; margin: 0; font-family: monospace;">${otp}</h1>
          </div>
          
          <p style="color: #666; font-size: 14px; margin-top: 20px;">
            <strong>Important:</strong> This code will expire in 5 minutes for your security.
          </p>
          
          <p style="color: #666; font-size: 14px;">
            If you didn't create an account with AquaSense, please ignore this email.
          </p>
          
          <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
          
          <p style="color: #999; font-size: 12px; text-align: center;">
            This is an automated message from AquaSense. Please do not reply to this email.
          </p>
        </div>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`Signup OTP sent to ${email}: ${otp}`);
  } catch (error) {
    console.error('Error sending signup OTP email:', error);
    throw new Error('Failed to send verification email. Please check your email configuration. Original error: ' + error.message);
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

app.post("/logout", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith("Bearer ")) {
      const token = authHeader.split(" ")[1];
      console.log(`User ${userId} logged out with token: ${token.substring(0, 10)}...`);
      
      // Optional: Store logout activity in database
      try {
        const logoutTime = new Date();
        await db.query(
          'INSERT INTO user_activity (user_id, action, timestamp, ip_address) VALUES (?, ?, ?, ?)',
          [userId, 'logout', logoutTime, req.ip || 'unknown']
        );
      } catch (activityErr) {
        console.log("Activity logging failed (non-critical):", activityErr.message);
      }
      
      // Clear any server-side session data if exists
      try {
        await db.query(
          'UPDATE users SET access_token = NULL WHERE id = ?',
          [userId]
        );
      } catch (tokenErr) {
        console.log("Token clearing failed (non-critical):", tokenErr.message);
      }
    }
    
    res.status(200).json({ 
      message: "Logout successful.",
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error("Logout error:", error);
    // Still return success for logout even if cleanup fails
    res.status(200).json({ message: "Logout successful." });
  }
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

      await db.query('UPDATE users SET email_verified = 1 WHERE email = ?', [email]);
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

    if (user.email_verified !== 1) {
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

// Signup OTP endpoints
app.post("/api/signup-otp", async (req, res) => {
  const { username, email, phone, password, confirm_password } = req.body;

  if (!username || !email || !password || !confirm_password) {
    return res.status(400).json({ success: false, message: "All fields are required" });
  }

  if (password !== confirm_password) {
    return res.status(400).json({ success: false, message: "Passwords do not match" });
  }

  try {
    // Check if email already exists
    const [existingUsers] = await db.query("SELECT * FROM users WHERE email = ?", [email]);
    if (existingUsers.length > 0) {
      return res.status(400).json({ success: false, message: "Email already registered" });
    }

    // Check if username already exists
    const [existingUsernames] = await db.query("SELECT * FROM users WHERE username = ?", [username]);
    if (existingUsernames.length > 0) {
      return res.status(400).json({ success: false, message: "Username already taken" });
    }

    // Generate and store OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiry = Date.now() + 300000; // 5 minutes
    
    // Store signup data temporarily with OTP
    const signupKey = `signup_${email}`;
    otpStorage[signupKey] = { 
      otp, 
      expiry, 
      username, 
      email, 
      phone, 
      password 
    };

    // Send OTP email
    await sendSignupOTP(email, otp);
    
    res.json({ 
      success: true, 
      message: "Verification code sent to your email. Please check your inbox." 
    });
  } catch (error) {
    console.error("Error during signup OTP process:", error);
    return res.status(500).json({ 
      success: false, 
      message: "Internal server error: " + error.message 
    });
  }
});

app.post("/api/verify-signup-otp", async (req, res) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    return res.status(400).json({ success: false, message: "Email and OTP are required" });
  }

  try {
    const signupKey = `signup_${email}`;
    const storedData = otpStorage[signupKey];
    
    if (!storedData) {
      return res.status(404).json({ 
        success: false, 
        message: "OTP not found or expired. Please request a new one." 
      });
    }

    if (storedData.expiry < Date.now()) {
      delete otpStorage[signupKey];
      return res.status(410).json({ 
        success: false, 
        message: "OTP expired. Please request a new one." 
      });
    }

    if (storedData.otp === otp) {
      // OTP verified, now create the user account
      const hashedPassword = await bcrypt.hash(storedData.password, saltRounds);
      const sql = "INSERT INTO users (username, email, phone, password_hash, role, email_verified) VALUES (?, ?, ?, ?, 'user', 1)";
      
      const [result] = await db.query(sql, [
        storedData.username, 
        storedData.email, 
        storedData.phone || null, 
        hashedPassword
      ]);

      // Clean up stored data
      delete otpStorage[signupKey];
      
      res.json({ 
        success: true, 
        message: "Account created successfully! You can now log in.",
        userId: result.insertId 
      });
    } else {
      res.status(400).json({ success: false, message: "Invalid OTP. Please try again." });
    }
  } catch (error) {
    console.error("Error verifying signup OTP:", error);
    return res.status(500).json({ 
      success: false, 
      message: "Internal Server Error", 
      error: error.message 
    });
  }
});

app.post("/api/resend-signup-otp", async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ success: false, message: "Email is required" });
  }

  try {
    const signupKey = `signup_${email}`;
    const storedData = otpStorage[signupKey];
    
    if (!storedData) {
      return res.status(404).json({ 
        success: false, 
        message: "No pending signup found for this email." 
      });
    }

    // Generate new OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiry = Date.now() + 300000; // 5 minutes
    
    // Update stored data with new OTP
    otpStorage[signupKey] = { 
      ...storedData,
      otp, 
      expiry 
    };

    // Send new OTP
    await sendSignupOTP(email, otp);
    
    res.json({ 
      success: true, 
      message: "New verification code sent to your email." 
    });
  } catch (error) {
    console.error("Error resending signup OTP:", error);
    return res.status(500).json({ 
      success: false, 
      message: "Internal server error: " + error.message 
    });
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
    res.json({ success: true, notifications: formattedNotifications });
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ success: false, message: 'Error fetching notifications', error: error.message });
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
  try {
    // Count total number of sensor types (7 sensor types in the system)
    // Since there's no single 'sensors' table, we count by sensor types
    const sensorTypes = [
      'turbidity_readings',
      'phlevel_readings', 
      'tds_readings',
      'salinity_readings',
      'ec_readings',
      'ec_compensated_readings',
      'temperature_readings'
    ];
    
    let totalSensors = 0;
    for (const table of sensorTypes) {
      try {
        // Since sensor tables don't have device_id, just check if table has any data
        const [result] = await db.query(`SELECT COUNT(*) AS count FROM ${table} LIMIT 1`);
        if (result[0].count > 0) {
          totalSensors++;
        }
      } catch (tableErr) {
        console.warn(`Table ${table} might not exist or is empty:`, tableErr.message);
      }
    }
    
    res.json({ totalSensors: totalSensors });
  } catch (err) {
    console.error('Error fetching total sensors:', err);
    res.status(500).json({ error: 'Failed to fetch total sensors' });
  }
});

// --- Device-Scoped Endpoints for Admin Dashboard ---

// Helper: derive device_id for a given user id
async function getDeviceIdForUser(userId) {
  try {
    console.log(`DEBUG: Looking for device_id for user ${userId}`);
    
    // Check if users table has device_id column
    const [userDeviceCol] = await db.query(
      'SELECT COUNT(*) AS cnt FROM information_schema.columns WHERE table_schema = ? AND table_name = ? AND column_name = ?',
      ['aquasense', 'users', 'device_id']
    );
    console.log(`DEBUG: Users table has device_id column: ${userDeviceCol[0].cnt > 0}`);
    
    if (userDeviceCol[0].cnt > 0) {
      const [rows] = await db.query('SELECT device_id FROM users WHERE id = ?', [userId]);
      console.log(`DEBUG: Direct device_id query result:`, rows);
      if (rows.length > 0 && rows[0].device_id) {
        console.log(`DEBUG: Found device_id ${rows[0].device_id} for user ${userId}`);
        return rows[0].device_id;
      }
    }

    // Otherwise, check if users has establishment_id and estab has device_id
    const [userEstabCol] = await db.query(
      'SELECT COUNT(*) AS cnt FROM information_schema.columns WHERE table_schema = ? AND table_name = ? AND column_name = ?',
      ['aquasense', 'users', 'establishment_id']
    );
    console.log(`DEBUG: Users table has establishment_id column: ${userEstabCol[0].cnt > 0}`);
    
    if (userEstabCol[0].cnt > 0) {
      const [rows] = await db.query(
        'SELECT u.establishment_id, e.device_id FROM users u LEFT JOIN estab e ON u.establishment_id = e.id WHERE u.id = ?',
        [userId]
      );
      console.log(`DEBUG: User-establishment query result:`, rows);
      if (rows.length > 0 && rows[0].device_id) {
        console.log(`DEBUG: Found device_id ${rows[0].device_id} via establishment_id ${rows[0].establishment_id} for user ${userId}`);
        return rows[0].device_id;
      }
    }

    // Not found
    console.warn(`DEBUG: No device mapping found for user ${userId}`);
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
    console.log(`🔍 DEBUG: Counting users for admin ${userId} based on device_id`);
    
    // Get admin's device_id
    const [adminInfo] = await db.query(
      'SELECT device_id FROM users WHERE id = ?',
      [userId]
    );
    
    if (adminInfo.length === 0 || !adminInfo[0].device_id) {
      console.warn(`No device_id found for admin ${userId}; returning zero totalUsers.`);
      return res.json({ totalUsers: 0 });
    }
    
    const adminDeviceId = adminInfo[0].device_id;
    console.log(`🔍 DEBUG: Admin device_id: ${adminDeviceId}`);
    
    // Count users that have the same device_id as the admin
    const [rows] = await db.query('SELECT COUNT(*) AS totalUsers FROM users WHERE device_id = ?', [adminDeviceId]);
    const totalUsers = rows[0].totalUsers || 0;
    
    console.log(`🔍 DEBUG: Found ${totalUsers} users with device_id ${adminDeviceId}`);
    
    return res.json({ totalUsers: totalUsers });
  } catch (error) {
    console.error('Error in /api/my/total-users:', error);
    res.status(500).json({ error: 'Server error while fetching my total users' });
  }
});

app.get('/api/my/total-sensors', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    console.log(`🔍 DEBUG: Fetching total sensors for user ID: ${userId} with token`);
    
    // Get admin's establishment_id
    const [adminInfo] = await db.query(
      'SELECT establishment_id FROM users WHERE id = ?',
      [userId]
    );
    
    if (adminInfo.length === 0 || !adminInfo[0].establishment_id) {
      console.warn(`No establishment_id found for admin ${userId}; returning zero totalSensors.`);
      return res.json({ totalSensors: 0 });
    }
    
    const establishmentId = adminInfo[0].establishment_id;
    console.log(`🔍 DEBUG: Getting establishment for admin user ID: ${userId} based on device_id`);
    console.log(`🔍 DEBUG: Admin establishment_id: ${establishmentId}`);
    
    // Get configured sensors from estab_sensors table
    const [configuredSensors] = await db.query(
      `SELECT COUNT(DISTINCT es.sensor_id) as totalSensors
       FROM estab_sensors es
       WHERE es.estab_id = ?`,
      [establishmentId]
    );
    
    const totalSensors = configuredSensors[0]?.totalSensors || 0;
    
    console.log(`🔍 DEBUG: Total sensors response status: 200`);
    console.log(`🔍 DEBUG: Total sensors response body: {"totalSensors":${totalSensors}}`);
    console.log(`🔍 DEBUG: Parsed total sensors data: {totalSensors: ${totalSensors}}`);
    
    return res.json({ totalSensors: totalSensors });
  } catch (error) {
    console.error('Error in /api/my/total-sensors:', error);
    res.status(500).json({ error: 'Server error while fetching my total sensors' });
  }
});

// New endpoint: Get admin's device and establishment association info
app.get('/api/my/device-info', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    console.log(`🔍 DEBUG: Getting device and establishment info for admin user ${userId}`);
    
    // Get admin's device_id and establishment_id
    const [adminInfo] = await db.query(
      'SELECT device_id, establishment_id FROM users WHERE id = ?',
      [userId]
    );
    
    if (adminInfo.length === 0) {
      return res.json({
        hasDevice: false,
        hasEstablishment: false,
        deviceMessage: 'Admin user not found'
      });
    }
    
    const admin = adminInfo[0];
    const hasDevice = admin.device_id != null;
    const hasEstablishment = admin.establishment_id != null;
    
    let establishmentName = null;
    
    // If admin has establishment_id, get the establishment name
    if (hasEstablishment) {
      const [estabInfo] = await db.query(
        'SELECT estab_name FROM estab WHERE id = ?',
        [admin.establishment_id]
      );
      
      if (estabInfo.length > 0) {
        establishmentName = estabInfo[0].estab_name;
      }
    }
    
    console.log(`🔍 DEBUG: Admin ${userId} - Device: ${admin.device_id}, Establishment: ${admin.establishment_id} (${establishmentName})`);
    
    return res.json({
      hasDevice: hasDevice,
      hasEstablishment: hasEstablishment,
      deviceId: admin.device_id,
      establishmentId: admin.establishment_id,
      establishmentName: establishmentName,
      deviceMessage: hasEstablishment ? 
        `Admin associated with establishment: ${establishmentName}` : 
        (hasDevice ? 'Admin has device but no establishment' : 'Admin has no device or establishment')
    });
    
  } catch (error) {
    console.error('Error in /api/my/device-info:', error);
    res.status(500).json({ error: 'Server error while fetching device info' });
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
    const [establishmentIdColumn] = await db.query(
      'SELECT COUNT(*) AS cnt FROM information_schema.columns WHERE table_schema = ? AND table_name = ? AND column_name = ?',
      ['aquasense', 'users', 'establishment_id']
    );

    const [userDeviceIdColumn] = await db.query(
      'SELECT COUNT(*) AS cnt FROM information_schema.columns WHERE table_schema = ? AND table_name = ? AND column_name = ?',
      ['aquasense', 'users', 'device_id']
    );

    const hasEstablishmentId = establishmentIdColumn[0].cnt > 0;
    const hasUserDeviceId = userDeviceIdColumn[0].cnt > 0;

    let querySql;
    let params = [deviceId];

    if (hasEstablishmentId) {
      // users.establishment_id -> estab.id, filter estab.device_id = deviceId
      querySql = `SELECT COUNT(*) AS totalUsers FROM users u JOIN estab e ON u.establishment_id = e.id WHERE e.device_id = ?`;
    } else if (hasUserDeviceId) {
      // users.device_id directly references device
      querySql = `SELECT COUNT(*) AS totalUsers FROM users WHERE device_id = ?`;
    } else {
      return res.status(400).json({ error: 'Unable to determine user-to-device mapping. Please ensure users table has either establishment_id or device_id column.' });
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

// Original endpoints (backward compatibility)
createGetDataEndpoint('turbidity', 'turbidity_readings', 'timestamp');
createGetDataEndpoint('ph', 'phlevel_readings', 'timestamp');
createGetDataEndpoint('tds', 'tds_readings', 'timestamp');
createGetDataEndpoint('salinity', 'salinity_readings', 'timestamp');
createGetDataEndpoint('ec', 'ec_readings', 'timestamp');
createGetDataEndpoint('ec_compensated', 'ec_compensated_readings', 'timestamp');
createGetDataEndpoint('temperature', 'temperature_readings', 'timestamp');

// Device-specific sensor data endpoints with access control
const createDeviceSpecificEndpoint = (endpoint, tableName, timestampColumn) => {
  app.get(`/api/device/${endpoint}`, authenticateToken, async (req, res) => {
    try {
      const userId = req.user.id;
      const userRole = req.user.role;
      const requestedDeviceId = req.query.device_id;
      const period = req.query.period || '24h';
      
      console.log(`🔍 DEBUG: User ${userId} (${userRole}) requesting ${endpoint} data for device ${requestedDeviceId}`);
      
      let deviceIds = [];
      
      if (userRole === 'Super Admin') {
        // Super Admin can access all devices
        if (requestedDeviceId) {
          deviceIds = [requestedDeviceId];
        } else {
          // Get all device IDs if none specified
          const [allDevices] = await db.query('SELECT DISTINCT device_id FROM estab WHERE device_id IS NOT NULL');
          deviceIds = allDevices.map(d => d.device_id);
        }
      } else {
        // Regular users and admins need to check access
        let userDeviceAccess = [];
        
        if (userRole === 'Admin') {
          // Admin - get devices they manage
          const [adminDevices] = await db.query(
            'SELECT e.device_id FROM estab e JOIN users u ON e.id = u.establishment_id WHERE u.id = ?',
            [userId]
          );
          userDeviceAccess = adminDevices.map(d => d.device_id);
        } else {
          // Regular user - get devices they have access to
          const [accessibleDevices] = await db.query(
            'SELECT device_id FROM user_device_access WHERE user_id = ?',
            [userId]
          );
          userDeviceAccess = accessibleDevices.map(d => d.device_id);
        }
        
        console.log(`🔍 DEBUG: User ${userId} has access to devices:`, userDeviceAccess);
        
        if (requestedDeviceId) {
          // Check if user has access to the requested device
          if (userDeviceAccess.includes(requestedDeviceId)) {
            deviceIds = [requestedDeviceId];
          } else {
            return res.status(403).json({ 
              error: 'Access denied to requested device',
              availableDevices: userDeviceAccess 
            });
          }
        } else {
          deviceIds = userDeviceAccess;
        }
      }
      
      if (deviceIds.length === 0) {
        return res.json({ 
          data: [], 
          message: 'No accessible devices found',
          availableDevices: deviceIds 
        });
      }
      
      // Build query with device filtering
      const timeFilter = getTimeFilterClause(period);
      const deviceFilter = deviceIds.length === 1 
        ? `AND device_id = '${deviceIds[0]}'`
        : `AND device_id IN (${deviceIds.map(id => `'${id}'`).join(',')})`;
      
      const query = `SELECT * FROM ${tableName} WHERE 1=1 ${deviceFilter} ${timeFilter} ORDER BY ${timestampColumn} ASC`;
      
      console.log(`🔍 DEBUG: Executing query: ${query}`);
      
      const [rows] = await db.query(query);
      
      res.json({ 
        success: true,
        data: rows, 
        deviceIds: deviceIds,
        totalRecords: rows.length 
      });
      
    } catch (err) {
      console.error(`❌ Device-specific ${endpoint} Query Error:`, err);
      return res.status(500).json({ error: "Database Query Error" });
    }
  });
};

// Create device-specific endpoints for all sensor types
createDeviceSpecificEndpoint('turbidity', 'turbidity_readings', 'timestamp');
createDeviceSpecificEndpoint('ph', 'phlevel_readings', 'timestamp');
createDeviceSpecificEndpoint('tds', 'tds_readings', 'timestamp');
createDeviceSpecificEndpoint('salinity', 'salinity_readings', 'timestamp');
createDeviceSpecificEndpoint('ec', 'ec_readings', 'timestamp');
createDeviceSpecificEndpoint('ec_compensated', 'ec_compensated_readings', 'timestamp');
createDeviceSpecificEndpoint('temperature', 'temperature_readings', 'timestamp');

// Endpoint to get available sensors for a specific device
app.get('/api/device/available-sensors', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    const requestedDeviceId = req.query.device_id;
    
    if (!requestedDeviceId) {
      return res.status(400).json({ error: 'device_id parameter is required' });
    }
    
    console.log(`🔍 Fetching sensors for device ${requestedDeviceId}`);
    
    // Remove commas from deviceId to handle both formats (74175 and 74,175)
    const cleanDeviceId = requestedDeviceId.replace(/,/g, '');
    
    // Check if user has access to this device
    let hasAccess = false;
    
    if (userRole === 'Super Admin') {
      hasAccess = true;
    } else if (userRole === 'Admin') {
      const [adminDevices] = await db.query(
        'SELECT e.device_id FROM estab e JOIN users u ON e.id = u.establishment_id WHERE u.id = ? AND REPLACE(e.device_id, ",", "") = ?',
        [userId, cleanDeviceId]
      );
      hasAccess = adminDevices.length > 0;
    } else {
      const [userAccess] = await db.query(
        'SELECT device_id FROM user_device_access WHERE user_id = ? AND REPLACE(device_id, ",", "") = ?',
        [userId, cleanDeviceId]
      );
      hasAccess = userAccess.length > 0;
    }
    
    if (!hasAccess) {
      return res.status(403).json({ error: 'Access denied to requested device' });
    }
    
    // Get establishment ID from device_id
    const [estabInfo] = await db.query(
      'SELECT id FROM estab WHERE REPLACE(device_id, ",", "") = ?',
      [cleanDeviceId]
    );
    
    if (estabInfo.length === 0) {
      return res.status(404).json({ error: 'Device not found' });
    }
    
    const establishmentId = estabInfo[0].id;
    console.log(`🔍 Device ${cleanDeviceId} belongs to establishment ${establishmentId}`);
    
    // Get configured sensors from estab_sensors table
    const [configuredSensors] = await db.query(
      `SELECT s.id, s.sensor_name, es.sensor_id
       FROM estab_sensors es
       JOIN sensors s ON es.sensor_id = s.id
       WHERE es.estab_id = ?
       ORDER BY s.id`,
      [establishmentId]
    );
    
    console.log(`🔍 Found ${configuredSensors.length} configured sensors for establishment ${establishmentId}`);
    
    // Map sensor names to types used by the frontend
    const sensorTypeMapping = {
      'Total Dissolved Solids': { type: 'tds', unit: 'ppm' },
      'Conductivity': { type: 'ec', unit: 'μS/cm' },
      'Temperature': { type: 'temperature', unit: '°C' },
      'Turbidity': { type: 'turbidity', unit: 'NTU' },
      'ph Level': { type: 'ph', unit: 'pH' },
      'Salinity': { type: 'salinity', unit: 'ppt' },
      'Electrical Conductivity': { type: 'ec_compensated', unit: 'μS/cm' }
    };
    
    const availableSensors = configuredSensors.map(sensor => {
      const mapping = sensorTypeMapping[sensor.sensor_name];
      return {
        type: mapping ? mapping.type : sensor.sensor_name.toLowerCase(),
        name: sensor.sensor_name,
        unit: mapping ? mapping.unit : '',
        sensor_id: sensor.sensor_id
      };
    });
    
    console.log(`✅ Returning ${availableSensors.length} sensors:`, availableSensors.map(s => s.name).join(', '));
    
    res.json({
      success: true,
      deviceId: requestedDeviceId,
      availableSensors: availableSensors,
      totalSensorTypes: availableSensors.length
    });
    
  } catch (error) {
    console.error('Error fetching available sensors:', error);
    res.status(500).json({ error: 'Failed to fetch available sensors' });
  }
});

// Get all devices accessible to the current user
app.get('/api/user/accessible-devices', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    
    let devices = [];
    
    if (userRole === 'Super Admin') {
      // Super Admin can access all devices
      const [allDevices] = await db.query(
        'SELECT e.device_id, e.estab_name as device_name, e.id as estab_id FROM estab e WHERE e.device_id IS NOT NULL'
      );
      devices = allDevices;
    } else if (userRole === 'Admin') {
      // Admin can access devices they manage
      const [adminDevices] = await db.query(
        `SELECT e.device_id, e.estab_name as device_name, e.id as estab_id 
         FROM estab e 
         JOIN users u ON e.id = u.establishment_id 
         WHERE u.id = ? AND e.device_id IS NOT NULL`,
        [userId]
      );
      devices = adminDevices;
    } else {
      // Regular user can access devices they have been granted access to
      const [userDevices] = await db.query(
        `SELECT e.device_id, e.estab_name as device_name, e.id as estab_id, uda.access_granted_at
         FROM user_device_access uda
         JOIN estab e ON uda.device_id = e.device_id
         WHERE uda.user_id = ?`,
        [userId]
      );
      devices = userDevices;
    }
    
    res.json({
      success: true,
      userId: userId,
      userRole: userRole,
      devices: devices,
      totalDevices: devices.length
    });
    
  } catch (error) {
    console.error('Error fetching accessible devices:', error);
    res.status(500).json({ error: 'Failed to fetch accessible devices' });
  }
});

// Get user's device access requests with status
app.get('/api/user/device-requests', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    console.log('DEBUG: User requesting device access status, User ID:', userId);
    
    const [requests] = await db.query(
      `SELECT dar.id, dar.device_id, e.estab_name as device_name, dar.status, 
              dar.message as user_message, dar.response_message, dar.created_at, dar.updated_at,
              u_admin.username as admin_name
       FROM device_access_requests dar
       LEFT JOIN estab e ON dar.device_id = e.device_id  
       LEFT JOIN users u_admin ON dar.admin_id = u_admin.id
       WHERE dar.user_id = ?
       ORDER BY dar.created_at DESC`,
      [userId]
    );
    
    console.log('DEBUG: Found', requests.length, 'device requests for user', userId);
    
    res.json({
      success: true,
      requests: requests
    });
    
  } catch (error) {
    console.error('Error fetching user device requests:', error);
    res.status(500).json({ error: 'Failed to fetch device requests' });
  }
});

// Listen on the assigned port on all interfaces
server.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Backend running on port ${port} (all interfaces)`);
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

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'Server is running', timestamp: new Date().toISOString() });
});

// Test endpoint to verify API is working
app.get('/api/test', (req, res) => {
    res.json({ message: 'API is working', timestamp: new Date().toISOString() });
});

// ============= DEVICE ACCESS REQUEST ENDPOINTS =============

// 1. Submit device access request
app.post('/api/device-request', authenticateToken, async (req, res) => {
    console.log('DEBUG: Device request endpoint hit');
    console.log('DEBUG: Request body:', req.body);
    console.log('DEBUG: User ID:', req.user?.id);
    
    let connection;
    try {
        const userId = req.user.id;
        const { deviceId, message } = req.body;

        if (!deviceId || deviceId.trim() === '') {
            return res.status(400).json({ error: 'Device ID is required.' });
        }

        connection = await db.getConnection();

        // Debug: Show all available devices from estab table
        const [allDevices] = await connection.query('SELECT device_id, estab_name FROM estab');
        console.log('DEBUG: Available devices from estab:', allDevices);
        console.log('DEBUG: Looking for device ID:', deviceId.trim());

        // Remove commas from device ID for comparison
        const cleanDeviceId = deviceId.trim().replace(/,/g, '');

        // Check if device exists in estab table
        // Use REPLACE to handle commas in stored device_id values
        const [deviceRows] = await connection.query(
            'SELECT * FROM estab WHERE REPLACE(device_id, ",", "") = ?',
            [cleanDeviceId]
        );

        if (deviceRows.length === 0) {
            console.log('DEBUG: Device not found in estab table');
            return res.status(404).json({ 
                error: 'Device not found. Please check the Device ID.',
                availableDevices: allDevices.map(d => d.device_id)
            });
        }

        const device = deviceRows[0];
        
        // Find the admin who manages this device by checking users table with establishment_id
        const establishmentId = device.id; // The estab table ID
        const [adminRows] = await connection.query(
            'SELECT id FROM users WHERE establishment_id = ? AND role = "Admin" LIMIT 1',
            [establishmentId]
        );
        
        let adminId;
        if (adminRows.length > 0) {
            adminId = adminRows[0].id;
            console.log('DEBUG: Found admin', adminId, 'for establishment', establishmentId);
        } else {
            // Fallback to Super Admin if no specific admin found
            const [superAdmins] = await connection.query(
                'SELECT id FROM users WHERE role = "Super Admin" LIMIT 1'
            );
            
            if (superAdmins.length === 0) {
                return res.status(500).json({ error: 'No admin found to process the request.' });
            }
            
            adminId = superAdmins[0].id;
            console.log('DEBUG: Using Super Admin', adminId, 'as fallback');
        }

        // Check if user already has access to this device
        // Use REPLACE to handle commas in device_id comparison
        const [accessRows] = await connection.query(
            'SELECT * FROM user_device_access WHERE user_id = ? AND REPLACE(device_id, ",", "") = ?',
            [userId, cleanDeviceId]
        );

        if (accessRows.length > 0) {
            return res.status(400).json({ error: 'You already have access to this device.' });
        }

        // Check if there's already a pending request
        // Use REPLACE to handle commas in device_id comparison
        const [pendingRows] = await connection.query(
            'SELECT * FROM device_access_requests WHERE user_id = ? AND REPLACE(device_id, ",", "") = ? AND status = "pending"',
            [userId, cleanDeviceId]
        );

        if (pendingRows.length > 0) {
            return res.status(400).json({ error: 'You already have a pending request for this device.' });
        }

        // Get user details for notification
        const [userRows] = await connection.query(
            'SELECT username, email FROM users WHERE id = ?',
            [userId]
        );

        const user = userRows[0];

        // Create the request
        const requestId = uuidv4();
        await connection.query(
            'INSERT INTO device_access_requests (id, user_id, device_id, admin_id, message, status, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())',
            [requestId, userId, deviceId, adminId, message || '', 'pending']
        );

        // Create notification for admin
        const notificationId = uuidv4();
        const notificationMessage = `User "${user.username}" has requested access to device "${deviceId}". ${message ? 'Message: ' + message : ''}`;
        
        await connection.query(
            'INSERT INTO notifications (id, user_id, type, title, message, created_at, is_read) VALUES (?, ?, ?, ?, ?, NOW(), false)',
            [notificationId, adminId, 'device_request', 'Device Access Request', notificationMessage]
        );

        res.status(200).json({ 
            success: true, 
            message: 'Device access request submitted successfully!',
            requestId: requestId
        });

    } catch (error) {
        console.error('Error submitting device request:', error);
        res.status(500).json({ error: 'Failed to submit device request.' });
    } finally {
        if (connection) connection.release();
    }
});

// 2. Get pending device requests for admin
app.get('/api/device-requests/pending', authenticateToken, async (req, res) => {
    let connection;
    try {
        const adminId = req.user.id;
        const adminRole = req.user.role;
        console.log('DEBUG: Admin requesting pending device requests, Admin ID:', adminId, 'Role:', adminRole);

        connection = await db.getConnection();
        
        // If Super Admin, show all pending requests. Otherwise, show only requests assigned to this admin
        let query, params;
        if (adminRole === 'Super Admin') {
            query = `SELECT 
                dar.id, dar.device_id, dar.message, dar.created_at, dar.admin_id,
                u.username, u.email,
                e.estab_name as device_name
            FROM device_access_requests dar
            JOIN users u ON dar.user_id = u.id
            LEFT JOIN estab e ON dar.device_id = e.device_id
            WHERE dar.status = 'pending'
            ORDER BY dar.created_at DESC`;
            params = [];
        } else {
            query = `SELECT 
                dar.id, dar.device_id, dar.message, dar.created_at, dar.admin_id,
                u.username, u.email,
                e.estab_name as device_name
            FROM device_access_requests dar
            JOIN users u ON dar.user_id = u.id
            LEFT JOIN estab e ON dar.device_id = e.device_id
            WHERE dar.admin_id = ? AND dar.status = 'pending'
            ORDER BY dar.created_at DESC`;
            params = [adminId];
        }

        const [rows] = await connection.query(query, params);

        console.log('DEBUG: Found device requests for admin', adminId, ':', rows.length);
        console.log('DEBUG: Device requests:', rows);
        res.status(200).json({ success: true, requests: rows });

    } catch (error) {
        console.error('Error fetching pending requests:', error);
        res.status(500).json({ error: 'Failed to fetch pending requests.' });
    } finally {
        if (connection) connection.release();
    }
});

// 3. Approve or reject device access request
app.post('/api/device-requests/:requestId/respond', authenticateToken, async (req, res) => {
    let connection;
    try {
        const adminId = req.user.id;
        const { requestId } = req.params;
        const { action, response_message } = req.body; // action: 'approve' or 'reject'

        if (!['approve', 'reject'].includes(action)) {
            return res.status(400).json({ error: 'Invalid action. Must be "approve" or "reject".' });
        }

        connection = await db.getConnection();

        // Get the request details
        const [requestRows] = await connection.query(
            'SELECT * FROM device_access_requests WHERE id = ? AND admin_id = ? AND status = "pending"',
            [requestId, adminId]
        );

        if (requestRows.length === 0) {
            return res.status(404).json({ error: 'Request not found or already processed.' });
        }

        const request = requestRows[0];

        // Update request status
        await connection.query(
            'UPDATE device_access_requests SET status = ?, response_message = ?, responded_at = NOW() WHERE id = ?',
            [action === 'approve' ? 'approved' : 'rejected', response_message || '', requestId]
        );

        // If approved, grant access to user
        if (action === 'approve') {
            await connection.query(
                'INSERT INTO user_device_access (user_id, device_id, access_granted_at) VALUES (?, ?, NOW()) ON DUPLICATE KEY UPDATE access_granted_at = NOW()',
                [request.user_id, request.device_id]
            );
        }

        // Create notification for user
        const notificationId = uuidv4();
        const notificationTitle = action === 'approve' ? 'Device Access Approved' : 'Device Access Rejected';
        const notificationMessage = action === 'approve' 
            ? `Your request for device "${request.device_id}" has been approved! ${response_message ? 'Admin message: ' + response_message : ''}`
            : `Your request for device "${request.device_id}" has been rejected. ${response_message ? 'Admin message: ' + response_message : ''}`;
        
        await connection.query(
            'INSERT INTO notifications (id, user_id, type, title, message, created_at, is_read) VALUES (?, ?, ?, ?, ?, NOW(), false)',
            [notificationId, request.user_id, 'device_response', notificationTitle, notificationMessage]
        );

        res.status(200).json({ 
            success: true, 
            message: `Request ${action === 'approve' ? 'approved' : 'rejected'} successfully!` 
        });

    } catch (error) {
        console.error('Error responding to request:', error);
        res.status(500).json({ error: 'Failed to respond to request.' });
    } finally {
        if (connection) connection.release();
    }
});

// 4. Check user's device access
app.get('/api/user/device-access', authenticateToken, async (req, res) => {
    let connection;
    try {
        const userId = req.user.id;
        console.log('Checking device access for user ID:', userId);

        connection = await db.getConnection();

        // First, let's check if the user_device_access table exists and get its structure
        const [tableCheck] = await connection.query(
            `SHOW COLUMNS FROM user_device_access`
        );
        console.log('user_device_access table columns:', tableCheck.map(col => col.Field));

        const [rows] = await connection.query(
            `SELECT 
                uda.device_id, uda.access_granted_at,
                e.estab_name as device_name, e.id
            FROM user_device_access uda
            LEFT JOIN estab e ON uda.device_id = e.device_id
            WHERE uda.user_id = ?`,
            [userId]
        );

        console.log('Found device access rows:', rows);
        res.status(200).json({ success: true, devices: rows });

    } catch (error) {
        console.error('Error fetching user device access:', error);
        console.error('Error details:', error.message);
        res.status(500).json({ error: 'Failed to fetch device access.', details: error.message });
    } finally {
        if (connection) connection.release();
    }
});

// Debug endpoint to check database structure
app.get('/api/debug/tables', authenticateToken, async (req, res) => {
    let connection;
    try {
        connection = await db.getConnection();
        
        // Check user_device_access structure
        try {
            const [columns] = await connection.query(`DESCRIBE user_device_access`);
            console.log('user_device_access columns:', columns);
            res.json({ 
                success: true, 
                columns: columns,
                message: 'Table structure retrieved successfully'
            });
        } catch (err) {
            console.log('user_device_access table error:', err.message);
            res.status(500).json({ error: 'Table does not exist: ' + err.message });
        }
        
    } catch (error) {
        console.error('Debug endpoint error:', error);
        res.status(500).json({ error: error.message });
    } finally {
        if (connection) connection.release();
    }
});

// 5. Get user's request history
app.get('/api/user/device-requests', authenticateToken, async (req, res) => {
    let connection;
    try {
        const userId = req.user.id;

        connection = await db.getConnection();

        const [rows] = await connection.query(
            `SELECT 
                dar.id, dar.device_id, dar.message, dar.status, 
                dar.response_message, dar.created_at, dar.responded_at,
                d.device_name
            FROM device_access_requests dar
            LEFT JOIN devices d ON dar.device_id = d.device_id
            WHERE dar.user_id = ?
            ORDER BY dar.created_at DESC`,
            [userId]
        );

        res.status(200).json({ success: true, requests: rows });

    } catch (error) {
        console.error('Error fetching user requests:', error);
        res.status(500).json({ error: 'Failed to fetch user requests.' });
    } finally {
        if (connection) connection.release();
    }
});

// ============= END DEVICE ACCESS REQUEST ENDPOINTS =============

// ============= ESTABLISHMENT SENSORS ENDPOINTS =============

// Get sensors for a specific establishment based on estab_sensors table
app.get('/api/establishment/:establishmentId/sensors', authenticateToken, async (req, res) => {
  let connection;
  try {
    const { establishmentId } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;
    
    console.log(`🔍 DEBUG: User ${userId} (${userRole}) requesting sensors for establishment ${establishmentId}`);
    
    connection = await db.getConnection();
    
    // Check if user has access to this establishment
    if (userRole !== 'Super Admin') {
      const [userEstab] = await connection.query(
        'SELECT establishment_id FROM users WHERE id = ?',
        [userId]
      );
      
      if (userEstab.length === 0 || userEstab[0].establishment_id != establishmentId) {
        return res.status(403).json({ error: 'Access denied to this establishment' });
      }
    }
    
    // Get sensors for this establishment
    const [sensors] = await connection.query(
      `SELECT s.id, s.sensor_name, es.estab_id, es.sensor_id
       FROM estab_sensors es
       JOIN sensors s ON es.sensor_id = s.id
       WHERE es.estab_id = ?
       ORDER BY s.id`,
      [establishmentId]
    );
    
    console.log(`🔍 DEBUG: Found ${sensors.length} sensors for establishment ${establishmentId}`);
    
    res.json({
      success: true,
      establishmentId: establishmentId,
      sensors: sensors,
      totalSensors: sensors.length
    });
    
  } catch (error) {
    console.error('Error fetching establishment sensors:', error);
    res.status(500).json({ error: 'Failed to fetch sensors for establishment' });
  } finally {
    if (connection) connection.release();
  }
});

// Get sensors for a specific device_id
app.get('/api/device/:deviceId/sensors', authenticateToken, async (req, res) => {
  let connection;
  try {
    const { deviceId } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;
    
    console.log(`🔍 DEBUG: User ${userId} (${userRole}) requesting sensors for device ${deviceId}`);
    
    connection = await db.getConnection();
    
    // Remove commas from deviceId to handle both formats (74175 and 74,175)
    const cleanDeviceId = deviceId.replace(/,/g, '');
    
    // Get establishment ID from device_id
    // Use REPLACE to strip commas from database values for comparison
    const [estabInfo] = await connection.query(
      'SELECT id FROM estab WHERE REPLACE(device_id, ",", "") = ?',
      [cleanDeviceId]
    );
    
    if (estabInfo.length === 0) {
      console.log(`❌ Device not found: ${deviceId} (cleaned: ${cleanDeviceId})`);
      return res.status(404).json({ error: 'Device not found' });
    }
    
    const establishmentId = estabInfo[0].id;
    
    // Check if user has access to this device
    if (userRole !== 'Super Admin') {
      const [userEstab] = await connection.query(
        'SELECT establishment_id FROM users WHERE id = ?',
        [userId]
      );
      
      if (userEstab.length === 0 || userEstab[0].establishment_id != establishmentId) {
        // Check if user has device access
        // Use REPLACE to handle commas in device_id comparison
        const [deviceAccess] = await connection.query(
          'SELECT * FROM user_device_access WHERE user_id = ? AND REPLACE(device_id, ",", "") = ?',
          [userId, cleanDeviceId]
        );
        
        if (deviceAccess.length === 0) {
          return res.status(403).json({ error: 'Access denied to this device' });
        }
      }
    }
    
    // Get sensors for this establishment
    const [sensors] = await connection.query(
      `SELECT s.id, s.sensor_name, es.estab_id, es.sensor_id
       FROM estab_sensors es
       JOIN sensors s ON es.sensor_id = s.id
       WHERE es.estab_id = ?
       ORDER BY s.id`,
      [establishmentId]
    );
    
    console.log(`🔍 DEBUG: Found ${sensors.length} sensors for device ${deviceId} (establishment ${establishmentId})`);
    
    res.json({
      success: true,
      deviceId: deviceId,
      establishmentId: establishmentId,
      sensors: sensors,
      totalSensors: sensors.length
    });
    
  } catch (error) {
    console.error('Error fetching device sensors:', error);
    res.status(500).json({ error: 'Failed to fetch sensors for device' });
  } finally {
    if (connection) connection.release();
  }
});

// ============= END ESTABLISHMENT SENSORS ENDPOINTS =============