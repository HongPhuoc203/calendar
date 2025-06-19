import 'dart:convert';
import 'package:http/http.dart' as http;

class AIChatService {
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';
  static const String _apiKey = 'AIzaSyByGO6YdVt7oOHaGAqUf048At23M60oiRk'; // Lấy từ https://ai.google.dev/

  // Template prompt được tối ưu cho Gemini 2.5 Flash
  static const String _systemPrompt = '''
Bạn là EventMaster AI - chuyên gia tư vấn tổ chức sự kiện hàng đầu tại Việt Nam với 10+ năm kinh nghiệm.

🎯 NHIỆM VỤ CỦA BẠN:
- Tư vấn lập kế hoạch sự kiện chi tiết và thực tế
- Ước tính chi phí chính xác (VNĐ) dựa trên thị trường Việt Nam
- Gợi ý địa điểm phù hợp theo từng khu vực
- Tạo checklist cụ thể cho từng loại sự kiện  
- Đưa ra timeline tổ chức hợp lý

📋 PHONG CÁCH TRẢ LỜI:
- Ngắn gọn, súc tích nhưng đầy đủ thông tin
- Sử dụng emoji phù hợp để dễ đọc
- Chia thành các mục rõ ràng
- Luôn hỏi thêm chi tiết nếu cần thiết
- Đưa ra 2-3 phương án khác nhau

🔍 LUÔN BAO GỒM:
- Chi phí ước tính cụ thể (VNĐ)
- Thời gian chuẩn bị khuyến nghị  
- Tips tiết kiệm chi phí
- Những điều cần lưu ý đặc biệt

Hãy trả lời như một chuyên gia thực thụ, không quá dài dòng nhưng rất hữu ích!
''';

  static Future<String> sendMessage(String userMessage, {List<Map<String, String>>? chatHistory}) async {
    try {
      // Tạo context từ lịch sử chat
      String fullPrompt = _systemPrompt;
      
      if (chatHistory != null && chatHistory.isNotEmpty) {
        fullPrompt += '\nLịch sử hội thoại:\n';
        for (var chat in chatHistory) {
          fullPrompt += 'Người dùng: ${chat['user']}\nTrợ lý: ${chat['assistant']}\n';
        }
      }
      
      fullPrompt += '\nCâu hỏi hiện tại: $userMessage';

      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': fullPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'topK': 64,
            'topP': 0.95,
            'maxOutputTokens': 2048,
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
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'] ?? 'Xin lỗi, tôi không thể trả lời câu hỏi này.';
        }
      }
      
      return 'Có lỗi xảy ra khi kết nối với AI. Vui lòng thử lại sau.';
      
    } catch (e) {
      print('AI Chat Error: $e');
      return 'Không thể kết nối với trợ lý AI. Kiểm tra kết nối mạng và thử lại.';
    }
  }

  // Các câu hỏi gợi ý được cập nhật cho Gemini 2.5 Flash
  static List<String> getSuggestedQuestions() {
    return [
      '🎂 Tổ chức sinh nhật 25 người, ngân sách 3 triệu?',
      '💒 Chi phí đám cưới 150 khách ở Hà Nội?', 
      '🏢 Checklist sự kiện công ty 100 người?',
      '🎓 Địa điểm họp lớp 50 người ở TP.HCM?',
      '🎪 Ý tưởng sự kiện độc đáo thu hút khách?',
      '📊 Timeline chuẩn bị sự kiện 2 tuần?',
    ];
  }

  // Phân tích loại sự kiện từ tin nhắn người dùng
  static String detectEventType(String message) {
    message = message.toLowerCase();
    
    if (message.contains('sinh nhật') || message.contains('birthday')) {
      return 'Sinh nhật';
    } else if (message.contains('đám cưới') || message.contains('wedding')) {
      return 'Đám cưới';
    } else if (message.contains('công ty') || message.contains('corporate')) {
      return 'Sự kiện công ty';
    } else if (message.contains('họp lớp') || message.contains('reunion')) {
      return 'Họp lớp';
    } else if (message.contains('hội thảo') || message.contains('seminar')) {
      return 'Hội thảo';
    }
    
    return 'Sự kiện chung';
  }
}
