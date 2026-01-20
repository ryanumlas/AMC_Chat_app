import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';  // ← Points to FULL chat screen
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load the environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Could not load .env file: $e");
  }

  // FIX: Changed MyApp() to ChatApp() to match the class name below
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  // FIX: Added a const constructor so 'const ChatApp()' works
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat UI Lab - Complete ✅',
      theme: ThemeData(
        // Set to dark to match the "cool" UI we built
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ChatScreen(),  // ← Uses your FULL ChatScreen
      debugShowCheckedModeBanner: false,  // Clean screen
    );
  }
}