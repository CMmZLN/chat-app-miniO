import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/screens/Login/login_form.dart';
import 'package:flutter_frontend/componnets/already_have_an_account_acheck.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({Key? key}) : super(key: key);

  @override
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AuthController authController = AuthController();
  final workSpaceName = TextEditingController();
  final channelName = TextEditingController();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final passwordConfirmation = TextEditingController();

  bool _isLoading = false;

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String error = "";

  void _submitForm() async {
    if (_isLoading) {
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        setState(() {
          _isLoading = true;
        });
        await authController.createUser(
          workSpaceName.text,
          channelName.text,
          name.text,
          email.text,
          password.text,
          passwordConfirmation.text,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginForm()),
        );
      } catch (e) {
        String error = e.toString();
        SnackBar(
            content: Text(
          error,
          style: const TextStyle(color: Colors.red),
        ));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //for cheecking password format
  bool _validatePassword(String password) {
    String _errorMessage = '';

    // Regex pattern for password validation
    RegExp passwordPattern =
        RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$%&*~]).{8,}$');

    if (!passwordPattern.hasMatch(password)) {
      _errorMessage =
          'Password must be at least 8 characters long\nand contain at least one uppercase letter, one low\nercase letter, one digit, and one special character.';
    }

    if (_errorMessage.isEmpty) {
      return true;
    } else {
      setState(() {
        error = _errorMessage;
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 30),
              child: Text(
                "Sign Up",
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: navColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: TextFormField(
                keyboardType: TextInputType.name,
                controller: workSpaceName,
                textInputAction: TextInputAction.next,
                cursorColor: kPrimaryColor,
                decoration: InputDecoration(
                  fillColor: Colors.grey[300],
                  hintText: "WorkSpace Name",
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Icon(
                      Icons.work_outline,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a WorkSpace Name';
                  }
                  return null;
                },
              ),
            ),
             
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: TextFormField(
                controller: channelName,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.done,
                cursorColor: kPrimaryColor,
                decoration: InputDecoration(
                  fillColor: Colors.grey[300],
                  hintText: "Channel Name",
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Icon(
                      Icons.message_outlined,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a Channel Name';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: TextFormField(
                controller: name,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                cursorColor: kPrimaryColor,
                decoration: InputDecoration(
                  fillColor: Colors.grey[300],
                  hintText: "Name",
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Icon(
                      Icons.person_2_outlined,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a Name';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                cursorColor: kPrimaryColor,
                decoration: InputDecoration(
                  fillColor: Colors.grey[300],
                  hintText: "Email",
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Icon(
                      Icons.email_outlined,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an Email';
                  }
                  if (!RegExp(r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
                          caseSensitive: false)
                      .hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: TextFormField(
                controller: password,
                textInputAction: TextInputAction.none,
                obscureText: !_passwordVisible,
                cursorColor: kPrimaryColor,
                decoration: InputDecoration(
                  fillColor: Colors.grey[300],
                  hintText: "Password",
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Icon(
                      Icons.lock,
                      color: Colors.grey[600],
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                    icon: Icon(_passwordVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a Password';
                  } else if (value.length < 8) {
                    return 'Password should have at least 8 characters';
                  } else if (!_validatePassword(value)) {
                    return error;
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: TextFormField(
                controller: passwordConfirmation,
                textInputAction: TextInputAction.done,
                obscureText: !_confirmPasswordVisible,
                cursorColor: kPrimaryColor,
                decoration: InputDecoration(
                  fillColor: Colors.grey[300],
                  hintText: "Re-Enter Password",
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(defaultPadding),
                    child: Icon(
                      Icons.lock_outline,
                      color: Colors.grey[600],
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _confirmPasswordVisible = !_confirmPasswordVisible;
                      });
                    },
                    icon: Icon(_confirmPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please re-enter your confirmpassword';
                  } else if (value.length < 8) {
                    return 'Confirm Password Should have at least 8 characters';
                  } else if (value != password.text) {
                    return 'Password and Confirm are not match';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(
              height: defaultPadding / 2,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(navColor),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!_isLoading)
                      Text("Sign Up".toUpperCase(),
                          style:
                              const TextStyle(fontSize: 16, letterSpacing: 2))
                    else
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      ) // ProgressionBar(
                    //     imageName: 'mailSending2.json',
                    //     height: MediaQuery.sizeOf(context).height,
                    //     size: MediaQuery.sizeOf(context).width)
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: defaultPadding,
            ),
            AlreadyHaveAnAccountCheck(
              login: false,
              press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginForm()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
