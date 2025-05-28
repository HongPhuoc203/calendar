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
        initialRoute: '/login',
        routes: {
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
