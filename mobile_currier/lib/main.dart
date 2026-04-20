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
  int _driverId = 0;

  void _onLogin(String name, int id) {
    setState(() {
      _isLoggedIn = true;
      _driverName = name;
      _driverId = id;
    });
  }

  void _onLogout() {
    setState(() {
      _isLoggedIn = false;
      _driverName = '';
      _driverId = 0;
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
          ? HomePage(
              driverName: _driverName,
              driverId: _driverId,
              onLogout: _onLogout,
            )
          : LoginPage(onLogin: _onLogin),
    );
  }
}
