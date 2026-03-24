import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const CourierApp());
}

class CourierApp extends StatefulWidget {
  const CourierApp({super.key});

  @override
  State<CourierApp> createState() => _CourierAppState();
}

class _CourierAppState extends State<CourierApp> {
  bool _isLoggedIn = false;
  String _driverName = '';

  void _onLogin(String name) {
    setState(() {
      _isLoggedIn = true;
      _driverName = name;
    });
  }

  void _onLogout() {
    setState(() {
      _isLoggedIn = false;
      _driverName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Courier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      home: _isLoggedIn
          ? HomePage(driverName: _driverName, onLogout: _onLogout)
          : LoginPage(onLogin: _onLogin),
    );
  }
}
