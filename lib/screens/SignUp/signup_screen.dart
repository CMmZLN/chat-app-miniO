import 'package:flutter/widgets.dart';

import 'components/signup_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/responsive.dart';
import 'package:flutter_frontend/componnets/background.dart';
import 'package:flutter_frontend/screens/SignUp/components/sign_up_top_image.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body:
            // Background(
            // child:
            SingleChildScrollView(
      child: Responsive(
          mobile: MobileSignupScreen(),
          desktop: Row(
            children: [
              // Expanded(child: SignUpScreenTopImage()),
              Expanded(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 450,
                    child: SignUpForm(),
                  ),
                  SizedBox(
                    height: defaultPadding / 2,
                  )
                ],
              ))
            ],
          )),
    )
        // ),
        );
  }
}

class MobileSignupScreen extends StatelessWidget {
  const MobileSignupScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [navColor, themeColor2], // Your gradient colors
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
                // child: SvgPicture.asset("assets/icons/login.svg"),
                child: Center(
                  child: Center(
                    child: SizedBox(
                        width: 200,
                        height: 100,
                        child: Image.asset("assets/images/logo2.png")),
                  ),
                )),
            // SignUpScreenTopImage(),
            const SignUpForm(),
            // const SocalSignUp()
          ],
        ),
      ),
    );
  }
}
