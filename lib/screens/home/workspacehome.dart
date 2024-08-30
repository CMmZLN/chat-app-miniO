import 'dart:async';
import 'dart:convert';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/customLoadingForHome.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/screens/check_token_status.dart';
import 'package:flutter_frontend/screens/draftmessage/draft_message_body.dart';
import 'package:flutter_frontend/screens/profile/profile.dart';
import '../groupMessage/groupMessage.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/progression.dart';
import 'package:flutter_frontend/model/SessionState.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/screens/home/homeDrawer.dart';
import 'package:flutter_frontend/screens/mChannel/m_channel_create.dart';
import 'package:flutter_frontend/screens/memverinvite/member_invite.dart';
import 'package:flutter_frontend/screens/directMessage/direct_message.dart';
import 'package:flutter_frontend/services/userservice/mainpage/mian_page.dart';
import 'package:flutter_frontend/services/mChannelService/m_channel_services.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';

import 'package:web_socket_channel/web_socket_channel.dart';

class WorkHome extends StatefulWidget {
  const WorkHome({Key? key}) : super(key: key);

  @override
  State<WorkHome> createState() => _WorkHomeState();
}

class _WorkHomeState extends State<WorkHome> {
  int? joinId;
  DateTime? currentBackPressTime;

  ScrollController directScroll = ScrollController();
  ScrollController channelScroll = ScrollController();

  final _apiService = MainPageService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  bool isreading = false;
  late Future<void> refreshFuture;
  late ScrollController _scrollController;

  int channelLengths = 0;

  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    startFecting();
    getMainPage();
  }

  @override
  void dispose() {
    super.dispose();
  }

  AuthController controller = AuthController();
  int? directMessageUserID;
  String? directMessageUserName;
  bool _showJoinButton = true;

  Future<String?> getToken() async {
    return await controller.getToken();
  }

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }

  Future<void> getMainPage() async {
    var token = await getToken();
    final response = await MainPageService(Dio((BaseOptions(headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    })))).mainPage(token!);
    if (mounted) {
      setState(() {
        SessionStore.sessionData = response;
      });
    }
  }

  void startFecting() async {
    _refresh();
  }

  Future<void> _refresh() async {
    await getMainPage();
  }

  @override
  Widget build(BuildContext context) {
    if (SessionStore.sessionData == null) {
      return const LoadingForHome();
      // return const ProgressionBar(
      //   imageName: 'waiting.json',
      //   color: Colors.white,
      //   height: 500,
      //   size: 500,
      // );
    } else {
      var data = SessionStore.sessionData;
      String currentEmail = data!.currentUser!.email.toString();
      String currentName = data.currentUser!.name.toString();
      int currentUserId = data.currentUser!.id!.toInt();
      String? currentUserProfileImage = data.currentUser?.imageUrl;
      bool currentUserActiveStatus = data.currentUser!.activeStatus!;

      if (currentUserProfileImage != null && !kIsWeb) {
        currentUserProfileImage = MinioToIP.replaceMinioWithIP(
            currentUserProfileImage, ipAddressForMinio);
      }

      String workspace = data.mWorkspace!.workspaceName.toString();
      List<String> initials =
          workspace.split(" ").map((e) => e.substring(0, 1)).toList();
      String w_name = initials.join("");
      String currentWs = data.mWorkspace!.workspaceName!.toString();
      int channelLength = data.mPChannels!.length;
      channelLengths = data.mChannels!.length;
      int workSpaceUserLength = data.mUsers!.length;
      int allunread = data.allUnreadCount!.toInt();
      List? directDraftCounts = data.directDraftCounts;
      List? groupDraftCounts = data.groupDraftCounts;

      int directDraftlength = data.tDirectDraft!.length;
      int directThreadDraftlength = data.tDirectThreadDraft!.length;
      int groupDraftlength = data.tGroupDraft!.length;
      int groupThreadDraftlength = data.tGroupThreadsDraft!.length;

      int totalDraftLength = directThreadDraftlength +
          directDraftlength +
          groupDraftlength +
          groupThreadDraftlength;

      if (SessionStore.sessionData!.currentUser!.memberStatus == true) {
        return WillPopScope(
          onWillPop: () async {
            if (currentBackPressTime == null ||
                DateTime.now().difference(currentBackPressTime!) >
                    const Duration(seconds: 2)) {
              currentBackPressTime = DateTime.now();
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Press back again to exit')));
              return false;
            } else {
              return true;
            }
          },
          child: Scaffold(
            key: _scaffoldKey,
            drawer: Drawer(
              child: HomeDrawer(
                useremail: currentEmail,
                username: currentName,
                workspacename: currentWs,
              ),
            ),
            backgroundColor: kPriamrybackground,
            appBar: AppBar(
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent, // Transparent status bar
                statusBarIconBrightness:
                    Brightness.light, // Light icons on the status bar
                // Light icons on the navigation bar
              ),
              flexibleSpace: Container(
                decoration: themeColor,
              ),
              leading: GestureDetector(
                onTap: _openDrawer,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.grey[600],
                    ),
                    child: Center(
                      child: Text(
                        workspace[0],
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    // child: Center(
                    //   child: currentUserProfileImage == null ||
                    //           currentUserProfileImage.isEmpty
                    //       ? const Icon(Icons.person)
                    //       : ClipRRect(
                    //           borderRadius: BorderRadius.circular(10),
                    //           child: Image.network(
                    //             currentUserProfileImage,
                    //             fit: BoxFit.cover,
                    //             width: 40,
                    //             height: 40,
                    //           ),
                    //         ),
                    // ),
                  ),
                ),
              ),
              title: Column(
                children: [
                  Text(
                    workspace,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              actions: [
                allunread == 0
                    ? Container()
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Stack(
                          children: [
                            const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Center(
                                      child: Text(
                                    "$allunread",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  )),
                                ))
                          ],
                        ),
                      ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: GestureDetector(
                    onTap: () {
                      AuthService.checkTokenStatus(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Profile(
                                    currentUserWorkspace: workspace,
                                    name: currentName,
                                  )));
                    },
                    child: Stack(
                      children: [
                        Center(
                          child: currentUserProfileImage == null ||
                                  currentUserProfileImage.isEmpty
                              ? Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          192, 255, 255, 255),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.person))
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    currentUserProfileImage,
                                    fit: BoxFit.cover,
                                    width: 35,
                                    height: 35,
                                  ),
                                ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 10,
                          child: Container(
                            height: 10,
                            width: 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: Colors.white,
                                width: 1,
                              ),
                              color: currentUserActiveStatus == true
                                  ? const Color.fromARGB(255, 3, 247, 11)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DraftMessageView(),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  width: 1,
                                  color:
                                      const Color.fromARGB(255, 204, 203, 203)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        // border: Border.all(width: 2),
                                        // borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.drafts,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    const Text(
                                      'Draft Messages',
                                      style:
                                          TextStyle(color: kPrimaryTextColor),
                                    )
                                  ],
                                ),
                                if (totalDraftLength != 0)
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "$totalDraftLength",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // if (totalDraftLength != 0)
                        //   Container(
                        //     width: 14,
                        //     height: 14,
                        //     decoration: BoxDecoration(
                        //       color: Colors.red,
                        //       borderRadius: BorderRadius.circular(7),
                        //     ),
                        //     child: Center(
                        //       child: Text(
                        //         "$totalDraftLength",
                        //         style: const TextStyle(
                        //           color: navColor,
                        //           fontSize: 10,
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                      ],
                    ),
                    const Divider(),
                    ExpansionTile(
                      shape: const Border(bottom: BorderSide.none),
                      initiallyExpanded: true,
                      title: const Text(
                        'Channels',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      children: [
                        // ConstrainedBox(
                        //   constraints: const BoxConstraints(maxHeight: 300.0),
                        //   child:
                        ListView.builder(
                          controller: channelScroll,
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemCount: channelLengths + channelLength,
                          itemBuilder: (context, index) {
                            if (index < channelLengths) {
                              final channel = data.mChannels![index];
                              final messageCount =
                                  data.mChannels![index].messageCount!.toInt();
                              List<MUsers>? userName = data.mUsers;
                              final groupDraftStatus =
                                  groupDraftCounts![index] != 0;
                              return GestureDetector(
                                onTap: () {
                                  AuthService.checkTokenStatus(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GroupMessage(
                                        channelID: channel.id,
                                        channelStatus: channel.channelStatus,
                                        channelName: channel.channelName,
                                        workspace_id: data.mWorkspace!.id,
                                        memberName: userName,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              channel.channelStatus!
                                                  ? Icon(
                                                      Icons.tag,
                                                      color: Colors.grey[600],
                                                      size: 20,
                                                    )
                                                  : Icon(
                                                      Icons.lock,
                                                      color: Colors.grey[600],
                                                      size: 20,
                                                    ),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              Text(
                                                channel.channelName ?? '',
                                                style: const TextStyle(
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    color: kPrimaryTextColor,
                                                    fontSize: 16),
                                              ),
                                            ],
                                          ),
                                          messageCount == 0
                                              ? Container()
                                              : Container(
                                                  height: 20,
                                                  width: 20,
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Center(
                                                      child: Text(
                                                    "$messageCount",
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  )),
                                                ),
                                          if (groupDraftStatus)
                                            const Icon(
                                              Icons.edit,
                                              size: 14,
                                              color: kPrimaryTextColor,
                                            )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                // child: ListTile(
                                //   leading: channel.channelStatus!
                                //       ? const Icon(Icons.tag)
                                //       : const Icon(Icons.lock),
                                //   title: Row(
                                //     children: [
                                //       Text(
                                //         channel.channelName ?? '',
                                //         style: const TextStyle(
                                //             color: kPrimaryTextColor),
                                //       ),
                                //       const SizedBox(
                                //         width: 15,
                                //       ),
                                //       messageCount == 0
                                //           ? Container()
                                //           : Container(
                                //               height: 15,
                                //               width: 15,
                                //               decoration: BoxDecoration(
                                //                 color: Colors.yellow,
                                //                 borderRadius:
                                //                     BorderRadius.circular(7.5),
                                //               ),
                                //               child: Center(
                                //                   child: Text(
                                //                 "${messageCount}",
                                //                 style: const TextStyle(
                                //                     fontSize: 10),
                                //               )),
                                //             ),
                                //       if (groupDraftStatus)
                                //         Icon(
                                //           Icons.edit,
                                //           size: 14,
                                //           color: kPrimaryTextColor,
                                //         )
                                //     ],
                                //   ),
                                // ),
                              );
                            } else {
                              List<MUsers>? userName = data.mUsers;

                              final channel =
                                  data.mPChannels![index - channelLengths];

                              bool channelExists = data.mChannels!
                                  .any((m) => m.id == channel.id);

                              if (channelExists) {
                                return const SizedBox.shrink();
                              } else {
                                return GestureDetector(
                                  onTap: () {},
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                channel.channelStatus!
                                                    ? Icon(
                                                        Icons.tag,
                                                        color: Colors.grey[600],
                                                        size: 20,
                                                      )
                                                    : Icon(
                                                        Icons.lock,
                                                        color: Colors.grey[600],
                                                        size: 20,
                                                      ),
                                                const SizedBox(
                                                  width: 10,
                                                ),
                                                Text(
                                                  channel.channelName ?? '',
                                                  style: const TextStyle(
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      color: kPrimaryTextColor,
                                                      fontSize: 16),
                                                ),
                                              ],
                                            ),
                                            if (_showJoinButton)
                                              Row(
                                                children: [
                                                  TextButton(
                                                      onPressed: () {
                                                        AuthService
                                                            .checkTokenStatus(
                                                                context);
                                                        // Perform API call to join channel
                                                        MChannelServices()
                                                            .channelJoin(
                                                                currentUserId,
                                                                channel.id!
                                                                    .toInt())
                                                            .then((_) {
                                                          // If API call is successful, hide the button
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  GroupMessage(
                                                                channelID:
                                                                    channel.id,
                                                                channelStatus:
                                                                    channel
                                                                        .channelStatus,
                                                                channelName: channel
                                                                    .channelName,
                                                                workspace_id: data
                                                                    .mWorkspace!
                                                                    .id,
                                                                memberName:
                                                                    userName,
                                                              ),
                                                            ),
                                                          );
                                                          setState(() {
                                                            _showJoinButton =
                                                                false;
                                                          });
                                                        }).catchError((error) {
                                                          // Handle error if API call fails
                                                        });
                                                      },
                                                      style: ButtonStyle(
                                                        padding: MaterialStateProperty
                                                            .all<EdgeInsets>(
                                                                EdgeInsets
                                                                    .zero), // Removes the padding
                                                        minimumSize:
                                                            MaterialStateProperty
                                                                .all<Size>(
                                                                    const Size(
                                                                        0,
                                                                        0)), // Removes the minimum size constraints
                                                        tapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap, // Reduces the touch target size
                                                      ),
                                                      child: const Text(
                                                        "Join",
                                                        // style: TextStyle(
                                                        //     color: Colors.red),
                                                      ))
                                                  // TextButton(
                                                  //   style: ButtonStyle(
                                                  //       side:
                                                  //           MaterialStateProperty
                                                  //               .all(
                                                  //     const BorderSide(
                                                  //         width: 1,
                                                  //         color: Colors.grey),
                                                  //   )),
                                                  //   onPressed: () {
                                                  //     AuthService
                                                  //         .checkTokenStatus(
                                                  //             context);
                                                  //     // Perform API call to join channel
                                                  //     MChannelServices()
                                                  //         .channelJoin(
                                                  //             currentUserId,
                                                  //             channel.id!
                                                  //                 .toInt())
                                                  //         .then((_) {
                                                  //       // If API call is successful, hide the button
                                                  //       setState(() {
                                                  //         _showJoinButton =
                                                  //             false;
                                                  //       });
                                                  //     }).catchError((error) {
                                                  //       // Handle error if API call fails
                                                  //     });
                                                  //   },
                                                  //   child: const Text(
                                                  //     'Join ME',
                                                  //     style: TextStyle(
                                                  //         fontSize: 14),
                                                  //   ),
                                                  // )
                                                ],
                                              )
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                  // child: ListTile(
                                  //   leading: channel.channelStatus!
                                  //       ? const Icon(Icons.tag)
                                  //       : const Icon(Icons.lock),
                                  //   title: Text(
                                  //     channel.channelName ?? '',
                                  //     style: const TextStyle(
                                  //         color: kPrimaryTextColor),
                                  //   ),
                                  //   trailing: _showJoinButton
                                  //       ? TextButton(
                                  //           style: ButtonStyle(
                                  //               side: MaterialStateProperty.all(
                                  //             const BorderSide(
                                  //                 width: 1,
                                  //                 color: Colors.black),
                                  //           )),
                                  //           onPressed: () {
                                  //             AuthService.checkTokenStatus(
                                  //                 context);
                                  //             // Perform API call to join channel
                                  //             MChannelServices()
                                  //                 .channelJoin(currentUserId,
                                  //                     channel.id!.toInt())
                                  //                 .then((_) {
                                  //               // If API call is successful, hide the button
                                  //               setState(() {
                                  //                 _showJoinButton = false;
                                  //               });
                                  //             }).catchError((error) {
                                  //               // Handle error if API call fails
                                  //             });
                                  //           },
                                  //           child: const Text('Join ME'),
                                  //         )
                                  //       : null, // If _showJoinButton is false, don't show the button
                                  // ),
                                );
                              }
                            }
                          },
                        ),
                        // ),
                        GestureDetector(
                          onTap: () {
                            AuthService.checkTokenStatus(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MChannelCreate(),
                              ),
                            );
                          },
                          // child: const ListTile(
                          //   leading: Icon(Icons.add),
                          //   title: Text("Add Channel!"),
                          // ),
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 0),
                            child: const Row(
                              children: [
                                Icon(Icons.add),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  "Add Channel",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ExpansionTile(
                      initiallyExpanded: true,
                      title: const Text(
                        "Direct Messages",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      children: [
                        ListView.builder(
                          controller: directScroll,
                          shrinkWrap: true,
                          itemCount: workSpaceUserLength,
                          itemBuilder: (context, index) {
                            bool? activeStatus =
                                data.mUsers![index].activeStatus;
                            String userName =
                                data.mUsers![index].name.toString();
                            List<String> initials = userName
                                .split(" ")
                                .map((e) => e.substring(0, 1))
                                .toList();
                            String dm_name = initials.join("");
                            final directDraftStatus =
                                directDraftCounts![index] != 0;
                            int userIds = data.mUsers![index].id!.toInt();
                            int count1 = data.directMsgcounts![index].toInt();
                            String? profileImage = data.mUsers![index].imageUrl;
                            if (profileImage != null && !kIsWeb) {
                              profileImage = MinioToIP.replaceMinioWithIP(
                                  profileImage, ipAddressForMinio);
                            }
                            return GestureDetector(
                              onTap: () {
                                AuthService.checkTokenStatus(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DirectMessageWidget(
                                      user_status: activeStatus,
                                      userId: userIds,
                                      receiverName: userName,
                                      activeStatus: activeStatus,
                                      profileImage: profileImage,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 8),
                                    child: Row(
                                      children: [
                                        Stack(children: [
                                          Container(
                                            height: 35,
                                            width: 35,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: Colors.grey[300],
                                            ),
                                            child: Center(
                                              child: profileImage == null ||
                                                      profileImage.isEmpty
                                                  ? const Icon(Icons.person)
                                                  : ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      child: Image.network(
                                                        profileImage,
                                                        fit: BoxFit.cover,
                                                        width: 40,
                                                        height: 40,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                              right: 0,
                                              top: 0,
                                              child: count1 == 0
                                                  ? Container()
                                                  : Container(
                                                      height: 16,
                                                      width: 16,
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      7.5),
                                                          color: Colors.red,
                                                          border: Border.all(
                                                              color:
                                                                  Colors.white,
                                                              width: 1)),
                                                      child: Center(
                                                          child: Text(
                                                        "$count1",
                                                        style: const TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      )))),
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              height: 10,
                                              width: 10,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(7),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 1,
                                                ),
                                                color: activeStatus == true
                                                    ? const Color.fromARGB(
                                                        255, 3, 247, 11)
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ]),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        currentUserId == userIds
                                            ? RichText(
                                                text: TextSpan(
                                                  text: '$userName  ',
                                                  style: const TextStyle(
                                                      color: Colors.black),
                                                  children: const [
                                                    TextSpan(
                                                        text: '(You)',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                  ],
                                                ),
                                              )
                                            : Text(
                                                userName,
                                                style: const TextStyle(
                                                    color: kPrimaryTextColor,
                                                    fontSize: 16),
                                              ),
                                        if (directDraftStatus) ...[
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          const Icon(
                                            Icons.edit,
                                            size: 14,
                                            color: kPrimaryTextColor,
                                          )
                                        ]
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              // child: ListTile(
                              //   leading: Stack(children: [
                              //     Container(
                              //       height: 40,
                              //       width: 40,
                              //       decoration: BoxDecoration(
                              //         borderRadius:
                              //             BorderRadius.circular(10),
                              //         color: Colors.grey[300],
                              //       ),
                              //       child: Center(
                              //         child: profileImage == null ||
                              //                 profileImage.isEmpty
                              //             ? const Icon(Icons.person)
                              //             : ClipRRect(
                              //                 borderRadius:
                              //                     BorderRadius.circular(10),
                              //                 child: Image.network(
                              //                   profileImage,
                              //                   fit: BoxFit.cover,
                              //                   width: 40,
                              //                   height: 40,
                              //                 ),
                              //               ),
                              //       ),
                              //     ),
                              //     Positioned(
                              //         right: 0,
                              //         top: 0,
                              //         child: count1 == 0
                              //             ? Container()
                              //             : Container(
                              //                 height: 15,
                              //                 width: 15,
                              //                 decoration: BoxDecoration(
                              //                     borderRadius:
                              //                         BorderRadius.circular(
                              //                             7.5),
                              //                     color: Colors.yellow,
                              //                     border: Border.all(
                              //                         color: Colors.white,
                              //                         width: 1)),
                              //                 child: Center(
                              //                     child: Text(
                              //                   "$count1",
                              //                   style: const TextStyle(
                              //                       fontSize: 10),
                              //                 )))),
                              //     Positioned(
                              //       right: 0,
                              //       bottom: 0,
                              //       child: Container(
                              //         height: 10,
                              //         width: 10,
                              //         decoration: BoxDecoration(
                              //           borderRadius:
                              //               BorderRadius.circular(7),
                              //           border: Border.all(
                              //             color: Colors.white,
                              //             width: 1,
                              //           ),
                              //           color: activeStatus == true
                              //               ? const Color.fromARGB(
                              //                   255, 3, 247, 11)
                              //               : Colors.grey,
                              //         ),
                              //       ),
                              //     ),
                              //   ]),
                              //   title: Row(children: [
                              //     currentUserId == userIds
                              //         ? RichText(
                              //             text: TextSpan(
                              //               text: userName + '  ',
                              //               style: const TextStyle(
                              //                   color: kPrimaryTextColor),
                              //               children: [
                              //                 TextSpan(
                              //                     text: '(You)',
                              //                     style: TextStyle(
                              //                         fontWeight:
                              //                             FontWeight.bold)),
                              //               ],
                              //             ),
                              //           )
                              //         : Text(
                              //             userName,
                              //             style: const TextStyle(
                              //                 color: kPrimaryTextColor),
                              //           ),
                              //     if (directDraftStatus) ...[
                              //       const SizedBox(
                              //         width: 10,
                              //       ),
                              //       const Icon(
                              //         Icons.edit,
                              //         size: 14,
                              //         color: kPrimaryTextColor,
                              //       )
                              //     ]
                              //   ]),
                              // )
                            );
                          },
                        ),
                        GestureDetector(
                          onTap: () {
                            AuthService.checkTokenStatus(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MemberInvitation(),
                              ),
                            );
                          },
                          child: const ListTile(
                            leading: Icon(Icons.add),
                            title: Text(
                              "Add Member",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        return CustomLogOut();
      }
    }
  }
}
