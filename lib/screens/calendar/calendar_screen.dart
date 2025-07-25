import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../services/auth_services.dart';
import '../../services/notification_services.dart';
import '../../screens/expenses/expense_statistics_screen.dart';
import '../../screens/ai/ai_chat_support_screen.dart';
import '../../screens/ai/chat_history_screen.dart';
import 'google_calendar_sync_screen.dart';
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  
  // Stream subscriptions to manage events loading and auth state
  StreamSubscription<List<Event>>? _eventsSubscription;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    _fabController.forward();
    
    // Listen for authentication state changes
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user == null) {
        // User logged out, clear all data
        _clearEventsData();
      } else {
        // User logged in, load events
        _loadEvents();
      }
    });
    
    // Initial load if user is already authenticated
    if (_authService.currentUser != null) {
      _loadEvents();
    }
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    _authSubscription?.cancel();
    _animationController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    // Cancel any existing subscription first
    _eventsSubscription?.cancel();
    
    setState(() => _isLoading = true);
    
    final userId = _authService.currentUser?.uid;
    print('Current user ID: $userId');
    
    if (userId != null) {
      print('Loading events for user: $userId');
      _eventsSubscription = _eventService.getUserEvents(userId).listen(
        (events) {
          // Check if widget is still mounted and user is still authenticated
          if (!mounted || _authService.currentUser?.uid != userId) {
            print('Widget unmounted or user changed, stopping event loading');
            return;
          }
          
          print('Received ${events.length} events');
          if (events.isEmpty) {
            print('No events found for user $userId');
          }
          setState(() {
            _events = {};
            for (var event in events) {
              print('Event data: ${event.toMap()}');
              final date = DateTime.utc(
                event.startTime.year,
                event.startTime.month,
                event.startTime.day,
              );
              if (_events[date] == null) _events[date] = [];
              _events[date]!.add(event);
              print('Added event: ${event.title} for date: $date');
            }
            _isLoading = false;
          });
        },
        onError: (error) {
          print('Error loading events: $error');
          if (mounted) {
            setState(() => _isLoading = false);
            // Only show error if user is still authenticated
            if (_authService.currentUser?.uid == userId) {
              _showCustomSnackBar('Lỗi tải sự kiện: $error', isError: true);
            }
          }
        },
      );
    } else {
      print('No user ID available');
      setState(() => _isLoading = false);
      if (mounted) {
        _showCustomSnackBar('Vui lòng đăng nhập để xem sự kiện', isError: true);
      }
    }
  }

  void _clearEventsData() {
    _eventsSubscription?.cancel();
    _eventsSubscription = null;
    setState(() {
      _events.clear();
      _isLoading = false;
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    final utcDay = DateTime.utc(day.year, day.month, day.day);
    final events = _events[utcDay] ?? [];
    print('Getting events for $utcDay: ${events.length} events');
    return events;
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
          Builder(
            builder: (context) => IconButton(
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 28,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withAlpha((0.1 * 255).round()),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFFE91E63),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _authService.currentUser?.email != null
                      ? _authService.currentUser!.email!.split('@')[0]
                      : 'Lịch của tôi',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
              ],
            ),
          ),
          IconButton(
            onPressed: _loadEvents,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withAlpha((0.1 * 255).round()),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              // Clear events data and cancel subscription before logout
              _clearEventsData();
              
              await _authService.signOut();
              if (!mounted) return;
              _showCustomSnackBar('Đăng xuất thành công');
              ScaffoldMessenger.of(context).clearSnackBars();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withAlpha((0.2 * 255).round()),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TableCalendar<Event>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: const TextStyle(
              color: Color(0xFFE91E63),
              fontWeight: FontWeight.w600,
            ),
            holidayTextStyle: const TextStyle(
              color: Color(0xFFE91E63),
              fontWeight: FontWeight.w600,
            ),
            selectedDecoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFFF1744)],
              ),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: const Color(0xFFE91E63).withAlpha((0.3 * 255).round()),
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: Color(0xFFFF1744),
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            canMarkersOverflow: true,
            markersOffset: const PositionedOffset(bottom: 5),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: const Color(0xFFE91E63).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            formatButtonTextStyle: const TextStyle(
              color: Color(0xFFE91E63),
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: const Icon(
              Icons.chevron_left,
              color: Color(0xFFE91E63),
            ),
            rightChevronIcon: const Icon(
              Icons.chevron_right,
              color: Color(0xFFE91E63),
            ),
            titleTextStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
        ),
      ),
    );
  }

  
  Widget _buildEventCard(Event event, int index) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, index == 0 ? 16 : 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/event-details',
              arguments: event,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event_rounded,
                        color: Color(0xFFE91E63),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          Navigator.pushNamed(
                            context,
                            '/event-form',
                            arguments: event,
                          );
                        } else if (value == 'delete') {
                          _showDeleteDialog(event);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Xóa', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: event.cost == 0 
                      ? Colors.blue.withAlpha((0.1 * 255).round())
                      : Colors.green.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.cost == 0 
                        ? 'Miễn phí'
                        : '${NumberFormat('#,###', 'vi_VN').format(event.cost.toInt())} đ',
                        style: TextStyle(
                          color: event.cost == 0 ? Colors.blue : Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa sự kiện "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _eventService.deleteEvent(event.id);
              final notificationService = NotificationService();
              await notificationService.cancelNotification(int.parse(event.id));
              if (mounted) {
                _showCustomSnackBar('Đã xóa sự kiện thành công');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFFF1744)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.calendar_month_rounded, color: Colors.white, size: 40),
                  SizedBox(height: 12),
                  Text('C Global Calendar', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded, color: Color(0xFFE91E63)),
              title: const Text('Thống kê chi phí'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExpenseStatisticsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy_rounded, color: Color(0xFF2196F3)),
              title: const Text('Trợ lí AI'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AIChatScreen(),
                  ),
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: Color(0xFFE91E63)),
              title: const Text('Đồng bộ Google Calendar'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GoogleCalendarSyncScreen(),
                  ),
                ).then((result) {
                  // If events were imported, reload the calendar
                  if (result == true) {
                    _loadEvents();
                  }
                });
              },
            ),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Column(
                children: [
                  _buildCalendar(),
                  Expanded(
                    child: _selectedDay == null
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Chọn một ngày để xem sự kiện',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _getEventsForDay(_selectedDay!).isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_busy_rounded,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Không có sự kiện nào trong ngày này',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _getEventsForDay(_selectedDay!).length,
                                itemBuilder: (context, index) {
                                  final event = _getEventsForDay(_selectedDay!)[index];
                                  return _buildEventCard(event, index);
                                },
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: ScaleTransition(
              scale: _fabAnimation,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2196F3),
                      Color(0xFF21CBF3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withAlpha((0.3 * 255).round()),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                // child: FloatingActionButton.extended(
                //   heroTag: 'test_notification',
                //   onPressed: _testNotification,
                //   backgroundColor: Colors.transparent,
                //   elevation: 0,
                //   icon: const Icon(
                //     Icons.notifications_active,
                //     color: Colors.white,
                //   ),
                //   label: const Text(
                //     'Test Notification',
                //     style: TextStyle(color: Colors.white),
                //   ),
                // ),
              ),
            ),
          ),
          ScaleTransition(
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
              child: FloatingActionButton(
                heroTag: 'add_event',
                onPressed: () {
                  Navigator.pushNamed(context, '/event-form');
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  
}