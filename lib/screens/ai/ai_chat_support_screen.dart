import 'package:flutter/material.dart';
import '../../services/AIChatService.dart';
import '../../models/conversation.dart';
import '../../services/conversation_service.dart';
import 'chat_history_screen.dart';

class AIChatScreen extends StatefulWidget {
  final Conversation? initialConversation;
  
  const AIChatScreen({super.key, this.initialConversation});
  
  @override
  _AIChatScreenState createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  Conversation? _currentConversation;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  Future<void> _initializeConversation() async {
    if (widget.initialConversation != null) {
      // Load existing conversation
      setState(() {
        _currentConversation = widget.initialConversation;
        _messages.addAll(widget.initialConversation!.messages);
      });
    } else {
      // Start new conversation or load current one
      final currentConv = await ConversationService.getCurrentConversation();
      if (currentConv != null) {
        setState(() {
          _currentConversation = currentConv;
          _messages.addAll(currentConv.messages);
        });
      } else {
        // Create new conversation and add welcome message
        _currentConversation = ConversationService.createNewConversation();
        _addWelcomeMessage();
      }
    }
    _scrollToBottom();
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      text: 'Xin chào! Tôi là trợ lý AI của bạn. Tôi có thể giúp bạn tư vấn về tổ chức sự kiện, ước tính chi phí, gợi ý địa điểm và nhiều hơn nữa. Bạn cần tư vấn gì?',
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(welcomeMessage);
    });
    
    // Save welcome message to conversation
    if (_currentConversation != null) {
      _currentConversation = ConversationService.addMessageToConversation(
        _currentConversation!,
        welcomeMessage,
      );
      ConversationService.saveCurrentConversation(_currentConversation!);
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    // Save user message to conversation
    if (_currentConversation != null) {
      _currentConversation = ConversationService.addMessageToConversation(
        _currentConversation!,
        userMessage,
      );
      await ConversationService.saveCurrentConversation(_currentConversation!);
    }

    _messageController.clear();
    _scrollToBottom();

    // Chuẩn bị lịch sử chat - sửa lỗi logic
    List<Map<String, String>> chatHistory = [];
    
    // Lấy các cặp user-assistant gần đây nhất (tối đa 3 cặp)
    for (int i = _messages.length - 2; i >= 1; i -= 2) {
      if (chatHistory.length >= 3) break;
      
      // Kiểm tra xem có đủ 2 tin nhắn (user và assistant) không
      if (i >= 1 && 
          _messages[i].isUser == false && // assistant message
          _messages[i - 1].isUser == true) { // user message
        chatHistory.add({
          'user': _messages[i - 1].text,
          'assistant': _messages[i].text,
        });
      }
    }

    try {
      String response = await AIChatService.sendMessage(message, chatHistory: chatHistory);
      
      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        eventType: AIChatService.detectEventType(message),
      );
      
      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });
      
      // Save AI response to conversation
      if (_currentConversation != null) {
        _currentConversation = ConversationService.addMessageToConversation(
          _currentConversation!,
          aiMessage,
        );
        await ConversationService.saveCurrentConversation(_currentConversation!);
      }
    } catch (e) {
      print('Error in _sendMessage: $e');
      final errorMessage = ChatMessage(
        text: 'Xin lỗi, có lỗi xảy ra. Vui lòng thử lại sau.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });
      
      // Save error message to conversation
      if (_currentConversation != null) {
        _currentConversation = ConversationService.addMessageToConversation(
          _currentConversation!,
          errorMessage,
        );
        await ConversationService.saveCurrentConversation(_currentConversation!);
      }
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendSuggestedQuestion(String question) {
    _sendMessage(question);
  }

  void _startNewConversation() async {
    // Save current conversation first
    if (_currentConversation != null && _messages.isNotEmpty) {
      await ConversationService.saveConversation(_currentConversation!);
    }
    
    // Clear current conversation
    await ConversationService.clearCurrentConversation();
    
    // Reset state
    setState(() {
      _messages.clear();
      _currentConversation = ConversationService.createNewConversation();
    });
    
    _addWelcomeMessage();
  }

  void _showChatHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.blue),
            SizedBox(width: 8),
            Text('Trợ lý AI Sự kiện'),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử trò chuyện',
            onPressed: _showChatHistory,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'new_chat':
                  _startNewConversation();
                  break;
                case 'history':
                  _showChatHistory();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_chat',
                child: Row(
                  children: [
                    Icon(Icons.add_comment, size: 20),
                    SizedBox(width: 8),
                    Text('Cuộc trò chuyện mới'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20),
                    SizedBox(width: 8),
                    Text('Lịch sử trò chuyện'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Gợi ý câu hỏi
          if (_messages.length <= 1) _buildSuggestedQuestions(),
          
          // Danh sách tin nhắn
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // Input box
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildSuggestedQuestions() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Câu hỏi gợi ý:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AIChatService.getSuggestedQuestions()
                .map((question) => GestureDetector(
                      onTap: () => _sendSuggestedQuestion(question),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          question,
                          style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                        ),
                      ),
                    ))
                .toList(),
          ),
          Divider(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(Icons.smart_toy, color: Colors.blue),
          ),
          SizedBox(width: 12),
          Text('Đang suy nghĩ...'),
          SizedBox(width: 8),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.smart_toy, color: Colors.blue, size: 18),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.eventType != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        message.eventType!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: message.isUser ? Colors.white70 : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.person, color: Colors.green, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Nhập câu hỏi của bạn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: _sendMessage,
              enabled: !_isLoading,
            ),
          ),
          SizedBox(width: 12),
          FloatingActionButton(
            onPressed: _isLoading ? null : () => _sendMessage(_messageController.text),
            child: Icon(Icons.send),
            mini: true,
            backgroundColor: _isLoading ? Colors.grey : Colors.blue,
          ),
        ],
      ),
    );
  }
}

