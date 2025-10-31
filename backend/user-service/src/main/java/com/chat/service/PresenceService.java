package com.chat.service;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PresenceService {

    private final RedisTemplate<String, String> redisTemplate;
    private static final String ONLINE_USERS_KEY = "online:users";
    private static final long PRESENCE_TIMEOUT = 5; // minutes

    public void setUserOnline(Long userId) {
        String key = ONLINE_USERS_KEY + ":" + userId;
        redisTemplate.opsForValue().set(key, "online", PRESENCE_TIMEOUT, TimeUnit.MINUTES);
    }

    public void setUserOffline(Long userId) {
        String key = ONLINE_USERS_KEY + ":" + userId;
        redisTemplate.delete(key);
    }

    public boolean isUserOnline(Long userId) {
        String key = ONLINE_USERS_KEY + ":" + userId;
        return Boolean.TRUE.equals(redisTemplate.hasKey(key));
    }

    public Set<Long> getOnlineUsers() {
        Set<String> keys = redisTemplate.keys(ONLINE_USERS_KEY + ":*");
        if (keys == null) return Set.of();
        
        return keys.stream()
                .map(key -> key.substring(key.lastIndexOf(":") + 1))
                .map(Long::parseLong)
                .collect(Collectors.toSet());
    }

    public void heartbeat(Long userId) {
        setUserOnline(userId);
    }
}
