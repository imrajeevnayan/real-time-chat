package com.chat.controller;

import com.chat.dto.CreateChatRoomRequest;
import com.chat.model.ChatRoom;
import com.chat.model.Message;
import com.chat.model.Participant;
import com.chat.service.ChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;

    @PostMapping("/rooms")
    public ResponseEntity<ChatRoom> createRoom(
            @RequestHeader("X-User-Id") Long userId,
            @RequestBody CreateChatRoomRequest request) {
        ChatRoom room = chatService.createChatRoom(userId, request);
        return ResponseEntity.ok(room);
    }

    @GetMapping("/rooms")
    public ResponseEntity<List<ChatRoom>> getUserRooms(@RequestHeader("X-User-Id") Long userId) {
        return ResponseEntity.ok(chatService.getUserChatRooms(userId));
    }

    @GetMapping("/rooms/{roomId}")
    public ResponseEntity<ChatRoom> getRoom(@PathVariable Long roomId) {
        return ResponseEntity.ok(chatService.getChatRoom(roomId));
    }

    @GetMapping("/messages/{roomId}")
    public ResponseEntity<List<Message>> getRoomMessages(@PathVariable Long roomId) {
        return ResponseEntity.ok(chatService.getRoomMessages(roomId));
    }

    @GetMapping("/rooms/{roomId}/participants")
    public ResponseEntity<List<Participant>> getRoomParticipants(@PathVariable Long roomId) {
        return ResponseEntity.ok(chatService.getRoomParticipants(roomId));
    }

    @GetMapping("/health")
    public ResponseEntity<String> health() {
        return ResponseEntity.ok("Chat Service is running");
    }
}
