import 'package:flutter/material.dart';
import '../../services/google_calendar_service.dart';
import '../../services/event_service.dart';
import '../../services/auth_services.dart';
import '../../models/event.dart';

class GoogleCalendarSyncScreen extends StatefulWidget {
  const GoogleCalendarSyncScreen({super.key});

  @override
  State<GoogleCalendarSyncScreen> createState() => _GoogleCalendarSyncScreenState();
}

class _GoogleCalendarSyncScreenState extends State<GoogleCalendarSyncScreen> with SingleTickerProviderStateMixin {
  final GoogleCalendarService _googleCalendarService = GoogleCalendarService();
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isSyncing = false;
  String _statusMessage = '';
  List<Event> _importedEvents = [];
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _checkGoogleSignInStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkGoogleSignInStatus() {
    setState(() {
      if (_googleCalendarService.isSignedIn) {
        _statusMessage = 'Đã kết nối với Google Calendar';
      } else {
        _statusMessage = 'Chưa kết nối với Google Calendar';
      }
    });
  }

  Future<void> _connectToGoogle() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Đang kết nối...';
    });

    try {
      final success = await _googleCalendarService.signIn();
      if (success) {
        _statusMessage = 'Kết nối thành công với Google Calendar!';
        _showSnackBar(_statusMessage, isError: false);
      } else {
        _statusMessage = 'Không thể kết nối với Google Calendar';
        _showSnackBar(_statusMessage, isError: true);
      }
    } catch (e) {
      _statusMessage = 'Lỗi kết nối: $e';
      _showSnackBar(_statusMessage, isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnectFromGoogle() async {
    await _googleCalendarService.signOut();
    setState(() {
      _statusMessage = 'Đã ngắt kết nối khỏi Google Calendar';
      _importedEvents.clear();
    });
    _showSnackBar(_statusMessage, isError: false);
  }

  Future<void> _syncFromGoogle() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      _showSnackBar('Vui lòng đăng nhập trước', isError: true);
      return;
    }

    setState(() => _isSyncing = true);

    try {
      await _googleCalendarService.syncCalendars(
        userId: userId,
        onEventsImported: (events) {
          setState(() {
            _importedEvents = events;
          });
        },
        onStatusUpdate: (status) {
          setState(() {
            _statusMessage = status;
          });
        },
      );
      
      _showSnackBar('Đồng bộ thành công ${_importedEvents.length} sự kiện!', isError: false);
    } catch (e) {
      _showSnackBar('Lỗi đồng bộ: $e', isError: true);
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _importSelectedEvents() async {
    if (_importedEvents.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      for (var event in _importedEvents) {
        await _eventService.createEvent(event);
      }
      
      _showSnackBar('Đã nhập ${_importedEvents.length} sự kiện thành công!', isError: false);
      Navigator.pop(context, true); // Return true to indicate events were imported
    } catch (e) {
      _showSnackBar('Lỗi nhập sự kiện: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildConnectionCard(),
                    const SizedBox(height: 16),
                    _buildSyncCard(),
                    const SizedBox(height: 16),
                    if (_importedEvents.isNotEmpty) _buildImportedEventsCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 50,
      pinned: true,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [                
                const SizedBox(height: 50),
                const Text(
                  'Đồng bộ Google Calendar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_circle_rounded,
                    color: Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Kết nối tài khoản',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (!_googleCalendarService.isSignedIn)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _connectToGoogle,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(_isLoading ? 'Đang kết nối...' : 'Kết nối Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _disconnectFromGoogle,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Ngắt kết nối'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.cloud_sync_rounded,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Đồng bộ sự kiện',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Tải về các sự kiện từ Google Calendar của bạn trong vòng 6 tháng tới.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: (!_googleCalendarService.isSignedIn || _isSyncing) ? null : _syncFromGoogle,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(_isSyncing ? 'Đang đồng bộ...' : 'Tải sự kiện từ Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportedEventsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Sự kiện đã tải (${_importedEvents.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _importedEvents.length,
                itemBuilder: (context, index) {
                  final event = _importedEvents[index];
                  return ListTile(
                    title: Text(event.title),
                    subtitle: Text(
                      '${event.startTime.day}/${event.startTime.month} ${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}',
                    ),
                    leading: const Icon(Icons.event_rounded, color: Color(0xFFE91E63)),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _importSelectedEvents,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isLoading ? 'Đang nhập...' : 'Nhập tất cả sự kiện'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 