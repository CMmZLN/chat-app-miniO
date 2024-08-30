import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/theme/app_color.dart';
import 'package:flutter_frontend/screens/signup/signup_screen.dart';
import 'package:flutter_frontend/componnets/already_have_an_account_acheck.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:go_router/go_router.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({Key? key}) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _workspaceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthController _authController = AuthController();
  bool _isLoading = false;

  Future<void> _signIn(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      _formKey.currentState!.save();
      int? status = await _authController.loginUser(
          _nameController.text.trimRight(),
          _passwordController.text.trimRight(),
          _workspaceController.text.trimRight(),
          context);

      setState(() {
        _isLoading = false;
      });

      if (status == 200) {
        _nameController.clear();
        _passwordController.clear();
        _workspaceController.clear();
        // ignore: use_build_context_synchronously

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Sign In Successful!',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ));
        // ignore: use_build_context_synchronously
        context.go("/home");
        // Navigator.push(
        //     context, MaterialPageRoute(builder: (context) => const Nav()));
      } else if (status == 401) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Account Deactivate. Please contact admin.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
      } else if (status == 404) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid workspace name combination'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
      } else if (status == 422) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid name/password combination'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
      } else if (status == 500) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User name does not exist'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _workspaceController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   resizeToAvoidBottomInset: true,
    //   body: Stack(
    //     children: [
    //       Container(
    //         decoration: const BoxDecoration(
    //           gradient: LinearGradient(
    //             colors: [navColor, Colors.blue], // Your gradient colors
    //             begin: Alignment.topLeft,
    //             end: Alignment.bottomRight,
    //           ),
    //         ),
    //       ),
    //       SingleChildScrollView(
    //         padding: const EdgeInsets.all(24),
    //         child: Column(
    //           children: [
    //             const SizedBox(height: 50),
    //             const SizedBox(
    //                 height: 100,
    //                 width: 250,
    //                 // child: SvgPicture.asset("assets/icons/login.svg"),
    //                 child: Center(
    //                   child: Text(
    //                     "Login",
    //                     style: TextStyle(
    //                         fontSize: 40,
    //                         fontWeight: FontWeight.bold,
    //                         letterSpacing: 2,
    //                         color: Colors.white),
    //                   ),
    //                 )),
    //             const SizedBox(
    //               height: 50,
    //             ),
    //             Container(
    //               decoration: BoxDecoration(
    //                 // color: const Color.fromARGB(188, 255, 255, 255),
    //                 color: Colors.white,
    //                 borderRadius: BorderRadius.circular(16),
    //               ),
    //               padding:
    //                   const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
    //               child: Padding(
    //                 padding: const EdgeInsets.symmetric(vertical: 6),
    //                 child: Form(
    //                   key: _formKey,
    //                   child: Column(
    //                     mainAxisSize: MainAxisSize.min,
    //                     children: [
    //                       TextFormField(
    //                         controller: _nameController,
    //                         keyboardType: TextInputType.name,
    //                         textInputAction: TextInputAction.next,
    //                         cursorColor: kPrimaryColor,
    //                         decoration: InputDecoration(
    //                           hintText: "Your Name",
    //                           prefixIcon: Padding(
    //                             padding: const EdgeInsets.all(defaultPadding),
    //                             child:
    //                                 Icon(Icons.person, color: Colors.grey[600]),
    //                           ),
    //                         ),
    //                         validator: (value) {
    //                           if (value == null || value.isEmpty) {
    //                             return 'Please enter your name';
    //                           }
    //                           return null;
    //                         },
    //                       ),
    //                       const SizedBox(height: 20),
    //                       TextFormField(
    //                         controller: _passwordController,
    //                         textInputAction: TextInputAction.done,
    //                         obscureText: true,
    //                         cursorColor: kPrimaryColor,
    //                         decoration: InputDecoration(
    //                           hintText: "Your password",
    //                           prefixIcon: Padding(
    //                             padding: const EdgeInsets.all(defaultPadding),
    //                             child: Icon(
    //                               Icons.lock,
    //                               color: Colors.grey[600],
    //                             ),
    //                           ),
    //                         ),
    //                         validator: (value) {
    //                           if (value == null || value.isEmpty) {
    //                             return 'Please enter your password';
    //                           }
    //                           return null;
    //                         },
    //                       ),
    //                       const SizedBox(height: 20),
    //                       TextFormField(
    //                         controller: _workspaceController,
    //                         textInputAction: TextInputAction.next,
    //                         cursorColor: kPrimaryColor,
    //                         decoration: InputDecoration(
    //                           hintText: "Your Workspace Name",
    //                           prefixIcon: Padding(
    //                             padding: const EdgeInsets.all(defaultPadding),
    //                             child: Icon(
    //                               Icons.work,
    //                               color: Colors.grey[600],
    //                             ),
    //                           ),
    //                         ),
    //                         validator: (value) {
    //                           if (value == null || value.isEmpty) {
    //                             return 'Please enter your workspace name';
    //                           }
    //                           return null;
    //                         },
    //                       ),
    //                       const SizedBox(height: 36),
    //                       SizedBox(
    //                         width: MediaQuery.of(context).size.width,
    //                         height: 54,
    //                         child: ElevatedButton(
    //                           onPressed: _isLoading
    //                               ? null
    //                               : () async => await _signIn(context),
    //                           style: ButtonStyle(
    //                             backgroundColor:
    //                                 MaterialStateProperty.all<Color>(navColor),
    //                           ),
    //                           child: _isLoading
    //                               ? const SizedBox(
    //                                   width: 24,
    //                                   height: 24,
    //                                   child: CircularProgressIndicator(
    //                                     color: Colors.white,
    //                                   ),
    //                                 )
    //                               : Text(
    //                                   "Login".toUpperCase(),
    //                                   style: const TextStyle(
    //                                       fontSize: 16, letterSpacing: 2),
    //                                 ),
    //                         ),
    //                       ),
    //                       const SizedBox(height: 32),
    //                       AlreadyHaveAnAccountCheck(
    //                         press: () {
    //                           Navigator.push(
    //                             context,
    //                             MaterialPageRoute(
    //                               builder: (context) => const SignUpScreen(),
    //                             ),
    //                           );
    //                         },
    //                       ),
    //                     ],
    //                   ),
    //                 ),
    //               ),
    //             ),
    //           ],
    //         ),
    //       ),
    //     ],
    //   ),
    // );

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [navColor, themeColor2], // Your gradient colors
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Center(
                        child: SizedBox(
                            width: 200,
                            height: 100,
                            child: Image.asset("assets/images/logo2.png")),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(240, 255, 255, 255),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, -2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(0, 0, 0, 40),
                            child: Text(
                              "Login",
                              style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: navColor),
                            ),
                          ),
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            cursorColor: kPrimaryColor,
                            decoration: InputDecoration(
                              fillColor: Colors.grey[300],
                              hintText: "Your Name",
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(defaultPadding),
                                child:
                                    Icon(Icons.person, color: Colors.grey[600]),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            textInputAction: TextInputAction.done,
                            obscureText: true,
                            cursorColor: kPrimaryColor,
                            decoration: InputDecoration(
                              fillColor: Colors.grey[300],
                              hintText: "Your password",
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(defaultPadding),
                                child: Icon(
                                  Icons.lock,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _workspaceController,
                            textInputAction: TextInputAction.next,
                            cursorColor: kPrimaryColor,
                            decoration: InputDecoration(
                              fillColor: Colors.grey[300],
                              hintText: "Your Workspace Name",
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(defaultPadding),
                                child: Icon(
                                  Icons.work,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your workspace name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 36),
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async => await _signIn(context),
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(navColor),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      "Login".toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 16, letterSpacing: 2),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          AlreadyHaveAnAccountCheck(
                            press: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUpScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
