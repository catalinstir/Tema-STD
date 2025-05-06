#!/bin/bash

echo "Waiting for chat-mysql pod to be ready..."
kubectl wait --for=condition=ready pod -l app=chat-mysql --timeout=120s

MYSQL_POD=$(kubectl get pods -l app=chat-mysql -o jsonpath="{.items[0].metadata.name}")
echo "MySQL pod: $MYSQL_POD"

cat > init.sql << EOF
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
("System", "Welcome to the chat!", NOW()),
("System", "You can start chatting now!", NOW()),
("System", "This is a real-time chat application using WebSockets", NOW());
EOF

echo "Copying init.sql to MySQL pod..."
kubectl cp init.sql $MYSQL_POD:/tmp/init.sql

echo "Initializing database..."
kubectl exec $MYSQL_POD -- bash -c "mysql -u root -p\${MYSQL_ROOT_PASSWORD} < /tmp/init.sql"

echo "Verifying database setup..."
kubectl exec $MYSQL_POD -- bash -c "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'SHOW DATABASES;'"

echo "Verifying table setup..."
kubectl exec $MYSQL_POD -- bash -c "mysql -u root -p\${MYSQL_ROOT_PASSWORD} -e 'USE chat; SHOW TABLES;'"

rm init.sql

echo "Chat MySQL database setup complete!"
