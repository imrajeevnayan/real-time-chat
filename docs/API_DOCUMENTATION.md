# API Reference

## Base URL
```
http://localhost:8080
```

All API endpoints are accessed through the API Gateway running on port 8080.

## Authentication

All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer {token}
```

### Obtaining a Token

Tokens are obtained through the login or register endpoints. The token should be stored and included in subsequent requests.

## Auth Service Endpoints

### POST /api/auth/register

Register a new user account.

**Request Body:**
```json
{
  "username": "string (required, 3-50 chars)",
  "email": "string (required, valid email)",
  "password": "string (required, min 6 chars)",
  "profilePic": "string (optional)"
}
```

**Success Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userId": 1,
  "username": "john",
  "email": "john@example.com",
  "profilePic": null
}
```

**Error Responses:**
- 400 Bad Request - Username or email already exists
- 400 Bad Request - Validation errors

### POST /api/auth/login

Authenticate an existing user.

**Request Body:**
```json
{
  "username": "string (required)",
  "password": "string (required)"
}
```

**Success Response (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userId": 1,
  "username": "john",
  "email": "john@example.com",
  "profilePic": null
}
```

**Error Responses:**
- 401 Unauthorized - Invalid credentials

### POST /api/auth/validate

Validate a JWT token (internal use).

**Query Parameters:**
- `token` - JWT token to validate

**Success Response (200 OK):**
```json
{
  "valid": true,
  "userId": 1,
  "username": "john"
}
```

## User Service Endpoints

### GET /api/users/{id}

Get user profile by ID.

**Headers:**
- `Authorization: Bearer {token}`

**Success Response (200 OK):**
```json
{
  "id": 1,
  "username": "john",
  "email": "john@example.com",
  "profilePic": null,
  "status": "online"
}
```

**Error Responses:**
- 401 Unauthorized - Missing or invalid token
- 404 Not Found - User not found

### PUT /api/users/update

Update current user's profile.

**Headers:**
- `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "username": "string (optional)",
  "email": "string (optional, valid email)",
  "profilePic": "string (optional)"
}
```

**Success Response (200 OK):**
```json
{
  "id": 1,
  "username": "john_updated",
  "email": "john.updated@example.com",
  "profilePic": "https://example.com/pic.jpg",
  "status": "online"
}
```

### GET /api/users/search

Search users by username.

**Headers:**
- `Authorization: Bearer {token}`

**Query Parameters:**
- `q` - Search query (case-insensitive partial match)

**Success Response (200 OK):**
```json
[
  {
    "id": 2,
    "username": "alice",
    "email": "alice@example.com",
    "profilePic": null,
    "status": "online"
  },
  {
    "id": 3,
    "username": "bob",
    "email": "bob@example.com",
    "profilePic": null,
    "status": "offline"
  }
]
```

### GET /api/users/online

Get list of currently online users.

**Headers:**
- `Authorization: Bearer {token}`

**Success Response (200 OK):**
```json
[
  {
    "id": 2,
    "username": "alice",
    "email": "alice@example.com",
    "profilePic": null,
    "status": "online"
  }
]
```

### POST /api/users/status

Update user's online status.

**Headers:**
- `Authorization: Bearer {token}`

**Query Parameters:**
- `status` - New status value (e.g., "online", "offline", "away")

**Success Response (200 OK):**
No content

### POST /api/users/heartbeat

Send presence heartbeat to maintain online status.

**Headers:**
- `Authorization: Bearer {token}`

**Success Response (200 OK):**
No content

## Chat Service Endpoints

### POST /api/chat/rooms

Create a new chat room.

**Headers:**
- `Authorization: Bearer {token}`

**Request Body:**
```json
{
  "name": "Project Discussion",
  "type": "private | group",
  "participantIds": [2, 3, 4]
}
```

**Success Response (200 OK):**
```json
{
  "id": 1,
  "name": "Project Discussion",
  "type": "group",
  "createdBy": 1,
  "createdAt": "2025-10-31T04:52:16"
}
```

**Notes:**
- For private chats with 2 participants, if room already exists, it will be returned instead of creating a new one
- Creator is automatically added as a participant

### GET /api/chat/rooms

Get all chat rooms for the current user.

**Headers:**
- `Authorization: Bearer {token}`

**Success Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "Project Discussion",
    "type": "group",
    "createdBy": 1,
    "createdAt": "2025-10-31T04:52:16"
  },
  {
    "id": 2,
    "name": "john & alice",
    "type": "private",
    "createdBy": 1,
    "createdAt": "2025-10-31T05:00:00"
  }
]
```

### GET /api/chat/rooms/{roomId}

Get chat room details.

**Headers:**
- `Authorization: Bearer {token}`

**Path Parameters:**
- `roomId` - Chat room ID

**Success Response (200 OK):**
```json
{
  "id": 1,
  "name": "Project Discussion",
  "type": "group",
  "createdBy": 1,
  "createdAt": "2025-10-31T04:52:16"
}
```

### GET /api/chat/messages/{roomId}

Get message history for a chat room.

**Headers:**
- `Authorization: Bearer {token}`

**Path Parameters:**
- `roomId` - Chat room ID

**Success Response (200 OK):**
```json
[
  {
    "id": 1,
    "chatRoomId": 1,
    "senderId": 1,
    "content": "Hello everyone!",
    "timestamp": "2025-10-31T04:52:16",
    "status": "sent"
  },
  {
    "id": 2,
    "chatRoomId": 1,
    "senderId": 2,
    "content": "Hi there!",
    "timestamp": "2025-10-31T04:53:00",
    "status": "sent"
  }
]
```

### GET /api/chat/rooms/{roomId}/participants

Get participants in a chat room.

**Headers:**
- `Authorization: Bearer {token}`

**Path Parameters:**
- `roomId` - Chat room ID

**Success Response (200 OK):**
```json
[
  {
    "id": 1,
    "userId": 1,
    "chatRoomId": 1
  },
  {
    "id": 2,
    "userId": 2,
    "chatRoomId": 1
  }
]
```

## WebSocket Endpoints

### Connection

**Endpoint:** `/ws`

Connect using SockJS and STOMP protocol.

**Example (JavaScript):**
```javascript
import SockJS from 'sockjs-client';
import { Client } from '@stomp/stompjs';

const socket = new SockJS('http://localhost:8080/ws');
const stompClient = new Client({
  webSocketFactory: () => socket,
  reconnectDelay: 5000
});

stompClient.activate();
```

### Subscribe to Room Messages

**Destination:** `/topic/messages/{roomId}`

Receive all messages sent to a specific chat room.

**Message Format:**
```json
{
  "id": 1,
  "chatRoomId": 1,
  "senderId": 1,
  "senderName": "john",
  "content": "Hello!",
  "timestamp": "2025-10-31T04:52:16",
  "status": "sent",
  "type": "CHAT"
}
```

**Example:**
```javascript
stompClient.subscribe('/topic/messages/1', (message) => {
  const data = JSON.parse(message.body);
  console.log('New message:', data);
});
```

### Send Message

**Destination:** `/app/sendMessage`

Send a new message to a chat room.

**Message Format:**
```json
{
  "chatRoomId": 1,
  "senderId": 1,
  "senderName": "john",
  "content": "Hello everyone!",
  "type": "CHAT"
}
```

**Example:**
```javascript
stompClient.publish({
  destination: '/app/sendMessage',
  body: JSON.stringify({
    chatRoomId: 1,
    senderId: 1,
    senderName: 'john',
    content: 'Hello!'
  })
});
```

### Subscribe to Typing Indicators

**Destination:** `/topic/typing/{roomId}`

Receive typing notifications for a specific room.

**Message Format:**
```json
{
  "senderId": 1,
  "senderName": "john",
  "chatRoomId": 1,
  "type": "TYPING"
}
```

**Example:**
```javascript
stompClient.subscribe('/topic/typing/1', (message) => {
  const data = JSON.parse(message.body);
  console.log(`${data.senderName} is typing...`);
});
```

### Send Typing Indicator

**Destination:** `/app/typing/{roomId}`

Notify others that you are typing.

**Message Format:**
```json
{
  "senderId": 1,
  "senderName": "john",
  "chatRoomId": 1
}
```

**Example:**
```javascript
stompClient.publish({
  destination: '/app/typing/1',
  body: JSON.stringify({
    senderId: 1,
    senderName: 'john',
    chatRoomId: 1
  })
});
```

## Error Handling

All endpoints may return the following error responses:

### 400 Bad Request
Invalid request data or validation errors.
```json
{
  "error": "Username already exists"
}
```

### 401 Unauthorized
Missing or invalid authentication token.
```json
{
  "error": "Invalid or expired token"
}
```

### 404 Not Found
Requested resource not found.
```json
{
  "error": "User not found"
}
```

### 500 Internal Server Error
Server-side error occurred.
```json
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred"
  }
}
```

## Rate Limiting

The API Gateway implements rate limiting to prevent abuse:
- Default: 100 requests per minute per IP
- WebSocket connections: 10 new connections per minute per IP

## CORS

The API supports CORS for the following origins:
- http://localhost:5173 (Frontend dev)
- http://localhost:3000 (Alternative frontend port)

For production, configure additional allowed origins in the gateway configuration.
