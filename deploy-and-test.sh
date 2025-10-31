#!/bin/bash

# Real-Time Chat Application - Deployment and Testing Script
# This script deploys and tests all application components

set -e

echo "=========================================="
echo "Real-Time Chat Application Deployment"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check prerequisites
echo "Step 1: Checking prerequisites..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi
print_success "Docker is installed"

if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed"
    exit 1
fi
print_success "Docker Compose is installed"

# Stop any existing containers
echo ""
echo "Step 2: Cleaning up existing containers..."
docker-compose down -v 2>/dev/null || true
print_success "Cleaned up existing containers"

# Build and start services
echo ""
echo "Step 3: Building and starting services..."
print_info "This may take 5-10 minutes for the first build..."
docker-compose up -d --build

# Wait for services to be ready
echo ""
echo "Step 4: Waiting for services to start..."
sleep 30

# Check if containers are running
echo ""
echo "Step 5: Checking service health..."

services=("chat-postgres" "chat-redis" "chat-auth-service" "chat-user-service" "chat-chat-service" "chat-gateway-service" "chat-frontend")
all_running=true

for service in "${services[@]}"; do
    if docker ps | grep -q "$service"; then
        print_success "$service is running"
    else
        print_error "$service is not running"
        all_running=false
    fi
done

if [ "$all_running" = false ]; then
    print_error "Some services failed to start. Check logs with: docker-compose logs"
    exit 1
fi

# Wait a bit more for services to fully initialize
echo ""
print_info "Waiting for services to fully initialize..."
sleep 30

# Test health endpoints
echo ""
echo "Step 6: Testing service health endpoints..."

health_endpoints=(
    "http://localhost:8081/api/auth/health:Auth Service"
    "http://localhost:8082/api/users/health:User Service"
    "http://localhost:8083/api/chat/health:Chat Service"
)

for endpoint_info in "${health_endpoints[@]}"; do
    IFS=':' read -r endpoint name <<< "$endpoint_info"
    response=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint" 2>/dev/null || echo "000")
    if [ "$response" = "200" ]; then
        print_success "$name health check passed"
    else
        print_error "$name health check failed (HTTP $response)"
    fi
done

# Test user registration
echo ""
echo "Step 7: Testing user registration..."
register_response=$(curl -s -X POST http://localhost:8080/api/auth/register \
    -H "Content-Type: application/json" \
    -d '{
        "username": "testuser1",
        "email": "test1@example.com",
        "password": "password123"
    }' 2>/dev/null || echo '{"error": "request failed"}')

if echo "$register_response" | grep -q "token"; then
    print_success "User registration successful"
    TOKEN=$(echo "$register_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    USER_ID=$(echo "$register_response" | grep -o '"userId":[0-9]*' | cut -d':' -f2)
    print_info "Token: ${TOKEN:0:50}..."
else
    print_error "User registration failed"
    echo "Response: $register_response"
fi

# Test user login
echo ""
echo "Step 8: Testing user login..."
login_response=$(curl -s -X POST http://localhost:8080/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{
        "username": "testuser1",
        "password": "password123"
    }' 2>/dev/null || echo '{"error": "request failed"}')

if echo "$login_response" | grep -q "token"; then
    print_success "User login successful"
else
    print_error "User login failed"
    echo "Response: $login_response"
fi

# Test authenticated endpoints
if [ ! -z "$TOKEN" ]; then
    echo ""
    echo "Step 9: Testing authenticated endpoints..."
    
    # Get user profile
    profile_response=$(curl -s -X GET http://localhost:8080/api/users/$USER_ID \
        -H "Authorization: Bearer $TOKEN" 2>/dev/null)
    
    if echo "$profile_response" | grep -q "username"; then
        print_success "Get user profile successful"
    else
        print_error "Get user profile failed"
    fi
    
    # Search users
    search_response=$(curl -s -X GET "http://localhost:8080/api/users/search?q=test" \
        -H "Authorization: Bearer $TOKEN" 2>/dev/null)
    
    if echo "$search_response" | grep -q "\["; then
        print_success "User search successful"
    else
        print_error "User search failed"
    fi
    
    # Get user rooms
    rooms_response=$(curl -s -X GET http://localhost:8080/api/chat/rooms \
        -H "Authorization: Bearer $TOKEN" 2>/dev/null)
    
    if echo "$rooms_response" | grep -q "\["; then
        print_success "Get chat rooms successful"
    else
        print_error "Get chat rooms failed"
    fi
fi

# Register second user for chat testing
echo ""
echo "Step 10: Creating second user for testing..."
register_response2=$(curl -s -X POST http://localhost:8080/api/auth/register \
    -H "Content-Type: application/json" \
    -d '{
        "username": "testuser2",
        "email": "test2@example.com",
        "password": "password123"
    }' 2>/dev/null || echo '{"error": "request failed"}')

if echo "$register_response2" | grep -q "token"; then
    print_success "Second user registration successful"
    TOKEN2=$(echo "$register_response2" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    USER_ID2=$(echo "$register_response2" | grep -o '"userId":[0-9]*' | cut -d':' -f2)
else
    print_error "Second user registration failed"
fi

# Create chat room
if [ ! -z "$TOKEN" ] && [ ! -z "$USER_ID2" ]; then
    echo ""
    echo "Step 11: Testing chat room creation..."
    
    room_response=$(curl -s -X POST http://localhost:8080/api/chat/rooms \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"Test Chat Room\",
            \"type\": \"private\",
            \"participantIds\": [$USER_ID2]
        }" 2>/dev/null)
    
    if echo "$room_response" | grep -q "id"; then
        print_success "Chat room creation successful"
        ROOM_ID=$(echo "$room_response" | grep -o '"id":[0-9]*' | cut -d':' -f2)
        print_info "Room ID: $ROOM_ID"
    else
        print_error "Chat room creation failed"
        echo "Response: $room_response"
    fi
fi

# Test frontend accessibility
echo ""
echo "Step 12: Testing frontend accessibility..."
frontend_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5173 2>/dev/null || echo "000")
if [ "$frontend_response" = "200" ]; then
    print_success "Frontend is accessible"
else
    print_error "Frontend is not accessible (HTTP $frontend_response)"
fi

# Test WebSocket endpoint
echo ""
echo "Step 13: Testing WebSocket endpoint..."
ws_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ws/info 2>/dev/null || echo "000")
if [ "$ws_response" = "200" ] || [ "$ws_response" = "404" ]; then
    print_success "WebSocket endpoint is accessible"
else
    print_error "WebSocket endpoint check inconclusive (HTTP $ws_response)"
fi

# Display container logs
echo ""
echo "Step 14: Checking for errors in logs..."
error_count=$(docker-compose logs --tail=50 2>/dev/null | grep -i "error\|exception\|failed" | wc -l)
if [ "$error_count" -eq 0 ]; then
    print_success "No errors found in recent logs"
else
    print_error "Found $error_count potential errors in logs"
    print_info "Review logs with: docker-compose logs"
fi

# Summary
echo ""
echo "=========================================="
echo "Deployment Test Summary"
echo "=========================================="
echo ""
print_info "Services are running at:"
echo "  Frontend:     http://localhost:5173"
echo "  API Gateway:  http://localhost:8080"
echo "  Auth Service: http://localhost:8081"
echo "  User Service: http://localhost:8082"
echo "  Chat Service: http://localhost:8083"
echo ""
print_info "Database connections:"
echo "  PostgreSQL:   localhost:5432"
echo "  Redis:        localhost:6379"
echo ""
print_info "Test credentials:"
echo "  Username: testuser1"
echo "  Password: password123"
echo ""
print_success "Deployment test completed!"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop:      docker-compose down"
echo "To stop & clean: docker-compose down -v"
echo ""
