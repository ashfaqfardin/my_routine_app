import 'package:flutter/material.dart';
import 'package:my_routine_app/my_home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyRoutineApp',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFF3E0), // Set scaffold background color
        textTheme: TextTheme(
          // Customize text colors
          headlineSmall: TextStyle(
            color: Colors.brown[900], // Dark brown for titles
          ),
          bodyLarge: TextStyle(
            color: Colors.brown[900], // Dark brown for body text
          ),
        ), colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.brown).copyWith(background: const Color(0xFFFFF3E0)),
      ),
      home: const MyRoutineApp(title: 'My Routine App',),
      debugShowCheckedModeBanner: false,
    );
  }
}