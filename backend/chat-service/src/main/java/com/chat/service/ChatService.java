package com.chat.service;

import com.chat.dto.CreateChatRoomRequest;
import com.chat.model.ChatRoom;
import com.chat.model.Message;
import com.chat.model.Participant;
import com.chat.repository.ChatRoomRepository;
import com.chat.repository.MessageRepository;
import com.chat.repository.ParticipantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ChatService {

    private final ChatRoomRepository chatRoomRepository;
    private final ParticipantRepository participantRepository;
    private final MessageRepository messageRepository;

    @Transactional
    public ChatRoom createChatRoom(Long creatorId, CreateChatRoomRequest request) {
        // For private chats, check if room already exists
        if ("private".equals(request.getType()) && request.getParticipantIds().size() == 1) {
            Long otherUserId = request.getParticipantIds().get(0);
            var existingRoom = chatRoomRepository.findPrivateRoom(creatorId, otherUserId);
            if (existingRoom.isPresent()) {
                return existingRoom.get();
            }
        }

        ChatRoom chatRoom = new ChatRoom();
        chatRoom.setName(request.getName());
        chatRoom.setType(request.getType());
        chatRoom.setCreatedBy(creatorId);
        chatRoom = chatRoomRepository.save(chatRoom);

        // Add creator as participant
        Participant creatorParticipant = new Participant();
        creatorParticipant.setUserId(creatorId);
        creatorParticipant.setChatRoomId(chatRoom.getId());
        participantRepository.save(creatorParticipant);

        // Add other participants
        for (Long userId : request.getParticipantIds()) {
            if (!userId.equals(creatorId)) {
                Participant participant = new Participant();
                participant.setUserId(userId);
                participant.setChatRoomId(chatRoom.getId());
                participantRepository.save(participant);
            }
        }

        return chatRoom;
    }

    public List<ChatRoom> getUserChatRooms(Long userId) {
        return chatRoomRepository.findByUserId(userId);
    }

    public ChatRoom getChatRoom(Long roomId) {
        return chatRoomRepository.findById(roomId)
                .orElseThrow(() -> new RuntimeException("Chat room not found"));
    }

    public List<Message> getRoomMessages(Long roomId) {
        return messageRepository.findByChatRoomIdOrderByTimestampAsc(roomId);
    }

    public Message saveMessage(Message message) {
        return messageRepository.save(message);
    }

    public boolean isUserInRoom(Long userId, Long roomId) {
        return participantRepository.existsByUserIdAndChatRoomId(userId, roomId);
    }

    public List<Participant> getRoomParticipants(Long roomId) {
        return participantRepository.findByChatRoomId(roomId);
    }
}
