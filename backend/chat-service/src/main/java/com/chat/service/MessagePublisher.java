package com.chat.service;

import com.chat.dto.ChatMessageDTO;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.listener.ChannelTopic;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class MessagePublisher {

    private final RedisTemplate<String, Object> redisTemplate;
    private final ChannelTopic chatTopic;

    public void publish(ChatMessageDTO message) {
        try {
            redisTemplate.convertAndSend(chatTopic.getTopic(), message);
            log.debug("Published message to Redis: {}", message);
        } catch (Exception e) {
            log.error("Error publishing message to Redis", e);
        }
    }
}
