import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'firebase_options.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/flashcards/screens/deck_pack_list_screen.dart';
import 'features/flashcards/screens/flashcard_home_screen.dart';
import 'core/core.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_service.dart';
import 'core/services/adaptive_theme_service.dart';
import 'core/services/pet_service.dart';

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
      initial: AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => MaterialApp(
        title: 'Burbly Flashcard',
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: darkTheme,
        home: const WelcomeScreen(),
        routes: {
          '/home': (context) => const DeckPackListScreen(),
          '/flashcards': (context) => const FlashcardHomeScreen(),
          '/transitions': (context) => const TransitionDemoScreen(),
        },
      ),
    );
  }
}


