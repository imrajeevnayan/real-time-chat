package com.chat.repository;

import com.chat.model.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {
    List<Message> findByChatRoomIdOrderByTimestampAsc(Long chatRoomId);
    List<Message> findTop50ByChatRoomIdOrderByTimestampDesc(Long chatRoomId);
}
