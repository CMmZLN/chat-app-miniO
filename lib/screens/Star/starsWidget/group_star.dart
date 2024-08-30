import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/model/groupMessage.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/dataInsert/star_list.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:flutter_frontend/services/starlistsService/star_list.service.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;

class GroupStarWidget extends StatefulWidget {
  const GroupStarWidget({Key? key}) : super(key: key);

  @override
  State<GroupStarWidget> createState() => _GroupStarState();
}

class _GroupStarState extends State<GroupStarWidget> {
  List<EmojiCountsforGpMsg> tGroupEmojiCounts = [];
  List<dynamic> tGroupReactMsgIds = [];
  List<ReactUserDataForGpMsg> reactUsernamesForGroupMsg = [];

  final _starListService = StarListsService(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));

  int userId = SessionStore.sessionData!.currentUser!.id!.toInt();

  late Future<void> refreshFuture;

  TargetPlatform? platform;
  BuildMulitFile mulitFile = BuildMulitFile();
  BuildSingleFile singleFile = BuildSingleFile();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      return;
    } else if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else {
      platform = TargetPlatform.iOS;
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      var token = await getToken();
      var data = await _starListService.getAllStarList(userId, token!);
      if (mounted) {
        setState(() {
          StarListStore.starList = data;
          tGroupEmojiCounts = data.tGroupEmojiCounts!;
          tGroupReactMsgIds = data.tGroupReactMsgIds!;
          reactUsernamesForGroupMsg = data.reactUsernamesForGroupMsg!;
        });
      }
    } catch (e) {}
  }

  Future<void> _refresh() async {
    await _fetchData();
  }

  Future<String?> getToken() async {
    return await AuthController().getToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kPriamrybackground,
        body: LiquidPullToRefresh(
          onRefresh: _refresh,
          color: Colors.blue.shade100,
          animSpeedFactor: 200,
          showChildOpacityTransition: true,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: StarListStore.starList!.groupStar!.length,
                  itemBuilder: (context, index) {
                    var snapshot = StarListStore.starList;
                    String name = snapshot!.groupStar![index].name.toString();
                    List<String> initials =
                        name.split(" ").map((e) => e.substring(0, 1)).toList();
                    String gp_name = initials.join("");

                    var filterMsg =
                        snapshot.groupStar![index].groupmsg.toString();

                    String groupmsg = filterMsg;
                    String channelName =
                        snapshot.groupStar![index].channelName.toString();
                    int groupMsgId = snapshot.groupStar![index].id!.toInt();
                    String dateFormat =
                        snapshot.groupStar![index].createdAt.toString();
                    DateTime dateTime = DateTime.parse(dateFormat).toLocal();
                    String time =
                        DateFormat('MMM d, yyyy hh:mm a').format(dateTime);

                    List<dynamic>? files = [];
                    List<dynamic>? fileName = [];

                    files = snapshot.groupStar![index].files;
                    fileName = snapshot.groupStar![index].fileNames;

                    String? profileImage =
                        snapshot.groupStar![index].profileImage;

                    if (profileImage != null && !kIsWeb) {
                      profileImage = MinioToIP.replaceMinioWithIP(
                          profileImage, ipAddressForMinio);
                    }

                    return Container(
                      padding: EdgeInsets.only(top: 10),
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[300],
                                ),
                                child: Center(
                                  child: profileImage == null ||
                                          profileImage.isEmpty
                                      ? const Icon(Icons.person)
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: Image.network(
                                            profileImage,
                                            fit: BoxFit.cover,
                                            width: 40,
                                            height: 40,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 5)
                            ],
                          ),
                          SizedBox(width: 5),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.7,
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(10),
                                        bottomLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10))),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        channelName,
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.7,
                                        // child: Text(groupmsg,
                                        //     style: const TextStyle(fontSize: 15)),
                                        child: flutter_html.Html(
                                          data: groupmsg,
                                          style: {
                                            ".ql-code-block":
                                                flutter_html.Style(
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                    padding: flutter_html
                                                            .HtmlPaddings
                                                        .symmetric(
                                                            horizontal: 10,
                                                            vertical: 5),
                                                    margin:
                                                        flutter_html.Margins
                                                            .symmetric(
                                                                vertical: 7)),
                                            ".highlight": flutter_html.Style(
                                              display: flutter_html
                                                  .Display.inlineBlock,
                                              backgroundColor: Colors.grey[200],
                                              color: Colors.red,
                                              padding: flutter_html.HtmlPaddings
                                                  .symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                            ),
                                            "blockquote": flutter_html.Style(
                                              border: const Border(
                                                  left: BorderSide(
                                                      color: Colors.grey,
                                                      width: 5.0)),
                                              margin: flutter_html.Margins
                                                  .symmetric(vertical: 10.0),
                                              padding: flutter_html.HtmlPaddings
                                                  .only(left: 10),
                                            ),
                                            "ol": flutter_html.Style(
                                              margin: flutter_html.Margins
                                                  .symmetric(horizontal: 10),
                                              padding: flutter_html.HtmlPaddings
                                                  .symmetric(horizontal: 10),
                                            ),
                                            "ul": flutter_html.Style(
                                              display: flutter_html
                                                  .Display.inlineBlock,
                                              padding: flutter_html.HtmlPaddings
                                                  .symmetric(horizontal: 10),
                                              margin:
                                                  flutter_html.Margins.all(0),
                                            ),
                                            "pre": flutter_html.Style(
                                              backgroundColor: Colors.grey[300],
                                              padding: flutter_html.HtmlPaddings
                                                  .symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                            ),
                                            "code": flutter_html.Style(
                                              display: flutter_html
                                                  .Display.inlineBlock,
                                              backgroundColor: Colors.grey[300],
                                              color: Colors.red,
                                              padding: flutter_html.HtmlPaddings
                                                  .symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                            )
                                          },
                                        ),
                                      ),
                                      files!.length == 1
                                          ? singleFile.buildSingleFile(
                                              files.first ?? '',
                                              context,
                                              platform,
                                              fileName?.first ?? '')
                                          : mulitFile.buildMultipleFiles(
                                              files,
                                              platform,
                                              context,
                                              fileName ?? []),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      Text(
                                        time,
                                        style: const TextStyle(fontSize: 10),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.7,
                                child: Wrap(
                                    direction: Axis.horizontal,
                                    spacing: 7,
                                    children: List.generate(
                                        tGroupEmojiCounts!.length, (index) {
                                      bool show = false;
                                      List userIds = [];
                                      List reactUsernames = [];

                                      if (tGroupEmojiCounts![index]
                                              .groupmsgid ==
                                          groupMsgId) {
                                        for (dynamic reactUser
                                            in reactUsernamesForGroupMsg!) {
                                          if (reactUser.groupmsgid ==
                                                  tGroupEmojiCounts![index]
                                                      .groupmsgid &&
                                              tGroupEmojiCounts![index].emoji ==
                                                  reactUser.emoji) {
                                            userIds.add(reactUser.userid);
                                            reactUsernames.add(reactUser.name);
                                          }
                                        } //reactUser for loop end
                                      }
                                      for (int i = 0;
                                          i < tGroupEmojiCounts!.length;
                                          i++) {
                                        if (tGroupEmojiCounts![i].groupmsgid ==
                                            groupMsgId) {
                                          for (int j = 0;
                                              j <
                                                  reactUsernamesForGroupMsg!
                                                      .length;
                                              j++) {
                                            if (userIds.contains(
                                                reactUsernamesForGroupMsg![j]
                                                    .userid)) {
                                              return Container(
                                                width: 50,
                                                height: 25,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: userIds
                                                            .contains(userId)
                                                        ? Colors.green
                                                        : Colors
                                                            .red, // Use emojiBorderColor here
                                                    width: 1,
                                                  ),
                                                  color: const Color.fromARGB(
                                                      226, 212, 234, 250),
                                                ),
                                                padding: EdgeInsets.zero,
                                                child: TextButton(
                                                  onPressed: null,
                                                  onLongPress: () async {
                                                    HapticFeedback
                                                        .heavyImpact();
                                                    await showDialog(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return SimpleDialog(
                                                            title: const Center(
                                                              child: Text(
                                                                "People Who React",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        20),
                                                              ),
                                                            ),
                                                            children: [
                                                              SizedBox(
                                                                width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width,
                                                                child: ListView
                                                                    .builder(
                                                                  shrinkWrap:
                                                                      true,
                                                                  itemCount:
                                                                      reactUsernames
                                                                          .length,
                                                                  itemBuilder:
                                                                      (context,
                                                                          index) {
                                                                    return SingleChildScrollView(
                                                                        child:
                                                                            SimpleDialogOption(
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.pop(context),
                                                                      child:
                                                                          Center(
                                                                        child:
                                                                            Text(
                                                                          "${reactUsernames[index]}さん",
                                                                          style: const TextStyle(
                                                                              fontSize: 18,
                                                                              letterSpacing: 0.1),
                                                                        ),
                                                                      ),
                                                                    ));
                                                                  },
                                                                ),
                                                              )
                                                            ],
                                                          );
                                                        });
                                                  },
                                                  style: ButtonStyle(
                                                    padding:
                                                        WidgetStateProperty.all(
                                                            EdgeInsets.zero),
                                                    minimumSize:
                                                        WidgetStateProperty.all(
                                                            const Size(50, 25)),
                                                  ),
                                                  child: Text(
                                                    '${tGroupEmojiCounts![index].emoji} ${tGroupEmojiCounts![index].emojiCount}',
                                                    style: const TextStyle(
                                                      color: Colors.blueAccent,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      }
                                      return Container();
                                    })),
                              )
                            ],
                          )
                        ],
                      ),
                    );
                    // ListTile(
                    //   leading: Container(
                    //     height: 50,
                    //     width: 50,
                    //     color: Colors.amber,
                    //     child: Center(
                    //       child: Text(
                    //         name.characters.first.toUpperCase(),
                    //         style: const TextStyle(
                    //           fontSize: 30,
                    //           fontWeight: FontWeight.bold,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    //   title: Text(
                    //     channelName,
                    //    style: const TextStyle(fontSize: 20)
                    //   ),
                    //   subtitle:
                    //       Text(groupmsg, style: const TextStyle(fontSize: 15)),
                    //   trailing: Text(
                    //     time,
                    //     style: const TextStyle(fontSize: 10),
                    //   ),
                    // );
                  },
                ),
              ),
            ],
          ),
        ));
  }
}