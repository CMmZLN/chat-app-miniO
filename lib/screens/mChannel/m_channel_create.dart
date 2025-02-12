import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/screens/check_token_status.dart';
import 'package:flutter_frontend/services/mChannelService/m_channel_services.dart';

class MChannelCreate extends StatefulWidget {
  const MChannelCreate({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MChannelCreateState createState() => _MChannelCreateState();
}

String workSpaceName =
    SessionStore.sessionData!.mWorkspace!.workspaceName!.toString();

class _MChannelCreateState extends State<MChannelCreate> {
  final MChannelServices _mChannelService = MChannelServices();
  final TextEditingController _channelNameController = TextEditingController();
  String _currentOption = 'Public-Anyone in $workSpaceName'; // Default option
  bool isTokenExpired = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPriamrybackground,
      appBar: AppBar(
         systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // Transparent status bar
          statusBarIconBrightness:
              Brightness.light,),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Create a Channel',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AuthService.checkTokenStatus(context);
              _createChannel();
            },
            child: const Text(
              'Create',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: themeColor,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _channelNameController,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              cursorColor: Colors.blue, // Change to your desired color
              decoration: const InputDecoration(
                hintText: "Write Your Channel Name",
                prefixIcon: Icon(
                  Icons.group_add,
                  color: Color.fromARGB(255, 77, 76, 76),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Visibility',
              style: TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                ListTile(
                  title: Text('Public-Anyone in ${workSpaceName.toString()}'),
                  leading: Radio(
                    activeColor: navColor,
                    value: 'Public',
                    groupValue: _currentOption,
                    onChanged: (value) {
                      setState(() {
                        _currentOption = value!;
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Private-Only specific people'),
                  leading: Radio(
                    activeColor: navColor,
                    value: 'Private',
                    groupValue: _currentOption,
                    onChanged: (value) {
                      setState(() {
                        _currentOption = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createChannel() async {
    try {
      final String channelName = _channelNameController.text.trim();
      final int channelStatus = _currentOption == 'Private' ? 0 : 1;
      await _mChannelService.createChannel(channelName, channelStatus);

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Channel created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // ignore: use_build_context_synchronously
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Nav(),
          ));
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create channel'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
