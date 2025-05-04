CREATE DATABASE IF NOT EXISTS chat;
USE chat;

CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    timestamp DATETIME NOT NULL
);

-- Add some initial test messages
INSERT INTO messages (username, message, timestamp) VALUES 
("System", "Welcome to the chat!", NOW());
