import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../services/auth_services.dart';
import '../../services/notification_services.dart';

class EventFormScreen extends StatefulWidget {
  final Event? event;

  const EventFormScreen({super.key, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _eventService = EventService();
  final _authService = AuthService();
  final _notificationService = NotificationService();
  
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  List<String> _selectedNotifications = [];
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  final List<Map<String, dynamic>> _notificationOptions = [
    {'title': '15 phút trước', 'value': '15 minutes before', 'icon': Icons.access_time},
    {'title': '1 giờ trước', 'value': '1 hour before', 'icon': Icons.schedule},
    {'title': '1 ngày trước', 'value': '1 day before', 'icon': Icons.today},
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fabController.forward();
    });
    
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
       // Format chi phí với dấu phẩy khi hiển thị

       // Format chi phí với dấu phẩy khi hiển thị (chỉ khi > 0)
      final costValue = widget.event!.cost.toInt();
      if (costValue > 0) {
        final formatter = NumberFormat('#,###', 'vi_VN');
        _costController.text = formatter.format(costValue);
      } else {
        _costController.text = '0';
      }
      // final formatter = NumberFormat('#,###', 'vi_VN');
      // _costController.text = formatter.format(widget.event!.cost.toInt());
    //  _costController.text = widget.event!.cost.toString();
      _startTime = widget.event!.startTime;
      _endTime = widget.event!.endTime;
      _selectedNotifications = List.from(widget.event!.notificationOptions);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _animationController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _showCustomSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_startTime.isAfter(_endTime)) {
        _showCustomSnackBar('Thời gian bắt đầu phải trước thời gian kết thúc', isError: true);
        return;
      }
      
      setState(() => _isLoading = true);
      
      try {
        final userId = _authService.currentUser?.uid;
        if (userId == null) {
          _showCustomSnackBar('Vui lòng đăng nhập để tạo sự kiện', isError: true);
          setState(() => _isLoading = false);
          return;
        }

        final costText = _costController.text.replaceAll(',', '');
        final cost = double.parse(costText.isEmpty ? '0' : costText);

        final event = Event(
          id: widget.event?.id ?? const Uuid().v4(),
          title: _titleController.text,
          description: _descriptionController.text,
          startTime: _startTime,
          endTime: _endTime,
          cost: cost * 1000, // Convert to VND
          userId: userId,
          notificationOptions: _selectedNotifications,
        );

        if (widget.event == null) {
          await _eventService.createEvent(event);
          _showCustomSnackBar('Tạo sự kiện thành công');
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          await _eventService.updateEvent(event);
          _showCustomSnackBar('Cập nhật sự kiện thành công');
          Navigator.of(context).pop();
        }

        // Schedule notifications
        if (_selectedNotifications.isNotEmpty) {
          try {
            final permission = await _notificationService.requestPermission();
            if (permission) {
              print('[EventForm] Starting notification scheduling...');
              print('[EventForm] Event start time: $_startTime');
              print('[EventForm] Current time: ${DateTime.now()}');
              for (int i = 0; i < _selectedNotifications.length; i++) {
                final notification = _selectedNotifications[i];
                DateTime notificationTime;
                String notificationBody;
                
                switch (notification) {
                  case '15 minutes before':
                    notificationTime = _startTime.subtract(const Duration(minutes: 15));//đây có ngh
                    notificationBody = 'Sự kiện "${event.title}" sẽ bắt đầu sau 15 phút';
                    break;
                  case '1 hour before':
                    notificationTime = _startTime.subtract(const Duration(hours: 1));
                    notificationBody = 'Sự kiện "${event.title}" sẽ bắt đầu sau 1 giờ';
                    break;
                  case '1 day before':
                    notificationTime = _startTime.subtract(const Duration(days: 1));
                    notificationBody = 'Sự kiện "${event.title}" sẽ bắt đầu vào ngày mai';
                    break;
                  default:
                    continue;
                }

                final now = DateTime.now();
                final timeUntilNotification = notificationTime.difference(now) ;
                print('[EventForm] Notification type: $notification');
                print('[EventForm] Notification time: $notificationTime');
                print('[EventForm] Time until notification: ${timeUntilNotification.inMinutes} minutes');
                
                
                // Skip if notification time is in the past
                // có nghĩa là nếu thời gian thông báo đã qua thì không cần lên lịch
                if (notificationTime.isAfter(now.add(Duration(seconds: 30)))) {
                  try {
                    // Schedule the notification
                    await _notificationService.scheduleNotification( // đây có nghĩa là lên lịch thông báo
                      id: event.id.hashCode + i, // Unique ID for each notification
                      title: 'Nhắc nhở sự kiện',
                      body: notificationBody,
                      scheduledTime: notificationTime,
                      useExactTiming: true, // Use exact timing for the notification
                    );
                    print('[EventForm] Scheduling notification for ${event.title} at $notificationTime');

                  } catch (e) {
                    print('[EventForm] ✗ Failed to schedule notification: $e');
                  }
                } else {
                  print('[EventForm] ⚠️ Skipping notification - time is too close or in the past');
                  print('[EventForm] Current time: $now');
                  print('[EventForm] Notification time: $notificationTime');
                }
              }
              // Add a small delay and then verify scheduled notifications
              await Future.delayed(Duration(milliseconds: 1000));
              await _notificationService.debugScheduledNotifications();
            
            } else {
              _showCustomSnackBar('Bạn cần cấp quyền thông báo để sử dụng tính năng này', isError: true);

            }
          } catch (e) {
            print('Error scheduling notifications: $e');
            _showCustomSnackBar('Lỗi khi lập lịch thông báo: ${e.toString()}', isError: true);
          }
        }
      } catch (e) {
        _showCustomSnackBar('Lỗi: ${e.toString()}', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDateTime(bool isStartTime) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: isStartTime ? _startTime : _endTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE91E63),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          isStartTime ? _startTime : _endTime,
        ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFE91E63),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          if (isStartTime) {
            _startTime = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          } else {
            _endTime = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          }
        });
      }
    }
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1a1a1a),
            Color(0xFF2d2d2d),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event == null ? 'Tạo sự kiện' : 'Chỉnh sửa sự kiện',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.event == null ? 'Tạo sự kiện mới' : 'Cập nhật thông tin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormCard({required String title, required Widget child, IconData? icon}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFFE91E63),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            if (title.isNotEmpty) const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    String? prefix,
    String? suffix,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        suffixText: suffix,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE91E63),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector({
    required String title,
    required DateTime dateTime,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFE91E63),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy - HH:mm').format(dateTime),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_right_rounded,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOptions() {
    return Column(
      children: _notificationOptions.map((option) {
        final isSelected = _selectedNotifications.contains(option['value']);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedNotifications.remove(option['value']);
                } else {
                  _selectedNotifications.add(option['value']);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFFE91E63).withAlpha((0.1 * 255).round())
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFFE91E63)
                      : Colors.grey[200]!,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE91E63)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      option['icon'],
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? const Color(0xFFE91E63)
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFFE91E63)
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                      color: isSelected 
                          ? const Color(0xFFE91E63)
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Title Field
                        _buildFormCard(
                          title: 'Thông tin cơ bản',
                          icon: Icons.info_outline_rounded,
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _titleController,
                                label: 'Tiêu đề',
                                hint: 'Nhập tiêu đề sự kiện',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập tiêu đề';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _descriptionController,
                                label: 'Mô tả',
                                hint: 'Nhập mô tả sự kiện (tùy chọn)',
                                maxLines: 3,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _costController,
                                label: 'Chi phí',
                                hint: 'ví dụ : 20000 , 1000000',                                
                                suffix: ' đ', 
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly, // Chỉ cho phép số nguyên
                                  // Thêm formatter để hiển thị dấu phẩy ngăn cách hàng nghìn
                                  TextInputFormatter.withFunction((oldValue, newValue) {
                                    if (newValue.text.isEmpty) return newValue;
                                    
                                    // Loại bỏ tất cả dấu phẩy trước khi parse
                                    final digitsOnly = newValue.text.replaceAll(',', '');
                                    final number = int.tryParse(digitsOnly);
                                    if (number == null) return oldValue;
                                    
                                    // Format lại với dấu phẩy
                                    final formatter = NumberFormat('#,###', 'vi_VN');
                                    final formatted = formatter.format(number);
                                    
                                    // Tính toán lại cursor position
                                    final newCursorPos = formatted.length;

                                    // final number = int.tryParse(newValue.text.replaceAll(',', ''));
                                    // if (number == null) return oldValue;
                                    
                                    // final formatter = NumberFormat('#,###', 'vi_VN');
                                    // final formatted = formatter.format(number);
                                    
                                    return TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(offset: newCursorPos),
                                    );
                                  }),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập chi phí (nhập 0 nếu miễn phí)';
                                  }
                                  // Xử lý validation cho số có dấu phẩy
                                  final cleanValue = value.replaceAll(',', '');
                                  final cost = double.tryParse(cleanValue);
                                  
                                  if (cost == null) {
                                    return 'Vui lòng nhập số hợp lệ';
                                  }
                                  
                                  if (cost < 0) {
                                    return 'Chi phí không thể âm';
                                  }                                  
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        // Date Time Section
                        _buildFormCard(
                          title: 'Thời gian',
                          icon: Icons.schedule_rounded,
                          child: Column(
                            children: [
                              _buildDateTimeSelector(
                                title: 'Thời gian bắt đầu',
                                dateTime: _startTime,
                                onTap: () => _selectDateTime(true),
                                icon: Icons.play_arrow_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildDateTimeSelector(
                                title: 'Thời gian kết thúc',
                                dateTime: _endTime,
                                onTap: () => _selectDateTime(false),
                                icon: Icons.stop_rounded,
                              ),
                            ],
                          ),
                        ),
                        
                        // Notifications Section
                        _buildFormCard(
                          title: 'Thông báo',
                          icon: Icons.notifications_active_rounded,
                          child: _buildNotificationOptions(),
                        ),
                        
                        const SizedBox(height: 100), // Space for FAB
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE91E63),
                Color(0xFFFF1744),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withAlpha((0.3 * 255).round()),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _isLoading ? null : _saveEvent,
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.save_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
            label: Text(
              _isLoading 
                  ? 'Đang lưu...'
                  : (widget.event == null ? 'Tạo sự kiện' : 'Cập nhật'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}