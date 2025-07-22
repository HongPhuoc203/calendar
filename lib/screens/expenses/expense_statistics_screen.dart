import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../services/auth_services.dart';

class ExpenseStatisticsScreen extends StatefulWidget {
  const ExpenseStatisticsScreen({super.key});

  @override
  State<ExpenseStatisticsScreen> createState() => _ExpenseStatisticsScreenState();
}

class _ExpenseStatisticsScreenState extends State<ExpenseStatisticsScreen>
    with TickerProviderStateMixin {
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  
  List<Event> _events = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = true;
  
  // Time filter options
  String _selectedTimeFilter = 'Tháng này';
  final List<String> _timeFilterOptions = [
    'Tuần này',
    'Tháng này', 
    '6 tháng qua',
    'Năm này',
    'Tùy chọn'
  ];
  
  DateTimeRange? _customDateRange;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _chartController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadEvents();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartController,
      curve: Curves.elasticOut,
    ));
    
    _fadeController.forward();
    _slideController.forward();
    _chartController.forward();
  }

  Future<void> _loadEvents() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;
      
      setState(() => _isLoading = true);
      
      _eventService.getUserEvents(userId).listen((events) {
        setState(() {
          _events = events;
          _filterEventsByTime();
          _isLoading = false;
        });
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading events: $e');
    }
  }

  void _filterEventsByTime() {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (_selectedTimeFilter) {
      case 'Tuần này':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
        break;
      case 'Tháng này':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
        break;
      case '6 tháng qua':
        startDate = DateTime(now.year, now.month - 6, 1);
        break;
      case 'Năm này':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31);
        break;
      case 'Tùy chọn':
        if (_customDateRange != null) {
          startDate = _customDateRange!.start;
          endDate = _customDateRange!.end;
        } else {
          startDate = DateTime(now.year, now.month, 1);
        }
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    _filteredEvents = _events.where((event) {
      return event.startTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
             event.startTime.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  double get _totalExpense {
    return _filteredEvents.fold(0.0, (sum, event) => sum + event.cost);
  }

  double get _averageExpense {
    if (_filteredEvents.isEmpty) return 0.0;
    return _totalExpense / _filteredEvents.length;
  }

  int get _totalEvents {
    return _filteredEvents.length;
  }

  int get _freeEvents {
    return _filteredEvents.where((event) => event.cost == 0).length;
  }

  int get _paidEvents {
    return _filteredEvents.where((event) => event.cost > 0).length;
  }

  // Category-based statistics
  Map<String, double> get _expensesByCategory {
    final Map<String, double> categoryData = {};
    
    for (final event in _filteredEvents) {
      String category;
      if (event.cost == 0) {
        category = 'Miễn phí';
      } else if (event.cost <= 100000) {
        category = 'Chi phí thấp (≤100k)';
      } else if (event.cost <= 500000) {
        category = 'Chi phí trung bình (100k-500k)';
      } else {
        category = 'Chi phí cao (>500k)';
      }
      
      categoryData[category] = (categoryData[category] ?? 0) + event.cost;
    }
    
    return categoryData;
  }

  Map<String, double> get _monthlyExpenses {
    final Map<String, double> monthlyData = {};
    
    for (final event in _filteredEvents) {
      final monthKey = DateFormat('MM/yyyy').format(event.startTime);
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + event.cost;
    }
    
    return monthlyData;
  }

  List<PieChartSectionData> get _pieChartSections {
    final categoryData = _expensesByCategory;
    final total = _totalExpense;
    
    if (total == 0) return [];
    
    final colors = [
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF673AB7),
      const Color(0xFF3F51B5),
      const Color(0xFF2196F3),
      const Color(0xFF00BCD4),
    ];
    
    int colorIndex = 0;
    return categoryData.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<BarChartGroupData> get _barChartData {
    final monthlyData = _monthlyExpenses;
    final sortedEntries = monthlyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    return sortedEntries.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value,
            color: const Color(0xFFE91E63),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  String get _trendComparison {
    if (_filteredEvents.length < 2) return 'Chưa đủ dữ liệu để so sánh';
    
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final previousMonth = DateTime(now.year, now.month - 1, 1);
    
    final currentMonthExpense = _events
        .where((e) => e.startTime.month == now.month && e.startTime.year == now.year)
        .fold(0.0, (sum, event) => sum + event.cost);
        
    final previousMonthExpense = _events
        .where((e) => e.startTime.month == previousMonth.month && e.startTime.year == previousMonth.year)
        .fold(0.0, (sum, event) => sum + event.cost);
    
    if (previousMonthExpense == 0) return 'Tháng trước chưa có chi tiêu';
    
    final percentChange = ((currentMonthExpense - previousMonthExpense) / previousMonthExpense * 100);
    final isIncrease = percentChange > 0;
    
    return '${isIncrease ? '+' : ''}${percentChange.toStringAsFixed(1)}% so với tháng trước';
  }

  String get _eventCountComparison {
    final now = DateTime.now();
    final currentMonthEvents = _events
        .where((e) => e.startTime.month == now.month && e.startTime.year == now.year)
        .length;
        
    final previousMonthEvents = _events
        .where((e) => e.startTime.month == now.month - 1 && e.startTime.year == now.year)
        .length;
    
    if (previousMonthEvents == 0) return 'Tháng trước chưa có sự kiện';
    
    final change = currentMonthEvents - previousMonthEvents;
    if (change == 0) return 'Giữ nguyên so với tháng trước';
    
    return '${change > 0 ? '+' : ''}$change sự kiện so với tháng trước';
  }

  Future<void> _exportStatistics() async {
    try {
      final report = _generateTextReport();
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/expense_report_${DateFormat('ddMMyyyy_HHmmss').format(DateTime.now())}.txt');
      await file.writeAsString(report);
      
      await Share.shareXFiles([XFile(file.path)], text: 'Báo cáo thống kê chi phí');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xuất báo cáo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi xuất báo cáo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateTextReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== BÁO CÁO THỐNG KÊ CHI PHÍ ===');
    buffer.writeln('Thời gian tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
    buffer.writeln('Khoảng thời gian: $_selectedTimeFilter');
    if (_customDateRange != null) {
      buffer.writeln('Từ: ${DateFormat('dd/MM/yyyy').format(_customDateRange!.start)}');
      buffer.writeln('Đến: ${DateFormat('dd/MM/yyyy').format(_customDateRange!.end)}');
    }
    buffer.writeln('');
    
    buffer.writeln('=== TỔNG QUAN ===');
    buffer.writeln('Tổng số sự kiện: $_totalEvents');
    buffer.writeln('Sự kiện miễn phí: $_freeEvents');
    buffer.writeln('Sự kiện có phí: $_paidEvents');
    buffer.writeln('Tổng chi phí: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_totalExpense)}');
    buffer.writeln('Chi phí trung bình: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_averageExpense)}');
    buffer.writeln('');
    
    buffer.writeln('=== XU HƯỚNG ===');
    buffer.writeln('So sánh chi phí: $_trendComparison');
    buffer.writeln('So sánh số lượng: $_eventCountComparison');
    buffer.writeln('');
    
    buffer.writeln('=== CHI TIẾT THEO THÁNG ===');
    final monthlyData = _monthlyExpenses;
    monthlyData.entries.forEach((entry) {
      buffer.writeln('${entry.key}: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(entry.value)}');
    });
    buffer.writeln('');
    
    buffer.writeln('=== PHÂN LOẠI CHI PHÍ ===');
    final categoryData = _expensesByCategory;
    categoryData.entries.forEach((entry) {
      final percentage = (entry.value / _totalExpense * 100);
      buffer.writeln('${entry.key}: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(entry.value)} (${percentage.toStringAsFixed(1)}%)');
    });
    
    return buffer.toString();
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
                const Text(
                  'Thống kê & Tổng hợp',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
              ],
            ),
          ),
          // Export button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _exportStatistics,
              icon: const Icon(
                Icons.share_rounded,
                color: Colors.white,
                size: 24,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.withAlpha((0.2 * 255).round()),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Color(0xFFE91E63),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilterCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
                  Icons.date_range_rounded,
                  color: Color(0xFFE91E63),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Lọc theo thời gian',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeFilterOptions.map((option) {
              final isSelected = _selectedTimeFilter == option;
              return GestureDetector(
                onTap: () async {
                  if (option == 'Tùy chọn') {
                    final DateTimeRange? range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _customDateRange,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFFE91E63),
                              onPrimary: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (range != null) {
                      setState(() {
                        _customDateRange = range;
                        _selectedTimeFilter = option;
                        _filterEventsByTime();
                      });
                    }
                  } else {
                    setState(() {
                      _selectedTimeFilter = option;
                      _filterEventsByTime();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFFE91E63)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFFE91E63)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedTimeFilter == 'Tùy chọn' && _customDateRange != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(_customDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_customDateRange!.end)}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Tổng chi tiêu',
                  value: NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_totalExpense),
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFFE91E63),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Trung bình',
                  value: NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_averageExpense),
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Tổng sự kiện',
                  value: '$_totalEvents sự kiện',
                  icon: Icons.event_rounded,
                  color: const Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Miễn phí',
                  value: '$_freeEvents/$_totalEvents',
                  icon: Icons.free_breakfast_rounded,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
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
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Xu hướng so sánh',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.attach_money_rounded, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chi phí: $_trendComparison',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event_note_rounded, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sự kiện: $_eventCountComparison',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    final sections = _pieChartSections;
    final categoryData = _expensesByCategory;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF673AB7).withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Color(0xFF673AB7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Phân loại chi phí',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (sections.isNotEmpty)
            Column(
              children: [
                ScaleTransition(
                  scale: _chartAnimation,
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categoryData.entries.map((entry) {
                    final index = categoryData.keys.toList().indexOf(entry.key);
                    final colors = [
                      const Color(0xFFE91E63),
                      const Color(0xFF9C27B0),
                      const Color(0xFF673AB7),
                      const Color(0xFF3F51B5),
                      const Color(0xFF2196F3),
                      const Color(0xFF00BCD4),
                    ];
                    final color = colors[index % colors.length];
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            )
          else
            _buildEmptyState('pie_chart_outline', 'Chưa có dữ liệu phân loại'),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final barData = _barChartData;
    final monthlyData = _monthlyExpenses;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF2196F3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Biểu đồ cột theo tháng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (barData.isNotEmpty)
            ScaleTransition(
              scale: _chartAnimation,
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    barGroups: barData,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              NumberFormat.compact(locale: 'vi_VN').format(value),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            final entries = monthlyData.entries.toList()
                              ..sort((a, b) => a.key.compareTo(b.key));
                            if (index >= 0 && index < entries.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  entries[index].key,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: true),
                  ),
                ),
              ),
            )
          else
            _buildEmptyState('bar_chart_outlined', 'Chưa có dữ liệu theo tháng'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String iconName, String message) {
    IconData icon;
    switch (iconName) {
      case 'pie_chart_outline':
        icon = Icons.pie_chart_outline;
        break;
      case 'bar_chart_outlined':
        icon = Icons.bar_chart_outlined;
        break;
      default:
        icon = Icons.error_outline;
    }
    
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thêm một số sự kiện để xem thống kê',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: [
        // Time filter skeleton
        Container(
          margin: const EdgeInsets.all(16),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        // Summary cards skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Charts skeleton
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.all(16),
          height: 280,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 280,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
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
              child: _isLoading
                  ? _buildLoadingSkeleton()
                  : SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildTimeFilterCard(),
                            _buildSummaryCards(),
                            const SizedBox(height: 16),
                            _buildTrendCard(),
                            _buildCategoryPieChart(),
                            _buildBarChart(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _chartController.dispose();
    super.dispose();
  }
} 