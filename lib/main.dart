import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:ip_messanger/models/user_model.dart';
import 'package:ip_messanger/pages/home_page/home_page.dart';
import 'package:ip_messanger/pages/login_page.dart';
import 'package:ip_messanger/services/user_service.dart';
import 'package:ip_messanger/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optimize performance by setting preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IP Messanger',
      theme: appTheme,
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await UserService.getCurrentUser();
      if (!mounted) return;

      setState(() => _isLoading = false);

      if (UserModel.currentUser != null) {
        _navigateToPage(HomePage());
      } else {
        _navigateToPage(LoginPage());
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError("Error Loading Current User!");
    }
  }

  void _navigateToPage(Widget page) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => page));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            _isLoading
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                )
                : const SizedBox.shrink(),
      ),
    );
  }
}
