#!/bin/bash

docker build -t chat-backend:latest ./chat-system/backend
docker build -t chat-frontend:latest ./chat-system/frontend
