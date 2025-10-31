import { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import { RootState } from '../../store';
import { setRooms, setCurrentRoom, setMessages, addMessage } from '../../store/chatSlice';
import { chatService } from '../../services/chatService';
import { wsService } from '../../services/websocketService';
import ChatRoomList from './ChatRoomList';
import ChatWindow from './ChatWindow';
import { Message } from '../../types';

export default function ChatContainer() {
  const dispatch = useDispatch();
  const { currentRoom } = useSelector((state: RootState) => state.chat);
  const { user } = useSelector((state: RootState) => state.auth);

  useEffect(() => {
    loadRooms();
    
    // Connect to WebSocket
    wsService.connect(() => {
      console.log('Connected to WebSocket');
    });

    return () => {
      wsService.disconnect();
    };
  }, []);

  useEffect(() => {
    if (currentRoom) {
      loadMessages(currentRoom.id);
      
      // Subscribe to room messages
      wsService.subscribeToRoom(currentRoom.id, (message: Message) => {
        dispatch(addMessage(message));
      });
    }
  }, [currentRoom]);

  const loadRooms = async () => {
    try {
      const rooms = await chatService.getUserRooms();
      dispatch(setRooms(rooms));
    } catch (error) {
      console.error('Failed to load rooms', error);
    }
  };

  const loadMessages = async (roomId: number) => {
    try {
      const messages = await chatService.getRoomMessages(roomId);
      dispatch(setMessages(messages));
    } catch (error) {
      console.error('Failed to load messages', error);
    }
  };

  return (
    <div className="flex h-screen bg-gray-100">
      <ChatRoomList onRoomSelect={(room) => dispatch(setCurrentRoom(room))} />
      {currentRoom ? (
        <ChatWindow />
      ) : (
        <div className="flex-1 flex items-center justify-center text-gray-500">
          <p className="text-lg">Select a chat room to start messaging</p>
        </div>
      )}
    </div>
  );
}
