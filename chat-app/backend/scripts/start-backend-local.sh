#!/bin/bash

echo "Removing local mysql and apache2 services"
sudo systemctl stop mysql
sudo systemctl stop apache2


cd ~/Documents/STD/Tema-STD/chat-app/backend/websocket-chat

echo "Running db container"
docker run --name chat-mysql -e MYSQL_ROOT_PASSWORD=password -e MYSQL_DATABASE=chat -e MYSQL_USER=chatuser -e MYSQL_PASSWORD=chatpassword -p 3306:3306 -d mysql:5.7

echo "Letting it start..."
sleep 5

echo "Logging in the db"
docker exec -i chat-mysql mysql -u chatuser -pchatpassword chat < ~/Documents/STD/Tema-STD/chat-app/mysql/init.sql

echo "Building backend image"
docker build -t chat-backend .

echo "Runnimg backend"
docker run -p 8080:8080 -p 80:80 chat-backend
