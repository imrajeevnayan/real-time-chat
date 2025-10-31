import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { ChatState, ChatRoom, Message, User } from '../types';

const initialState: ChatState = {
  rooms: [],
  currentRoom: null,
  messages: [],
  onlineUsers: [],
  typingUsers: [],
};

const chatSlice = createSlice({
  name: 'chat',
  initialState,
  reducers: {
    setRooms: (state, action: PayloadAction<ChatRoom[]>) => {
      state.rooms = action.payload;
    },
    addRoom: (state, action: PayloadAction<ChatRoom>) => {
      state.rooms.push(action.payload);
    },
    setCurrentRoom: (state, action: PayloadAction<ChatRoom | null>) => {
      state.currentRoom = action.payload;
      state.messages = [];
    },
    setMessages: (state, action: PayloadAction<Message[]>) => {
      state.messages = action.payload;
    },
    addMessage: (state, action: PayloadAction<Message>) => {
      state.messages.push(action.payload);
    },
    setOnlineUsers: (state, action: PayloadAction<User[]>) => {
      state.onlineUsers = action.payload;
    },
    addTypingUser: (state, action: PayloadAction<number>) => {
      if (!state.typingUsers.includes(action.payload)) {
        state.typingUsers.push(action.payload);
      }
    },
    removeTypingUser: (state, action: PayloadAction<number>) => {
      state.typingUsers = state.typingUsers.filter(id => id !== action.payload);
    },
  },
});

export const {
  setRooms,
  addRoom,
  setCurrentRoom,
  setMessages,
  addMessage,
  setOnlineUsers,
  addTypingUser,
  removeTypingUser,
} = chatSlice.actions;

export default chatSlice.reducer;
