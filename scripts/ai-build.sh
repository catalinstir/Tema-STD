#!/bin/bash

docker build -t ai-backend:latest ./ai-app/backend
docker build -t ai-frontend:latest ./ai-app/frontend
