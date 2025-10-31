# Testing Documentation

## Test Suite Overview

The Real-Time Chat Application includes comprehensive testing covering all features and components.

## Automated Testing Scripts

### 1. Deployment and Basic Testing
**Script**: `deploy-and-test.sh`

This script:
- Deploys all services using Docker Compose
- Performs health checks on all microservices
- Tests basic authentication flow
- Creates test users
- Verifies API endpoints
- Checks frontend accessibility

**Usage**:
```bash
cd /workspace/backend
../deploy-and-test.sh
```

**Expected Runtime**: 5-10 minutes (first run with build)

### 2. End-to-End Testing
**Script**: `test-e2e.sh`

Comprehensive test suite covering:
- 22 automated test cases
- All authentication scenarios
- User management operations
- Chat room creation and management
- Message handling
- Presence tracking
- Error handling and security

**Usage**:
```bash
cd /workspace/backend
../test-e2e.sh
```

**Expected Runtime**: 2-3 minutes

## Test Coverage

### Authentication Tests (6 tests)
1. Service health checks
2. User registration with valid data
3. Duplicate username rejection
4. User login with correct credentials
5. Login with incorrect password rejection
6. Unauthorized access blocking

### User Management Tests (5 tests)
7. Get user profile with valid token
8. Update user profile
9. Register multiple users
10. User search functionality
11. Get online users list

### Chat Features Tests (8 tests)
12. Create private chat room
13. Retrieve user's chat rooms
14. Get chat room details
15. Get room participants
16. Get message history
17. Create group chat room
18. Update user status
19. Send presence heartbeat

### Security Tests (2 tests)
20. Invalid token rejection
21. Token expiration handling

### Infrastructure Tests (2 tests)
22. Frontend accessibility
23. WebSocket endpoint availability

## Manual Testing Guide

### Setup
1. Deploy the application:
```bash
cd /workspace/backend
docker-compose up -d
```

2. Wait for services to be ready (~1 minute)

3. Open frontend: http://localhost:5173

### Test Scenarios

#### Scenario 1: User Registration and Login
1. Click "Register"
2. Enter username, email, password
3. Verify automatic login after registration
4. Verify redirect to chat interface

**Expected Result**: User successfully registered and logged in

#### Scenario 2: Create Private Chat
1. Login as User A
2. Click "+" to create new chat
3. Search for User B
4. Click on User B to create private chat
5. Verify chat room appears in room list

**Expected Result**: Private chat room created successfully

#### Scenario 3: Send Real-Time Messages
1. Open chat room
2. Type and send message
3. Open same account in another browser/incognito
4. Verify message appears instantly in both windows

**Expected Result**: Real-time message delivery

#### Scenario 4: Typing Indicators
1. Open chat room in two browsers (User A and User B)
2. Start typing in User A's window
3. Observe typing indicator in User B's window

**Expected Result**: "Someone is typing..." appears in real-time

#### Scenario 5: Online Presence
1. Login as User A
2. Observe User A shown as "online" in user list
3. Close User A's browser
4. Wait 5 minutes
5. Check presence status

**Expected Result**: Status changes from "online" to "offline"

#### Scenario 6: Message Persistence
1. Send several messages in a chat room
2. Close and reopen browser
3. Login again
4. Open same chat room

**Expected Result**: All previous messages are displayed

#### Scenario 7: User Search
1. Login to application
2. Click "+" to search users
3. Type partial username
4. Verify search results update in real-time

**Expected Result**: Users matching search query appear

#### Scenario 8: Group Chat
1. Create group chat with 3+ users
2. Send message from User A
3. Verify message appears for all participants

**Expected Result**: Message delivered to all group members

### API Testing with cURL

#### Test 1: Register User
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "Test123!"
  }'
```

**Expected**: Status 200, returns token and user info

#### Test 2: Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "Test123!"
  }'
```

**Expected**: Status 200, returns JWT token

#### Test 3: Get User Profile
```bash
TOKEN="your-jwt-token"
curl -X GET http://localhost:8080/api/users/1 \
  -H "Authorization: Bearer $TOKEN"
```

**Expected**: Status 200, returns user profile data

#### Test 4: Create Chat Room
```bash
curl -X POST http://localhost:8080/api/chat/rooms \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Room",
    "type": "private",
    "participantIds": [2]
  }'
```

**Expected**: Status 200, returns room details

## WebSocket Testing

### Using Browser Console

Open browser console on http://localhost:5173 and run:

```javascript
// Connect to WebSocket
const socket = new SockJS('http://localhost:8080/ws');
const stompClient = Stomp.over(socket);

stompClient.connect({}, function(frame) {
    console.log('Connected: ' + frame);
    
    // Subscribe to room messages
    stompClient.subscribe('/topic/messages/1', function(message) {
        console.log('Received:', JSON.parse(message.body));
    });
    
    // Send message
    stompClient.send('/app/sendMessage', {}, JSON.stringify({
        chatRoomId: 1,
        senderId: 1,
        content: 'Hello from console!'
    }));
});
```

**Expected**: Message sent and received through WebSocket

## Performance Testing

### Load Testing with Apache Bench

Test concurrent connections:
```bash
# Test registration endpoint
ab -n 100 -c 10 -p register.json -T application/json \
   http://localhost:8080/api/auth/register

# Test login endpoint  
ab -n 1000 -c 50 -p login.json -T application/json \
   http://localhost:8080/api/auth/login
```

**Expected**: All requests complete successfully, < 500ms average response time

### WebSocket Load Testing

Use `artillery` for WebSocket load testing:

```yaml
# artillery-config.yml
config:
  target: 'http://localhost:8080'
  phases:
    - duration: 60
      arrivalRate: 10
scenarios:
  - name: 'WebSocket Chat'
    engine: 'socketio'
    flow:
      - emit:
          channel: '/app/sendMessage'
          data:
            chatRoomId: 1
            senderId: 1
            content: 'Load test message'
```

Run: `artillery run artillery-config.yml`

**Expected**: All messages delivered, < 100ms latency

## Security Testing

### Test 1: SQL Injection Attempt
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin'\''; DROP TABLE users; --",
    "password": "password"
  }'
```

**Expected**: Login fails, no database modification

### Test 2: XSS Attempt in Messages
```bash
curl -X POST http://localhost:8080/api/chat/rooms \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "<script>alert('XSS')</script>",
    "type": "private",
    "participantIds": [2]
  }'
```

**Expected**: Script tags escaped, rendered as text

### Test 3: CSRF Protection
Attempt API call without proper headers:
```bash
curl -X POST http://localhost:8080/api/chat/rooms \
  -H "Content-Type: application/json"
```

**Expected**: 401 Unauthorized

## Database Testing

### Check Data Integrity

```sql
-- Connect to database
psql -h localhost -U postgres -d chatdb

-- Verify user creation
SELECT id, username, email, status FROM users;

-- Verify chat rooms
SELECT id, name, type, created_by FROM chat_rooms;

-- Verify messages
SELECT id, chat_room_id, sender_id, content, timestamp 
FROM messages 
ORDER BY timestamp DESC 
LIMIT 10;

-- Check participants
SELECT p.id, u.username, cr.name 
FROM participants p
JOIN users u ON p.user_id = u.id
JOIN chat_rooms cr ON p.chat_room_id = cr.id;
```

## Redis Testing

### Check Presence Data

```bash
# Connect to Redis
redis-cli

# Check online users
KEYS online:users:*

# Get user status
GET online:users:1

# Monitor real-time activity
MONITOR
```

## Troubleshooting Tests

### If Tests Fail

1. **Check Service Status**:
```bash
docker-compose ps
```

2. **View Service Logs**:
```bash
docker-compose logs auth-service
docker-compose logs user-service
docker-compose logs chat-service
```

3. **Verify Database Connection**:
```bash
docker exec -it chat-postgres psql -U postgres -d chatdb -c "\dt"
```

4. **Check Redis Connection**:
```bash
docker exec -it chat-redis redis-cli PING
```

5. **Test Network**:
```bash
curl -v http://localhost:8080/api/auth/health
```

## Test Reports

### Generate Test Report

After running tests, generate a report:

```bash
./test-e2e.sh > test-report.txt 2>&1
echo "Test completed at: $(date)" >> test-report.txt
```

### Expected Success Rate

- **All Tests**: 100% pass rate
- **Response Time**: < 500ms for API calls
- **WebSocket Latency**: < 100ms
- **Availability**: 99.9% uptime

## Continuous Integration

For CI/CD pipeline integration:

```yaml
# .github/workflows/test.yml
name: Test Suite
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build and Test
        run: |
          cd backend
          docker-compose up -d
          sleep 60
          ../test-e2e.sh
      - name: Cleanup
        run: |
          cd backend
          docker-compose down -v
```

## Test Data Cleanup

After testing, clean up test data:

```bash
# Stop and remove all containers and volumes
cd /workspace/backend
docker-compose down -v

# This removes:
# - All test users
# - All chat rooms
# - All messages
# - All presence data
```

## Conclusion

This comprehensive testing suite ensures:
- All features work as specified
- Security measures are effective
- Performance meets requirements
- Real-time functionality operates correctly
- Data persistence works reliably
- Error handling is robust

Run tests before each deployment to ensure application quality.
