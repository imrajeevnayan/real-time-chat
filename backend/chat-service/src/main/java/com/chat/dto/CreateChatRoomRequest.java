package com.chat.dto;

import lombok.Data;
import java.util.List;

@Data
public class CreateChatRoomRequest {
    private String name;
    private String type; // "private" or "group"
    private List<Long> participantIds;
}
