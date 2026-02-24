import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// The root widget for the application.
class MyApp extends StatelessWidget {
  /// Creates the root widget for the Flutter application.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_frontend',
      home: const HelloWorldHomePage(),
    );
  }
}

/// A minimal home screen that shows a centered "Hello World" message.
class HelloWorldHomePage extends StatelessWidget {
  /// Creates the Hello World home page.
  const HelloWorldHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(
        title: Text('flutter_frontend'),
      ),
      body: Center(
        child: Text('Hello World'),
      ),
    );
  }
}
