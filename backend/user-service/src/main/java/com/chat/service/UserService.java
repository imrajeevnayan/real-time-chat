package com.chat.service;

import com.chat.dto.UpdateUserRequest;
import com.chat.dto.UserDTO;
import com.chat.model.User;
import com.chat.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PresenceService presenceService;

    public UserDTO getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return convertToDTO(user);
    }

    public UserDTO updateUser(Long userId, UpdateUserRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        if (request.getUsername() != null) {
            user.setUsername(request.getUsername());
        }
        if (request.getEmail() != null) {
            user.setEmail(request.getEmail());
        }
        if (request.getProfilePic() != null) {
            user.setProfilePic(request.getProfilePic());
        }

        user = userRepository.save(user);
        return convertToDTO(user);
    }

    public List<UserDTO> searchUsers(String query) {
        return userRepository.findByUsernameContainingIgnoreCase(query)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public List<UserDTO> getOnlineUsers() {
        return presenceService.getOnlineUsers()
                .stream()
                .map(this::getUserById)
                .collect(Collectors.toList());
    }

    public void setUserStatus(Long userId, String status) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setStatus(status);
        userRepository.save(user);

        if ("online".equals(status)) {
            presenceService.setUserOnline(userId);
        } else {
            presenceService.setUserOffline(userId);
        }
    }

    private UserDTO convertToDTO(User user) {
        return new UserDTO(
            user.getId(),
            user.getUsername(),
            user.getEmail(),
            user.getProfilePic(),
            presenceService.isUserOnline(user.getId()) ? "online" : user.getStatus()
        );
    }
}
