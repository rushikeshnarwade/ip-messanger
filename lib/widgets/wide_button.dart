import 'package:flutter/material.dart';
import 'package:ip_messanger/theme/app_theme.dart';

class SmallButton extends StatefulWidget {
  final Function() onTap;
  final String text;

  const SmallButton({super.key, required this.onTap, required this.text});

  @override
  State<SmallButton> createState() => _SmallButtonState();
}

class _SmallButtonState extends State<SmallButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_isLoading) {
          return;
        }

        setState(() {
          _isLoading = true;
        });

        await widget.onTap();

        setState(() {
          _isLoading = false;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: Color(0xff4481c1),
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        width: 100,
        child: Center(
          child:
              _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(widget.text, style: appTheme.textTheme.bodyLarge),
        ),
      ),
    );
  }
}
