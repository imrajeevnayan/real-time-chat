import { Client } from '@stomp/stompjs';
import SockJS from 'sockjs-client';
import { Message } from '../types';

const WS_URL = import.meta.env.VITE_WS_URL || 'http://localhost:8080/ws';

class WebSocketService {
  private client: Client | null = null;
  private messageCallback: ((message: Message) => void) | null = null;
  private typingCallback: ((data: any) => void) | null = null;

  connect(onConnected?: () => void) {
    this.client = new Client({
      webSocketFactory: () => new SockJS(WS_URL),
      reconnectDelay: 5000,
      heartbeatIncoming: 4000,
      heartbeatOutgoing: 4000,
      debug: (str) => {
        console.log('STOMP: ' + str);
      },
      onConnect: () => {
        console.log('WebSocket connected');
        onConnected?.();
      },
      onStompError: (frame) => {
        console.error('STOMP error', frame);
      },
    });

    this.client.activate();
  }

  disconnect() {
    if (this.client) {
      this.client.deactivate();
      this.client = null;
    }
  }

  subscribeToRoom(roomId: number, onMessage: (message: Message) => void) {
    if (!this.client) return;

    this.messageCallback = onMessage;

    this.client.subscribe(`/topic/messages/${roomId}`, (message) => {
      const parsedMessage: Message = JSON.parse(message.body);
      onMessage(parsedMessage);
    });
  }

  subscribeToTyping(roomId: number, onTyping: (data: any) => void) {
    if (!this.client) return;

    this.typingCallback = onTyping;

    this.client.subscribe(`/topic/typing/${roomId}`, (message) => {
      const data = JSON.parse(message.body);
      onTyping(data);
    });
  }

  sendMessage(message: Omit<Message, 'id' | 'timestamp' | 'status'>) {
    if (!this.client) return;

    this.client.publish({
      destination: '/app/sendMessage',
      body: JSON.stringify(message),
    });
  }

  sendTyping(roomId: number, userId: number, username: string) {
    if (!this.client) return;

    this.client.publish({
      destination: `/app/typing/${roomId}`,
      body: JSON.stringify({ senderId: userId, senderName: username, chatRoomId: roomId }),
    });
  }

  isConnected(): boolean {
    return this.client?.connected || false;
  }
}

export const wsService = new WebSocketService();
