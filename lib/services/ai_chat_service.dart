import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIChatService {
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // Cache để tránh gọi API quá nhiều
  static final Map<String, String> _responseCache = {};
  
  // Template prompt được tối ưu hóa
  static const String _systemPrompt = '''
Bạn là EventMaster AI - chuyên gia tư vấn tổ chức sự kiện hàng đầu tại Việt Nam với 10+ năm kinh nghiệm.

🎯 NHIỆM VỤ CỦA BẠN:
- Tư vấn lập kế hoạch sự kiện chi tiết và thực tế
- Ước tính chi phí chính xác (VNĐ) theo thị trường Việt Nam 2024
- Gợi ý địa điểm phù hợp theo từng khu vực (Hà Nội, TP.HCM, Đà Nẵng...)
- Tạo checklist cụ thể cho từng loại sự kiện
- Đưa ra timeline tổ chức hợp lý
- Gợi ý nhà cung cấp dịch vụ uy tín

📋 PHONG CÁCH TRẢ LỜI:
- Ngắn gọn, súc tích nhưng đầy đủ thông tin (tối đa 300 từ)
- Sử dụng emoji phù hợp để dễ đọc
- Chia thành các mục rõ ràng với bullet points
- Luôn hỏi thêm chi tiết nếu cần thiết
- Đưa ra 2-3 phương án khác nhau

🔍 LUÔN BAO GỒM:
- Chi phí ước tính cụ thể (VNĐ) với breakdown chi tiết
- Thời gian chuẩn bị khuyến nghị (tuần/tháng)
- Tips tiết kiệm chi phí thực tế
- Những điều cần lưu ý đặc biệt theo mùa/thời tiết
- Gợi ý backup plan

💡 ĐẶC BIỆT CHÚ Ý:
- Giá cả theo thị trường Việt Nam hiện tại
- Phong tục tập quán địa phương
- Thời tiết và mùa vụ
- Quy định pháp lý (nếu cần)

Hãy trả lời như một chuyên gia thực thụ, thân thiện và hữu ích!
''';

  static Future<String> sendMessage(String userMessage, {List<Map<String, String>>? chatHistory}) async {
    // Debug: In ra thông tin API key
    print('🔑 API Key length: ${_apiKey.length}');
    print('🔑 API Key first 10 chars: ${_apiKey.length > 10 ? _apiKey.substring(0, 10) : _apiKey}...');
    
    // Kiểm tra API key
    if (_apiKey.isEmpty) {
      print('❌ API key is empty!');
      return '❌ Lỗi: API key chưa được cấu hình. Vui lòng kiểm tra file .env';
    }

    // Kiểm tra cache
    String cacheKey = _generateCacheKey(userMessage, chatHistory);
    if (_responseCache.containsKey(cacheKey)) {
      print('📦 Using cached response');
      return _responseCache[cacheKey]!;
    }

    try {
      print('🚀 Sending request to Gemini API...');
      
      // Tạo context từ lịch sử chat (chỉ lấy 3 tin nhắn gần nhất)
      String fullPrompt = _systemPrompt;
      
      if (chatHistory != null && chatHistory.isNotEmpty) {
        fullPrompt += '\n📝 Lịch sử hội thoại gần đây:\n';
        for (var chat in chatHistory.take(3)) {
          if (chat['user']?.isNotEmpty == true) {
            fullPrompt += '👤 Người dùng: ${chat['user']}\n🤖 Trợ lý: ${chat['assistant']}\n\n';
          }
        }
      }
      
      fullPrompt += '\n💬 Câu hỏi hiện tại: $userMessage\n\nHãy trả lời ngắn gọn và hữu ích:';

      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': fullPrompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.9,
          'maxOutputTokens': 1024,
          'responseMimeType': 'text/plain',
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH', 
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      });

      print('📤 Request URL: $_geminiApiUrl?key=${_apiKey.substring(0, 10)}...');
      print('📤 Request body length: ${requestBody.length}');

      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      ).timeout(Duration(seconds: 30));

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('✅ Response data structure: ${data.keys.toList()}');
        
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidates = data['candidates'] as List;
          print('📋 Number of candidates: ${candidates.length}');
          
          if (candidates[0]['content'] != null && 
              candidates[0]['content']['parts'] != null &&
              candidates[0]['content']['parts'].isNotEmpty) {
            
            String aiResponse = candidates[0]['content']['parts'][0]['text'] ?? 
                                'Xin lỗi, tôi không thể trả lời câu hỏi này.';
            
            print('✅ AI response length: ${aiResponse.length}');
            print('✅ AI response preview: ${aiResponse.substring(0, aiResponse.length > 100 ? 100 : aiResponse.length)}...');
            
            // Lưu vào cache
            _responseCache[cacheKey] = aiResponse;
            
            // Giới hạn cache size
            if (_responseCache.length > 50) {
              _responseCache.remove(_responseCache.keys.first);
            }
            
            return aiResponse;
          } else {
            print('❌ No text content in response');
            return 'Xin lỗi, AI không thể tạo phản hồi phù hợp.';
          }
        } else {
          print('❌ No candidates in response: ${data}');
          return _handleApiError(data);
        }
      } else if (response.statusCode == 429) {
        print('⏳ Rate limit exceeded');
        return '⏳ Đã vượt quá giới hạn API. Vui lòng thử lại sau 1 phút.';
      } else {
        print('❌ API Error ${response.statusCode}: ${response.body}');
        return '❌ Lỗi API (${response.statusCode}). Vui lòng thử lại sau.';
      }
      
    } catch (e) {
      print('💥 Exception in sendMessage: $e');
      print('💥 Exception type: ${e.runtimeType}');
      
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        return '🌐 Không có kết nối internet. Vui lòng kiểm tra mạng.';
      } else if (e.toString().contains('FormatException')) {
        return '📝 Lỗi định dạng phản hồi từ server. Vui lòng thử lại.';
      }
      return '❌ Không thể kết nối với trợ lý AI. Lỗi: ${e.toString().substring(0, 100)}';
    }
  }

  // Xử lý lỗi API chi tiết
  static String _handleApiError(Map<String, dynamic> data) {
    if (data['error'] != null) {
      String errorMessage = data['error']['message'] ?? 'Lỗi không xác định';
      if (errorMessage.contains('API key')) {
        return '🔑 API key không hợp lệ. Vui lòng kiểm tra lại.';
      }
    }
    return '❌ AI không thể trả lời. Vui lòng thử câu hỏi khác.';
  }

  // Tạo cache key
  static String _generateCacheKey(String message, List<Map<String, String>>? history) {
    return '${message.toLowerCase().trim()}_${history?.length ?? 0}';
  }

  // Câu hỏi gợi ý được cập nhật
  static List<String> getSuggestedQuestions() {
    return [
      '🎂 Sinh nhật 25 người, ngân sách 3 triệu',
      '💒 Chi phí đám cưới 150 khách Hà Nội',
      '🏢 Checklist sự kiện công ty 100 người',
      '🎓 Địa điểm họp lớp 50 người TPHCM',
      '🎪 Ý tưởng sự kiện độc đáo thu hút',
      '📊 Timeline chuẩn bị sự kiện 2 tuần',
      '💰 Mẹo tiết kiệm chi phí sự kiện',
      '🎨 Trang trí sự kiện theo xu hướng',
    ];
  }

  // Phân tích loại sự kiện từ tin nhắn người dùng
  static String detectEventType(String message) {
    message = message.toLowerCase();
    
    Map<String, List<String>> eventTypes = {
      'Sinh nhật': ['sinh nhật', 'birthday', 'sinh', 'tuổi'],
      'Đám cưới': ['đám cưới', 'wedding', 'cưới', 'hôn lễ'],
      'Sự kiện công ty': ['công ty', 'corporate', 'teambuilding', 'hội nghị'],
      'Họp lớp': ['họp lớp', 'reunion', 'gặp mặt', 'đồng học'],
      'Hội thảo': ['hội thảo', 'seminar', 'workshop', 'đào tạo'],
      'Khai trương': ['khai trương', 'opening', 'mở cửa', 'ra mắt'],
      'Tiệc tất niên': ['tất niên', 'year end', 'cuối năm', 'liên hoan'],
      'Lễ hội': ['lễ hội', 'festival', 'sự kiện văn hóa', 'trình diễn'],
    };
    
    for (var type in eventTypes.entries) {
      if (type.value.any((keyword) => message.contains(keyword))) {
        return type.key;
      }
    }
    
    return 'Sự kiện chung';
  }

  // Kiểm tra tình trạng API
  static Future<bool> checkApiStatus() async {
    try {
      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': 'test'}]}],
          'generationConfig': {'maxOutputTokens': 1}
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Lấy thống kê sử dụng API (nếu cần)
  static Map<String, int> getUsageStats() {
    return {
      'cached_responses': _responseCache.length,
      'total_requests': _responseCache.length, // Simplified
    };
  }
}