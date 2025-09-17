import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/home/home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Criminal Tracking System',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: AppColors.primaryColor,
          scaffoldBackgroundColor: AppColors.backgroundColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
        home: const HomeScreen(), // Start with HomeScreen as requested
        routes: {
          '/home': (context) => const HomeScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}