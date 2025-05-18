const express = require("express");
const mysql = require("mysql2");
const { SerialPort } = require("serialport");
const { ReadlineParser } = require("@serialport/parser-readline");
const bodyParser = require("body-parser");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");
const bcrypt = require('bcrypt');
const saltRounds = 10;

const app = express();
const port = 5000;

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
const db = mysql.createConnection({
  host: "localhost",
  user: "root",
  password: "",
  database: "aquasense",
});

app.post("/register", async (req, res) => {
  const { username, email, phone = null, password, confirm_password } = req.body;

  if (!username || !email || !password || !confirm_password) {
    return res.status(400).json({ error: "All fields are required" });
  }

  if (password !== confirm_password) {
    return res.status(400).json({ error: "Passwords do not match" });
  }

  try {
    // Hash Password
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // SQL Query
    const sql = "INSERT INTO users (username, email, phone, password_hash) VALUES (?, ?, ?, ?)";

    // Insert User Data
    db.query(sql, [username, email, phone || null, hashedPassword], (err, result) => {
      if (err) {
        console.error("Database error:", err.sqlMessage);
        return res.status(500).json({ error: "Database error occurred" });
      }
      res.json({
        message: "User registered successfully!",
        userId: result.insertId, // Return inserted user ID
      });
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
    db.query(sql, [username], async (err, results) => {
        if (err) {
            console.error("Database error:", err);
            return res.status(500).json({ error: "Database error occurred" });
        }

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
            role: user.role 
            // token: "your_jwt_token_here"
        });
    });
});

// NEW: Endpoint to fetch all users
app.get("/users", (req, res) => {
    const sql = "SELECT id, username, role FROM users"; 
    db.query(sql, (err, results) => {
        if (err) {
            console.error("Database error fetching users:", err);
            return res.status(500).json({ error: "Failed to fetch users from database." });
        }
        res.status(200).json(results); 
    });
});

// NEW: Endpoint to update a user by ID (PUT request)
app.put("/users/:id", (req, res) => {
    const userId = req.params.id; 
    const { username, role } = req.body;

    if (!username || !role) {
        return res.status(400).json({ error: "Username and role are required for update." });
    }
    const sql = "UPDATE users SET username = ?, role = ? WHERE id = ?";
    db.query(sql, [username, role, userId], (err, result) => {
        if (err) {
            console.error("Database error updating user:", err);
            return res.status(500).json({ error: "Failed to update user in database." });
        }
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: "User not found or no changes made." });
        }
        res.status(200).json({ message: "User updated successfully!" });
    });
});

// NEW: Endpoint to delete a user by ID (DELETE request)
app.delete("/users/:id", (req, res) => {
    const userId = req.params.id;

    const sql = "DELETE FROM users WHERE id = ?";
    db.query(sql, [userId], (err, result) => {
        if (err) {
            console.error("Database error deleting user:", err);
            return res.status(500).json({ error: "Failed to delete user from database." });
        }
        if (result.affectedRows === 0) {
            return res.status(404).json({ error: "User not found." });
        }
        res.status(200).json({ message: "User deleted successfully!" });
    });
});

// Set up SerialPort (Change COM5 to your correct port)
// const serialPort = new SerialPort({ path: "COM5", baudRate: 9600 });
// const parser = serialPort.pipe(new ReadlineParser({ delimiter: "\n" }));

// serialPort.on("open", () => {
//   console.log("✅ Serial Port Opened: COM5");
// });

// // Read and store data from Arduino
// parser.on("data", (data) => {
//   console.log("📡 Raw Data Received:", data.trim());

//   try {
//     const jsonData = JSON.parse(data.trim());
//     const turbidityValue = jsonData.turbidity_value;
//     const timestamp = new Date().toISOString();

//     console.log("🔄 Parsed Turbidity Value:", turbidityValue, "Timestamp:", timestamp);

//     // Insert into MySQL
//     const query = "INSERT INTO turbidity_readings (turbidity_value, timestamp) VALUES (?, ?)";
//     db.query(query, [turbidityValue, timestamp], (err, result) => {
//       if (err) {
//         console.error("❌ Database Insert Error:", err);
//       } else {
//         console.log("✅ Data Inserted Successfully: ID", result.insertId);

//         // Emit real-time data update
//         io.emit("updateData", { value: turbidityValue, timestamp });
//         console.log("📢 WebSocket Event Emitted:", { value: turbidityValue, timestamp });
//       }
//     });
//   } catch (err) {
//     console.error("❌ JSON Parse Error:", err);
//   }
// });

// API Route to Fetch Data
app.get("/data", (req, res) => {
  console.log("📥 GET /data request received");

  db.query("SELECT * FROM turbidity_readings ORDER BY id DESC LIMIT 10", (err, results) => {
    if (err) {
      console.error("❌ Database Query Error:", err);
      return res.status(500).json({ error: "Database Query Error" });
    }

    console.log(`✅ API Response Sent: ${results.length} records`);
    res.json(results);
  });
});

// Start Express & Socket.IO Server
server.listen(port, () => {
  console.log(`🚀 Backend running on http://localhost:${port}`);
});
io.listen(3001, () => {
  console.log("🔌 WebSocket server running on port 3001");
});
