import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhic_tool/pages/home/home_page.dart';

final Map<String, Color> colorMap = {
  'red': Colors.red,
  'blue': Colors.blue,
  'green': Colors.green,
  'yellow': Colors.yellow,
  'orange': Colors.orange,
  'purple': Colors.purple,
  'grey': Colors.grey,
  'teal': Colors.teal,
  'lime': Colors.lime,
};

final themeColorNotifier = ValueNotifier<Color>(Colors.blue);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  String? savedColorName = prefs.getString('colorSeed');
  themeColorNotifier.value = colorMap[savedColorName] ?? Colors.blue;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: themeColorNotifier,
      builder: (context, color, _) {
        return MaterialApp(
          home: const HomePage(),
          theme: ThemeData(colorSchemeSeed: color),
        );
      },
    );
  }
}
