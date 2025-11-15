import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/core/firebase_config.dart';
import 'screens/auth/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuilderConnect',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthCheckScreen(),
      debugShowCheckedModeBanner: false,
      // Thêm localizations để DatePickerDialog hoạt động
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // Tiếng Anh (fallback)
        Locale('vi', 'VN'), // Tiếng Việt (nếu có locale file)
      ],
    );
  }
}

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Luôn hiển thị Login Screen khi khởi động
    // User sẽ đăng nhập và chuyển vào Home
    return const LoginScreen();
  }
}
