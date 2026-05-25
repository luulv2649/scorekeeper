import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_store.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = GameStore();
  await store.load();

  runApp(
    ChangeNotifierProvider.value(
      value: store,
      child: const ScoreKeeperApp(),
    ),
  );
}

class ScoreKeeperApp extends StatelessWidget {
  const ScoreKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScoreKeeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD1622A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD1622A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
