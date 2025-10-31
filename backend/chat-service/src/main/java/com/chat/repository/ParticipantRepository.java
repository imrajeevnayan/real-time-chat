package com.chat.repository;

import com.chat.model.Participant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ParticipantRepository extends JpaRepository<Participant, Long> {
    List<Participant> findByChatRoomId(Long chatRoomId);
    boolean existsByUserIdAndChatRoomId(Long userId, Long chatRoomId);
}
