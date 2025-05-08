### 1. Check Container Status

docker-compose ps

This shows the status of all containers. Ensure all are in the "Up" state.

### 2. View Container Logs

docker-compose logs [service-name]

Example: `docker-compose logs chat-backend`

### 3. Restart a Specific Service

docker-compose restart [service-name]

### 4. Rebuild a Service

docker-compose up -d --build [service-name]

### Joomla Issues

1. **Joomla not loading properly:**
   - Check MySQL connection in `docker-compose logs joomla-mysql`
   - Ensure Joomla configuration is correct
   - Try rebuilding: `docker-compose up -d --build joomla`

2. **Cannot integrate iframes:**
   - Verify that the custom template files are in the correct location
   - Check Joomla's template settings
   - Ensure iframe URLs are correct

### Chat Application Issues

1. **WebSocket connection failing:**
   - Check that chat-backend is running: `docker-compose logs chat-backend`
   - Verify WebSocket URL in the Chat.vue file (`ws://localhost:88/chat`)
   - Ensure port 88 is correctly mapped

2. **Chat messages not persisting:**
   - Check MySQL connection: `docker-compose logs chat-mysql`
   - Inspect the database: 
     ```bash
     docker-compose exec chat-mysql bash -c "mysql -u root -ppassword -e 'USE chat; SELECT * FROM messages;'"
     ```

### AI Application Issues

1. **Cannot upload audio files:**
   - Check browser console for CORS errors
   - Verify that AI backend is running: `docker-compose logs ai-backend`
   - Ensure port 92 is correctly mapped

2. **Azure services not working:**
   - Check environment variables in docker-compose.yml
   - Verify Azure credentials
   - Check logs: `docker-compose logs ai-backend`

## Network Issues

1. **Services cannot communicate:**
   - Ensure all services are on the same network
   - Try using service names instead of localhost within containers
   - Check if network exists: `docker network ls`

2. **Port conflicts:**
   - Check if ports are already in use on your host machine
   - Change port mappings in docker-compose.yml if needed

## Reset Environment

If you need a fresh start:

```bash
# Stop all containers
docker-compose down

# Remove all volumes
docker-compose down -v

# Rebuild and start
docker-compose up -d --build
```

## Additional Commands

### Enter Container Shell

```bash
docker-compose exec [service-name] bash
```

Example: `docker-compose exec chat-backend bash`

### Check Network Configuration

```bash
docker network inspect app-network
```

### Monitor Resource Usage

```bash
docker stats
```
