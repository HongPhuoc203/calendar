// import './models/event.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:provider/provider.dart';
// import './screens/auth/login_screen.dart';
// import 'screens/auth/register_screen.dart';
// import 'screens/calendar/calendar_screen.dart';
// import 'screens/events/event_form_screen.dart';
// import 'screens/events/event_detail_screen.dart';
// import 'services/auth_services.dart';
// import 'services/notification_services.dart';
// import 'firebase_options.dart';
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
//   await NotificationService().initialize();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         Provider<AuthService>(
//           create: (_) => AuthService(),
//         ),
//       ],
//       child: MaterialApp(
//         title: 'Calendar App',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//           useMaterial3: true,
//         ),
//         debugShowCheckedModeBanner: false,
//         // Define the initial route and the routes for navigation
//         initialRoute: '/login',
//         routes: {
//           '/login': (context) => const LoginScreen(),
//           '/register': (context) => const RegisterScreen(),
//           '/calendar': (context) => const CalendarScreen(),
//         },
//         onGenerateRoute: (settings) {
//           if (settings.name == '/event-form') {
//             final event = settings.arguments as Event?;
//             return MaterialPageRoute(
//               builder: (context) => EventFormScreen(event: event),
//             );
//           }
//           if (settings.name == '/event-details') {
//             final event = settings.arguments as Event;
//             return MaterialPageRoute(
//               builder: (context) => EventDetailsScreen(event: event),
//             );
//           }
//           return null;
//         },
//       ),
//     );
//   }
// }


import './models/event.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import './screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/events/event_form_screen.dart';
import 'screens/events/event_detail_screen.dart';
import 'services/auth_services.dart';
import 'services/notification_services.dart';
import 'firebase_options.dart';
import 'dart:async';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'Calendar App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        // Thay đổi initial route thành splash screen
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/calendar': (context) => const CalendarScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/event-form') {
            final event = settings.arguments as Event?;
            return MaterialPageRoute(
              builder: (context) => EventFormScreen(event: event),
            );
          }
          if (settings.name == '/event-details') {
            final event = settings.arguments as Event;
            return MaterialPageRoute(
              builder: (context) => EventDetailsScreen(event: event),
            );
          }
          return null;
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Khởi tạo các animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Khởi tạo các animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Bắt đầu animations với độ trễ
    _startAnimations();
    
    // Chuyển đến login screen sau 4 giây
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
    
    await Future.delayed(const Duration(milliseconds: 300));
    _slideController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _rotateController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Color(0xFF1a1a1a),
              Colors.black87,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo hoặc Icon với hiệu ứng xoay và scale
              AnimatedBuilder(
                animation: Listenable.merge([_rotateController, _scaleController]),
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateAnimation.value * 2 * 3.14159,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFF1744), // Đỏ hồng
                              Color(0xFFE91E63), // Hồng
                              Color(0xFFFF1744),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF1744).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Text với hiệu ứng slide và fade
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFF1744),
                        Color(0xFFE91E63),
                        Color(0xFFFF1744),
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'C Global Calendar',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Subtitle với hiệu ứng fade
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Quản lý lịch trình thông minh',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Loading indicator với hiệu ứng
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF1744),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

