package com.chat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChatMessageDTO {
    private Long id;
    private Long chatRoomId;
    private Long senderId;
    private String senderName;
    private String content;
    private String timestamp;
    private String status;
    private MessageType type;

    public enum MessageType {
        CHAT, JOIN, LEAVE, TYPING
    }
}
