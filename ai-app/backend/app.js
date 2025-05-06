const express = require('express');
const multer = require('multer');
const { BlobServiceClient } = require('@azure/storage-blob');
const { SpeechConfig, AudioConfig, SpeechRecognizer } = require('microsoft-cognitiveservices-speech-sdk');
const sql = require('mssql');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const app = express();
const port = 80;

// Configure middleware
app.use(cors());
app.use(express.json());

// Configure Azure storage
const AZURE_STORAGE_CONNECTION_STRING = process.env.AZURE_STORAGE_CONNECTION_STRING;
const blobServiceClient = BlobServiceClient.fromConnectionString(AZURE_STORAGE_CONNECTION_STRING);
const containerName = "audio-files";
const containerClient = blobServiceClient.getContainerClient(containerName);

// Create container if it doesn't exist
async function createContainerIfNotExists() {
  try {
    await containerClient.create();
    console.log(`Container "${containerName}" created successfully`);
  } catch (error) {
    if (error.statusCode === 409) {
      console.log(`Container "${containerName}" already exists`);
    } else {
      console.error(`Error creating container: ${error.message}`);
    }
  }
}
createContainerIfNotExists();

// Configure Azure SQL
const sqlConfig = {
  user: process.env.SQL_USER || 'admin',
  password: process.env.SQL_PASSWORD || 'password',
  server: process.env.SQL_SERVER || 'your-server.database.windows.net',
  database: process.env.SQL_DATABASE || 'ai-app',
  options: {
    encrypt: true
  }
};

// Initialize SQL connection pool
const pool = new sql.ConnectionPool(sqlConfig);
const poolConnect = pool.connect();

// Ensure SQL table exists
async function initializeDatabase() {
  try {
    await poolConnect;
    await pool.request().query(`
      IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'audio_files')
      BEGIN
        CREATE TABLE audio_files (
          id INT IDENTITY(1,1) PRIMARY KEY,
          filename NVARCHAR(255) NOT NULL,
          blob_url NVARCHAR(1000) NOT NULL,
          timestamp DATETIME NOT NULL DEFAULT GETDATE(),
          transcription NVARCHAR(MAX)
        )
      END
    `);
    console.log("Database initialized successfully");
  } catch (err) {
    console.error("Error initializing database:", err);
  }
}
initializeDatabase();

// Configure file storage for uploads
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, '/tmp/uploads/');
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});

// Create uploads directory if it doesn't exist
if (!fs.existsSync('/tmp/uploads/')) {
  fs.mkdirSync('/tmp/uploads/', { recursive: true });
}

const upload = multer({ storage: storage });

// Configure Azure Speech Service
function getSpeechConfig() {
  return SpeechConfig.fromSubscription(
    process.env.SPEECH_KEY || 'your-speech-key',
    process.env.SPEECH_REGION || 'westeurope'
  );
}

// Function to transcribe audio
async function transcribeAudio(filePath) {
  return new Promise((resolve, reject) => {
    const speechConfig = getSpeechConfig();
    const audioConfig = AudioConfig.fromWavFileInput(fs.readFileSync(filePath));
    const recognizer = new SpeechRecognizer(speechConfig, audioConfig);

    recognizer.recognizeOnceAsync(
      (result) => {
        recognizer.close();
        resolve(result.text);
      },
      (error) => {
        recognizer.close();
        reject(error);
      }
    );
  });
}

// API endpoint to upload audio file
app.post('/api/upload', upload.single('audioFile'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).send({ message: 'No file uploaded' });
    }

    const filePath = req.file.path;
    const fileName = req.file.originalname;

    // Upload to Blob Storage
    const blockBlobClient = containerClient.getBlockBlobClient(fileName);
    await blockBlobClient.uploadFile(filePath);
    const blobUrl = blockBlobClient.url;

    // Process with Speech-to-Text
    const transcription = await transcribeAudio(filePath);

    // Store in SQL Database
    await pool.request()
      .input('filename', sql.NVarChar, fileName)
      .input('blob_url', sql.NVarChar, blobUrl)
      .input('transcription', sql.NVarChar, transcription)
      .query(`
        INSERT INTO audio_files (filename, blob_url, transcription)
        VALUES (@filename, @blob_url, @transcription);
        SELECT SCOPE_IDENTITY() AS id;
      `);

    // Clean up temporary file
    fs.unlinkSync(filePath);

    res.status(200).send({
      message: 'File processed successfully',
      fileName,
      blobUrl,
      transcription
    });
  } catch (error) {
    console.error('Error processing file:', error);
    res.status(500).send({ message: 'Error processing file', error: error.message });
  }
});

// API endpoint to get file history
app.get('/api/history', async (req, res) => {
  try {
    const result = await pool.request()
      .query('SELECT id, filename, blob_url, timestamp, transcription FROM audio_files ORDER BY timestamp DESC');
    
    res.status(200).send(result.recordset);
  } catch (error) {
    console.error('Error fetching history:', error);
    res.status(500).send({ message: 'Error fetching history', error: error.message });
  }
});

// Start server
app.listen(port, () => {
  console.log(`AI backend listening at http://localhost:${port}`);
});
