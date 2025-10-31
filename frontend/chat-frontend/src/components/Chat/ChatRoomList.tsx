import { useSelector, useDispatch } from 'react-redux';
import { RootState } from '../../store';
import { logout } from '../../store/authSlice';
import { addRoom } from '../../store/chatSlice';
import { chatService } from '../../services/chatService';
import { useState } from 'react';
import { MessageSquare, Plus, LogOut, Users } from 'lucide-react';

interface ChatRoomListProps {
  onRoomSelect: (room: any) => void;
}

export default function ChatRoomList({ onRoomSelect }: ChatRoomListProps) {
  const { rooms, currentRoom } = useSelector((state: RootState) => state.chat);
  const { user } = useSelector((state: RootState) => state.auth);
  const dispatch = useDispatch();
  const [showNewChat, setShowNewChat] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<any[]>([]);

  const handleSearch = async (query: string) => {
    setSearchQuery(query);
    if (query.length > 0) {
      try {
        const results = await chatService.searchUsers(query);
        setSearchResults(results.filter((u: any) => u.id !== user?.id));
      } catch (error) {
        console.error('Search failed', error);
      }
    } else {
      setSearchResults([]);
    }
  };

  const createPrivateChat = async (otherUser: any) => {
    try {
      const room = await chatService.createRoom(
        `${user?.username} & ${otherUser.username}`,
        'private',
        [otherUser.id]
      );
      dispatch(addRoom(room));
      onRoomSelect(room);
      setShowNewChat(false);
      setSearchQuery('');
      setSearchResults([]);
    } catch (error) {
      console.error('Failed to create chat', error);
    }
  };

  return (
    <div className="w-80 bg-white border-r border-gray-200 flex flex-col">
      <div className="p-4 border-b border-gray-200">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold">Chats</h2>
          <div className="flex gap-2">
            <button
              onClick={() => setShowNewChat(!showNewChat)}
              className="p-2 hover:bg-gray-100 rounded-full transition"
            >
              <Plus size={20} />
            </button>
            <button
              onClick={() => dispatch(logout())}
              className="p-2 hover:bg-gray-100 rounded-full transition text-red-600"
            >
              <LogOut size={20} />
            </button>
          </div>
        </div>
        
        {showNewChat && (
          <div className="mb-4">
            <input
              type="text"
              placeholder="Search users..."
              value={searchQuery}
              onChange={(e) => handleSearch(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            {searchResults.length > 0 && (
              <div className="mt-2 max-h-40 overflow-y-auto border border-gray-200 rounded-md">
                {searchResults.map((user) => (
                  <button
                    key={user.id}
                    onClick={() => createPrivateChat(user)}
                    className="w-full px-3 py-2 hover:bg-gray-50 text-left flex items-center gap-2"
                  >
                    <Users size={16} />
                    <span>{user.username}</span>
                  </button>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      <div className="flex-1 overflow-y-auto">
        {rooms.length === 0 ? (
          <div className="p-4 text-center text-gray-500">
            <p>No chats yet</p>
            <p className="text-sm mt-2">Click + to start a new chat</p>
          </div>
        ) : (
          rooms.map((room) => (
            <button
              key={room.id}
              onClick={() => onRoomSelect(room)}
              className={`w-full p-4 flex items-center gap-3 hover:bg-gray-50 border-b border-gray-100 transition ${
                currentRoom?.id === room.id ? 'bg-blue-50' : ''
              }`}
            >
              <div className="w-10 h-10 bg-blue-500 rounded-full flex items-center justify-center text-white font-semibold">
                <MessageSquare size={20} />
              </div>
              <div className="flex-1 text-left">
                <p className="font-semibold text-sm">{room.name}</p>
                <p className="text-xs text-gray-500">{room.type}</p>
              </div>
            </button>
          ))
        )}
      </div>

      <div className="p-4 border-t border-gray-200 bg-gray-50">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-green-500 rounded-full flex items-center justify-center text-white font-semibold">
            {user?.username.charAt(0).toUpperCase()}
          </div>
          <div>
            <p className="font-semibold text-sm">{user?.username}</p>
            <p className="text-xs text-green-600">Online</p>
          </div>
        </div>
      </div>
    </div>
  );
}
