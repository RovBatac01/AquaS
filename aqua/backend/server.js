const express = require("express");
const mysql = require("mysql2");
const { SerialPort } = require("serialport");
const { ReadlineParser } = require("@serialport/parser-readline");
const bodyParser = require("body-parser");
const cors = require("cors");
const http = require("http");
const { Server } = require("socket.io");

const app = express();
const port = 3000;

// Middleware
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
  user: "root", // Change if needed
  password: "", // Add your MySQL password
  database: "sensor_db",
});

db.connect((err) => {
  if (err) {
    console.error("❌ MySQL Connection Error:", err);
    return;
  }
  console.log("✅ Connected to MySQL Database.");
});

// Set up SerialPort (Change COM5 to your correct port)
const serialPort = new SerialPort({ path: "COM5", baudRate: 9600 });
const parser = serialPort.pipe(new ReadlineParser({ delimiter: "\n" }));

serialPort.on("open", () => {
  console.log("✅ Serial Port Opened: COM5");
});

// Read and store data from Arduino
parser.on("data", (data) => {
  console.log("📡 Raw Data Received:", data.trim());

  try {
    const jsonData = JSON.parse(data.trim());
    const turbidityValue = jsonData.turbidity_value;
    const timestamp = new Date().toISOString();

    console.log("🔄 Parsed Turbidity Value:", turbidityValue, "Timestamp:", timestamp);

    // Insert into MySQL
    const query = "INSERT INTO turbidity_readings (turbidity_value, timestamp) VALUES (?, ?)";
    db.query(query, [turbidityValue, timestamp], (err, result) => {
      if (err) {
        console.error("❌ Database Insert Error:", err);
      } else {
        console.log("✅ Data Inserted Successfully: ID", result.insertId);

        // Emit real-time data update
        io.emit("updateData", { value: turbidityValue, timestamp });
        console.log("📢 WebSocket Event Emitted:", { value: turbidityValue, timestamp });
      }
    });
  } catch (err) {
    console.error("❌ JSON Parse Error:", err);
  }
});

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
