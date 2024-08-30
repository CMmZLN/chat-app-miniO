import 'dart:convert';

import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/screens/Navigation/profle.dart';
import 'package:flutter_frontend/screens/check_token_status.dart';
import 'package:flutter_frontend/screens/profile/profile.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:http/http.dart' as http;

class UserEdit extends StatefulWidget {
  final String? username;
  final String? email;
  final String? workspaceName;
  const UserEdit(
      {Key? key, required this.username, this.email, this.workspaceName})
      : super(key: key);

  @override
  State<UserEdit> createState() => _UserEditState();
}

class _UserEditState extends State<UserEdit> {
  String error = "";
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController _editUserController =
      TextEditingController(text: widget.username);
  bool _isUsernameChanging = false;
  final AuthController _authController = AuthController();
  bool _isTextBoxVisible = false;

  WebSocketChannel? _channel;
  String? username;

  @override
  void initState() {
    super.initState();
    connectWebSocket();
  }

  void connectWebSocket() {
    var url = 'ws://$wsUrl/cable';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    final subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'ProfileChannel'}),
    });

    _channel!.sink.add(subscriptionMessage);
    _channel!.stream.listen(
      (message) {
        try {
          var parsedMessage = jsonDecode(message) as Map<String, dynamic>;

          if (parsedMessage.containsKey('type') &&
              parsedMessage['type'] == 'ping') {
            return;
          }

          if (parsedMessage.containsKey('message')) {
            var messageContent = parsedMessage['message'];
            if (messageContent.containsKey("name")) {
              username = messageContent["name"];
            }
          }
        } catch (e) {
          rethrow;
        }
      },
      onDone: () {
        _channel!.sink.close();
      },
      onError: (error) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
           systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // Transparent status bar
          statusBarIconBrightness:
              Brightness.light,),
          leading: IconButton(
              onPressed: () {
                AuthService.checkTokenStatus(context);
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              )),
          flexibleSpace: Container(
            decoration: themeColor,
          ),
          title: const Text(
            'User Name Edit',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                    key: formKey,
                    child: Column(children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.email,
                            color: Colors.grey,
                          ),
                          title: Text(
                            "${widget.email}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: defaultPadding,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.work,
                            color: Colors.grey,
                          ),
                          title: Text(
                            "${widget.workspaceName}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: defaultPadding / 2,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: defaultPadding),
                        child: TextFormField(
                          controller: _editUserController,
                          textInputAction: TextInputAction.done,
                          cursorColor: kPrimaryColor,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please Enter Your Name';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Enter Your Name",
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(
                                  10), // Set the border radius here
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: _isTextBoxVisible,
                        child: Container(
                          width: 450.0,
                          color: const Color.fromARGB(
                              255, 233, 201, 211), // Background color
                          padding: const EdgeInsets.all(
                              8.0), // Padding around the text
                          child: Center(
                            child: Text(
                              "Name $error",
                              style: const TextStyle(
                                color: Color.fromARGB(
                                    255, 223, 59, 47), // Text color
                                // Add more text styling as needed
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: defaultPadding / 2,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: defaultPadding),
                        child: ElevatedButton(
                          onPressed: () {
                            AuthService.checkTokenStatus(context);
                            editUsername(_editUserController.text.trimRight());
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.all<Color>(navColor),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (!_isUsernameChanging)
                                const Text('Change Username')
                              else
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.0,
                                  ),
                                )
                              // ProgressionBar(
                              //     imageName: 'mailSending2.json',
                              //     height: MediaQuery.sizeOf(context).height,
                              //     size: MediaQuery.sizeOf(context).width)
                            ],
                          ),
                        ),
                      )
                    ]))),
          ),
        ));
  }

  Future<void> editUsername(String username) async {
    var token = await AuthController().getToken();
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      try {
        setState(() {
          _isUsernameChanging = true;
        });
        final response = await http.patch(
            Uri.parse("http://10.0.2.2:3000/m_users/edit_username"),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{"username": username}));
        final body = json.decode(response.body);

        if (response.statusCode == 200) {
          setState(() {
            _isTextBoxVisible = false;

            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('User name has been successfully changed'),
              backgroundColor: Colors.green,
            ));
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Profile(
                        currentUserWorkspace: widget.workspaceName!,
                        name: username)));
          });
        } else if (response.statusCode == 422) {
          setState(() {
            _isTextBoxVisible = true;
            error = body["error_message"]["name"].join("\nName ");
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Failed to change user name'),
              backgroundColor: Colors.red,
            ));
          });
        }
      } catch (e) {
        print("error $e");

        rethrow;
      } finally {
        setState(() {
          _isUsernameChanging = false;
        });
      }
    }
  }
}
