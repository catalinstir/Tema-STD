#!/bin/bash

docker build -t chat-backend:latest ./chat-app/backend
docker build -t chat-frontend:latest ./chat-app/frontend
