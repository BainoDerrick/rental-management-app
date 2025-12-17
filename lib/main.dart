import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rental_management_app/screens/add_tenant_screen.dart';
import 'package:rental_management_app/screens/splash_screen.dart';
import 'firebase_options.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('app_icon');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Initialize flutter_libphonenumber
  await FlutterLibphonenumber().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1E88E5);
    const accentYellow = Color(0xFFFFCA28);

    return MaterialApp(
      title: 'Rental Management App',
      theme: ThemeData(
        // Set primary color to match the app's theme
        primarySwatch: Colors.blue,
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: Colors.white, // Changed to white for consistency with gradient backgrounds
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Poppins', // Apply Poppins font globally
        appBarTheme: const AppBarTheme(
          elevation: 0,
          color: primaryBlue,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        textTheme: const TextTheme(
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: primaryBlue),
          ),
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.black87,
          ),
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.grey[400],
          ),
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          secondary: accentYellow,
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}