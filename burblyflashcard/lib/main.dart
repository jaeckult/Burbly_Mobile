import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/flashcards/screens/deck_pack_list_screen.dart';
import 'features/flashcards/screens/flashcard_home_screen.dart';
import 'core/core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize DataService
    await DataService().initialize();
    
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
    return MaterialApp(
      title: 'Burbly Flashcard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const WelcomeScreen(),
      routes: {
        '/home': (context) => const DeckPackListScreen(),
        '/flashcards': (context) => const FlashcardHomeScreen(),
      },
    );
  }
}


