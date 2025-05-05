#!/bin/bash

cd ~/Documents/STD/Tema-STD/chat-app/backend/websocket-chat

mvn clean package

docker run --name chat-mysql -e MYSQL_ROOT_PASSWORD=password -e MYSQL_DATABASE=chat -e MYSQL_USER=chatuser -e MYSQL_PASSWORD=chatpassword -p 3306:3306 -d mysql:5.7

sleep 5

docker exec -i chat-mysql mysql -u chatuser -pchatpassword chat < ~/Documents/STD/Tema-STD/chat-app/mysql/init.sql

# Change: private static final String DB_URL = "jdbc:mysql://chat-mysql:3306/chat";
# To: private static final String DB_URL = "jdbc:mysql://localhost:3306/chat";

mvn clean package

docker build -t chat-backend .
docker run -p 8080:8080 -p 80:80 chat-backend
