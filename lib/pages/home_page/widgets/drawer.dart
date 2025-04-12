import 'package:flutter/material.dart';
import 'package:ip_messanger/main.dart';
import 'package:ip_messanger/models/user_model.dart';
import 'package:ip_messanger/services/auth_service.dart';
import 'package:ip_messanger/theme/app_colors.dart';
import 'package:ip_messanger/widgets/wide_button.dart';

class HomePageDrawer extends StatefulWidget {
  const HomePageDrawer({super.key});

  @override
  State<HomePageDrawer> createState() => _HomePageDrawerState();
}

class _HomePageDrawerState extends State<HomePageDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(5)),
              color: AppColors.background,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 5,
              children: [
                Text(UserModel.currentUser!.username),
                Text(UserModel.currentUser!.email),
                Text(UserModel.currentUser!.ipAddress),
              ],
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: SmallButton(onTap: _logout, text: 'Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthCheck()),
      );
    }
  }
}
