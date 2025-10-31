package com.chat.repository;

import com.chat.model.ChatRoom;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {
    @Query("SELECT cr FROM ChatRoom cr JOIN Participant p ON cr.id = p.chatRoomId WHERE p.userId = ?1")
    List<ChatRoom> findByUserId(Long userId);

    @Query("SELECT cr FROM ChatRoom cr JOIN Participant p1 ON cr.id = p1.chatRoomId " +
           "JOIN Participant p2 ON cr.id = p2.chatRoomId " +
           "WHERE cr.type = 'private' AND p1.userId = ?1 AND p2.userId = ?2")
    Optional<ChatRoom> findPrivateRoom(Long user1Id, Long user2Id);
}
