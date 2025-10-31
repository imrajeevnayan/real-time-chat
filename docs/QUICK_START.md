# Quick Start Guide

Get the Real-Time Chat Application running in 5 minutes!

## Prerequisites Check

Before starting, ensure you have:
- [ ] Docker installed (version 20.10+)
- [ ] Docker Compose installed (version 2.0+)
- [ ] At least 4GB of free RAM
- [ ] Ports 5173, 8080-8083, 5432, 6379 available

Check Docker:
```bash
docker --version
docker-compose --version
```

## Option 1: Docker Compose (Recommended)

### Step 1: Navigate to Backend Directory
```bash
cd /workspace/backend
```

### Step 2: Start All Services
```bash
docker-compose up --build
```

This will:
- Build all 4 microservices
- Start PostgreSQL database
- Start Redis cache
- Initialize database schema
- Start API Gateway
- Start React frontend

**Wait for**: "Started [ServiceName]Application" messages (about 2-3 minutes)

### Step 3: Access the Application
Open your browser and go to:
```
http://localhost:5173
```

### Step 4: Create an Account
1. Click "Register"
2. Enter username, email, and password
3. Click "Register" button
4. You'll be automatically logged in

### Step 5: Start Chatting
1. Click the "+" button in the top right
2. Search for a user (try "alice" or "bob" - sample users)
3. Click on a user to start a private chat
4. Type a message and hit Enter or click Send

## Option 2: Manual Development Setup

### Step 1: Start Infrastructure Services
```bash
# Start PostgreSQL
docker run -d -p 5432:5432 \
  -e POSTGRES_DB=chatdb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  --name chat-postgres \
  postgres:15-alpine

# Start Redis
docker run -d -p 6379:6379 \
  --name chat-redis \
  redis:7-alpine

# Wait 10 seconds for services to be ready
sleep 10
```

### Step 2: Initialize Database
```bash
docker exec -i chat-postgres psql -U postgres -d chatdb < /workspace/database/init.sql
```

### Step 3: Set Environment Variables
```bash
export DB_HOST=localhost
export DB_NAME=chatdb
export DB_USER=postgres
export DB_PASSWORD=postgres
export REDIS_HOST=localhost
export REDIS_PORT=6379
export JWT_SECRET=your-256-bit-secret-key-change-this-in-production-environment
```

### Step 4: Start Backend Services

Open 4 separate terminal windows and run:

**Terminal 1 - Auth Service:**
```bash
cd /workspace/backend/auth-service
mvn spring-boot:run
```

**Terminal 2 - User Service:**
```bash
cd /workspace/backend/user-service
mvn spring-boot:run
```

**Terminal 3 - Chat Service:**
```bash
cd /workspace/backend/chat-service
mvn spring-boot:run
```

**Terminal 4 - Gateway Service:**
```bash
cd /workspace/backend/gateway-service
mvn spring-boot:run
```

Wait for each service to start (look for "Started [ServiceName]Application")

### Step 5: Start Frontend

Open a 5th terminal:
```bash
cd /workspace/frontend/chat-frontend
pnpm install
pnpm dev
```

### Step 6: Access Application
Open browser: http://localhost:5173

## Testing the Application

### Create Multiple Users

1. Open browser in normal mode, register as "alice"
2. Open browser in incognito/private mode, register as "bob"
3. In alice's window, search for "bob" and start a chat
4. Send messages back and forth to see real-time updates

### Test Features

- **Real-time messaging**: Send messages and see instant delivery
- **Typing indicators**: Start typing and watch the indicator appear
- **Online status**: Check the online users list
- **Message history**: Refresh the page and see messages persist
- **Multiple rooms**: Create chats with different users

## Verify Services are Running

### Health Checks

Open these URLs in your browser:
- Auth Service: http://localhost:8081/api/auth/health
- User Service: http://localhost:8082/api/users/health
- Chat Service: http://localhost:8083/api/chat/health
- API Gateway: http://localhost:8080/api/auth/health

All should return: "Service is running"

### Check Docker Containers

```bash
docker-compose ps
```

You should see all services in "Up" state:
```
NAME                    STATUS
chat-postgres          Up
chat-redis             Up
chat-auth-service      Up
chat-user-service      Up
chat-chat-service      Up
chat-gateway-service   Up
chat-frontend          Up
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f auth-service
docker-compose logs -f chat-service
```

## Common Issues

### Port Already in Use

If you get "port is already allocated" error:

```bash
# Find what's using the port (e.g., 8080)
lsof -i :8080

# Kill the process
kill -9 <PID>

# Or change the port in docker-compose.yml
```

### Database Connection Failed

```bash
# Check PostgreSQL is running
docker ps | grep postgres

# View PostgreSQL logs
docker logs chat-postgres

# Restart PostgreSQL
docker restart chat-postgres
```

### WebSocket Connection Failed

1. Check that Chat Service is running on port 8083
2. Verify API Gateway is running on port 8080
3. Check browser console for CORS errors
4. Ensure you're using the correct WebSocket URL in frontend .env

### Frontend Build Errors

```bash
# Clear node_modules and reinstall
cd /workspace/frontend/chat-frontend
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

## Stopping the Application

### Docker Compose

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes all data)
docker-compose down -v
```

### Manual Setup

```bash
# Stop backend services (Ctrl+C in each terminal)

# Stop infrastructure
docker stop chat-postgres chat-redis
docker rm chat-postgres chat-redis
```

## Sample Data

The database is initialized with 3 sample users:
- **alice** (alice@example.com)
- **bob** (bob@example.com)  
- **charlie** (charlie@example.com)

Note: You'll need to register with these usernames again since the init script doesn't set actual passwords, or you can update the init.sql to use properly hashed passwords.

## API Testing with cURL

### Register a User
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'
```

### Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

Save the token from the response!

### Get User Profile
```bash
TOKEN="your-jwt-token-here"
curl -X GET http://localhost:8080/api/users/1 \
  -H "Authorization: Bearer $TOKEN"
```

### Search Users
```bash
curl -X GET "http://localhost:8080/api/users/search?q=test" \
  -H "Authorization: Bearer $TOKEN"
```

## Next Steps

- [ ] Read the full [README.md](README.md) for detailed features
- [ ] Check [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for complete API reference
- [ ] Review [DEPLOYMENT.md](DEPLOYMENT.md) for production deployment
- [ ] Explore the code structure in [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)

## Getting Help

If you encounter issues:
1. Check the logs: `docker-compose logs -f`
2. Verify all services are running: `docker-compose ps`
3. Review the troubleshooting section in README.md
4. Check that all prerequisites are met

## Success!

If you can:
- ✅ Register a new user
- ✅ Login successfully
- ✅ Create a chat with another user
- ✅ Send and receive messages in real-time
- ✅ See typing indicators

**Congratulations! Your Real-Time Chat Application is running successfully!**

---

**Pro Tip**: Open the application in two different browsers (or normal + incognito mode) to fully test the real-time messaging capabilities.
