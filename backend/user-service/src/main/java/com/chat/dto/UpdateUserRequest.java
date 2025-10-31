package com.chat.dto;

import jakarta.validation.constraints.Email;
import lombok.Data;

@Data
public class UpdateUserRequest {
    private String username;
    
    @Email(message = "Invalid email format")
    private String email;
    
    private String profilePic;
}
