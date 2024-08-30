import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/screens/SignUp/signup_screen.dart';

import '../../Login/login_form.dart';

class LoginAndSignupBtn extends StatelessWidget {
  const LoginAndSignupBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginForm()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: navColor,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(30), // Adjust the radius as needed
              ),
            ),
            child: Text(
              'Login'.toString(),
              style: const TextStyle(fontSize: 18, letterSpacing: 1),
            )),
        const SizedBox(
          height: 20,
        ),
        ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SignUpScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: navColor,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(30), // Adjust the radius as needed
              ),
            ),
            child: const Text(
              "Sign Up",
              style: TextStyle(fontSize: 18, letterSpacing: 1),
            ))
      ],
    );
  }
}
