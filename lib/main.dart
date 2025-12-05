import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_attend/View/Login.dart';


import 'firebase_options.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);


  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _token;
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.instance.getToken().then((token) {
      setState(() {
        _token = token;
      });
      print('FCM Token: $_token');
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message while in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Xampus Admin',
      theme: _buildTheme(Brightness.light),
      home: Login(),
    );
  }
}

ThemeData _buildTheme(Brightness brightness) {
  final baseScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B82F6),
    brightness: brightness,
  );

  final textTheme = GoogleFonts.interTextTheme(
    brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: baseScheme,
    scaffoldBackgroundColor: brightness == Brightness.dark ? const Color(0xFF0B1220) : const Color(0xFFF7F9FC),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: baseScheme.surface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: baseScheme.onSurface,
      ),
      foregroundColor: baseScheme.onSurface,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: baseScheme.surface,
      surfaceTintColor: baseScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(0),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.dark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: baseScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: baseScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: baseScheme.primary, width: 1.5),
      ),
      labelStyle: TextStyle(color: baseScheme.onSurfaceVariant),
      prefixIconColor: baseScheme.onSurfaceVariant,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: baseScheme.primary,
        foregroundColor: baseScheme.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: baseScheme.primary,
        side: BorderSide(color: baseScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    dividerTheme: DividerThemeData(color: baseScheme.outlineVariant),
    visualDensity: VisualDensity.standard,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: baseScheme.inverseSurface,
      contentTextStyle: TextStyle(color: baseScheme.onInverseSurface),
    ),
  );
}
