import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/model/confirm.dart';
import 'package:flutter_frontend/screens/Login/login_form.dart';
import 'package:flutter_frontend/services/confirmInvitation/confirm_member_invitation.dart';
import 'package:flutter_frontend/services/confirmInvitation/confirm_invitation_service.dart';

class ConfirmPage extends StatefulWidget {
  final int? channelId;
  final String? email;
  final int? workspaceId;

  const ConfirmPage({Key? key, this.channelId, this.email, this.workspaceId})
      : super(key: key);

  @override
  State<ConfirmPage> createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  Future<Confirm>? _confirmFuture;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final _apiService = MemberInvitation();

  bool _isLoading = false;

  String? channelName;
  String? workspaceName;
  String error = "";

  void _submitForm(BuildContext context) async {
    if (_isLoading) {
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        setState(() {
          _isLoading = true;
        });
        await _apiService.memberInvitationConfirm(
          passwordController.text,
          confirmPasswordController.text,
          nameController.text,
          widget.email!,
          channelName!,
          workspaceName!,
          widget.workspaceId!,
        );

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Sign Up Successful!',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ));

        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginForm(),
            ));
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'SignUp Failed. Please check your network connection or try again later.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _confirmFuture = ConfirmInvitationService(Dio(BaseOptions(headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    }))).getConfirmData(widget.channelId!, widget.email!, widget.workspaceId!);
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
    return Scaffold(
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   flexibleSpace: Container(
      //     decoration: themeColor,
      //   ),
      //   title: const Center(
      //     child: Text(
      //       'Confirm Invitation',
      //       style: TextStyle(color: Colors.white),
      //     ),
      //   ),
      // ),
      body: FutureBuilder<Confirm>(
        future: _confirmFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // return const ProgressionBar(
            //   imageName: 'waiting.json',
            //   height: 200,
            //   size: 200,
            // );
            return const CircularProgressIndicator();
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Text('Error occurred or data is null');
          } else {
            var muser = snapshot.data!;
            channelName = muser.mUser!.profileImage;
            workspaceName = muser.mUser!.rememberDigest;

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [navColor, themeColor2], // Your gradient colors
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
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
                    Container(
                      height: MediaQuery.of(context).size.height * 0.8,
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
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Center(
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(0, 10, 0, 30),
                                child: Text(
                                  "Sign Up",
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                      color: navColor),
                                ),
                              ),
                              Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextFormField(
                                      initialValue: channelName,
                                      enabled: false,
                                      decoration: InputDecoration(
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.all(
                                              defaultPadding),
                                          child: Icon(
                                            Icons.message_outlined,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      initialValue: widget.email,
                                      enabled: false,
                                      decoration: InputDecoration(
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.all(
                                              defaultPadding),
                                          child: Icon(
                                            Icons.email_outlined,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      initialValue: workspaceName,
                                      enabled: false,
                                      decoration: InputDecoration(
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.all(
                                              defaultPadding),
                                          child: Icon(
                                            Icons.work_outline,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.done,
                                      controller: nameController,
                                      decoration: InputDecoration(
                                        hintText: 'Name',
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.all(
                                              defaultPadding),
                                          child: Icon(
                                            Icons.person_2_outlined,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter Your Name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.done,
                                      controller: passwordController,
                                      obscureText: !_passwordVisible,
                                      decoration: InputDecoration(
                                        hintText: 'Password',
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.all(
                                              defaultPadding),
                                          child: Icon(
                                            Icons.lock,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _passwordVisible =
                                                  !_passwordVisible;
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
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.done,
                                      controller: confirmPasswordController,
                                      obscureText: !_confirmPasswordVisible,
                                      decoration: InputDecoration(
                                        hintText: 'Password Confirmation',
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.all(
                                              defaultPadding),
                                          child: Icon(
                                            Icons.lock_outline,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _confirmPasswordVisible =
                                                  !_confirmPasswordVisible;
                                            });
                                          },
                                          icon: Icon(_confirmPasswordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please re-enter your password confirmation';
                                        } else if (value.length < 8) {
                                          return 'Confirm Password Should have at least 8 characters';
                                        } else if (value !=
                                            passwordController.text) {
                                          return 'Password and Confirm are not match';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () async {
                                        _isLoading
                                            ? null
                                            : _submitForm(context);
                                      },
                                      style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                navColor),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          if (!_isLoading)
                                            const Text("Confirm",
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    letterSpacing: 1))
                                          else
                                            const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.0,
                                              ),
                                            ) // ProgressionBar
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
