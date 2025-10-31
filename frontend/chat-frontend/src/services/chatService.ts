import api from './api';
import { ChatRoom, Message } from '../types';

export const chatService = {
  createRoom: async (name: string, type: 'private' | 'group', participantIds: number[]): Promise<ChatRoom> => {
    const response = await api.post<ChatRoom>('/api/chat/rooms', {
      name,
      type,
      participantIds,
    });
    return response.data;
  },

  getUserRooms: async (): Promise<ChatRoom[]> => {
    const response = await api.get<ChatRoom[]>('/api/chat/rooms');
    return response.data;
  },

  getRoomMessages: async (roomId: number): Promise<Message[]> => {
    const response = await api.get<Message[]>(`/api/chat/messages/${roomId}`);
    return response.data;
  },

  searchUsers: async (query: string) => {
    const response = await api.get(`/api/users/search?q=${query}`);
    return response.data;
  },

  getOnlineUsers: async () => {
    const response = await api.get('/api/users/online');
    return response.data;
  },
};
