import 'package:flutter/material.dart';
import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/componnets/background.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/responsive.dart';
import 'package:flutter_frontend/screens/Login/login_form.dart';
import 'package:flutter_frontend/screens/check_token_status.dart';
import 'package:go_router/go_router.dart';
import 'components/login_signup_btn.dart';
import 'components/welcome_image.dart';

// class WelcomeScreen extends StatefulWidget {
//   WelcomeScreen({super.key, required this.token});

//   var token;

//   @override
//   State<WelcomeScreen> createState() => _WelcomeScreenState();
// }

// class _WelcomeScreenState extends State<WelcomeScreen> {
//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(const Duration(seconds: 3), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//             builder: (context) => widget.token == '' || widget.token == null
//                 ? const LoginForm()
//                 : const Nav()),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         color: const Color.fromARGB(255, 28, 15, 49),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 width: 70,
//                 height: 70,
//                 decoration: const BoxDecoration(
//                     image: DecorationImage(
//                         image: AssetImage("assets/images/logo2.png"))),
//               ),
//               const Padding(
//                 padding: EdgeInsets.symmetric(vertical: 20),
//                 child: Text("Mandalay Team 4",
//                     style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class Splash extends StatefulWidget {
  Splash({super.key, required this.token, required this.isTokenExpired});

  var token;
  bool isTokenExpired;

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      widget.isTokenExpired == true || widget.token == null
          ? context.go('/login')
          : context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color.fromARGB(255, 28, 15, 49),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 100,
                decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/logo2.png"))),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("Welcome to MiMo",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class WelcomeScreen extends StatelessWidget {
//   const WelcomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return
//         // const Background(
//         //     child:
//         Scaffold(
//             body: Stack(
//       children: [
//         Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [navColor, Colors.blue], // Your gradient colors
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//         const SingleChildScrollView(
//           child: SafeArea(
//               child: Responsive(
//                   mobile: MobileWelcomeScreen(),
//                   desktop: Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       Expanded(child: WelcomeImage()),
//                       Expanded(
//                           child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           SizedBox(
//                             width: 450,
//                             child: LoginAndSignupBtn(),
//                           )
//                         ],
//                       ))
//                     ],
//                   ))),
//           // )
//         ),
//       ],
//     ));
//   }
// }

class MobileWelcomeScreen extends StatelessWidget {
  const MobileWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          height: 80,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 50),
          child: Text(
            "Welcome to MiMo",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 30, color: Colors.white),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          decoration: BoxDecoration(
            color: const Color.fromARGB(221, 255, 255, 255),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              WelcomeImage(),
              Row(
                children: [
                  // Spacer(),
                  Expanded(child: LoginAndSignupBtn()),
                  // Spacer()
                ],
              )
            ],
          ),
        ),
      ],
    );
  }
}
