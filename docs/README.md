# Real-Time Chat Application

A scalable, secure, and high-performance real-time messaging platform built with Spring Boot microservices and React.

## Architecture Overview

This application follows a microservices architecture with the following components:

### Backend Services (Spring Boot)
1. **Auth Service** (Port 8081) - User authentication with JWT
2. **User Service** (Port 8082) - User management and presence tracking
3. **Chat Service** (Port 8083) - Real-time messaging with WebSockets
4. **API Gateway** (Port 8080) - Request routing and authentication

### Frontend
- **React Application** (Port 5173) - Modern UI with real-time updates

### Infrastructure
- **PostgreSQL** - Primary database for data persistence
- **Redis** - Caching and Pub/Sub message distribution

## Features

- User registration and authentication with JWT
- Real-time messaging using WebSockets (STOMP protocol)
- One-to-one and group chat support
- Online/offline presence tracking
- Typing indicators
- Message history and persistence
- User search functionality
- Secure password hashing with BCrypt
- Responsive UI with TailwindCSS

## Technology Stack

### Backend
- Spring Boot 3.2.0
- Spring WebSocket & STOMP
- Spring Security & JWT
- Spring Cloud Gateway
- Spring Data JPA
- PostgreSQL
- Redis
- Maven

### Frontend
- React 18.3
- TypeScript
- Redux Toolkit
- Vite
- TailwindCSS
- WebSocket (STOMP)
- Axios

## Prerequisites

- Java 17 or higher
- Maven 3.9+
- Node.js 18+ and pnpm
- Docker and Docker Compose
- PostgreSQL 15
- Redis 7

## Quick Start with Docker

1. Clone the repository and navigate to the backend directory:
```bash
cd backend
```

2. Start all services with Docker Compose:
```bash
docker-compose up --build
```

This will start:
- PostgreSQL on port 5432
- Redis on port 6379
- Auth Service on port 8081
- User Service on port 8082
- Chat Service on port 8083
- API Gateway on port 8080
- Frontend on port 5173

3. Access the application:
- Frontend: http://localhost:5173
- API Gateway: http://localhost:8080

## Manual Setup (Development)

### 1. Database Setup

Start PostgreSQL and Redis:
```bash
docker run -d -p 5432:5432 -e POSTGRES_DB=chatdb -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres postgres:15-alpine
docker run -d -p 6379:6379 redis:7-alpine
```

Initialize the database:
```bash
psql -h localhost -U postgres -d chatdb -f database/init.sql
```

### 2. Backend Services

Set environment variables:
```bash
export DB_HOST=localhost
export DB_NAME=chatdb
export DB_USER=postgres
export DB_PASSWORD=postgres
export REDIS_HOST=localhost
export REDIS_PORT=6379
export JWT_SECRET=your-256-bit-secret-key-change-this-in-production-environment
```

Start each service:

**Auth Service:**
```bash
cd backend/auth-service
mvn spring-boot:run
```

**User Service:**
```bash
cd backend/user-service
mvn spring-boot:run
```

**Chat Service:**
```bash
cd backend/chat-service
mvn spring-boot:run
```

**API Gateway:**
```bash
cd backend/gateway-service
mvn spring-boot:run
```

### 3. Frontend

```bash
cd frontend/chat-frontend
pnpm install
pnpm dev
```

## API Documentation

### Authentication Endpoints

**Register**
```http
POST /api/auth/register
Content-Type: application/json

{
  "username": "john",
  "email": "john@example.com",
  "password": "password123"
}
```

**Login**
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "john",
  "password": "password123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userId": 1,
  "username": "john",
  "email": "john@example.com"
}
```

### User Endpoints

**Get User Profile**
```http
GET /api/users/{id}
Authorization: Bearer {token}
```

**Update User**
```http
PUT /api/users/update
Authorization: Bearer {token}
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john.doe@example.com"
}
```

**Search Users**
```http
GET /api/users/search?q=john
Authorization: Bearer {token}
```

**Get Online Users**
```http
GET /api/users/online
Authorization: Bearer {token}
```

### Chat Endpoints

**Create Chat Room**
```http
POST /api/chat/rooms
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Project Discussion",
  "type": "group",
  "participantIds": [2, 3, 4]
}
```

**Get User's Chat Rooms**
```http
GET /api/chat/rooms
Authorization: Bearer {token}
```

**Get Room Messages**
```http
GET /api/chat/messages/{roomId}
Authorization: Bearer {token}
```

### WebSocket Communication

**Connect to WebSocket**
```javascript
const socket = new SockJS('http://localhost:8080/ws');
const stompClient = Stomp.over(socket);

stompClient.connect({}, () => {
  // Subscribe to room messages
  stompClient.subscribe('/topic/messages/1', (message) => {
    console.log(JSON.parse(message.body));
  });
  
  // Send message
  stompClient.send('/app/sendMessage', {}, JSON.stringify({
    chatRoomId: 1,
    senderId: 1,
    content: 'Hello World'
  }));
});
```

## Database Schema

### Users Table
```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    profile_pic TEXT,
    status VARCHAR(50) DEFAULT 'offline',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### Chat Rooms Table
```sql
CREATE TABLE chat_rooms (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    type VARCHAR(20) NOT NULL CHECK (type IN ('private', 'group')),
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### Messages Table
```sql
CREATE TABLE messages (
    id BIGSERIAL PRIMARY KEY,
    chat_room_id BIGINT NOT NULL REFERENCES chat_rooms(id),
    sender_id BIGINT NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'sent'
);
```

### Participants Table
```sql
CREATE TABLE participants (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    chat_room_id BIGINT NOT NULL REFERENCES chat_rooms(id),
    UNIQUE(user_id, chat_room_id)
);
```

## Configuration

### Environment Variables

**Backend Services:**
- `DB_HOST` - PostgreSQL host (default: localhost)
- `DB_NAME` - Database name (default: chatdb)
- `DB_USER` - Database user (default: postgres)
- `DB_PASSWORD` - Database password (default: postgres)
- `REDIS_HOST` - Redis host (default: localhost)
- `REDIS_PORT` - Redis port (default: 6379)
- `JWT_SECRET` - JWT signing secret (change in production!)

**Frontend:**
- `VITE_API_URL` - Backend API URL (default: http://localhost:8080)
- `VITE_WS_URL` - WebSocket URL (default: http://localhost:8080/ws)

## Testing

### Test Sample Users

The database initialization includes sample users:
- Username: alice, Password: password (to be hashed)
- Username: bob, Password: password (to be hashed)
- Username: charlie, Password: password (to be hashed)

### Manual Testing Steps

1. Register a new user or login with sample credentials
2. Search for other users to start a chat
3. Send messages and observe real-time delivery
4. Test typing indicators
5. Open multiple browser windows to test multi-user scenarios
6. Check online/offline status updates

## Production Deployment

### Security Checklist

- [ ] Change JWT_SECRET to a strong random value
- [ ] Use environment-specific database credentials
- [ ] Enable HTTPS/TLS for all services
- [ ] Configure CORS properly for production domain
- [ ] Set up rate limiting on API Gateway
- [ ] Enable database connection pooling
- [ ] Configure proper logging and monitoring
- [ ] Set up Redis persistence

### Scaling Considerations

- Deploy multiple instances of each microservice behind load balancers
- Use Redis Pub/Sub for message distribution across instances
- Implement database read replicas for read-heavy operations
- Use CDN for static frontend assets
- Configure horizontal pod autoscaling in Kubernetes

## Troubleshooting

### WebSocket Connection Issues
- Ensure CORS is properly configured in gateway
- Check that WebSocket endpoint is accessible
- Verify JWT token is valid and not expired

### Database Connection Errors
- Confirm PostgreSQL is running and accessible
- Check database credentials
- Verify database exists and is initialized

### Message Delivery Issues
- Check Redis connection
- Verify WebSocket subscription is active
- Check browser console for errors

## Project Structure

```
.
├── backend/
│   ├── auth-service/          # Authentication microservice
│   ├── user-service/          # User management microservice
│   ├── chat-service/          # Chat and messaging microservice
│   ├── gateway-service/       # API Gateway
│   └── docker-compose.yml     # Docker orchestration
├── frontend/
│   └── chat-frontend/         # React application
├── database/
│   └── init.sql              # Database schema
└── docs/
    └── README.md             # This file
```

## License

MIT License

## Contributors

Built with MiniMax Agent
