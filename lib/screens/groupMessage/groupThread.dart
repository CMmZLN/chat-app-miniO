import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:dio/dio.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/const/build_fiile.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/const/permissions.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/loadingScreenForThread.dart';
import 'package:flutter_frontend/model/group_thread_list.dart';
import 'package:flutter_frontend/screens/check_token_status.dart';
import 'package:flutter_frontend/screens/groupMessage/groupMessage.dart';
import 'package:flutter_frontend/services/groupMessageService/group_message_service.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/services/groupThreadApi/groupThreadService.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_frontend/services/groupThreadApi/retrofit/groupThread_services.dart';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_html/flutter_html.dart' as flutter_html;
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, must_be_immutable, override_on_non_overriding_member

// ignore: depend_on_referenced_packages

class GpThreadMessage extends StatefulWidget {
  String? name, fname, time, message, channelName;
  final memberName;
  final messageID, channelID, workspace_id;
  final channelStatus;
  final bool? activeStatus;
  final List<dynamic>? files;
  final List<dynamic>? fileNames;
  final String? profileImage;

  GpThreadMessage(
      {super.key,
      this.workspace_id,
      this.memberName,
      this.name,
      this.fname,
      this.time,
      this.message,
      this.messageID,
      this.channelID,
      this.channelStatus,
      this.channelName,
      this.activeStatus,
      this.files,
      this.fileNames,
      this.profileImage});

  @override
  State<GpThreadMessage> createState() => _GpThreadMessageState();
}

class _GpThreadMessageState extends State<GpThreadMessage> {
  late ScrollController _scrollController;

  final _apiSerive = GroupMessageServiceImpl();

  WebSocketChannel? _channel;
  List<gpThreads>? groupThreadData = [];
  List<dynamic>? groupThreadStar = [];
  List<mChannelUser>? channelUser = [];
  List<mUsers>? mUser = [];
  List<EmojiCountsforGpThread>? emojiCounts = [];
  List<ReactUserDataForGpThread>? reactUserDatas = [];
  List<ReactUserDataForGpMessage>? groupReactUserDatas = [];
  List<EmojiCountsforGpMessage>? groupEmojiCounts = [];

  bool isButtom = false;
  bool isLoading = false;
  bool hasFileToSEnd = false;
  List<PlatformFile> files = [];
  late String localpath;
  late bool permissionReady;
  TargetPlatform? platform;
  final PermissionClass permissions = PermissionClass();
  String? fileText;

  BuildSingleFile singleFile = BuildSingleFile();
  BuildMulitFile mulitFile = BuildMulitFile();
  late List<Map<String, Object?>> mention;

  bool isCursor = false;
  bool isSelectText = false;
  bool isfirstField = true;
  bool isClickedTextFormat = false;
  String htmlContent = "";
  bool draftStatus = false;
  int? draftedGroupThreadId;
  quill.QuillController _quilcontroller = quill.QuillController.basic();
  final FocusNode _focusNode = FocusNode();
  List uniqueList = [];
  OverlayEntry? _overlayEntry;
  final List _userList = []; // Example user list
  List _filteredUsers = [];
  List<String> mentionnames = [];

  bool isBlockquote = false;
  bool isOrderList = false;
  bool isBold = false;
  bool isItalic = false;
  bool isStrike = false;
  bool isLink = false;
  bool isUnorderList = false;
  bool isCode = false;
  bool isCodeblock = false;
  bool playBool = false;
  bool isEnter = false;
  bool discode = false;
  bool isEdit = false;
  bool showScrollButton = false;
  bool isScrolling = false;
  bool isMessaging = false;
  String editMsg = "";
  int? editTreadId;
  List _previousOps = [];
  int? groupMessageID;

  String selectedEmoji = "";
  String _seletedEmojiName = "";
  bool _isEmojiSelected = false;

  @override
  void initState() {
    super.initState();
    isCursor = false;
    _focusNode.unfocus();
    loadMessage();
    connectWebSocket();
    _scrollController = ScrollController();
    _scrollController.addListener(scrollListener);
    _quilcontroller.addListener(_onSelectionChanged);
    _focusNode.addListener(_focusChange);
    _quilcontroller.addListener(_onTextChanged);

    _previousOps = _quilcontroller.document.toDelta().toList();
    // To remove background color when format was remove
    _quilcontroller.document.changes.listen((change) {
      final delta = change.change; // Get the delta change

      for (final op in delta.toList()) {
        if (op.isDelete) {
          // Find the range of deleted text in the previous operations
          final start = _quilcontroller.selection.baseOffset - op.length!;
          final end = _quilcontroller.selection.baseOffset;

          // Check attributes in the range of deleted text
          final attributes = _getAttributesInRange(start, end);

          if (!(attributes.containsKey("bold"))) {
            setState(() {
              isBold = false;
              discode = false;
            });
          }
          if (!(attributes.containsKey("italic"))) {
            setState(() {
              isItalic = false;
              discode = false;
            });
          }
          if (!(attributes.containsKey("strike"))) {
            setState(() {
              isStrike = false;
              discode = false;
            });
          }
          if (!(attributes.containsKey("code"))) {
            setState(() {
              isCode = false;
              discode = false;
            });
          }
          if (attributes.containsKey("list")) {
            final int start = _quilcontroller.selection.baseOffset - 2;
            final int end = _quilcontroller.selection.baseOffset;
            _quilcontroller.replaceText(
                start, end - start, '', TextSelection.collapsed(offset: start));
            setState(() {
              discode = false;
            });
          }
        }
      }
      // Update the previous text and operations to the new state after handling changes
      _previousOps = _quilcontroller.document.toDelta().toList();
    });

    if (kIsWeb) {
      return;
    } else if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else {
      platform = TargetPlatform.iOS;
    }
  }

  Map<String, dynamic> _getAttributesInRange(int start, int end) {
    Map<String, dynamic> combinedAttributes = {};
    int currentPosition = 0;

    for (final op in _previousOps) {
      if (op.isInsert) {
        final text = op.data as String;
        final length = text.length;

        if (currentPosition + length >= start && currentPosition < end) {
          combinedAttributes.addAll(op.attributes ?? {});
        }
        currentPosition += length;
      } else if (op.isRetain) {
        currentPosition += op.length! as int;
      }
    }
    return combinedAttributes;
  }

  @override
  void dispose() {
    super.dispose();
    _channel!.sink.close();
    _quilcontroller.removeListener(_onSelectionChanged);
    _focusNode.removeListener(_focusChange);
    _quilcontroller.removeListener(_onTextChanged);
  }

  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  final _apiService = GroupThreadServices(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));

  final _groupThreadService = GroupMessageServiceImpl();

  TextEditingController threadMessage = TextEditingController();
  int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();
  void _sendGpThread() async {
    String message = threadMessage.text;
    int? channelId = widget.channelID;
    String mention = '';
    await GpThreadMsg()
        .sendGroupThreadData(message, channelId!, widget.messageID, mention);
    if (message.isEmpty) {
      setState(() {
        // groupThread = message;
      });
    }
    threadMessage.text = "";
  }

  GroupThreadMessage groupThreadList = GroupThreadMessage();
  // String? groupThread;
  Future<String?> getToken() async {
    return await AuthController().getToken();
  }

  void scrollListener() {
    if (_scrollController.position.pixels <
            _scrollController.position.maxScrollExtent - 100 ||
        isMessaging == false) {
      setState(() {
        isMessaging = true;
        showScrollButton = true;
      });
    } else {
      setState(() {
        isMessaging = false;
        showScrollButton = false;
      });
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 300,
      duration: const Duration(milliseconds: 100),
      curve: Curves.ease,
    );
  }

  void connectWebSocket() {
    var url =
        'ws://$wsUrl/cable?channel_id=${widget.channelID}&channel_name=${widget.channelName}&reply_to${widget.messageID}';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    final subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'GroupThreadChannel'}),
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

            // Handling chat message
            if (messageContent != null &&
                messageContent.containsKey('message')) {
              var msg = messageContent['message'];

              if (msg != null &&
                  msg.containsKey('groupthreadmsg') &&
                  msg['t_group_message_id'] == widget.messageID) {
                var groupThreadMessage = msg['groupthreadmsg'];
                int id = msg['id'];
                var date = msg['created_at'];
                int mUserId = msg['m_user_id'];
                bool draftMessageStatus = msg['draft_message_status'];
                List<dynamic> fileUrls = [];
                List<dynamic>? fileNames = [];
                String name = messageContent['sender_name'];

                String? profileName = messageContent['profile_image'];

                if (messageContent.containsKey('files')) {
                  var files = messageContent['files'];
                  if (files != null) {
                    fileUrls = files.map((file) => file['file']).toList();
                  }
                }
                if (messageContent.containsKey('files')) {
                  var files = messageContent['files'];
                  if (files != null) {
                    fileNames = files.map((file) => file['file_name']).toList();
                  }
                }

                setState(() {
                  groupThreadData?.add(gpThreads(
                      id: id,
                      groupthreadmsg: groupThreadMessage,
                      created_at: date,
                      sendUserId: mUserId,
                      name: name,
                      fileUrls: fileUrls,
                      fileName: fileNames,
                      profileName: profileName,
                      draftMessageStatus: draftMessageStatus));
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (isMessaging == false) {
                      _scrollToBottom();
                    }
                  });
                });
              } else {}
            } else if (messageContent.containsKey('messaged_star')) {
              var messageStarData = messageContent['messaged_star'];

              if (messageStarData != null &&
                  messageStarData['userid'] == currentUserId) {
                int groupthreadid = messageStarData['groupthreadid'];

                setState(() {
                  groupThreadStar?.add(groupthreadid);
                });
              } else {}
            } else if (messageContent.containsKey('unstared_message')) {
              var unstaredMsg = messageContent['unstared_message'];

              if (unstaredMsg != null &&
                  unstaredMsg['userid'] == currentUserId) {
                var unstaredMsgId = unstaredMsg['groupthreadid'];

                setState(() {
                  groupThreadStar?.removeWhere(
                    (element) => element == unstaredMsgId,
                  );
                });
              }
            } else if (messageContent.containsKey('react_message') &&
                messageContent['m_channel_id'] == widget.channelID) {
              var reactmsg = messageContent['react_message'];
              var userid = reactmsg['userid'];
              var groupthreadid = reactmsg['groupthreadid'];
              var emoji = reactmsg['emoji'];
              var reactUserInfo = messageContent['reacted_user_info'];
              var emojiCount;
              bool emojiExists = false;
              for (var element in emojiCounts!) {
                if (element.emoji == emoji &&
                    element.groupThreadId == groupthreadid) {
                  emojiCount = element.emojiCount! + 1;
                  element.emojiCount = emojiCount;
                  emojiExists = true;
                  break;
                }
              }
              if (!emojiExists) {
                emojiCount = 1;
                emojiCounts!.add(EmojiCountsforGpThread(
                    groupThreadId: groupthreadid,
                    emoji: emoji,
                    emojiCount: emojiCount));
              }

              setState(() {
                if (emojiExists) {
                  emojiCounts!.add(EmojiCountsforGpThread(
                      emojiCount: emojiCount, groupThreadId: groupthreadid));
                }

                reactUserDatas!.add(ReactUserDataForGpThread(
                    emoji: emoji,
                    groupThreadId: groupthreadid,
                    name: reactUserInfo,
                    userId: userid));
              });
            } else if (messageContent.containsKey('remove_reaction') &&
                messageContent['m_channel_id'] == widget.channelID) {
              var deleteRection = messageContent['remove_reaction'];
              var userId = deleteRection['userid'];
              var groupthreadid = deleteRection['groupthreadid'];
              var emoji = deleteRection['emoji'];
              var reactUserInfo = messageContent['reacted_user_info'];

              setState(() {
                for (var element in emojiCounts!) {
                  if (element.emoji == emoji &&
                      element.groupThreadId == groupthreadid) {
                    element.emojiCount = element.emojiCount! - 1;
                    break;
                  }
                }

                reactUserDatas?.removeWhere((element) =>
                    element.groupThreadId == groupthreadid &&
                    element.emoji == emoji &&
                    element.name == reactUserInfo);
              });
            } else if (messageContent.containsKey('update_group_thread')) {
              var msg = messageContent['update_group_thread'];

              var groupThreadMessage = msg['groupthreadmsg'];
              int id = msg['id'];
              var date = msg['created_at'];
              int mUserId = msg['m_user_id'];
              List<dynamic> fileUrls = [];
              List<dynamic>? fileNames = [];
              String name = messageContent['sender_name'];
              String? profileName = messageContent['profile_image'];

              groupThreadData!.removeWhere((e) => e.id == id);
              setState(() {
                groupThreadData?.add(gpThreads(
                    id: id,
                    groupthreadmsg: groupThreadMessage,
                    created_at: date,
                    sendUserId: mUserId,
                    name: name,
                    fileUrls: fileUrls,
                    fileName: fileNames,
                    profileName: profileName));
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (isMessaging == false) {
                    _scrollToBottom();
                  }
                });
              });
            } else if (messageContent.containsKey('group_react_message') &&
                messageContent['m_channel_id'] == widget.channelID) {
              var reactmsg = messageContent['group_react_message'];
              var userid = reactmsg['userid'];
              var groupmsgid = reactmsg['groupmsgid'];
              var emoji = reactmsg['emoji'];
              var reactUserInfo = messageContent['group_reacted_user_info'];
              var emojiCount;
              bool emojiExists = false;
              for (var element in groupEmojiCounts!) {
                if (element.groupEmoji == emoji &&
                    element.groupMessageId == groupmsgid) {
                  emojiCount = element.groupEmojiCount! + 1;
                  element.groupEmojiCount = emojiCount;
                  emojiExists = true;
                  break;
                }
              }
              if (!emojiExists) {
                emojiCount = 1;
                groupEmojiCounts!.add(EmojiCountsforGpMessage(
                    groupMessageId: groupmsgid,
                    groupEmoji: emoji,
                    groupEmojiCount: emojiCount));
              }

              setState(() {
                if (emojiExists) {
                  groupEmojiCounts!.add(EmojiCountsforGpMessage(
                      groupEmojiCount: emojiCount, groupMessageId: groupmsgid));
                }

                groupReactUserDatas!.add(ReactUserDataForGpMessage(
                    emoji: emoji,
                    groupMessageId: groupmsgid,
                    name: reactUserInfo,
                    userId: userid));
              });
            } else if (messageContent.containsKey('group_remove_reaction') &&
                messageContent['m_channel_id'] == widget.channelID) {
              var deleteRection = messageContent['group_remove_reaction'];
              var userId = deleteRection['userid'];
              var groupmsgid = deleteRection['groupmsgid'];
              var emoji = deleteRection['emoji'];
              var reactUserInfo = messageContent['group_reacted_user_info'];

              setState(() {
                for (var element in groupEmojiCounts!) {
                  if (element.groupEmoji == emoji &&
                      element.groupMessageId == groupmsgid) {
                    element.groupEmojiCount = element.groupEmojiCount! - 1;
                    break;
                  }
                }

                groupReactUserDatas?.removeWhere((element) =>
                    element.groupMessageId == groupmsgid &&
                    element.emoji == emoji &&
                    element.name == reactUserInfo &&
                    element.userId == userId);
              });
            } else {
              var deletemsg = messageContent['delete_msg'];
              int id = deletemsg['id'];
              setState(() {
                groupThreadData?.removeWhere(
                  (element) => element.id == id,
                );
              });
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

  void loadMessage() async {
    var token = await getToken();
    GroupThreadMessage data = await _apiService.getAllThread(
        widget.messageID, widget.channelID, token!);

    setState(() {
      groupThreadData = data.GpThreads;
      groupThreadStar = data.GpThreadStar;
      channelUser = data.TChannelUsers;
      mUser = data.MUsers;
      emojiCounts = data.emojiCounts;
      reactUserDatas = data.reactUserDatas;
      isLoading = true;
      groupEmojiCounts = data.GroupEmojiCounts;
      groupReactUserDatas = data.GroupReactUserDatas;
      groupThreadData?.forEach((groupThread) {
        if (groupThread.draftMessageStatus == true &&
            groupThread.sendUserId == currentUserId) {
          insertEditText(groupThread.groupthreadmsg);
        }
      });
    });
    mention = channelUser!.map(
      (e) {
        return {'display': e.name, 'name': e.name};
      },
    ).toList();
  }

  Future<void> sendGroupThreadData(String groupMessage, int channelID,
      int messageID, List<String> mentionName, bool draftStatus) async {
    if (groupMessage.startsWith("<br/>")) {
      groupMessage = groupMessage.replaceAll("<br/>", " ");
    }
    if (groupMessage.isNotEmpty || files.isNotEmpty) {
      await _groupThreadService.sendGroupThreadData(
          groupMessage, channelID, messageID, mentionName, files, draftStatus);
      groupThreadData?.forEach((groupThread) {
        if (groupThread.draftMessageStatus == true &&
            groupThread.sendUserId == currentUserId) {
          GpThreadMsg().deleteGpThread(
              groupThread.id!, widget.channelID, widget.messageID);
        }
      });
      files.clear();
    }
  }

  void pickFiles() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    setState(() {
      files.addAll(result.files);
      hasFileToSEnd = true;
    });
  }

  String detectStyles() {
    // Get the current Delta (content) from the Quill controller
    var delta = _quilcontroller.document.toDelta();
    final Delta updatedDelta = Delta();

    for (final op in delta.toList()) {
      if (op.attributes != null &&
          op.attributes!.containsKey("list") &&
          op.value != null &&
          op.value != "\n" &&
          op.attributes!.length == 1) {
        final newAttributes = Map<String, dynamic>.from(op.attributes!);
        newAttributes.remove('list');

        // Add the modified operation to the updated delta
        updatedDelta.insert(op.data);
      } else if (op.attributes != null &&
          op.attributes!.containsKey("list") &&
          op.value != null &&
          op.value != "\n") {
        final newAttributes = Map<String, dynamic>.from(op.attributes!);
        if (newAttributes.containsKey('list')) {
          newAttributes.remove('list');
        }
        updatedDelta.insert(op.data, newAttributes);
      } else {
        // Add the original operation to the updated delta
        updatedDelta.push(op);
      }
    }

    // Convert Delta to HTML using vsc_quill_delta_to_html package
    var converter = QuillDeltaToHtmlConverter(updatedDelta.toJson());

    String html = converter.convert();

    return html;
  }

  void _onSelectionChanged() {
    if (_quilcontroller.selection.extentOffset !=
        _quilcontroller.selection.baseOffset) {
      setState(() {
        isSelectText = true;
        isfirstField = false;
      });
      _checkSelectedWordFormatting();
    } else {
      setState(() {
        isSelectText = false;
        isfirstField = true;
      });
    }

    _checkWordFormatting();
  }

  void _focusChange() {
    if (_focusNode.hasFocus) {
      setState(() {
        isCursor = true;
      });
    } else {
      setState(() {
        isCursor = false;
      });
    }
  }

  void _onTextChanged() {
    String text = _quilcontroller.document.toPlainText();
    final selection = _quilcontroller.selection;

    getMchannelUsers();
    // remove duplicated name
    // uniqueList = _userList.toSet().toList();

    // Define a Set to keep track of added pairs
    final Set<String> addedPairs = {};

    // Remove duplicate pairs (both name and status)
    uniqueList = [];
    for (var user in _userList) {
      // Assuming _userList contains maps with 'name' and 'status' keys
      String pair = "${user['name']}-${user['status']}";
      if (!addedPairs.contains(pair)) {
        uniqueList.add(user);
        addedPairs.add(pair);
      }
    }

    if (selection.baseOffset == selection.extentOffset) {
      final offset = selection.baseOffset;
      if (selection.baseOffset > 0 && text[offset - 1] == '@') {
        // userlist won't show when String@
        if (text.indexOf("\n") == selection.extentOffset) {
          text = text.replaceAll("\n", "");
        }
        List txts = text.split(" ");
        String str = "";
        for (var i = 0; i < txts.length; i++) {
          str = txts[i];
        }
        if (str.startsWith("@") || str.contains("\n")) {
          setState(() {
            _filteredUsers = uniqueList;
          });
          _showUserList();
        }
      } else {
        // filtering users
        final atPos = text.lastIndexOf('@', selection.baseOffset);
        if (atPos != -1) {
          final query =
              text.substring(atPos + 1, selection.baseOffset).toLowerCase();
          _filteredUsers = uniqueList
              .where((user) =>
                  user["name"].toString().toLowerCase().startsWith(query))
              .toList();
          if (_filteredUsers.isEmpty) {
            _hideUserList();
          }
        } else {
          _hideUserList();
        }
      }
    }
  }

  void _checkSelectedWordFormatting() {
    final selection = _quilcontroller.selection;

    if (selection.isCollapsed) {
      return;
    }

    final checkSelectedBold = _isSelectedTextFormatted(
        selection.start, selection.end, quill.Attribute.bold);
    final checkSelectedItalic = _isSelectedTextFormatted(
        selection.start, selection.end, quill.Attribute.italic);
    final checkSelectedStrike = _isSelectedTextFormatted(
        selection.start, selection.end, quill.Attribute.strikeThrough);
    final checkSelectedCode = _isSelectedTextFormatted(
        selection.start, selection.end, quill.Attribute.inlineCode);

    if (checkSelectedBold) {
      setState(() {
        isBold = true;
      });
    } else {
      setState(() {
        isBold = false;
      });
    }

    if (checkSelectedItalic) {
      setState(() {
        isItalic = true;
      });
    } else {
      setState(() {
        isItalic = false;
      });
    }

    if (checkSelectedStrike) {
      setState(() {
        isStrike = true;
      });
    } else {
      setState(() {
        isStrike = false;
      });
    }

    if (checkSelectedCode) {
      setState(() {
        isCode = true;
      });
    } else {
      setState(() {
        isCode = false;
      });
    }
  }

  bool _isSelectedTextFormatted(int start, int end, quill.Attribute attribute) {
    final styles = _quilcontroller.getAllSelectionStyles();
    for (var style in styles) {
      if (style.attributes.containsKey(attribute.key)) {
        return true;
      }
    }
    return false;
  }

  void _checkWordFormatting() {
    final int cursorPosition = _quilcontroller.selection.baseOffset;
    // To avoid first word not working
    if (cursorPosition == 0) {
      return;
    }

    final doc = _quilcontroller.document;
    final text = doc.toPlainText();
    final wordRange = _getWordRangeAtCursor(text, cursorPosition);
    // final word = text.substring(wordRange.start, wordRange.end).trim();

    final checkLastBold = _isWordBold(wordRange);
    final checkLastItalic = _isWordItalic(wordRange);
    final checkLastStrikethrough = _isWordStrikethrough(wordRange);
    final checkLastCode = _isWordCode(wordRange);
    final checkLastCodeBlock = _isWordCodeBlock(wordRange);

    if (checkLastBold) {
      setState(() {
        isBold = true;
      });
    } else {
      setState(() {
        isBold = false;
      });
    }

    if (checkLastItalic) {
      setState(() {
        isItalic = true;
      });
    } else {
      setState(() {
        isItalic = false;
      });
    }

    if (checkLastStrikethrough) {
      setState(() {
        isStrike = true;
      });
    } else {
      setState(() {
        isStrike = false;
      });
    }

    if (checkLastCode) {
      setState(() {
        isCode = true;
      });
    } else {
      setState(() {
        isCode = false;
      });
    }

    if (checkLastCodeBlock) {
      setState(() {
        isCodeblock = true;
        discode = true;
      });
    } else {
      setState(() {
        isCodeblock = false;
        discode = false;
      });
    }
  }

  TextRange _getWordRangeAtCursor(String text, int cursorPosition) {
    if (cursorPosition <= 0 || cursorPosition >= text.length) {
      return TextRange(start: cursorPosition, end: cursorPosition);
    }

    int start = cursorPosition - 1;
    int end = cursorPosition;

    // Find the start of the word
    while (start > 0 && !_isWordBoundary(text[start - 1])) {
      start--;
    }

    // Find the end of the word
    while (end < text.length && !_isWordBoundary(text[end])) {
      end++;
    }

    return TextRange(start: start, end: end);
  }

  bool _isWordBold(TextRange wordRange) {
    for (int i = wordRange.start; i < wordRange.end; i++) {
      final style = _quilcontroller.getSelectionStyle().attributes;
      if (style.containsKey(quill.Attribute.bold.key)) {
        return true;
      }
    }
    return false;
  }

  bool _isWordItalic(TextRange wordRange) {
    for (int i = wordRange.start; i < wordRange.end; i++) {
      final style = _quilcontroller.getSelectionStyle().attributes;
      if (style.containsKey(quill.Attribute.italic.key)) {
        return true;
      }
    }
    return false;
  }

  bool _isWordStrikethrough(TextRange wordRange) {
    for (int i = wordRange.start; i < wordRange.end; i++) {
      final style = _quilcontroller.getSelectionStyle().attributes;
      if (style.containsKey(quill.Attribute.strikeThrough.key)) {
        return true;
      }
    }
    return false;
  }

  bool _isWordCode(TextRange wordRange) {
    for (int i = wordRange.start; i < wordRange.end; i++) {
      final style = _quilcontroller.getSelectionStyle().attributes;
      if (style.containsKey(quill.Attribute.inlineCode.key)) {
        return true;
      }
    }
    return false;
  }

  bool _isWordCodeBlock(TextRange wordRange) {
    for (int i = wordRange.start; i < wordRange.end; i++) {
      final style = _quilcontroller.getSelectionStyle().attributes;
      if (style.containsKey(quill.Attribute.codeBlock.key)) {
        return true;
      }
    }
    return false;
  }

  bool _isWordBoundary(String char) {
    return char == ' ' ||
        char == '\n' ||
        char == '\t' ||
        char == '.' ||
        char == ',' ||
        char == '!' ||
        char == '?';
  }

  void _clearEditor() {
    final length = _quilcontroller.document.length;
    _quilcontroller.replaceText(
        0, length, '', const TextSelection.collapsed(offset: 0));
    // Clear bg color
    setState(() {
      isBlockquote = false;
      isOrderList = false;
      isBold = false;
      isItalic = false;
      isStrike = false;
      isLink = false;
      isUnorderList = false;
      isCode = false;
      isCodeblock = false;
      discode = false;
    });
    // Clear format
    _quilcontroller
        .formatSelection(quill.Attribute.clone(quill.Attribute.ol, null));
    _quilcontroller
        .formatSelection(quill.Attribute.clone(quill.Attribute.ul, null));
    _quilcontroller.formatSelection(
        quill.Attribute.clone(quill.Attribute.blockQuote, null));
    _quilcontroller.formatSelection(
        quill.Attribute.clone(quill.Attribute.codeBlock, null));
  }

  void _insertLink() async {
    String selectedLinkText = "";
    final selection = _quilcontroller.selection;
    if (!selection.isCollapsed) {
      final startIndex = selection.baseOffset;
      final endIndex = selection.extentOffset;
      selectedLinkText = _quilcontroller.document
          .toPlainText()
          .substring(startIndex, endIndex);
    }

    final TextEditingController linktextController = selectedLinkText.isNotEmpty
        ? TextEditingController(text: selectedLinkText)
        : TextEditingController();
    final TextEditingController linkController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          elevation: 5.0,
          title: const Text('Insert Link'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter the text";
                    }
                    return null;
                  },
                  controller: linktextController,
                  decoration: const InputDecoration(labelText: 'Text'),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter the URL";
                    }
                    return null;
                  },
                  controller: linkController,
                  decoration: const InputDecoration(labelText: 'URL'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                setState(() {
                  isLink = false;
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Insert'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final text = linktextController.text;
                  final link = linkController.text;
                  if (text.isNotEmpty && link.isNotEmpty) {
                    final selection = _quilcontroller.selection;
                    final start = selection.baseOffset;
                    final length =
                        selection.extentOffset - selection.baseOffset;

                    _quilcontroller.replaceText(
                      start,
                      length,
                      text,
                      selection,
                    );

                    _quilcontroller.formatText(
                      start,
                      text.length,
                      quill.LinkAttribute(link),
                    );

                    // Move the cursor to the end of the inserted text
                    _quilcontroller.updateSelection(
                      TextSelection.collapsed(offset: start + text.length),
                      quill.ChangeSource.local,
                    );
                  }
                  setState(() {
                    isLink = false;
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    ).then((value) async {
      if (value == null) {
        setState(() {
          isLink = false;
        });
      } else {
        setState(() {
          isLink = false;
        });
      }
    });
  }

  Delta convertHtmlToDelta(String html) {
    if (html.contains("<ol>") || html.contains("<ul>")) {
      html = "<p>$html</p>";
    }
    final document = html_parser.parse(html);
    final delta = Delta();

    void parseNode(html_dom.Node node, Map<String, dynamic> attributes) {
      if (node is html_dom.Element) {
        var newAttributes = Map<String, dynamic>.from(attributes);

        switch (node.localName) {
          case 'strong':
            newAttributes['bold'] = true;
            break;
          case 'em':
            newAttributes['italic'] = true;
            break;
          case 's':
            newAttributes['strike'] = true;
            break;
          case 'a':
            newAttributes['link'] = node.attributes['href'];
            break;
          case 'code':
            newAttributes['code'] = true;
            break;
          case 'span':
            newAttributes['code'] = true;
            break;
          case 'p':
            if (node.nodes.isNotEmpty) {
              node.append(html_dom.Element.tag('br'));
            }
            for (var child in node.nodes) {
              parseNode(child, newAttributes);
            }
            return;
          case 'ol':
            for (var child in node.children) {
              if (child.localName == 'li') {
                parseNode(child, {});
                delta.insert("\n", {'list': 'ordered'});
              }
            }
            setState(() {
              isOrderList = true;
            });
            return;
          case 'ul':
            for (var child in node.children) {
              if (child.localName == 'li') {
                parseNode(child, {});
                delta.insert("\n", {'list': 'bullet'});
              }
            }
            setState(() {
              isUnorderList = true;
            });
            return;
          case 'blockquote':
            for (var child in node.nodes) {
              if (child.text!.isNotEmpty) {
                parseNode(child, {});
                delta.insert("\n", {'blockquote': true});
              }
            }
            setState(() {
              isBlockquote = true;
            });
            return;
          case "pre":
            for (var child in node.nodes) {
              if (child.text!.isNotEmpty) {
                if (child.text!.contains("\n")) {
                  List txtlist = child.text!.split("\n");
                  for (var txt in txtlist) {
                    delta.insert(txt, {});
                    delta.insert("\n", {'code-block': true});
                  }
                } else {
                  delta.insert(child.text, {});
                  delta.insert("\n", {'code-block': true});
                }
              }
            }
            setState(() {
              isCodeblock = true;
              discode = true;
            });
            return;
          case "div":
            for (var child in node.nodes) {
              if (child.text!.isNotEmpty) {
                if (child.text!.contains("\n")) {
                  List txtlist = child.text!.split("\n");
                  for (var txt in txtlist) {
                    delta.insert(txt, {});
                    delta.insert("\n", {'code-block': true});
                  }
                } else {
                  delta.insert(child.text, {});
                  delta.insert("\n", {'code-block': true});
                }
              }
            }
            setState(() {
              isCodeblock = true;
              discode = true;
            });
            return;
          case 'br':
            delta.insert('\n');
            return;
          default:
            for (var child in node.nodes) {
              parseNode(child, newAttributes);
            }
            return;
        }
        for (var child in node.nodes) {
          parseNode(child, newAttributes);
        }
      } else if (node is html_dom.Text) {
        final text = node.text;
        if (text.trim().isNotEmpty) {
          delta.insert(text, attributes);
        }
      }
    }

    for (var node in document.body!.nodes) {
      parseNode(node, {});
    }

    // Ensure the last block ends with a newline
    if (delta.length > 0 && !(delta.last.data as String).endsWith('\n')) {
      delta.insert('\n');
    }

    return delta;
  }

  void insertEditText(msg) {
    Delta delta = convertHtmlToDelta(msg);
    _quilcontroller = quill.QuillController(
      document: quill.Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  void _showUserList() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
    }
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideUserList() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  OverlayEntry _createOverlayEntry() {
    ScrollController scrollmention = ScrollController();

    return OverlayEntry(
      builder: (context) => Positioned(
        left: 20,
        top: 200,
        width: 380,
        height: 250,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(10.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 380,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      topRight: Radius.circular(10.0),
                    ),
                  ),
                ),
                ListView(
                  controller: scrollmention,
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: _filteredUsers.map((user) {
                    return ListTile(
                      leading: Icon(
                        Icons.person,
                        color: Colors.grey[300],
                      ),
                      title: Row(
                        children: [
                          Text(user["name"]),
                          SizedBox(width: 15),
                          Icon(
                            Icons.circle,
                            size: 15,
                            color: user["status"]
                                ? Color.fromARGB(255, 9, 238, 17)
                                : Colors.grey,
                          )
                        ],
                      ),
                      onTap: () {
                        _insertUser(user["name"]);
                        _hideUserList();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _insertUser(String user) {
    final selection = _quilcontroller.selection;
    final text = _quilcontroller.document.toPlainText();
    // final start = selection.baseOffset - 1;
    int cursorPosition = _quilcontroller.selection.baseOffset;

    int start = text.substring(0, cursorPosition).lastIndexOf(' ');
    int end = cursorPosition;

    if (start == -1) {
      start = 0;
    } else {
      start += 1;
    }

    final newText = text.replaceRange(start, selection.baseOffset, '@$user ');
    _quilcontroller.replaceText(
      start,
      end - start,
      '@$user ',
      _quilcontroller.selection,
    );

    _quilcontroller.updateSelection(
      TextSelection.collapsed(offset: start + user.length + 2),
      quill.ChangeSource.local,
    );
  }

  void insertMention(String text) {
    final index = _quilcontroller.selection.baseOffset;
    if (index >= 0) {
      _quilcontroller.document.insert(index, text);
    } else {
      _quilcontroller.document.insert(0, text);
    }
    _quilcontroller.updateSelection(
      TextSelection.collapsed(offset: index + text.length),
      ChangeSource.local,
    );
  }

  void getMchannelUsers() {
    for (var i = 0; i < channelUser!.length; i++) {
      var user = {
        'name': channelUser![i].name,
        'status': channelUser![i].activeStatus,
      };

      setState(() {
        // _userList.add(retrieveGroupMessage!.mChannelUsers![i].name!);
        _userList.add(user);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    dynamic channel = widget.channelStatus ? "public" : "private";
    String threadMsg = widget.message.toString();
    int? maxLiane = (threadMsg.length / 15).ceil();

    if (SessionStore.sessionData!.currentUser!.memberStatus == true) {
      var filteredThreads = groupThreadData
          ?.where((thread) =>
              thread.draftMessageStatus == false ||
              thread.draftMessageStatus == null)
          .toList();

      int replyLength = groupThreadData!.length;
      List<String> initials =
          widget.fname!.split(" ").map((e) => e.substring(0, 1)).toList();
      String groupName = initials.join("");
      final json = _quilcontroller.document.toDelta().toJson();
      final textFieldContent =
          quill.Document.fromJson(json).toPlainText().trim();
      String filterMsg = widget.message.toString();
      String gropMessageFiltered = filterMsg;
      return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: kPriamrybackground,
          appBar: AppBar(
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent, // Transparent status bar
              statusBarIconBrightness: Brightness.light,
            ),
            backgroundColor: navColor,
            leading: GestureDetector(
                onTap: () {
                  AuthService.checkTokenStatus(context);
                  if (textFieldContent.isNotEmpty) {
                    groupThreadData?.forEach((groupThread) {
                      if (groupThread.draftMessageStatus == true &&
                          groupThread.sendUserId == currentUserId) {
                        draftedGroupThreadId = groupThread.id;
                      }
                    });
                    if (draftedGroupThreadId == null) {
                      htmlContent = detectStyles();
                      if (htmlContent.contains("<p>")) {
                        htmlContent = htmlContent.replaceAll("<p>", "");
                        htmlContent = htmlContent.replaceAll("</p>", "");
                      }
                      draftStatus = true;
                      sendGroupThreadData(htmlContent, widget.channelID!,
                          widget.messageID!, mentionnames, draftStatus);
                    } else {
                      htmlContent = detectStyles();
                      if (htmlContent.contains("<p>")) {
                        htmlContent = htmlContent.replaceAll("<p>", "");
                        htmlContent = htmlContent.replaceAll("</p>", "");
                      }
                      GpThreadMsg().editGroupThreadMessage(
                          htmlContent, draftedGroupThreadId!, mentionnames);
                    }
                  } else {
                    groupThreadData?.forEach((groupThread) {
                      if (groupThread.draftMessageStatus == true &&
                          groupThread.sendUserId == currentUserId) {
                        GpThreadMsg().deleteGpThread(groupThread.id!,
                            widget.channelID, widget.messageID);
                      }
                    });
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupMessage(
                        channelID: widget.channelID,
                        channelStatus: widget.channelStatus,
                        channelName: widget.channelName,
                        workspace_id: widget.workspace_id,
                        memberName: widget.memberName,
                      ),
                    ),
                  );
                  // Navigator.pop(context);
                },
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                )),
            title: Column(
              children: [
                ListTile(
                  title: Text(
                    "Message",
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text("${channel} : ${widget.channelName}",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          body: isLoading == false
              ? const ShimmerThread()
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      isButtom = true;
                    });
                  },
                  child: Stack(children: [
                    Column(children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: SizedBox(
                          height: 100,
                          width: 500,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: Center(
                                        child: widget.profileImage == null ||
                                                widget.profileImage!.isEmpty
                                            ? Icon(Icons.person)
                                            : ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.network(
                                                  widget.profileImage!,
                                                  fit: BoxFit.cover,
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
                                              BorderRadius.circular(7),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                          color: widget.activeStatus == true
                                              ? Colors.green
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SingleChildScrollView(
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            widget.name.toString(),
                                            style:
                                                const TextStyle(fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            widget.time.toString(),
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Container(
                                        color: Colors.grey[200],
                                        child: flutter_html.Html(
                                          data: widget.message!.isNotEmpty
                                              ? widget.message.toString()
                                              : "",
                                          style: {
                                            ".ql-code-block":
                                                flutter_html.Style(
                                                    backgroundColor:
                                                        Colors.grey[300],
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
                                              backgroundColor: Colors.grey[300],
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
                                              margin:
                                                  flutter_html.Margins.all(0),
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
                                      widget.files!.length == 1
                                          ? singleFile.buildSingleFile(
                                              widget.files?.first ?? '',
                                              context,
                                              platform,
                                              widget.fileNames?.first ?? '')
                                          : mulitFile.buildMultipleFiles(
                                              widget.files ?? [],
                                              platform,
                                              context,
                                              widget.fileNames ?? []),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.7,
                                        child: Wrap(
                                          children: [
                                            Wrap(
                                                direction: Axis.horizontal,
                                                spacing: 7,
                                                children: List.generate(
                                                    groupEmojiCounts!.length,
                                                    (index) {
                                                  bool show = false;
                                                  List userIds = [];
                                                  List reactUsernames = [];

                                                  if (groupEmojiCounts![index]
                                                          .groupMessageId ==
                                                      widget.messageID) {
                                                    for (dynamic reactUser
                                                        in groupReactUserDatas!) {
                                                      if (reactUser
                                                                  .groupMessageId ==
                                                              groupEmojiCounts![
                                                                      index]
                                                                  .groupMessageId &&
                                                          groupEmojiCounts![
                                                                      index]
                                                                  .groupEmoji ==
                                                              reactUser.emoji) {
                                                        userIds.add(
                                                            reactUser.userId);
                                                        reactUsernames.add(
                                                            reactUser.name);
                                                      }
                                                    } //reactUser for loop end

                                                    if (userIds.contains(
                                                        currentUserId)) {
                                                      Container();
                                                    }
                                                  }
                                                  for (int i = 0;
                                                      i <
                                                          groupEmojiCounts!
                                                              .length;
                                                      i++) {
                                                    if (groupEmojiCounts![i]
                                                            .groupMessageId ==
                                                        widget.messageID) {
                                                      for (int j = 0;
                                                          j <
                                                              groupReactUserDatas!
                                                                  .length;
                                                          j++) {
                                                        if (userIds.contains(
                                                            groupReactUserDatas![
                                                                    j]
                                                                .userId)) {
                                                          return Container(
                                                            width: 50,
                                                            height: 25,
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16),
                                                              border:
                                                                  Border.all(
                                                                color: userIds.contains(
                                                                        currentUserId)
                                                                    ? Colors
                                                                        .green
                                                                    : Colors
                                                                        .red, // Use emojiBorderColor here
                                                                width: 1,
                                                              ),
                                                              color: Color
                                                                  .fromARGB(
                                                                      226,
                                                                      212,
                                                                      234,
                                                                      250),
                                                            ),
                                                            padding:
                                                                EdgeInsets.zero,
                                                            child: TextButton(
                                                              onPressed:
                                                                  () async {
                                                                setState(() {
                                                                  _isEmojiSelected =
                                                                      false;
                                                                });
                                                                HapticFeedback
                                                                    .vibrate();
                                                                // await _apiSerive.groupMessageReaction(
                                                                //     emoji:
                                                                //         emojiCounts![
                                                                //                 index]
                                                                //             .emoji!,
                                                                //     msgId: emojiCounts![
                                                                //             index]
                                                                //         .groupmsgid!,
                                                                //     sChannelId: widget
                                                                //         .channelID);
                                                                await _apiSerive.groupMessageReaction(
                                                                    emoji: groupEmojiCounts![
                                                                            index]
                                                                        .groupEmoji!,
                                                                    msgId: groupEmojiCounts![
                                                                            index]
                                                                        .groupMessageId!,
                                                                    sChannelId:
                                                                        widget
                                                                            .channelID,
                                                                    status: 0);
                                                              },
                                                              onLongPress:
                                                                  () async {
                                                                HapticFeedback
                                                                    .heavyImpact();
                                                                await showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (BuildContext
                                                                            context) {
                                                                      return SimpleDialog(
                                                                        title:
                                                                            Center(
                                                                          child:
                                                                              Text(
                                                                            "People Who React",
                                                                            style:
                                                                                TextStyle(fontSize: 20),
                                                                          ),
                                                                        ),
                                                                        children: [
                                                                          SizedBox(
                                                                            width:
                                                                                MediaQuery.of(context).size.width,
                                                                            child:
                                                                                ListView.builder(
                                                                              shrinkWrap: true,
                                                                              itemCount: reactUsernames.length,
                                                                              itemBuilder: (context, index) {
                                                                                return SingleChildScrollView(
                                                                                    child: SimpleDialogOption(
                                                                                  onPressed: () => Navigator.pop(context),
                                                                                  child: Center(
                                                                                    child: Text(
                                                                                      "${reactUsernames[index]}さん",
                                                                                      style: TextStyle(fontSize: 18, letterSpacing: 0.1),
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
                                                              style:
                                                                  ButtonStyle(
                                                                padding: WidgetStateProperty
                                                                    .all(EdgeInsets
                                                                        .zero),
                                                                minimumSize:
                                                                    WidgetStateProperty
                                                                        .all(Size(
                                                                            50,
                                                                            25)),
                                                              ),
                                                              child: Text(
                                                                '${groupEmojiCounts![index].groupEmoji} ${groupEmojiCounts![index].groupEmojiCount}',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .blueAccent,
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
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: IconButton(
                                                icon: Icon(Icons
                                                    .add_reaction_outlined),
                                                onPressed: () {
                                                  showModalBottomSheet(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return EmojiPicker(
                                                          onEmojiSelected:
                                                              (category,
                                                                  Emoji
                                                                      emoji) async {
                                                            setState(() {
                                                              groupMessageID =
                                                                  widget
                                                                      .messageID
                                                                      .toInt();
                                                              selectedEmoji =
                                                                  emoji.emoji;
                                                              _seletedEmojiName =
                                                                  emoji.name;
                                                              _isEmojiSelected =
                                                                  true;
                                                            });

                                                            await _apiSerive.groupMessageReaction(
                                                                emoji:
                                                                    selectedEmoji,
                                                                msgId:
                                                                    groupMessageID!,
                                                                sChannelId: widget
                                                                    .channelID,
                                                                status: 0);

                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          config: Config(
                                                            height: double
                                                                .maxFinite,
                                                            checkPlatformCompatibility:
                                                                true,
                                                            emojiViewConfig:
                                                                EmojiViewConfig(
                                                              emojiSizeMax: 23,
                                                            ),
                                                            swapCategoryAndBottomBar:
                                                                false,
                                                            skinToneConfig:
                                                                const SkinToneConfig(),
                                                            categoryViewConfig:
                                                                const CategoryViewConfig(),
                                                            bottomActionBarConfig:
                                                                const BottomActionBarConfig(),
                                                            searchViewConfig:
                                                                const SearchViewConfig(),
                                                          ),
                                                        );
                                                      });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  '${filteredThreads!.length} reply',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Divider(),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 0, right: 10, left: 10, bottom: 0),
                          child: ListView.builder(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            controller: _scrollController,
                            itemCount: replyLength,
                            itemBuilder: (context, index) {
                              bool? draftMessageStatus =
                                  groupThreadData![index].draftMessageStatus;

                              if (groupThreadData == null ||
                                  groupThreadData!.isEmpty ||
                                  draftMessageStatus == true) {
                                return const SizedBox();
                              }
                              if (index < filteredThreads.length) {
                                String filterMsg = filteredThreads[index]
                                    .groupthreadmsg
                                    .toString();
                                String message = filterMsg;
                                int groupThreadId =
                                    filteredThreads[index].id!.toInt();
                                int currentUser = SessionStore
                                    .sessionData!.currentUser!.id!
                                    .toInt();
                                int sendUserId =
                                    filteredThreads[index].sendUserId!.toInt();
                                String name =
                                    filteredThreads[index].name.toString();

                                List<dynamic>? files = [];
                                files = filteredThreads[index].fileUrls;

                                List<dynamic>? fileName = [];
                                fileName = filteredThreads[index].fileName;

                                String? profileName =
                                    filteredThreads[index].profileName;

                                if (profileName != null && !kIsWeb) {
                                  profileName = MinioToIP.replaceMinioWithIP(
                                      profileName, ipAddressForMinio);
                                }

                                bool? activeStatus;

                                for (var user
                                    in SessionStore.sessionData!.mUsers!) {
                                  if (user.name == name) {
                                    activeStatus = user.activeStatus;
                                  }
                                }

                                List<String> initials = name
                                    .split(" ")
                                    .map((e) => e.substring(0, 1))
                                    .toList();
                                String groupThread = initials.join("");
                                String time = filteredThreads[index]
                                    .created_at
                                    .toString();
                                DateTime date = DateTime.parse(time).toLocal();
                                String createdAt =
                                    DateFormat('MMM d, yyyy hh:mm a')
                                        .format(date);
                                List groupThreadStarIds =
                                    groupThreadStar!.toList();
                                bool isStar = groupThreadStarIds
                                    .contains(filteredThreads[index].id);
                                return Container(
                                  //direct Message
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10),
                                        child: Stack(
                                          children: [
                                            Container(
                                              height: 40,
                                              width: 40,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                color: Colors.grey[300],
                                              ),
                                              child: Center(
                                                child: profileName == null ||
                                                        profileName.isEmpty
                                                    ? const Icon(Icons.person)
                                                    : ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        child: Image.network(
                                                          profileName,
                                                          fit: BoxFit.cover,
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
                                                      BorderRadius.circular(7),
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 1,
                                                  ),
                                                  color: activeStatus == true
                                                      ? Colors.green
                                                      : Colors.black,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.only(
                                                  top: 6,
                                                  right: 10,
                                                  left: 10,
                                                  bottom: 6),
                                              decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          bottomLeft: Radius
                                                              .circular(13),
                                                          bottomRight:
                                                              Radius.circular(
                                                                  13),
                                                          topRight:
                                                              Radius.circular(
                                                                  13))),
                                              child: Container(
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Flexible(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Container(
                                                            constraints:
                                                                BoxConstraints(
                                                                    maxHeight:
                                                                        23),
                                                            child: Row(
                                                              // username,CreatedTime,Icons.more_vert_outlined
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(name,
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .black,
                                                                    )),
                                                                Row(
                                                                  children: [
                                                                    IconButton(
                                                                      icon:
                                                                          Icon(
                                                                        Icons
                                                                            .more_vert_outlined,
                                                                      ),
                                                                      onPressed:
                                                                          () async {
                                                                        await showModalBottomSheet(
                                                                            constraints:
                                                                                BoxConstraints(maxHeight: (currentUserId == sendUserId) ? MediaQuery.of(context).size.height * 0.25 : MediaQuery.of(context).size.height * 0.13, minWidth: MediaQuery.of(context).size.width * 10),
                                                                            context: context,
                                                                            builder: (BuildContext context) {
                                                                              return Container(
                                                                                  child: Column(
                                                                                children: [
                                                                                  // Stared Button
                                                                                  TextButton.icon(
                                                                                    onPressed: () {
                                                                                      AuthService.checkTokenStatus(context);
                                                                                      Navigator.pop(context);
                                                                                      if (groupThreadStarIds.contains(groupThreadId)) {
                                                                                        try {
                                                                                          GpThreadMsg().unStarThread(groupThreadId, widget.channelID, widget.messageID);
                                                                                        } catch (e) {
                                                                                          rethrow;
                                                                                        }
                                                                                      } else {
                                                                                        GpThreadMsg().sendStarThread(groupThreadId, widget.channelID, widget.messageID);
                                                                                      }
                                                                                    },
                                                                                    label: Text("Add Star", style: TextStyle(color: Colors.black, fontSize: 20)),
                                                                                    icon: Icon(
                                                                                      Icons.star,
                                                                                      color: isStar ? Colors.yellow : Colors.grey,
                                                                                    ),
                                                                                  ),
                                                                                  Divider(height: 1, color: Colors.grey[300], indent: 15.0, endIndent: 15.0),
                                                                                  // Reaction Icon
                                                                                  TextButton.icon(
                                                                                      onPressed: () {
                                                                                        AuthService.checkTokenStatus(context);
                                                                                        Navigator.pop(context);
                                                                                        showModalBottomSheet(
                                                                                            context: context,
                                                                                            builder: (BuildContext context) {
                                                                                              return EmojiPicker(
                                                                                                onEmojiSelected: (category, Emoji emoji) async {
                                                                                                  setState(() {
                                                                                                    selectedEmoji = emoji.emoji;
                                                                                                    _seletedEmojiName = emoji.name;
                                                                                                    _isEmojiSelected = true;
                                                                                                  });

                                                                                                  GpThreadMsg().groupThreadReaction(threadId: groupThreadId, emoji: selectedEmoji, emojiName: _seletedEmojiName, selectedGpMsgId: widget.messageID, sChannelId: widget.channelID);

                                                                                                  Navigator.pop(context);
                                                                                                },
                                                                                                config: Config(
                                                                                                  height: double.maxFinite,
                                                                                                  checkPlatformCompatibility: true,
                                                                                                  emojiViewConfig: EmojiViewConfig(
                                                                                                    emojiSizeMax: 23,
                                                                                                  ),
                                                                                                  swapCategoryAndBottomBar: false,
                                                                                                  skinToneConfig: const SkinToneConfig(),
                                                                                                  categoryViewConfig: const CategoryViewConfig(),
                                                                                                  bottomActionBarConfig: const BottomActionBarConfig(),
                                                                                                  searchViewConfig: const SearchViewConfig(),
                                                                                                ),
                                                                                              );
                                                                                            });
                                                                                      },
                                                                                      label: Text("Add Reaction", style: TextStyle(fontSize: 20, color: Colors.black)),
                                                                                      icon: Icon(
                                                                                        Icons.add_reaction_outlined,
                                                                                        color: Colors.black,
                                                                                      )),
                                                                                  if (currentUserId == sendUserId) Divider(height: 1, color: Colors.grey[300], indent: 15.0, endIndent: 15.0),

                                                                                  if (currentUserId == sendUserId) // Edit Button
                                                                                    TextButton.icon(
                                                                                      onPressed: () {
                                                                                        AuthService.checkTokenStatus(context);
                                                                                        Navigator.pop(context);
                                                                                        editTreadId = groupThreadId;
                                                                                        _clearEditor();
                                                                                        setState(() {
                                                                                          isEdit = true;
                                                                                        });
                                                                                        editMsg = message;

                                                                                        if (!(editMsg.contains("<br/><div class='ql-code-block'>"))) {
                                                                                          if (editMsg.contains("<div class='ql-code-block'>")) {
                                                                                            editMsg = editMsg.replaceAll("<div class='ql-code-block'>", "<br/><div class='ql-code-block'>");
                                                                                          }
                                                                                        }

                                                                                        if (!(editMsg.contains("<br/><blockquote>"))) {
                                                                                          if (editMsg.contains("<blockquote>")) {
                                                                                            editMsg = editMsg.replaceAll("<blockquote>", "<br/><blockquote>");
                                                                                          }
                                                                                        }

                                                                                        insertEditText(editMsg);
                                                                                        // Request focusr
                                                                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                                                                          _focusNode.requestFocus();
                                                                                          _quilcontroller.addListener(_onTextChanged);
                                                                                          _quilcontroller.addListener(_onSelectionChanged);
                                                                                          // move cursor to end
                                                                                          final length = _quilcontroller.document.length;
                                                                                          _quilcontroller.updateSelection(
                                                                                            TextSelection.collapsed(offset: length),
                                                                                            ChangeSource.local,
                                                                                          );
                                                                                        });
                                                                                      },
                                                                                      icon: Icon(Icons.edit, color: Colors.black),
                                                                                      label: Text("Edit Message", style: TextStyle(fontSize: 20, color: Colors.black)),
                                                                                    ),
                                                                                  if (currentUserId == sendUserId) Divider(height: 1, color: Colors.grey[300], indent: 15.0, endIndent: 15.0),
                                                                                  //Delete Button
                                                                                  if (currentUserId == sendUserId)
                                                                                    TextButton.icon(
                                                                                        onPressed: () {
                                                                                          AuthService.checkTokenStatus(context);
                                                                                          setState(() {
                                                                                            isCursor = false;
                                                                                          });
                                                                                          Navigator.pop(context);
                                                                                          GpThreadMsg().deleteGpThread(groupThreadId, widget.channelID, widget.messageID);
                                                                                        },
                                                                                        icon: Icon(Icons.delete, color: Colors.red),
                                                                                        label: Text(
                                                                                          "Delete Message",
                                                                                          style: TextStyle(fontSize: 20, color: Colors.red),
                                                                                        ))
                                                                                ],
                                                                              ));
                                                                            });
                                                                      },
                                                                    )
                                                                  ],
                                                                )
                                                              ],
                                                            ),
                                                          ),
                                                          if (message
                                                              .isNotEmpty)
                                                            Container(
                                                                constraints:
                                                                    BoxConstraints(
                                                                        maxHeight:
                                                                            double
                                                                                .infinity),
                                                                child:
                                                                    flutter_html
                                                                        .Html(
                                                                  data: message,
                                                                  style: {
                                                                    ".ql-code-block": flutter_html.Style(
                                                                        backgroundColor:
                                                                            Colors.grey[
                                                                                300],
                                                                        padding: flutter_html.HtmlPaddings.symmetric(
                                                                            horizontal:
                                                                                10,
                                                                            vertical:
                                                                                5),
                                                                        margin: flutter_html.Margins.symmetric(
                                                                            vertical:
                                                                                7)),
                                                                    ".highlight":
                                                                        flutter_html
                                                                            .Style(
                                                                      display: flutter_html
                                                                          .Display
                                                                          .inlineBlock,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .grey[300],
                                                                      color: Colors
                                                                          .red,
                                                                      padding: flutter_html.HtmlPaddings.symmetric(
                                                                          horizontal:
                                                                              10,
                                                                          vertical:
                                                                              5),
                                                                    ),
                                                                    "blockquote":
                                                                        flutter_html
                                                                            .Style(
                                                                      border: const Border(
                                                                          left: BorderSide(
                                                                              color: Colors.grey,
                                                                              width: 5.0)),
                                                                      margin: flutter_html
                                                                              .Margins
                                                                          .symmetric(
                                                                              vertical: 10.0),
                                                                      padding: flutter_html
                                                                              .HtmlPaddings
                                                                          .only(
                                                                              left: 10),
                                                                    ),
                                                                    "ol": flutter_html
                                                                        .Style(
                                                                      margin: flutter_html
                                                                              .Margins
                                                                          .symmetric(
                                                                              horizontal: 10),
                                                                      padding: flutter_html
                                                                              .HtmlPaddings
                                                                          .symmetric(
                                                                              horizontal: 10),
                                                                    ),
                                                                    "ul": flutter_html
                                                                        .Style(
                                                                      display: flutter_html
                                                                          .Display
                                                                          .inlineBlock,
                                                                      padding: flutter_html
                                                                              .HtmlPaddings
                                                                          .symmetric(
                                                                              horizontal: 10),
                                                                      margin: flutter_html
                                                                              .Margins
                                                                          .all(
                                                                              0),
                                                                    ),
                                                                    "pre": flutter_html
                                                                        .Style(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .grey[300],
                                                                      padding: flutter_html.HtmlPaddings.symmetric(
                                                                          horizontal:
                                                                              10,
                                                                          vertical:
                                                                              5),
                                                                    ),
                                                                    "code":
                                                                        flutter_html
                                                                            .Style(
                                                                      display: flutter_html
                                                                          .Display
                                                                          .inlineBlock,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .grey[300],
                                                                      color: Colors
                                                                          .red,
                                                                      padding: flutter_html.HtmlPaddings.symmetric(
                                                                          horizontal:
                                                                              10,
                                                                          vertical:
                                                                              5),
                                                                    )
                                                                  },
                                                                )),
                                                          if (files!.length ==
                                                              1)
                                                            Center(
                                                              child: singleFile
                                                                  .buildSingleFile(
                                                                      files[0],
                                                                      context,
                                                                      platform,
                                                                      fileName?.first ??
                                                                          ''),
                                                            ),
                                                          if (files.length >= 2)
                                                            mulitFile
                                                                .buildMultipleFiles(
                                                                    files,
                                                                    platform,
                                                                    context,
                                                                    fileName ??
                                                                        []),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Icon(
                                                                Icons.star,
                                                                color: isStar
                                                                    ? Colors
                                                                        .yellow
                                                                    : Colors
                                                                        .grey,
                                                                size: 18,
                                                              ),
                                                              Text(
                                                                createdAt,
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 10,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          15,
                                                                          15,
                                                                          15),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Column(
                                                    //   children: [
                                                    //     Row(
                                                    //       children: [
                                                    //         IconButton(
                                                    //           icon: Icon(Icons
                                                    //               .add_reaction_outlined),
                                                    //           onPressed: () {
                                                    //             AuthService
                                                    //                 .checkTokenStatus(
                                                    //                     context);
                                                    //             showModalBottomSheet(
                                                    //                 context:
                                                    //                     context,
                                                    //                 builder:
                                                    //                     (BuildContext
                                                    //                         context) {
                                                    //                   return EmojiPicker(
                                                    //                     onEmojiSelected:
                                                    //                         (category,
                                                    //                             Emoji
                                                    //                                 emoji) async {
                                                    //                       setState(
                                                    //                           () {
                                                    //                         selectedEmoji =
                                                    //                             emoji.emoji;
                                                    //                         _seletedEmojiName =
                                                    //                             emoji.name;
                                                    //                         _isEmojiSelected =
                                                    //                             true;
                                                    //                       });

                                                    //                       GpThreadMsg().groupThreadReaction(
                                                    //                           threadId:
                                                    //                               groupThreadId,
                                                    //                           emoji:
                                                    //                               selectedEmoji,
                                                    //                           emojiName:
                                                    //                               _seletedEmojiName,
                                                    //                           selectedGpMsgId: widget
                                                    //                               .messageID,
                                                    //                           sChannelId:
                                                    //                               widget.channelID);

                                                    //                       Navigator.pop(
                                                    //                           context);
                                                    //                     },
                                                    //                     config:
                                                    //                         Config(
                                                    //                       height: double
                                                    //                           .maxFinite,
                                                    //                       checkPlatformCompatibility:
                                                    //                           true,
                                                    //                       emojiViewConfig:
                                                    //                           EmojiViewConfig(
                                                    //                         emojiSizeMax:
                                                    //                             23,
                                                    //                       ),
                                                    //                       swapCategoryAndBottomBar:
                                                    //                           false,
                                                    //                       skinToneConfig:
                                                    //                           const SkinToneConfig(),
                                                    //                       categoryViewConfig:
                                                    //                           const CategoryViewConfig(),
                                                    //                       bottomActionBarConfig:
                                                    //                           const BottomActionBarConfig(),
                                                    //                       searchViewConfig:
                                                    //                           const SearchViewConfig(),
                                                    //                     ),
                                                    //                   );
                                                    //                 });
                                                    //           },
                                                    //         ),
                                                    //         IconButton(
                                                    //           onPressed: () {
                                                    //             AuthService
                                                    //                 .checkTokenStatus(
                                                    //                     context);
                                                    //             if (groupThreadStarIds
                                                    //                 .contains(
                                                    //                     groupThreadId)) {
                                                    //               try {
                                                    //                 GpThreadMsg().unStarThread(
                                                    //                     groupThreadId,
                                                    //                     widget
                                                    //                         .channelID,
                                                    //                     widget
                                                    //                         .messageID);
                                                    //               } catch (e) {
                                                    //                 rethrow;
                                                    //               }
                                                    //             } else {
                                                    //               GpThreadMsg().sendStarThread(
                                                    //                   groupThreadId,
                                                    //                   widget
                                                    //                       .channelID,
                                                    //                   widget
                                                    //                       .messageID);
                                                    //             }
                                                    //           },
                                                    //           icon: isStar
                                                    //               ? Icon(
                                                    //                   Icons.star,
                                                    //                   color: Colors
                                                    //                       .yellow,
                                                    //                 )
                                                    //               : Icon(Icons
                                                    //                   .star_border_outlined),
                                                    //         ),
                                                    //       ],
                                                    //     ),
                                                    //     Row(
                                                    //       children: [
                                                    //         if (currentUser ==
                                                    //             sendUserId)
                                                    //           Row(
                                                    //             children: [
                                                    //               IconButton(
                                                    //                 onPressed: () {
                                                    //                   AuthService
                                                    //                       .checkTokenStatus(
                                                    //                           context);
                                                    //                   GpThreadMsg().deleteGpThread(
                                                    //                       groupThreadId,
                                                    //                       widget
                                                    //                           .channelID,
                                                    //                       widget
                                                    //                           .messageID);
                                                    //                 },
                                                    //                 icon: Icon(
                                                    //                   Icons.delete,
                                                    //                   color: Colors
                                                    //                       .red,
                                                    //                 ),
                                                    //               ),
                                                    //               IconButton(
                                                    //                   onPressed:
                                                    //                       () {
                                                    //                     AuthService
                                                    //                         .checkTokenStatus(
                                                    //                             context);
                                                    //                     editTreadId =
                                                    //                         groupThreadId;
                                                    //                     _clearEditor();
                                                    //                     setState(
                                                    //                         () {
                                                    //                       isEdit =
                                                    //                           true;
                                                    //                     });
                                                    //                     editMsg =
                                                    //                         message;

                                                    //                     if (!(editMsg
                                                    //                         .contains(
                                                    //                             "<br/><div class='ql-code-block'>"))) {
                                                    //                       if (editMsg
                                                    //                           .contains(
                                                    //                               "<div class='ql-code-block'>")) {
                                                    //                         editMsg = editMsg.replaceAll(
                                                    //                             "<div class='ql-code-block'>",
                                                    //                             "<br/><div class='ql-code-block'>");
                                                    //                       }
                                                    //                     }

                                                    //                     if (!(editMsg
                                                    //                         .contains(
                                                    //                             "<br/><blockquote>"))) {
                                                    //                       if (editMsg
                                                    //                           .contains(
                                                    //                               "<blockquote>")) {
                                                    //                         editMsg = editMsg.replaceAll(
                                                    //                             "<blockquote>",
                                                    //                             "<br/><blockquote>");
                                                    //                       }
                                                    //                     }

                                                    //                     insertEditText(
                                                    //                         editMsg);
                                                    //                     // Request focusr
                                                    //                     WidgetsBinding
                                                    //                         .instance
                                                    //                         .addPostFrameCallback(
                                                    //                             (_) {
                                                    //                       _focusNode
                                                    //                           .requestFocus();
                                                    //                       _quilcontroller
                                                    //                           .addListener(
                                                    //                               _onTextChanged);
                                                    //                       _quilcontroller
                                                    //                           .addListener(
                                                    //                               _onSelectionChanged);
                                                    //                       // move cursor to end
                                                    //                       final length = _quilcontroller
                                                    //                           .document
                                                    //                           .length;
                                                    //                       _quilcontroller
                                                    //                           .updateSelection(
                                                    //                         TextSelection.collapsed(
                                                    //                             offset:
                                                    //                                 length),
                                                    //                         ChangeSource
                                                    //                             .local,
                                                    //                       );
                                                    //                     });
                                                    //                   },
                                                    //                   icon: const Icon(
                                                    //                       Icons
                                                    //                           .edit))
                                                    //             ],
                                                    //           ),
                                                    //       ],
                                                    //     )
                                                    //   ],
                                                    // )
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 300,
                                              child: Wrap(
                                                  direction: Axis.horizontal,
                                                  spacing: 7,
                                                  children: List.generate(
                                                      emojiCounts!.length,
                                                      (index) {
                                                    List userIds = [];
                                                    List userNames = [];

                                                    if (emojiCounts![index]
                                                            .groupThreadId ==
                                                        groupThreadId) {
                                                      for (dynamic reactUser
                                                          in reactUserDatas!) {
                                                        if (reactUser
                                                                    .groupThreadId ==
                                                                emojiCounts![
                                                                        index]
                                                                    .groupThreadId &&
                                                            emojiCounts![index]
                                                                    .emoji ==
                                                                reactUser
                                                                    .emoji) {
                                                          userIds.add(
                                                              reactUser.userId);
                                                          userNames.add(
                                                              reactUser.name);
                                                        }
                                                      } //reactUser for loop end
                                                    }
                                                    for (int i = 0;
                                                        i < emojiCounts!.length;
                                                        i++) {
                                                      if (emojiCounts![i]
                                                              .groupThreadId ==
                                                          groupThreadId) {
                                                        for (int j = 0;
                                                            j <
                                                                reactUserDatas!
                                                                    .length;
                                                            j++) {
                                                          if (userIds.contains(
                                                              reactUserDatas![j]
                                                                  .userId)) {
                                                            return Container(
                                                              width: 50,
                                                              height: 25,
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            16),
                                                                border:
                                                                    Border.all(
                                                                  color: userIds
                                                                          .contains(
                                                                              currentUser)
                                                                      ? Colors
                                                                          .green
                                                                      : Colors
                                                                          .red, // Use emojiBorderColor here
                                                                  width: 1,
                                                                ),
                                                                color: Color
                                                                    .fromARGB(
                                                                        226,
                                                                        212,
                                                                        234,
                                                                        250),
                                                              ),
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              child: TextButton(
                                                                onPressed:
                                                                    () async {
                                                                  setState(() {
                                                                    _isEmojiSelected =
                                                                        false;
                                                                  });
                                                                  HapticFeedback
                                                                      .vibrate();
                                                                  GpThreadMsg().groupThreadReaction(
                                                                      threadId:
                                                                          emojiCounts![index]
                                                                              .groupThreadId!,
                                                                      emoji: emojiCounts![
                                                                              index]
                                                                          .emoji!,
                                                                      emojiName:
                                                                          "",
                                                                      selectedGpMsgId:
                                                                          widget
                                                                              .messageID,
                                                                      sChannelId:
                                                                          widget
                                                                              .channelID);
                                                                },
                                                                onLongPress:
                                                                    () async {
                                                                  HapticFeedback
                                                                      .heavyImpact();
                                                                  await showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (BuildContext
                                                                            context) {
                                                                      return SimpleDialog(
                                                                        title:
                                                                            Center(
                                                                          child:
                                                                              Text(
                                                                            "People Who React",
                                                                            style:
                                                                                TextStyle(fontSize: 20),
                                                                          ),
                                                                        ),
                                                                        children: [
                                                                          SizedBox(
                                                                            width:
                                                                                MediaQuery.of(context).size.width,
                                                                            child:
                                                                                ListView.builder(
                                                                              shrinkWrap: true,
                                                                              itemBuilder: (ctx, index) {
                                                                                return SingleChildScrollView(
                                                                                  child: SimpleDialogOption(
                                                                                    onPressed: () => Navigator.pop(context),
                                                                                    child: Center(
                                                                                      child: Text(
                                                                                        "${userNames[index]}",
                                                                                        style: TextStyle(fontSize: 18, letterSpacing: 0.1),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              },
                                                                              itemCount: userNames.length,
                                                                            ),
                                                                          )
                                                                        ],
                                                                      );
                                                                    },
                                                                  );
                                                                },
                                                                style:
                                                                    ButtonStyle(
                                                                  padding: WidgetStateProperty.all(
                                                                      EdgeInsets
                                                                          .zero),
                                                                  minimumSize:
                                                                      WidgetStateProperty
                                                                          .all(Size(
                                                                              50,
                                                                              25)),
                                                                ),
                                                                child: Text(
                                                                  '${emojiCounts![index].emoji} ${emojiCounts![index].emojiCount}',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .blueAccent,
                                                                    fontSize:
                                                                        14,
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
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            },
                          ),
                        ),
                      ),
                      if (hasFileToSEnd && files.isNotEmpty)
                        FileDisplayWidget(files: files, platform: platform),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(25),
                                    topRight: Radius.circular(25))),
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(15, 10, 15, 10),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20)),
                              child: QuillEditor.basic(
                                focusNode: _focusNode,
                                configurations: QuillEditorConfigurations(
                                  minHeight: 20,
                                  maxHeight: 100,
                                  controller: _quilcontroller,
                                  placeholder: "send messages...",
                                  // readOnly: false,
                                  sharedConfigurations:
                                      const QuillSharedConfigurations(
                                    locale: Locale('de'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (isCursor &&
                              isfirstField &&
                              isClickedTextFormat == false)
                            Container(
                              color: Colors.grey[300],
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          child: IconButton(
                                              onPressed: () {
                                                pickFiles();
                                              },
                                              icon: const Icon(
                                                  Icons.attach_file_outlined))),
                                      IconButton(
                                          onPressed: () {
                                            setState(() {
                                              isfirstField = false;
                                              isSelectText = true;
                                              isClickedTextFormat = true;
                                            });
                                          },
                                          icon: Icon(
                                            Icons.text_format,
                                            size: 30,
                                            color: Colors.grey[800],
                                          )),
                                    ],
                                  ),
                                  if (isEdit)
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          margin: const EdgeInsets.fromLTRB(
                                              0, 0, 10, 0),
                                          decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          child: IconButton(
                                              color: Colors.white,
                                              onPressed: () {
                                                // _quilcontroller.clear();
                                                _clearEditor();
                                                SystemChannels.textInput
                                                    .invokeMethod(
                                                        'TextInput.hide'); // Hide the keyboard

                                                setState(() {
                                                  isEdit = false;
                                                  isCursor = false;
                                                });
                                              },
                                              icon: const Icon(Icons.close)),
                                        ),
                                        Container(
                                          width: 40,
                                          height: 40,
                                          margin: const EdgeInsets.fromLTRB(
                                              0, 0, 10, 0),
                                          decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          child: IconButton(
                                              onPressed: () {
                                                // for mention name
                                                String plaintext =
                                                    _quilcontroller.document
                                                        .toPlainText();
                                                List<String> currentMentions =
                                                    [];
                                                for (var i = 0;
                                                    i < uniqueList.length;
                                                    i++) {
                                                  if (plaintext.contains(
                                                      uniqueList[i]["name"])) {
                                                    currentMentions.add(
                                                        "@${uniqueList[i]["name"]}");
                                                  }
                                                }

                                                htmlContent = detectStyles();

                                                if (htmlContent
                                                    .contains("<p>")) {
                                                  htmlContent = htmlContent
                                                      .replaceAll("<p>", "");
                                                  htmlContent = htmlContent
                                                      .replaceAll("</p>", "");
                                                }

                                                if (htmlContent
                                                    .contains("<code>")) {
                                                  htmlContent =
                                                      htmlContent.replaceAll(
                                                          "<code>",
                                                          "<span class='highlight'>");
                                                  htmlContent =
                                                      htmlContent.replaceAll(
                                                          "</code>", "</span>");
                                                }

                                                if (htmlContent
                                                    .contains("<pre>")) {
                                                  htmlContent =
                                                      htmlContent.replaceAll(
                                                          "<pre>",
                                                          "<div class='ql-code-block'>");
                                                  htmlContent =
                                                      htmlContent.replaceAll(
                                                          "</pre>", "</div>");
                                                  htmlContent =
                                                      htmlContent.replaceAll(
                                                          "\n", "<br/>");
                                                }

                                                setState(() {
                                                  mentionnames.clear();
                                                  mentionnames
                                                      .addAll(currentMentions);
                                                  isEdit = false;
                                                });

                                                GpThreadMsg()
                                                    .editGroupThreadMessage(
                                                        htmlContent,
                                                        editTreadId!,
                                                        mentionnames);
                                                _clearEditor();
                                                SystemChannels.textInput
                                                    .invokeMethod(
                                                        'TextInput.hide'); // Hide the keyboard
                                              },
                                              color: Colors.white,
                                              icon: const Icon(Icons.check)),
                                        ),
                                      ],
                                    )
                                  else
                                    Container(
                                      width: 40,
                                      height: 40,
                                      margin: const EdgeInsets.fromLTRB(
                                          10, 0, 0, 0),
                                      decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              255, 24, 103, 167),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: IconButton(
                                          onPressed: () {
                                            AuthService.checkTokenStatus(
                                                context);
                                            // for mention name
                                            String plaintext = _quilcontroller
                                                .document
                                                .toPlainText();
                                            List<String> currentMentions = [];
                                            for (var i = 0;
                                                i < uniqueList.length;
                                                i++) {
                                              if (plaintext.contains(
                                                  uniqueList[i]["name"])) {
                                                currentMentions.add(
                                                    "@${uniqueList[i]["name"]}");
                                              }
                                            }

                                            htmlContent = detectStyles();

                                            if (htmlContent.contains("<p>")) {
                                              htmlContent = htmlContent
                                                  .replaceAll("<p>", "");
                                              htmlContent = htmlContent
                                                  .replaceAll("</p>", "");
                                            }

                                            if (htmlContent
                                                .contains("<code>")) {
                                              htmlContent =
                                                  htmlContent.replaceAll(
                                                      "<code>",
                                                      "<span class='highlight'>");
                                              htmlContent =
                                                  htmlContent.replaceAll(
                                                      "</code>", "</span>");
                                            }

                                            if (htmlContent.contains("<pre>")) {
                                              htmlContent = htmlContent.replaceAll(
                                                  "<pre>",
                                                  "<div class='ql-code-block'>");
                                              htmlContent =
                                                  htmlContent.replaceAll(
                                                      "</pre>", "</div>");
                                              htmlContent = htmlContent
                                                  .replaceAll("\n", "<br/>");
                                            }

                                            setState(() {
                                              mentionnames.clear();
                                              mentionnames
                                                  .addAll(currentMentions);
                                              isClickedTextFormat = false;
                                            });
                                            if (!htmlContent
                                                    .startsWith("<br/>") ||
                                                files.isNotEmpty) {
                                              sendGroupThreadData(
                                                  htmlContent,
                                                  widget.channelID!,
                                                  widget.messageID!,
                                                  mentionnames,
                                                  draftStatus);
                                              _clearEditor();
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.send,
                                            color: Colors.white,
                                          )),
                                    ),
                                ],
                              ),
                            ),
                          Visibility(
                            visible: isSelectText || isClickedTextFormat
                                ? true
                                : false,
                            child: Container(
                              color: Colors.grey[300],
                              padding:
                                  const EdgeInsets.fromLTRB(8.0, 0, 8.0, 10.0),
                              child: Row(
                                children: [
                                  IconButton(
                                      onPressed: () {
                                        setState(() {
                                          isClickedTextFormat = false;
                                          isSelectText = false;
                                          isfirstField = true;
                                        });
                                      },
                                      icon: const Icon(Icons.close)),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 3.0),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: isBold
                                                  ? Colors.grey[400]
                                                  : Colors.grey[300],
                                            ),
                                            child: discode
                                                ? const IconButton(
                                                    onPressed: null,
                                                    icon:
                                                        Icon(Icons.format_bold))
                                                : IconButton(
                                                    icon: const Icon(
                                                        Icons.format_bold),
                                                    onPressed: () {
                                                      setState(() {
                                                        if (isBold) {
                                                          isBold = false;
                                                        } else {
                                                          isBold = true;
                                                        }
                                                      });
                                                      if (isBold) {
                                                        _quilcontroller
                                                            .formatSelection(
                                                                quill.Attribute
                                                                    .bold);
                                                      } else {
                                                        _quilcontroller
                                                            .formatSelection(quill
                                                                    .Attribute
                                                                .clone(
                                                                    quill
                                                                        .Attribute
                                                                        .bold,
                                                                    null));
                                                      }
                                                    },
                                                  ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 3.0),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: isItalic
                                                  ? Colors.grey[400]
                                                  : Colors.grey[300],
                                            ),
                                            child: discode
                                                ? const IconButton(
                                                    onPressed: null,
                                                    icon: Icon(
                                                        Icons.format_italic))
                                                : IconButton(
                                                    icon: const Icon(
                                                        Icons.format_italic),
                                                    onPressed: () {
                                                      setState(() {
                                                        if (isItalic) {
                                                          isItalic = false;
                                                        } else {
                                                          isItalic = true;
                                                        }
                                                      });
                                                      if (isItalic) {
                                                        _quilcontroller
                                                            .formatSelection(
                                                                quill.Attribute
                                                                    .italic);
                                                      } else {
                                                        _quilcontroller
                                                            .formatSelection(quill
                                                                    .Attribute
                                                                .clone(
                                                                    quill
                                                                        .Attribute
                                                                        .italic,
                                                                    null));
                                                      }
                                                    },
                                                  ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 3.0),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: isStrike
                                                  ? Colors.grey[400]
                                                  : Colors.grey[300],
                                            ),
                                            child: discode
                                                ? const IconButton(
                                                    onPressed: null,
                                                    icon: Icon(
                                                        Icons.strikethrough_s))
                                                : IconButton(
                                                    icon: const Icon(
                                                        Icons.strikethrough_s),
                                                    onPressed: () {
                                                      setState(() {
                                                        if (isStrike) {
                                                          isStrike = false;
                                                        } else {
                                                          isStrike = true;
                                                        }
                                                      });
                                                      if (isStrike) {
                                                        _quilcontroller
                                                            .formatSelection(quill
                                                                .Attribute
                                                                .strikeThrough);
                                                      } else {
                                                        _quilcontroller
                                                            .formatSelection(quill
                                                                    .Attribute
                                                                .clone(
                                                                    quill
                                                                        .Attribute
                                                                        .strikeThrough,
                                                                    null));
                                                      }
                                                    },
                                                  ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 3.0),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: isLink
                                                  ? Colors.grey[400]
                                                  : Colors.grey[300],
                                            ),
                                            child: discode
                                                ? const IconButton(
                                                    onPressed: null,
                                                    icon: Icon(Icons.link))
                                                : IconButton(
                                                    icon:
                                                        const Icon(Icons.link),
                                                    onPressed: () {
                                                      setState(() {
                                                        if (isLink) {
                                                          isLink = false;
                                                        } else {
                                                          isLink = true;
                                                          isBold = false;
                                                          isItalic = false;
                                                          isStrike = false;
                                                        }
                                                      });
                                                      if (isLink) {
                                                        _insertLink();
                                                      }
                                                      _quilcontroller
                                                          .formatSelection(quill
                                                                  .Attribute
                                                              .clone(
                                                                  quill
                                                                      .Attribute
                                                                      .bold,
                                                                  null));
                                                      _quilcontroller
                                                          .formatSelection(quill
                                                                  .Attribute
                                                              .clone(
                                                                  quill
                                                                      .Attribute
                                                                      .italic,
                                                                  null));
                                                      _quilcontroller
                                                          .formatSelection(quill
                                                                  .Attribute
                                                              .clone(
                                                                  quill
                                                                      .Attribute
                                                                      .strikeThrough,
                                                                  null));
                                                    }),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 3.0),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: isOrderList
                                                  ? Colors.grey[400]
                                                  : Colors.grey[300],
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                  Icons.format_list_numbered),
                                              onPressed: () {
                                                setState(() {
                                                  setState(() {
                                                    if (isOrderList) {
                                                      isBlockquote = false;
                                                      isOrderList = false;
                                                      isUnorderList = false;
                                                      isCodeblock = false;
                                                    } else {
                                                      isBlockquote = false;
                                                      isOrderList = true;
                                                      isUnorderList = false;
                                                      isCodeblock = false;
                                                      discode = false;
                                                    }
                                                  });
                                                });

                                                if (isOrderList) {
                                                  _quilcontroller
                                                      .formatSelection(
                                                          quill.Attribute.ol);
                                                } else {
                                                  _quilcontroller
                                                      .formatSelection(
                                                          quill.Attribute.clone(
                                                              quill
                                                                  .Attribute.ol,
                                                              null));
                                                }
                                              },
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 3.0),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: isUnorderList
                                                  ? Colors.grey[400]
                                                  : Colors.grey[300],
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                  Icons.format_list_bulleted),
                                              onPressed: () {
                                                setState(() {
                                                  if (isUnorderList) {
                                                    isBlockquote = false;
                                                    isOrderList = false;
                                                    isUnorderList = false;
                                                    isCodeblock = false;
                                                  } else {
                                                    isBlockquote = false;
                                                    isOrderList = false;
                                                    isUnorderList = true;
                                                    isCodeblock = false;
                                                    discode = false;
                                                  }
                                                });
                                                if (isUnorderList) {
                                                  _quilcontroller
                                                      .formatSelection(
                                                          quill.Attribute.ul);
                                                } else {
                                                  _quilcontroller
                                                      .formatSelection(
                                                          quill.Attribute.clone(
                                                              quill
                                                                  .Attribute.ul,
                                                              null));
                                                }
                                              },
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 3.0),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: isBlockquote
                                                  ? Colors.grey[400]
                                                  : Colors.grey[300],
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                  Icons.align_horizontal_left),
                                              onPressed: () {
                                                setState(() {
                                                  setState(() {
                                                    if (isBlockquote) {
                                                      isBlockquote = false;
                                                      isOrderList = false;
                                                      isUnorderList = false;
                                                      isCodeblock = false;
                                                    } else {
                                                      isBlockquote = true;
                                                      isOrderList = false;
                                                      isUnorderList = false;
                                                      isCodeblock = false;
                                                      discode = false;
                                                    }
                                                  });
                                                });
                                                if (isBlockquote) {
                                                  _quilcontroller
                                                      .formatSelection(quill
                                                          .Attribute
                                                          .blockQuote);
                                                } else {
                                                  _quilcontroller
                                                      .formatSelection(
                                                          quill.Attribute.clone(
                                                              quill.Attribute
                                                                  .blockQuote,
                                                              null));
                                                }
                                              },
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 3.0),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: isCode
                                                  ? Colors.grey[400]
                                                  : Colors.grey[300],
                                            ),
                                            child: discode
                                                ? const IconButton(
                                                    onPressed: null,
                                                    icon: Icon(Icons.code))
                                                : IconButton(
                                                    icon:
                                                        const Icon(Icons.code),
                                                    onPressed: () {
                                                      setState(() {
                                                        if (isCode) {
                                                          isCode = false;
                                                        } else {
                                                          isCode = true;
                                                        }
                                                      });
                                                      if (isCode) {
                                                        _quilcontroller
                                                            .formatSelection(
                                                                quill.Attribute
                                                                    .inlineCode);
                                                      } else {
                                                        _quilcontroller
                                                            .formatSelection(quill
                                                                    .Attribute
                                                                .clone(
                                                                    quill
                                                                        .Attribute
                                                                        .inlineCode,
                                                                    null));
                                                      }
                                                    },
                                                  ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 3.0),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              color: isCodeblock
                                                  ? Colors.grey[400]
                                                  : Colors.grey[300],
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.article),
                                              onPressed: () {
                                                setState(() {
                                                  if (isCodeblock) {
                                                    isBlockquote = false;
                                                    isOrderList = false;
                                                    isUnorderList = false;
                                                    isCodeblock = false;
                                                    isCode = false;
                                                    discode = false;
                                                  } else {
                                                    isBlockquote = false;
                                                    isOrderList = false;
                                                    isUnorderList = false;
                                                    isCodeblock = true;
                                                    isCode = false;
                                                    discode = true;
                                                  }
                                                });
                                                if (isCodeblock) {
                                                  _quilcontroller
                                                      .formatSelection(quill
                                                          .Attribute.codeBlock);
                                                  _quilcontroller
                                                      .formatSelection(
                                                          quill.Attribute.clone(
                                                              quill.Attribute
                                                                  .bold,
                                                              null));
                                                  _quilcontroller
                                                      .formatSelection(
                                                          quill.Attribute.clone(
                                                              quill.Attribute
                                                                  .italic,
                                                              null));
                                                  _quilcontroller
                                                      .formatSelection(
                                                          quill.Attribute.clone(
                                                              quill.Attribute
                                                                  .inlineCode,
                                                              null));
                                                  _quilcontroller
                                                      .formatSelection(
                                                          quill.Attribute.clone(
                                                              quill.Attribute
                                                                  .strikeThrough,
                                                              null));
                                                } else {
                                                  _quilcontroller
                                                      .formatSelection(
                                                          quill.Attribute.clone(
                                                              quill.Attribute
                                                                  .codeBlock,
                                                              null));
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isEdit)
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          margin: const EdgeInsets.fromLTRB(
                                              0, 0, 10, 0),
                                          decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          child: IconButton(
                                              color: Colors.white,
                                              onPressed: () {
                                                // _quilcontroller.clear();
                                                _clearEditor();
                                                SystemChannels.textInput
                                                    .invokeMethod(
                                                        'TextInput.hide'); // Hide the keyboard
                                                setState(() {
                                                  isEdit = false;
                                                });
                                              },
                                              icon: const Icon(Icons.close)),
                                        ),
                                        Container(
                                          width: 40,
                                          height: 40,
                                          margin: const EdgeInsets.fromLTRB(
                                              0, 0, 10, 0),
                                          decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          child: IconButton(
                                              onPressed: () {
                                                // for mention name
                                                String plaintext =
                                                    _quilcontroller.document
                                                        .toPlainText();
                                                List<String> currentMentions =
                                                    [];
                                                for (var i = 0;
                                                    i < uniqueList.length;
                                                    i++) {
                                                  if (plaintext.contains(
                                                      uniqueList[i]["name"])) {
                                                    currentMentions.add(
                                                        "@${uniqueList[i]["name"]}");
                                                  }
                                                }

                                                htmlContent = detectStyles();

                                                if (htmlContent
                                                    .contains("<p>")) {
                                                  htmlContent = htmlContent
                                                      .replaceAll("<p>", "");
                                                  htmlContent = htmlContent
                                                      .replaceAll("</p>", "");
                                                }

                                                if (htmlContent
                                                    .contains("<code>")) {
                                                  htmlContent =
                                                      htmlContent.replaceAll(
                                                          "<code>",
                                                          "<span class='highlight'>");
                                                  htmlContent =
                                                      htmlContent.replaceAll(
                                                          "</code>", "</span>");
                                                }

                                                if (htmlContent
                                                    .contains("<pre>")) {
                                                  htmlContent =
                                                      htmlContent.replaceAll(
                                                          "<pre>",
                                                          "<div class='ql-code-block'>");
                                                  htmlContent =
                                                      htmlContent.replaceAll(
                                                          "</pre>", "</div>");
                                                  htmlContent =
                                                      htmlContent.replaceAll(
                                                          "\n", "<br/>");
                                                }

                                                setState(() {
                                                  mentionnames.clear();
                                                  mentionnames
                                                      .addAll(currentMentions);
                                                  isEdit = false;
                                                });

                                                GpThreadMsg()
                                                    .editGroupThreadMessage(
                                                        htmlContent,
                                                        editTreadId!,
                                                        mentionnames);
                                                _clearEditor();
                                                SystemChannels.textInput
                                                    .invokeMethod(
                                                        'TextInput.hide'); // Hide the keyboard
                                              },
                                              color: Colors.white,
                                              icon: const Icon(Icons.check)),
                                        ),
                                      ],
                                    )
                                  else
                                    Container(
                                      width: 40,
                                      height: 40,
                                      margin: const EdgeInsets.fromLTRB(
                                          10, 0, 0, 0),
                                      decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              255, 24, 103, 167),
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: IconButton(
                                          onPressed: () {
                                            AuthService.checkTokenStatus(
                                                context);
                                            // for mention name
                                            String plaintext = _quilcontroller
                                                .document
                                                .toPlainText();
                                            List<String> currentMentions = [];
                                            for (var i = 0;
                                                i < uniqueList.length;
                                                i++) {
                                              if (plaintext.contains(
                                                  uniqueList[i]["name"])) {
                                                currentMentions.add(
                                                    "@${uniqueList[i]["name"]}");
                                              }
                                            }

                                            htmlContent = detectStyles();

                                            if (htmlContent.contains("<p>")) {
                                              htmlContent = htmlContent
                                                  .replaceAll("<p>", "");
                                              htmlContent = htmlContent
                                                  .replaceAll("</p>", "");
                                            }

                                            if (htmlContent
                                                .contains("<code>")) {
                                              htmlContent =
                                                  htmlContent.replaceAll(
                                                      "<code>",
                                                      "<span class='highlight'>");
                                              htmlContent =
                                                  htmlContent.replaceAll(
                                                      "</code>", "</span>");
                                            }

                                            if (htmlContent.contains("<pre>")) {
                                              htmlContent = htmlContent.replaceAll(
                                                  "<pre>",
                                                  "<div class='ql-code-block'>");
                                              htmlContent =
                                                  htmlContent.replaceAll(
                                                      "</pre>", "</div>");
                                              htmlContent = htmlContent
                                                  .replaceAll("\n", "<br/>");
                                            }

                                            setState(() {
                                              mentionnames.clear();
                                              mentionnames
                                                  .addAll(currentMentions);
                                              isClickedTextFormat = false;
                                            });

                                            if (!htmlContent
                                                    .startsWith("<br/>") ||
                                                files.isNotEmpty) {
                                              sendGroupThreadData(
                                                  htmlContent,
                                                  widget.channelID!,
                                                  widget.messageID!,
                                                  mentionnames,
                                                  draftStatus);
                                              _clearEditor();
                                            }

                                            // sendGroupThreadData(
                                            //     htmlContent,
                                            //     widget.channelID!,
                                            //     widget.messageID!,
                                            //     mentionnames,
                                            //     draftStatus);
                                          },
                                          icon: const Icon(
                                            Icons.send,
                                            color: Colors.white,
                                          )),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]),
                    if (showScrollButton)
                      Positioned(
                        bottom: isCursor ? 120 : 60,
                        left: 145,
                        child: IconButton(
                          onPressed: () {
                            _scrollToBottom();
                            setState(() {
                              showScrollButton = false;
                            });
                          },
                          icon: const CircleAvatar(
                            backgroundColor: Color.fromARGB(117, 0, 0, 0),
                            radius: 25,
                            child: Icon(
                              Icons.arrow_downward,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                  ])));
    } else {
      return CustomLogOut();
    }
  }
}
