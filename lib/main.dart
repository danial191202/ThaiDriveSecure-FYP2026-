import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const FirebaseInitializer(),
    );
  }
}

/// ===============================
/// FIREBASE INITIALIZER WIDGET
/// ===============================
class FirebaseInitializer extends StatelessWidget {
  const FirebaseInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        /// Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        /// Error
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                "Firebase Error:\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        /// Success
        return const WelcomePage();
      },
    );
  }
}