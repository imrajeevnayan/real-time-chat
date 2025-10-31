package com.chat.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ValidationResponse {
    private boolean valid;
    private Long userId;
    private String username;
}
