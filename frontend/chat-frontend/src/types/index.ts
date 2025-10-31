export interface User {
  id: number;
  username: string;
  email: string;
  profilePic?: string;
  status: string;
}

export interface AuthResponse {
  token: string;
  userId: number;
  username: string;
  email: string;
  profilePic?: string;
}

export interface ChatRoom {
  id: number;
  name: string;
  type: 'private' | 'group';
  createdBy: number;
  createdAt: string;
}

export interface Message {
  id: number;
  chatRoomId: number;
  senderId: number;
  senderName?: string;
  content: string;
  timestamp: string;
  status: string;
  type?: 'CHAT' | 'JOIN' | 'LEAVE' | 'TYPING';
}

export interface ChatState {
  rooms: ChatRoom[];
  currentRoom: ChatRoom | null;
  messages: Message[];
  onlineUsers: User[];
  typingUsers: number[];
}

export interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  loading: boolean;
  error: string | null;
}
