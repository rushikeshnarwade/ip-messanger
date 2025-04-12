import 'package:flutter/material.dart';
import 'package:ip_messanger/common/showsnackbar.dart';
import 'package:ip_messanger/models/user_model.dart';
import 'package:ip_messanger/pages/home_page/home_page.dart';
import 'package:ip_messanger/services/auth_service.dart';
import 'package:ip_messanger/widgets/wide_button.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() =>
      _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final GlobalKey _formKey = GlobalKey();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    _emailController.text = "rushikeshnarwade53@gmail.com";
    _usernameController.text = 'rushikeshnarwade';
    _passwordController.text = "12345678";

    return Scaffold(
      appBar: AppBar(title: Text("Signup")),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: ListView(
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: "Username"),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: "Email"),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: "Password"),
                ),
                SizedBox(height: 20),
                SmallButton(onTap: _signup, text: "Signup"),
                SizedBox(height: 20),
                SmallButton(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  text: "Login",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _signup() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await AuthService.signup(username, email, password);
      if (UserModel.currentUser != null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        if (error.toString().contains('auth-error')) {
          showSnackbar(
            context,
            'Not able to signup using provided email and password',
          );
        } else {
          showSnackbar(
            context,
            "Unknown error: please check internet, email and password",
          );
        }
      }
    }
  }
}
