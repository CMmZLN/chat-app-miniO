import 'dart:convert';

import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/model/SessionState.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/confirm.dart';
import 'package:flutter_frontend/model/groupMessage.dart';
import '../../groupMessage/groupMessage.dart';

import 'package:flutter_frontend/services/mChannelService/m_channel_services.dart';
import 'package:flutter_frontend/services/groupMessageService/group_message_service.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_svg/svg.dart';

import 'package:flutter_frontend/services/groupMessageService/gropMessage/groupMessage_Services.dart';

enum ChannelType { public, private }

class DrawerPage extends StatefulWidget {
  final dynamic channelName, memberCount, channelStatus, channelId;
  dynamic memberName;
  dynamic adminID;
  dynamic member;

  DrawerPage(
      {super.key,
      this.channelName,
      this.adminID,
      this.memberCount,
      this.channelStatus,
      this.member,
      this.channelId,
      this.memberName});

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

String workSpaceName =
    SessionStore.sessionData!.mWorkspace!.workspaceName.toString();

class _DrawerPageState extends State<DrawerPage> {
  bool light = false;
  final TextEditingController _channelNameController = TextEditingController();
  ChannelType? currentOption;
  final _apiService = GroupMessageServiceImpl();
  WebSocketChannel? _channel;
  RetrieveGroupMessage? retrieveGroupMessage;

  final groupMessageService = GroupMessageServices(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));

  @override
  void initState() {
    super.initState();
    loadMessage();
    connectWebSocket();
    setState(() {
      currentOption =
          widget.channelStatus ? ChannelType.public : ChannelType.private;
    });
  }

  void loadMessage() async {
    var token = await AuthController().getToken();
    GroupMessgeModel data =
        await groupMessageService.getAllGpMsg(widget.channelId, token!);

    setState(() {
      retrieveGroupMessage = data.retrieveGroupMessage!;
    });
  }

  void connectWebSocket() {
    var url = 'ws://$wsUrl/cable';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    final subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'ChannelUserChannel'}),
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

            if (messageContent != null &&
                messageContent.containsKey('message')) {
              loadMessage();
            }
          } else {}
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
    if (retrieveGroupMessage != null) {
      widget.member = retrieveGroupMessage!.mChannelUsers;
      widget.adminID = retrieveGroupMessage!.create_admin;
    }
    dynamic notAdded = [];
    widget.memberName.forEach((member) {
      if (!widget.member.map((e) => e.name).contains(member.name)) {
        notAdded.add(member);
      }
    });

    int? currentID = SessionStore.sessionData!.currentUser!.id;
    int? channelAdmin = widget.adminID[0]!.userid!;
    int? memberNo = notAdded.length.toInt();

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.3,
            padding: const EdgeInsets.all(10),
            decoration: themeColor,
            child: Center(
              child: ListTile(
                leading: widget.channelStatus
                    ? const Icon(
                        Icons.tag,
                        size: 50,
                        // color: Color(0xFF2F3C7E),
                        color: Colors.white,
                      )
                    : const Icon(Icons.lock, size: 40, color: Colors.white),
                title: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    widget.channelName,
                    style: const TextStyle(
                        fontSize: 30,
                        // color: Color(0xFF2F3C7E),
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                subtitle: Text(
                  '${widget.member.toList().length} : member',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // see membert
                GestureDetector(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: SingleChildScrollView(
                              child: Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.4,
                                child: ListView.builder(
                                    itemCount: widget.member.toList().length,
                                    itemBuilder: (context, index) {
                                      bool? memberActive =
                                          widget.member[index].activeStatus;
                                      String? profileImages =
                                          widget.member[index].profileImage;

                                      if (profileImages != null && !kIsWeb) {
                                        profileImages =
                                            MinioToIP.replaceMinioWithIP(
                                                profileImages,
                                                ipAddressForMinio);
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            left: 10, top: 7, right: 10),
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                              color: Colors.grey.shade400,
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: ListTile(
                                              leading: Stack(
                                                children: [
                                                  Container(
                                                    height: 40,
                                                    width: 40,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      color: Colors.grey[300],
                                                    ),
                                                    child: Center(
                                                      child: profileImages ==
                                                                  null ||
                                                              profileImages
                                                                  .isEmpty
                                                          ? const Icon(
                                                              Icons.person)
                                                          : ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              child:
                                                                  Image.network(
                                                                profileImages,
                                                                fit: BoxFit
                                                                    .cover,
                                                                width: 40,
                                                                height: 40,
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    right: 0,
                                                    bottom: 0,
                                                    child: Container(
                                                      height: 10,
                                                      width: 10,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(7),
                                                        border: Border.all(
                                                          color: Colors.white,
                                                          width: 1,
                                                        ),
                                                        color:
                                                            memberActive == true
                                                                ? Colors.green
                                                                : Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              title: Text(widget
                                                  .member[index].name
                                                  .toString()),
                                              trailing: currentID !=
                                                          widget.member[index]
                                                              .id &&
                                                      channelAdmin !=
                                                          widget.member[index]
                                                              .id &&
                                                      currentID == channelAdmin
                                                  ? IconButton(
                                                      onPressed: () {
                                                        var response = _apiService
                                                            .deleteMember(
                                                                widget
                                                                    .member[
                                                                        index]
                                                                    .id,
                                                                widget
                                                                    .channelId);
                                                        response.whenComplete(
                                                            () => Navigator.pop(
                                                                context));
                                                      },
                                                      icon: const Icon(Icons
                                                          .logout_outlined),
                                                    )
                                                  : null),
                                        ),
                                      );
                                    }),
                              ),
                            )));
                  },
                  child: const ListTile(
                    leading: Icon(
                      Icons.people_alt_outlined,
                    ),
                    title: Text(
                      'See Member',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                //add button
                GestureDetector(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) => Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    const Text(
                                      'Member Add',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                    memberNo == 0
                                        ? SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.5,
                                            child: SvgPicture.asset(
                                              "assets/images/null1.svg",
                                              color: navColor,
                                            ),
                                          )
                                        : SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.4,
                                            child: ListView.builder(
                                                itemCount:
                                                    notAdded.length.toInt(),
                                                itemBuilder: (context, index) {
                                                  int userID = notAdded[index]
                                                      .id
                                                      .toInt();
                                                  String? notAddprofileImage =
                                                      notAdded[index]
                                                          .profileImage;

                                                  if (notAddprofileImage !=
                                                          null &&
                                                      !kIsWeb) {
                                                    notAddprofileImage = MinioToIP
                                                        .replaceMinioWithIP(
                                                            notAddprofileImage,
                                                            ipAddressForMinio);
                                                  }
                                                  return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 10,
                                                              right: 10,
                                                              top: 8),
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    10),
                                                            decoration: BoxDecoration(
                                                                color: Colors
                                                                    .grey
                                                                    .shade400,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10)),
                                                            child: ListTile(
                                                                leading:
                                                                    Container(
                                                                  height: 40,
                                                                  width: 40,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10),
                                                                    color: Colors
                                                                            .grey[
                                                                        300],
                                                                  ),
                                                                  child: Center(
                                                                    child: notAddprofileImage ==
                                                                                null ||
                                                                            notAddprofileImage
                                                                                .isEmpty
                                                                        ? const Icon(
                                                                            Icons.person)
                                                                        : ClipRRect(
                                                                            borderRadius:
                                                                                BorderRadius.circular(10),
                                                                            child:
                                                                                Image.network(
                                                                              notAddprofileImage,
                                                                              fit: BoxFit.cover,
                                                                              width: 40,
                                                                              height: 40,
                                                                            ),
                                                                          ),
                                                                  ),
                                                                ),
                                                                title: Text(notAdded[
                                                                        index]
                                                                    .name
                                                                    .toString()),
                                                                trailing:
                                                                    IconButton(
                                                                        onPressed:
                                                                            () {
                                                                          var response = MChannelServices().channelJoin(
                                                                              userID,
                                                                              widget.channelId);

                                                                          response
                                                                              .whenComplete(() {
                                                                            Navigator.pop(context);
                                                                          });
                                                                        },
                                                                        icon:
                                                                            const Icon(
                                                                          Icons
                                                                              .add,
                                                                        ))),
                                                          ),
                                                        ],
                                                      ));
                                                })),
                                  ],
                                ),
                              ),
                            ));
                  },
                  child: const ListTile(
                      leading: Icon(Icons.add),
                      title: Text(
                        'Member Add',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      )),
                ),

                //Leave Channel
                channelAdmin == currentID
                    ? const ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: Colors.grey,
                        ),
                        title: Text(
                          'Leave Channel',
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold),
                        ))
                    : GestureDetector(
                        onTap: () {
                          var response = _apiService.deleteMember(
                              currentID!, widget.channelId);
                          response.whenComplete(() => Navigator.push(context,
                              MaterialPageRoute(builder: (context) => Nav())));
                        },
                        child: const ListTile(
                            leading: Icon(
                              Icons.logout,
                            ),
                            title: Text(
                              'Leave Channel',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            )),
                      ),
                // Edit Button
                channelAdmin == currentID
                    ? GestureDetector(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return StatefulBuilder(
                                    builder: ((context, setState) {
                                  return AlertDialog(
                                    title: const Text("Edit Channel"),
                                    content: SingleChildScrollView(
                                      child: SizedBox(
                                        width: 300,
                                        child: Column(
                                          children: [
                                            const SizedBox(
                                              height: 15,
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: TextFormField(
                                                controller:
                                                    _channelNameController,
                                                keyboardType:
                                                    TextInputType.name,
                                                textInputAction:
                                                    TextInputAction.next,
                                                cursorColor: Colors
                                                    .blue, // Change to your desired color
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor: Colors.grey[
                                                      200], // Change to your desired background color
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.0), // Adjust border radius as needed
                                                    borderSide: const BorderSide(
                                                        width:
                                                            1), // No side border
                                                  ),
                                                  hintText:
                                                      "${widget.channelName}",
                                                  prefixIcon: Icon(
                                                    Icons.edit,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                validator: (value) {
                                                  if (value!.length > 15) {
                                                    return 'Channel name too long!';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                            Column(
                                              children: [
                                                RadioListTile<ChannelType>(
                                                  activeColor: navColor,
                                                  title: const Text(
                                                      'Public - Anyone'),
                                                  value: ChannelType.public,
                                                  groupValue: currentOption,
                                                  onChanged:
                                                      (ChannelType? value) {
                                                    setState(() {
                                                      currentOption = value!;
                                                    });
                                                  },
                                                ),
                                                RadioListTile<ChannelType>(
                                                  activeColor: navColor,
                                                  title: const Text('Private'),
                                                  value: ChannelType.private,
                                                  groupValue: currentOption,
                                                  onChanged:
                                                      (ChannelType? value) {
                                                    setState(() {
                                                      currentOption = value!;
                                                    });
                                                  },
                                                ),
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10,
                                                          right: 10,
                                                          top: 5,
                                                          bottom: 5),
                                                  child: SizedBox(
                                                    width: 300,
                                                    height: 55,
                                                    child: TextButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            30.0), // Adjust the radius as needed
                                                              ),
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          20,
                                                                      vertical:
                                                                          10),
                                                              backgroundColor:
                                                                  navColor
                                                              // Change to your desired background color
                                                              ),
                                                      onPressed: () {
                                                        editChannel(
                                                            widget.channelId);
                                                        print(
                                                            _channelNameController
                                                                .text.length);
                                                      },
                                                      child: const Text(
                                                        "Edit",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16),
                                                      ),
                                                      // child: const Center(
                                                      //   child: ListTile(
                                                      //     leading: Icon(
                                                      //       Icons.edit,
                                                      //       color: Colors.white,
                                                      //     ),
                                                      //     title: Text(
                                                      //       "Edit",
                                                      //       style: TextStyle(
                                                      //           color: Colors
                                                      //               .white,
                                                      //           fontWeight:
                                                      //               FontWeight
                                                      //                   .bold),
                                                      //     ),
                                                      //   ),
                                                      // )
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 15,
                                                )
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }));
                              });
                        },
                        child: const ListTile(
                            leading: Icon(Icons.edit),
                            title: Text(
                              'Edit Channel',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            )),
                      )
                    : const ListTile(
                        leading: Icon(
                          Icons.edit,
                          color: Colors.grey,
                        ),
                        title: Text('Edit Channel',
                            style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
          ),
          const SizedBox(
            height: 50,
          ),
          //delete channel
          channelAdmin == currentID
              ? GestureDetector(
                  onTap: () {
                    _apiService
                        .deleteChannel(widget.channelId)
                        .then((value) => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Nav(),
                            )));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Channel delete successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const ListTile(
                    leading: Icon(Icons.delete),
                    title: Text(
                      'Delete Channel',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : const ListTile(
                  leading: Icon(Icons.delete, color: Colors.grey),
                  title: Text('Delete Channel',
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                )
        ],
      ),
    );
  }

  void editChannel(int channelId) async {
    try {
      final String channelName = _channelNameController.text.isEmpty
          ? widget.channelName
          : _channelNameController.text.trim();
      final bool channelStatus =
          currentOption == ChannelType.private ? false : true;
      final int workspace_id =
          SessionStore.sessionData!.mWorkspace!.id!.toInt();
      await _apiService.updateChannel(
          channelId, channelStatus, channelName, workspace_id);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Channel edit successfully'),
          backgroundColor: Colors.green,
        ),
      );
      // ignore: use_build_context_synchronously
      Navigator.push(context, MaterialPageRoute(builder: (context) => Nav()));
    } catch (e) {
      print('Error creating channel: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to edit channel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
