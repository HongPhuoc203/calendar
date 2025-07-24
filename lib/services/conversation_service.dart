import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';
import '../models/conversation.dart' as models;

class ConversationService {
  static const String _conversationsKey = 'saved_conversations';
  static const String _currentConversationKey = 'current_conversation';
  static const int maxConversations = 50; // Limit to avoid storage issues

  // Save a conversation
  static Future<void> saveConversation(Conversation conversation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing conversations
      List<Conversation> conversations = await getConversations();
      
      // Check if conversation already exists (update it)
      int existingIndex = conversations.indexWhere((c) => c.id == conversation.id);
      if (existingIndex != -1) {
        conversations[existingIndex] = conversation;
      } else {
        // Add new conversation
        conversations.add(conversation);
      }
      
      // Sort by last message time (most recent first)
      conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      
      // Keep only the most recent conversations
      if (conversations.length > maxConversations) {
        conversations = conversations.take(maxConversations).toList();
      }
      
      // Save to SharedPreferences
      final conversationsJson = conversations.map((c) => c.toJson()).toList();
      await prefs.setString(_conversationsKey, jsonEncode(conversationsJson));
      
      print('Saved conversation: ${conversation.title}');
    } catch (e) {
      print('Error saving conversation: $e');
    }
  }

  // Get all saved conversations
  static Future<List<Conversation>> getConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversationsStr = prefs.getString(_conversationsKey);
      
      if (conversationsStr == null) return [];
      
      final List<dynamic> conversationsJson = jsonDecode(conversationsStr);
      final conversations = conversationsJson
          .map((json) => Conversation.fromJson(json))
          .toList();
      
      // Sort by last message time (most recent first)
      conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      
      return conversations;
    } catch (e) {
      print('Error loading conversations: $e');
      return [];
    }
  }

  // Delete a conversation
  static Future<void> deleteConversation(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Conversation> conversations = await getConversations();
      
      conversations.removeWhere((c) => c.id == conversationId);
      
      final conversationsJson = conversations.map((c) => c.toJson()).toList();
      await prefs.setString(_conversationsKey, jsonEncode(conversationsJson));
      
      // Also clear current conversation if it's the one being deleted
      final currentConv = await getCurrentConversation();
      if (currentConv?.id == conversationId) {
        await clearCurrentConversation();
      }
      
      print('Deleted conversation: $conversationId');
    } catch (e) {
      print('Error deleting conversation: $e');
    }
  }

  // Save current conversation (the one being actively used)
  static Future<void> saveCurrentConversation(Conversation conversation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentConversationKey, jsonEncode(conversation.toJson()));
      
      // Also save it to the main conversations list
      await saveConversation(conversation);
    } catch (e) {
      print('Error saving current conversation: $e');
    }
  }

  // Get current conversation
  static Future<Conversation?> getCurrentConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conversationStr = prefs.getString(_currentConversationKey);
      
      if (conversationStr == null) return null;
      
      return Conversation.fromJson(jsonDecode(conversationStr));
    } catch (e) {
      print('Error loading current conversation: $e');
      return null;
    }
  }

  // Clear current conversation (start new one)
  static Future<void> clearCurrentConversation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentConversationKey);
    } catch (e) {
      print('Error clearing current conversation: $e');
    }
  }

  // Create a new conversation with a unique ID
  static Conversation createNewConversation() {
    final now = DateTime.now();
    return Conversation(
      id: 'conv_${now.millisecondsSinceEpoch}',
      title: 'Cuộc trò chuyện mới',
      createdAt: now,
      lastMessageAt: now,
      messages: [],
    );
  }

  // Add message to conversation
  static Conversation addMessageToConversation(
    Conversation conversation,
    models.ChatMessage message,
  ) {
    final updatedMessages = List<models.ChatMessage>.from(conversation.messages);
    updatedMessages.add(message);
    
    // Update title if it's still the default and we have user messages
    String title = conversation.title;
    if (title == 'Cuộc trò chuyện mới' && message.isUser) {
      title = Conversation.generateTitle(updatedMessages);
    }
    
    return conversation.copyWith(
      messages: updatedMessages,
      lastMessageAt: message.timestamp,
      title: title,
    );
  }

  // Clear all conversations (for settings/reset)
  static Future<void> clearAllConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_conversationsKey);
      await prefs.remove(_currentConversationKey);
      print('Cleared all conversations');
    } catch (e) {
      print('Error clearing all conversations: $e');
    }
  }

  // Get conversation statistics
  static Future<Map<String, int>> getConversationStats() async {
    final conversations = await getConversations();
    int totalMessages = 0;
    
    for (final conv in conversations) {
      totalMessages += conv.messages.length;
    }
    
    return {
      'totalConversations': conversations.length,
      'totalMessages': totalMessages,
    };
  }
} 