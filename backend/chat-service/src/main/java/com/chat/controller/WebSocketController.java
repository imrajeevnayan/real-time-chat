package com.chat.controller;

import com.chat.dto.ChatMessageDTO;
import com.chat.model.Message;
import com.chat.service.ChatService;
import com.chat.service.MessagePublisher;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Controller
@RequiredArgsConstructor
@Slf4j
public class WebSocketController {

    private final SimpMessagingTemplate messagingTemplate;
    private final ChatService chatService;
    private final MessagePublisher messagePublisher;

    @MessageMapping("/sendMessage")
    public void sendMessage(@Payload ChatMessageDTO chatMessage) {
        log.debug("Received message: {}", chatMessage);

        try {
            // Save message to database
            Message message = new Message();
            message.setChatRoomId(chatMessage.getChatRoomId());
            message.setSenderId(chatMessage.getSenderId());
            message.setContent(chatMessage.getContent());
            message.setStatus("sent");
            
            message = chatService.saveMessage(message);

            // Prepare response
            chatMessage.setId(message.getId());
            chatMessage.setTimestamp(message.getTimestamp().format(DateTimeFormatter.ISO_DATE_TIME));
            chatMessage.setStatus(message.getStatus());
            chatMessage.setType(ChatMessageDTO.MessageType.CHAT);

            // Publish to Redis for distribution
            messagePublisher.publish(chatMessage);

            // Send to room subscribers
            messagingTemplate.convertAndSend(
                    "/topic/messages/" + chatMessage.getChatRoomId(),
                    chatMessage
            );

        } catch (Exception e) {
            log.error("Error processing message", e);
        }
    }

    @MessageMapping("/typing/{roomId}")
    public void handleTyping(@DestinationVariable Long roomId, @Payload ChatMessageDTO typingMessage) {
        typingMessage.setType(ChatMessageDTO.MessageType.TYPING);
        messagingTemplate.convertAndSend("/topic/typing/" + roomId, typingMessage);
    }
}
