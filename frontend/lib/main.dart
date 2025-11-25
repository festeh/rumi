import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/notes_provider.dart';
import 'services/theme_provider.dart';
import 'services/asr_settings_provider.dart';
import 'services/audio_service.dart';

void main() {
  // Validate required environment variables at startup
  AudioService.validateConfig();

  runApp(const RumiApp());
}

class RumiApp extends StatelessWidget {
  const RumiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ASRSettingsProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Rumi - Daily Notes',
            theme: themeProvider.themeData,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}