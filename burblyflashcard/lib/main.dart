import 'package:flutter/material.dart';
// duplicate import removed
import 'package:firebase_core/firebase_core.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'firebase_options.dart';
// import 'features/auth/auth_service.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/flashcards/screens/deck_pack_list_screen.dart';
import 'features/flashcards/screens/flashcard_home_screen.dart';
import 'core/core.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_service.dart';
import 'core/services/adaptive_theme_service.dart';
import 'core/services/pet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize core services
    await DataService().initialize();
    
    // Verify data persistence after initialization
    try {
      final dataService = DataService();
      final integrityCheck = await dataService.checkDataIntegrity();
      print('Data integrity check completed: ${integrityCheck['status']}');
    } catch (e) {
      print('Warning: Could not verify data integrity: $e');
    }
    
    // Initialize NotificationService with error handling
    try {
      await NotificationService().initialize();
      print('Notification service initialized successfully');
    } catch (e) {
      print('Warning: Notification service failed to initialize: $e');
      // Continue without notifications rather than crashing the app
    }
    
    // Initialize other services
    await PetService().initialize();
    
    // Start background service after notifications are set up
    try {
      await BackgroundService().start();
      print('Background service started successfully');
    } catch (e) {
      print('Warning: Background service failed to start: $e');
    }
    
    runApp(const MyApp());
  } catch (e) {
    print('Error during app initialization: $e');
    // Still run the app even if initialization fails
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: AdaptiveThemeService.lightTheme,
      dark: AdaptiveThemeService.darkTheme,
      initial: AdaptiveThemeMode.dark,
      builder: (theme, darkTheme) => MaterialApp(
        title: 'Burbly Flashcard',
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: darkTheme,
        navigatorKey: NotificationService().navigatorKey,
        home: const _RootScreen(),
        routes: {
          '/home': (context) => const DeckPackListScreen(),
          '/flashcards': (context) => const FlashcardHomeScreen(),
          '/transitions': (context) => const TransitionDemoScreen(),
        },
      ),
    );
  }
}


class _RootScreen extends StatefulWidget {
  const _RootScreen({Key? key}) : super(key: key);

  @override
  State<_RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<_RootScreen> {
  Widget? _screen;

  @override
  void initState() {
    super.initState();
    _decideStart();
  }

  Future<void> _decideStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
      final isGuestMode = prefs.getBool('isGuestMode') ?? false;
      final currentUser = FirebaseAuth.instance.currentUser;

      // Only show welcome/login on fresh install; otherwise go straight to home
      if (isFirstLaunch) {
        setState(() => _screen = const WelcomeScreen());
      } else if (!isGuestMode && currentUser == null) {
        // If not first launch but no signed-in user and not in guest mode, show welcome
        setState(() => _screen = const WelcomeScreen());
      } else {
        setState(() => _screen = const DeckPackListScreen());
      }
    } catch (_) {
      // Fallback to home
      setState(() => _screen = const DeckPackListScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_screen == null) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF5F7FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              'burbly',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Colors.black87,
                  ) ?? const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: Colors.black87,
                  ),
            ),
          ),
        ),
      );
    }
    return _screen!;
  }
}


