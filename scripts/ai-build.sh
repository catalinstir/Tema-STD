#!/bin/bash

docker build -t ai-backend:latest ./ai-application/backend
docker build -t ai-frontend:latest ./ai-application/frontend
