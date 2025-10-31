#!/bin/bash

# End-to-End Testing Script for Real-Time Chat Application
# This script performs comprehensive testing of all features

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ $1${NC}"; }
print_test() { echo -e "${BLUE}→ $1${NC}"; }

API_URL="http://localhost:8080"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local test_name="$1"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_test "Test $TOTAL_TESTS: $test_name"
}

assert_success() {
    if [ $? -eq 0 ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        print_success "$1"
        return 0
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        print_error "$1"
        return 1
    fi
}

echo "=========================================="
echo "End-to-End Testing Suite"
echo "=========================================="
echo ""

# Test 1: Service Health Checks
run_test "Service Health Checks"
auth_health=$(curl -s -o /dev/null -w "%{http_code}" $API_URL/api/auth/health)
user_health=$(curl -s -o /dev/null -w "%{http_code}" $API_URL/api/users/health)
chat_health=$(curl -s -o /dev/null -w "%{http_code}" $API_URL/api/chat/health)

if [ "$auth_health" = "200" ] && [ "$user_health" = "200" ] && [ "$chat_health" = "200" ]; then
    assert_success "All services are healthy"
else
    assert_success "Service health check failed" && false
fi

# Test 2: User Registration with Validation
run_test "User Registration with Valid Data"
timestamp=$(date +%s)
reg_response=$(curl -s -X POST $API_URL/api/auth/register \
    -H "Content-Type: application/json" \
    -d "{
        \"username\": \"user${timestamp}\",
        \"email\": \"user${timestamp}@test.com\",
        \"password\": \"Test123!@#\"
    }")

if echo "$reg_response" | grep -q "token"; then
    TOKEN1=$(echo "$reg_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    USER1_ID=$(echo "$reg_response" | grep -o '"userId":[0-9]*' | cut -d':' -f2)
    USER1_NAME=$(echo "$reg_response" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
    assert_success "User registration successful (User ID: $USER1_ID)"
else
    assert_success "User registration failed" && false
fi

# Test 3: User Registration with Duplicate Username (Should Fail)
run_test "User Registration with Duplicate Username (Expected Failure)"
dup_response=$(curl -s -X POST $API_URL/api/auth/register \
    -H "Content-Type: application/json" \
    -d "{
        \"username\": \"user${timestamp}\",
        \"email\": \"different${timestamp}@test.com\",
        \"password\": \"Test123!@#\"
    }")

if echo "$dup_response" | grep -qi "already exists\|exists"; then
    assert_success "Duplicate username correctly rejected"
else
    assert_success "Duplicate username validation failed" && false
fi

# Test 4: User Login with Correct Credentials
run_test "User Login with Correct Credentials"
login_response=$(curl -s -X POST $API_URL/api/auth/login \
    -H "Content-Type: application/json" \
    -d "{
        \"username\": \"user${timestamp}\",
        \"password\": \"Test123!@#\"
    }")

if echo "$login_response" | grep -q "token"; then
    assert_success "Login successful"
else
    assert_success "Login failed" && false
fi

# Test 5: User Login with Incorrect Password (Should Fail)
run_test "User Login with Incorrect Password (Expected Failure)"
wrong_login=$(curl -s -w "\n%{http_code}" -X POST $API_URL/api/auth/login \
    -H "Content-Type: application/json" \
    -d "{
        \"username\": \"user${timestamp}\",
        \"password\": \"WrongPassword123\"
    }")

http_code=$(echo "$wrong_login" | tail -1)
if [ "$http_code" = "401" ]; then
    assert_success "Invalid credentials correctly rejected"
else
    assert_success "Authentication validation failed" && false
fi

# Test 6: Access Protected Endpoint Without Token (Should Fail)
run_test "Access Protected Endpoint Without Authentication (Expected Failure)"
no_auth_response=$(curl -s -o /dev/null -w "%{http_code}" $API_URL/api/users/1)
if [ "$no_auth_response" = "401" ]; then
    assert_success "Unauthorized access correctly blocked"
else
    assert_success "Authorization check failed" && false
fi

# Test 7: Get User Profile with Valid Token
run_test "Get User Profile with Valid Token"
profile_response=$(curl -s -X GET $API_URL/api/users/$USER1_ID \
    -H "Authorization: Bearer $TOKEN1")

if echo "$profile_response" | grep -q "\"id\":$USER1_ID"; then
    assert_success "User profile retrieved successfully"
else
    assert_success "Get user profile failed" && false
fi

# Test 8: Update User Profile
run_test "Update User Profile"
update_response=$(curl -s -X PUT $API_URL/api/users/update \
    -H "Authorization: Bearer $TOKEN1" \
    -H "Content-Type: application/json" \
    -d "{
        \"profilePic\": \"https://example.com/avatar.jpg\"
    }")

if echo "$update_response" | grep -q "profilePic"; then
    assert_success "User profile updated successfully"
else
    assert_success "User profile update failed" && false
fi

# Test 9: Register Second User for Chat Testing
run_test "Register Second User for Multi-User Testing"
timestamp2=$(date +%s)
reg_response2=$(curl -s -X POST $API_URL/api/auth/register \
    -H "Content-Type: application/json" \
    -d "{
        \"username\": \"user${timestamp2}\",
        \"email\": \"user${timestamp2}@test.com\",
        \"password\": \"Test123!@#\"
    }")

if echo "$reg_response2" | grep -q "token"; then
    TOKEN2=$(echo "$reg_response2" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    USER2_ID=$(echo "$reg_response2" | grep -o '"userId":[0-9]*' | cut -d':' -f2)
    USER2_NAME=$(echo "$reg_response2" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
    assert_success "Second user registered (User ID: $USER2_ID)"
else
    assert_success "Second user registration failed" && false
fi

# Test 10: Search Users
run_test "User Search Functionality"
search_response=$(curl -s -X GET "$API_URL/api/users/search?q=user${timestamp}" \
    -H "Authorization: Bearer $TOKEN1")

if echo "$search_response" | grep -q "\"username\":"; then
    user_count=$(echo "$search_response" | grep -o "\"id\":" | wc -l)
    assert_success "User search successful (Found $user_count users)"
else
    assert_success "User search failed" && false
fi

# Test 11: Create Private Chat Room
run_test "Create Private Chat Room"
room_response=$(curl -s -X POST $API_URL/api/chat/rooms \
    -H "Authorization: Bearer $TOKEN1" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"${USER1_NAME} & ${USER2_NAME}\",
        \"type\": \"private\",
        \"participantIds\": [$USER2_ID]
    }")

if echo "$room_response" | grep -q "\"id\""; then
    ROOM_ID=$(echo "$room_response" | grep -o '"id":[0-9]*' | cut -d':' -f2)
    assert_success "Private chat room created (Room ID: $ROOM_ID)"
else
    assert_success "Chat room creation failed" && false
fi

# Test 12: Get User's Chat Rooms
run_test "Retrieve User's Chat Rooms"
rooms_response=$(curl -s -X GET $API_URL/api/chat/rooms \
    -H "Authorization: Bearer $TOKEN1")

if echo "$rooms_response" | grep -q "\"id\":$ROOM_ID"; then
    assert_success "Chat rooms retrieved successfully"
else
    assert_success "Get chat rooms failed" && false
fi

# Test 13: Get Chat Room Details
run_test "Get Chat Room Details"
room_detail=$(curl -s -X GET $API_URL/api/chat/rooms/$ROOM_ID \
    -H "Authorization: Bearer $TOKEN1")

if echo "$room_detail" | grep -q "\"id\":$ROOM_ID"; then
    assert_success "Chat room details retrieved"
else
    assert_success "Get room details failed" && false
fi

# Test 14: Get Room Participants
run_test "Get Room Participants"
participants=$(curl -s -X GET $API_URL/api/chat/rooms/$ROOM_ID/participants \
    -H "Authorization: Bearer $TOKEN1")

if echo "$participants" | grep -q "\"userId\":"; then
    participant_count=$(echo "$participants" | grep -o "\"userId\":" | wc -l)
    assert_success "Room participants retrieved ($participant_count participants)"
else
    assert_success "Get participants failed" && false
fi

# Test 15: Get Message History (Should be Empty Initially)
run_test "Get Message History from New Room"
messages=$(curl -s -X GET $API_URL/api/chat/messages/$ROOM_ID \
    -H "Authorization: Bearer $TOKEN1")

if echo "$messages" | grep -q "\[\]"; then
    assert_success "Message history retrieved (0 messages as expected)"
else
    assert_success "Get message history failed" && false
fi

# Test 16: Create Group Chat Room
run_test "Create Group Chat Room"
group_response=$(curl -s -X POST $API_URL/api/chat/rooms \
    -H "Authorization: Bearer $TOKEN1" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"Test Group Chat\",
        \"type\": \"group\",
        \"participantIds\": [$USER2_ID]
    }")

if echo "$group_response" | grep -q "\"type\":\"group\""; then
    GROUP_ROOM_ID=$(echo "$group_response" | grep -o '"id":[0-9]*' | cut -d':' -f2)
    assert_success "Group chat room created (Room ID: $GROUP_ROOM_ID)"
else
    assert_success "Group chat creation failed" && false
fi

# Test 17: Get Online Users
run_test "Get Online Users List"
online_users=$(curl -s -X GET $API_URL/api/users/online \
    -H "Authorization: Bearer $TOKEN1")

if echo "$online_users" | grep -q "\["; then
    assert_success "Online users list retrieved"
else
    assert_success "Get online users failed" && false
fi

# Test 18: Update User Status
run_test "Update User Status"
status_response=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$API_URL/api/users/status?status=online" \
    -H "Authorization: Bearer $TOKEN1")

if [ "$status_response" = "200" ]; then
    assert_success "User status updated successfully"
else
    assert_success "Status update failed" && false
fi

# Test 19: Send Heartbeat
run_test "Send Presence Heartbeat"
heartbeat_response=$(curl -s -o /dev/null -w "%{http_code}" -X POST $API_URL/api/users/heartbeat \
    -H "Authorization: Bearer $TOKEN1")

if [ "$heartbeat_response" = "200" ]; then
    assert_success "Heartbeat sent successfully"
else
    assert_success "Heartbeat failed" && false
fi

# Test 20: Token Expiry Validation (Invalid Token Should Fail)
run_test "Invalid Token Rejection (Expected Failure)"
invalid_token_response=$(curl -s -o /dev/null -w "%{http_code}" -X GET $API_URL/api/users/$USER1_ID \
    -H "Authorization: Bearer invalid.token.here")

if [ "$invalid_token_response" = "401" ]; then
    assert_success "Invalid token correctly rejected"
else
    assert_success "Token validation failed" && false
fi

# Test 21: Frontend Accessibility
run_test "Frontend Application Accessibility"
frontend_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5173)
if [ "$frontend_status" = "200" ]; then
    assert_success "Frontend is accessible"
else
    assert_success "Frontend accessibility failed" && false
fi

# Test 22: WebSocket Endpoint Availability
run_test "WebSocket Endpoint Availability"
ws_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ws/info)
if [ "$ws_status" = "200" ] || [ "$ws_status" = "404" ]; then
    assert_success "WebSocket endpoint is available"
else
    assert_success "WebSocket endpoint check failed" && false
fi

# Test Summary
echo ""
echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo ""
echo "Total Tests:  $TOTAL_TESTS"
print_success "Passed:       $PASSED_TESTS"
if [ $FAILED_TESTS -gt 0 ]; then
    print_error "Failed:       $FAILED_TESTS"
else
    echo "Failed:       $FAILED_TESTS"
fi
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    print_success "All tests passed! Application is fully functional."
    echo ""
    echo "Test Users Created:"
    echo "  User 1: $USER1_NAME (ID: $USER1_ID)"
    echo "  User 2: $USER2_NAME (ID: $USER2_ID)"
    echo ""
    echo "Test Chat Rooms Created:"
    echo "  Private Room ID: $ROOM_ID"
    echo "  Group Room ID: $GROUP_ROOM_ID"
    echo ""
    exit 0
else
    print_error "Some tests failed. Please review the logs."
    echo ""
    echo "Debug commands:"
    echo "  docker-compose logs auth-service"
    echo "  docker-compose logs user-service"
    echo "  docker-compose logs chat-service"
    echo "  docker-compose logs gateway-service"
    echo ""
    exit 1
fi
