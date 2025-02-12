import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:dio/dio.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_frontend/const/build_fiile.dart';
import 'package:flutter_frontend/const/build_mulit_file.dart';
import 'package:flutter_frontend/const/build_single_file.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/const/permissions.dart';
import 'package:flutter_frontend/constants.dart';

import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/customLoadPageForGroup.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/screens/check_token_status.dart';
import 'package:flutter_frontend/screens/groupMessage/Drawer/drawer.dart';
import 'package:flutter_frontend/screens/home/workspacehome.dart';
import 'package:flutter_frontend/services/groupMessageService/group_message_service.dart';
import 'package:flutter_frontend/services/userservice/api_controller_service.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/model/groupMessage.dart';

import 'package:flutter_frontend/screens/groupMessage/groupThread.dart';
import 'package:flutter_frontend/services/groupMessageService/gropMessage/groupMessage_Services.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_html/flutter_html.dart' as flutter_html;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
// ignore_for_file: prefer_const_constructors, must_be_immutable

// ignore: depend_on_referenced_packages

class GroupMessage extends StatefulWidget {
  final channelID, channelName, workspace_id, memberName;
  final channelStatus;
  final member;
  GroupMessage(
      {super.key,
      this.channelID,
      this.channelStatus,
      this.channelName,
      this.member,
      this.workspace_id,
      this.memberName});

  @override
  State<GroupMessage> createState() => _GroupMessage();
}

class _GroupMessage extends State<GroupMessage> with RouteAware {
  GlobalKey<FlutterMentionsState> key = GlobalKey<FlutterMentionsState>();
  final groupMessageService = GroupMessageServices(Dio(BaseOptions(headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  })));
  late ScrollController _scrollController;
  RetrieveGroupMessage? retrieveGroupMessage;
  Retrievehome? retrievehome;
  GroupMessgeModel? groupdata;
  String currentUserName =
      SessionStore.sessionData!.currentUser!.name.toString();
  int currentUserId = SessionStore.sessionData!.currentUser!.id!.toInt();

  List<int>? tGroupStarMsgids = [];

  List<TGroupMessages>? tGroupMessages = [];
  List<EmojiCountsforGpMsg>? emojiCounts = [];
  List<ReactUserDataForGpMsg>? reactUserData = [];

  WebSocketChannel? _channel;
  String? groupMessageName;
  bool isButtom = false;

  bool isLoading = false;
  bool isSelected = false;
  bool isStarred = false;
  int? _selectedMessageIndex;
  int? selectUserId;
  bool hasFileToSEnd = false;
  List<PlatformFile> files = [];
  late String localpath;
  late bool permissionReady;
  TargetPlatform? platform;
  final PermissionClass permissions = PermissionClass();
  String? fileText;

  BuildSingleFile singleFile = BuildSingleFile();
  BuildMulitFile mulitFile = BuildMulitFile();
  final _apiSerive = GroupMessageServiceImpl();
  late List<Map<String, Object?>> mention;

  bool isCursor = false;
  bool isSelectText = false;
  bool isfirstField = true;
  bool isClickedTextFormat = false;
  String htmlContent = "";
  bool draftStatus = false;
  int? draftedGroupMessageId;
  quill.QuillController _quilcontroller = quill.QuillController.basic();
  final FocusNode _focusNode = FocusNode();
  List uniqueList = [];
  OverlayEntry? _overlayEntry;
  final List _userList = []; // Example user list
  List<dynamic> _filteredUsers = [];
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
  bool isEnter = false;
  bool discode = false;
  bool isEdit = false;
  List _previousOps = [];
  String editMsg = "";
  bool showScrollButton = false;
  bool isScrolling = false;
  bool isMessaging = false;

  String selectedEmoji = "";
  String _seletedEmojiName = "";
  bool _isEmojiSelected = false;
  bool emojiBorderColor = false;
  @override
  void initState() {
    super.initState();
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
    _scrollController.removeListener(scrollListener);
    _scrollController.dispose();
  }

  void connectWebSocket() {
    var url =
        'ws://$wsUrl/cable?channel_id=${widget.workspace_id}&user_id=$currentUserId';
    _channel = WebSocketChannel.connect(Uri.parse(url));

    final subscriptionMessage = jsonEncode({
      'command': 'subscribe',
      'identifier': jsonEncode({'channel': 'GroupChannel'}),
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
                  msg.containsKey('groupmsg') &&
                  msg['m_channel_id'] == widget.channelID) {
                var groupMessage = msg['groupmsg'];
                int id = msg['id'];
                var date = msg['created_at'];
                int mUserId = msg['m_user_id'];
                bool draftMessageStatus = msg['draft_message_status'];
                List<dynamic> fileUrls = [];
                List<dynamic> fileName = [];
                String senduser = messageContent['sender_name'];
                String? profileImage = messageContent['profile_image'];

                if (messageContent.containsKey('files')) {
                  var files = messageContent['files'];
                  if (files != null) {
                    fileUrls = files.map((file) => file['file']).toList();
                  }
                }

                if (messageContent.containsKey('files')) {
                  var files = messageContent['files'];
                  if (files != null) {
                    fileName = files.map((file) => file['file_name']).toList();
                  }
                }

                setState(() {
                  tGroupMessages!.add(TGroupMessages(
                      createdAt: date,
                      fileUrls: fileUrls,
                      groupmsg: groupMessage,
                      id: id,
                      sendUserId: mUserId,
                      name: senduser,
                      profileName: profileImage,
                      fileName: fileName,
                      draftMessageStatus: draftMessageStatus));
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (isMessaging == false) {
                      _scrollToBottom();
                    }
                  });
                });
              } else {}
            } else if (messageContent.containsKey('messaged_star') &&
                messageContent['m_channel_id'] == widget.channelID) {
              var messageStarData = messageContent['messaged_star'];

              if (messageStarData != null &&
                  messageStarData['userid'] == currentUserId) {
                int groupmsgid = messageStarData['groupmsgid'];

                setState(() {
                  tGroupStarMsgids!.add(groupmsgid);
                });
              } else {}
            } else if (messageContent.containsKey('unstared_message') &&
                messageContent['m_channel_id'] == widget.channelID) {
              var unstaredMsg = messageContent['unstared_message'];

              if (unstaredMsg != null &&
                  unstaredMsg['userid'] == currentUserId) {
                int unstaredMsgId = unstaredMsg['groupmsgid'];
                setState(() {
                  tGroupStarMsgids!.removeWhere(
                    (element) => element == unstaredMsgId,
                  );
                });
              }
            } else if (messageContent.containsKey('react_message') &&
                messageContent['m_channel_id'] == widget.channelID) {
              var reactmsg = messageContent['react_message'];
              var userId = reactmsg['userid'];
              var groupmsgid = reactmsg['groupmsgid'];
              var emoji = reactmsg['emoji'];
              var reactUserInfo = messageContent['reacted_user_info'];

              var emojiCount;
              bool emojiExists = false;
              for (var element in emojiCounts!) {
                if (element.emoji == emoji &&
                    element.groupmsgid == groupmsgid) {
                  emojiCount = element.emojiCount! + 1;
                  element.emojiCount = emojiCount;
                  emojiExists = true;
                  break;
                }
              }
              if (!emojiExists) {
                emojiCount = 1;
                emojiCounts!.add(EmojiCountsforGpMsg(
                    groupmsgid: groupmsgid,
                    emoji: emoji,
                    emojiCount: emojiCount));
              }

              setState(() {
                if (emojiExists) {
                  emojiCounts!.add(EmojiCountsforGpMsg(
                      groupmsgid: groupmsgid, emojiCount: emojiCount));
                }
                reactUserData!.add(ReactUserDataForGpMsg(
                    emoji: emoji,
                    groupmsgid: groupmsgid,
                    name: reactUserInfo,
                    userid: userId));
              });
            } else if (messageContent.containsKey('remove_reaction') &&
                messageContent['m_channel_id'] == widget.channelID) {
              var deleteRection = messageContent['remove_reaction'];
              var userId = deleteRection['userid'];
              var groupMessageID = deleteRection['groupmsgid'];
              var emoji = deleteRection['emoji'];
              var reactUserInfo = messageContent['reacted_user_info'];

              setState(() {
                for (var element in emojiCounts!) {
                  if (element.emoji == emoji &&
                      element.groupmsgid == groupMessageID) {
                    element.emojiCount = element.emojiCount! - 1;
                    break;
                  }
                }

                reactUserData?.removeWhere((element) =>
                    element.groupmsgid == groupMessageID &&
                    element.emoji == emoji &&
                    element.name == reactUserInfo &&
                    element.userid == userId);
              });
            } else if (messageContent.containsKey('update_group_message')) {
              var msg = messageContent['update_group_message'];
              var groupMessage = msg['groupmsg'];
              int id = msg['id'];
              var date = msg['created_at'];
              int mUserId = msg['m_user_id'];
              List<dynamic> fileUrls = [];
              List<dynamic> fileName = [];
              String senduser = messageContent['sender_name'];
              String? profileImage = messageContent['profile_image'];

              tGroupMessages!.removeWhere((e) => e.id == id);
              setState(() {
                tGroupMessages!.add(TGroupMessages(
                    createdAt: date,
                    fileUrls: fileUrls,
                    groupmsg: groupMessage,
                    id: id,
                    sendUserId: mUserId,
                    name: senduser,
                    profileName: profileImage,
                    fileName: fileName));
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (isMessaging == false) {
                    _scrollToBottom();
                  }
                });
              });
            } else {
              var deletemsg = messageContent['delete_msg'];
              int id = deletemsg['id'];
              setState(() {
                tGroupMessages?.removeWhere((element) => element.id == id);
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

  void pickFiles() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    setState(() {
      files.addAll(result.files);
      hasFileToSEnd = true;
    });
  }

  void loadMessage() async {
    var token = await AuthController().getToken();
    GroupMessgeModel data =
        await groupMessageService.getAllGpMsg(widget.channelID, token!);

    setState(() {
      retrieveGroupMessage = data.retrieveGroupMessage;
      retrievehome = data.retrievehome;
      groupdata = data;
      tGroupStarMsgids = data.retrieveGroupMessage!.tGroupStarMsgids;
      emojiCounts = data.retrieveGroupMessage!.emojiCounts;
      reactUserData = data.retrieveGroupMessage!.reactUserData;
      tGroupMessages = data.retrieveGroupMessage!.tGroupMessages;
      isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      tGroupMessages?.forEach((tGroupMessage) {
        if (tGroupMessage.draftMessageStatus == true &&
            tGroupMessage.sendUserId == currentUserId) {
          insertEditText(tGroupMessage.groupmsg);
        }
      });
    });
    mention = retrieveGroupMessage!.mChannelUsers!.map((e) {
      return {'display': e.name, 'name': e.name};
    }).toList();
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

  Future<void> sendGroupMessageData(String groupMessage, int channelId,
      List<String> mentionName, bool draftStatus) async {
    if (groupMessage.startsWith("<br/>")) {
      groupMessage = groupMessage.replaceAll("<br/>", " ");
    }
    if (groupMessage.isNotEmpty || files.isNotEmpty) {
      try {
        await _apiSerive.sendGroupMessageData(
            groupMessage, channelId, mentionName, files, draftStatus);
        tGroupMessages?.forEach((tGroupMessage) {
          if (tGroupMessage.draftMessageStatus == true &&
              tGroupMessage.sendUserId == currentUserId) {
            _apiSerive.deleteGroupMessage(tGroupMessage.id!, widget.channelID);
          }
        });
        files.clear();
      } catch (e) {
        rethrow;
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState!.openDrawer();
  }

  String? channelName;
  int? memberCount;

  String detectStyles() {
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
    // final doc = _quilcontroller.document;
    // final text = doc.toPlainText();
    // final selectedText = text.substring(selection.start, selection.end).trim();

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
        discode = false;
      });
    } else {
      setState(() {
        isBold = false;
      });
    }

    if (checkLastItalic) {
      setState(() {
        isItalic = true;
        discode = false;
      });
    } else {
      setState(() {
        isItalic = false;
      });
    }

    if (checkLastStrikethrough) {
      setState(() {
        isStrike = true;
        discode = false;
      });
    } else {
      setState(() {
        isStrike = false;
      });
    }

    if (checkLastCode) {
      setState(() {
        isCode = true;
        discode = false;
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

  void insertEditText(msg) {
    Delta delta = convertHtmlToDelta(msg);
    _quilcontroller = quill.QuillController(
      document: quill.Document.fromDelta(delta),
      selection: const TextSelection.collapsed(offset: 0),
    );
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

  void getMchannelUsers() {
    for (var i = 0; i < retrieveGroupMessage!.mChannelUsers!.length; i++) {
      var user = {
        'name': retrieveGroupMessage!.mChannelUsers![i].name,
        'status': retrieveGroupMessage!.mChannelUsers![i].activeStatus,
      };

      setState(() {
        // _userList.add(retrieveGroupMessage!.mChannelUsers![i].name!);
        _userList.add(user);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int? groupMessageID;
    final json = _quilcontroller.document.toDelta().toJson();
    final textFieldContent = quill.Document.fromJson(json).toPlainText().trim();
    return isLoading == false
        ? ShimmerGroup()
        : Scaffold(
            backgroundColor: kPriamrybackground,
            resizeToAvoidBottomInset: true,
            key: _scaffoldKey,
            drawer: Drawer(
              child: DrawerPage(
                  channelId: widget.channelID,
                  channelName: widget.channelName,
                  channelStatus: widget.channelStatus,
                  memberCount: memberCount,
                  memberName: widget.memberName,
                  member: retrieveGroupMessage!.mChannelUsers,
                  adminID: retrieveGroupMessage!.create_admin),
            ),
            appBar: AppBar(
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent, // Transparent status bar
                statusBarIconBrightness: Brightness.light,
              ),
              leading: IconButton(
                onPressed: () {
                  AuthService.checkTokenStatus(context);
                  if (textFieldContent.isNotEmpty) {
                    tGroupMessages?.forEach((tGroupMessage) {
                      if (tGroupMessage.draftMessageStatus == true &&
                          tGroupMessage.sendUserId == currentUserId) {
                        draftedGroupMessageId = tGroupMessage.id;
                      }
                    });
                    if (draftedGroupMessageId == null) {
                      htmlContent = detectStyles();
                      if (htmlContent.contains("<p>")) {
                        htmlContent = htmlContent.replaceAll("<p>", "");
                        htmlContent = htmlContent.replaceAll("</p>", "");
                      }
                      int channelId = widget.channelID;
                      draftStatus = true;
                      sendGroupMessageData(
                          htmlContent, channelId, mentionnames, draftStatus);
                    } else {
                      htmlContent = detectStyles();
                      if (htmlContent.contains("<p>")) {
                        htmlContent = htmlContent.replaceAll("<p>", "");
                        htmlContent = htmlContent.replaceAll("</p>", "");
                      }
                      _apiSerive.editGroupMessage(
                          htmlContent, draftedGroupMessageId!, mentionnames);
                    }
                  } else {
                    tGroupMessages?.forEach((tGroupMessage) {
                      if (tGroupMessage.draftMessageStatus == true &&
                          tGroupMessage.sendUserId == currentUserId) {
                        _apiSerive.deleteGroupMessage(
                            tGroupMessage.id!, widget.channelID);
                      }
                    });
                  }
                  // context.go("/home");
                  // Navigator.pushNamedAndRemoveUntil(context, "/home",(route) => false);
                  Navigator.pushAndRemoveUntil(
                      context, MaterialPageRoute(builder: (_) => const Nav()),(route) => false);
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              flexibleSpace: Container(
                decoration: themeColor,
              ),
              title: Row(
                children: [
                  Container(
                    child: widget.channelStatus
                        ? Icon(
                            Icons.tag,
                            color: Colors.white,
                          )
                        : Icon(
                            Icons.lock,
                            color: Colors.white,
                          ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    children: [
                      GestureDetector(
                          onTap: () {
                            _openDrawer();
                          },
                          child: Text(
                            widget.channelName,
                            style: TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          )),
                    ],
                  ),
                ],
              ),
            ),
            body: Stack(children: [
              Column(
                children: [
                  Expanded(
                      child: ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    controller: _scrollController,
                    itemCount: retrieveGroupMessage!.tGroupMessages!.length,
                    itemBuilder: (context, index) {
                      var channelStar = tGroupMessages!;

                      List<dynamic>? files = [];
                      files = tGroupMessages![index].fileUrls;

                      bool? draftGroupMEssageStatus =
                          tGroupMessages![index].draftMessageStatus;

                      if (retrieveGroupMessage!.tGroupMessages == null ||
                          retrieveGroupMessage!.tGroupMessages!.isEmpty ||
                          draftGroupMEssageStatus == true) {
                        return Container();
                      }

                      List<dynamic>? fileNames = [];
                      fileNames = tGroupMessages![index].fileName;

                      String? profileImage = tGroupMessages![index].profileName;

                      if (profileImage != null && !kIsWeb) {
                        profileImage = MinioToIP.replaceMinioWithIP(
                            profileImage, ipAddressForMinio);
                      }

                      List<int> tempStar = tGroupStarMsgids?.toList() ?? [];
                      bool isStared = tempStar.contains(channelStar[index].id);

                      String filterMsg = channelStar[index].groupmsg ?? "";

                      String message = filterMsg;

                      String sendername =
                          tGroupMessages![index].name.toString();

                      int count = channelStar[index].count ?? 0;
                      String time = channelStar[index].createdAt.toString();
                      DateTime date = DateTime.parse(time).toLocal();

                      String created_at =
                          DateFormat('MMM d, yyyy hh:mm a').format(date);
                      bool isMessageFromCurrentUser =
                          currentUserName == channelStar[index].name;
                      int sendUserId =
                          tGroupMessages![index].sendUserId!.toInt();
                      int messageId = tGroupMessages![index].id!.toInt();

                      bool? activeStatus;
                      for (var user in SessionStore.sessionData!.mUsers!) {
                        if (user.name == sendername) {
                          activeStatus = user.activeStatus;
                        }
                      }

                      return SingleChildScrollView(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMessageIndex = channelStar[index].id;
                              isSelected = !isSelected;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isMessageFromCurrentUser)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // This container is whole message box
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.8,
                                            decoration: const BoxDecoration(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(10),
                                                topRight: Radius.circular(10),
                                                bottomLeft: Radius.circular(10),
                                                bottomRight: Radius.zero,
                                              ),
                                              color: Color.fromARGB(
                                                  110, 121, 120, 124),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 10.0,
                                                  right: 10.0,
                                                  top: 5,
                                                  bottom: 5),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  //UserProfile Name DateTime MoreIcon
                                                  Container(
                                                    constraints: BoxConstraints(
                                                        maxHeight: 25),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Container(
                                                              height:
                                                                  20, //This is user's profile image width and height
                                                              width: 20,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white54,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            5),
                                                                border:
                                                                    Border.all(
                                                                  width: 1,
                                                                  color: Colors
                                                                      .amber
                                                                      .shade100,
                                                                ),
                                                              ),
                                                              child: FittedBox(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: profileImage ==
                                                                            null ||
                                                                        profileImage
                                                                            .isEmpty
                                                                    ? const Icon(
                                                                        Icons
                                                                            .person)
                                                                    : CircleAvatar(
                                                                        radius:
                                                                            20,
                                                                        backgroundImage:
                                                                            NetworkImage(profileImage),
                                                                      ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(sendername,
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .black,
                                                                )),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            IconButton(
                                                                onPressed:
                                                                    () async {
                                                                  setState(() {
                                                                    _selectedMessageIndex =
                                                                        channelStar[index]
                                                                            .id;
                                                                  });
                                                                  await showModalBottomSheet(
                                                                      constraints: BoxConstraints(
                                                                          maxHeight: MediaQuery.of(context).size.height *
                                                                              0.3,
                                                                          minWidth: MediaQuery.of(context).size.width *
                                                                              10),
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (BuildContext
                                                                              context) {
                                                                        return Container(
                                                                          child:
                                                                              Column(
                                                                            children: [
                                                                              TextButton.icon(
                                                                                label: Text(
                                                                                  "Add Star",
                                                                                  style: TextStyle(fontSize: 20, color: Colors.black),
                                                                                ),
                                                                                icon: Icon(
                                                                                  Icons.star,
                                                                                  color: isStared ? Colors.yellow : Colors.grey,
                                                                                ),
                                                                                onPressed: () async {
                                                                                  Navigator.pop(context);
                                                                                  if (_selectedMessageIndex != null) {
                                                                                    if (isStared) {
                                                                                      await _apiSerive.deleteGroupStarMessage(tGroupMessages![index].id!, widget.channelID!);
                                                                                    } else {
                                                                                      await _apiSerive.getMessageStar(tGroupMessages![index].id!, widget.channelID!);
                                                                                    }
                                                                                  }
                                                                                },
                                                                              ),
                                                                              Divider(height: 1, color: Colors.grey[300], indent: 15.0, endIndent: 15.0),
                                                                              TextButton.icon(
                                                                                label: Text(
                                                                                  "Reply Message",
                                                                                  style: TextStyle(fontSize: 20, color: Colors.black),
                                                                                ),
                                                                                onPressed: () async {
                                                                                  Navigator.pop(context);
                                                                                  Navigator.push(
                                                                                      context,
                                                                                      MaterialPageRoute(
                                                                                          builder: (_) => GpThreadMessage(
                                                                                                channelID: widget.channelID,
                                                                                                workspace_id: widget.workspace_id,
                                                                                                memberName: widget.memberName,
                                                                                                channelStatus: widget.channelStatus,
                                                                                                channelName: widget.channelName,
                                                                                                messageID: tGroupMessages![index].id,
                                                                                                message: message,
                                                                                                name: retrieveGroupMessage!.tGroupMessages![index].name.toString(),
                                                                                                time: created_at,
                                                                                                fname: retrieveGroupMessage!.tGroupMessages![index].name.toString(),
                                                                                                activeStatus: activeStatus,
                                                                                                fileNames: fileNames,
                                                                                                files: files,
                                                                                                profileImage: profileImage,
                                                                                              )));
                                                                                },
                                                                                icon: const Icon(
                                                                                  Icons.reply,
                                                                                  color: Colors.black,
                                                                                ),
                                                                              ),
                                                                              Divider(height: 1, color: Colors.grey[300], indent: 15.0, endIndent: 15.0),
                                                                              TextButton.icon(
                                                                                  label: Text(
                                                                                    "Add Reaction",
                                                                                    style: TextStyle(color: Colors.black, fontSize: 20),
                                                                                  ),
                                                                                  onPressed: () async {
                                                                                    Navigator.pop(context);
                                                                                    showModalBottomSheet(
                                                                                      context: context,
                                                                                      builder: (BuildContext context) {
                                                                                        return EmojiPicker(
                                                                                          onEmojiSelected: (category, Emoji emoji) async {
                                                                                            setState(() {
                                                                                              groupMessageID = tGroupMessages![index].id!.toInt();
                                                                                              selectedEmoji = emoji.emoji;
                                                                                              _seletedEmojiName = emoji.name;
                                                                                              _isEmojiSelected = true;
                                                                                            });

                                                                                            await _apiSerive.groupMessageReaction(emoji: selectedEmoji, msgId: groupMessageID!, sChannelId: widget.channelID, status: 1);

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
                                                                                      },
                                                                                    );
                                                                                  },
                                                                                  icon: Icon(
                                                                                    Icons.add_reaction_outlined,
                                                                                    color: Colors.black,
                                                                                  )),
                                                                              Divider(height: 1, color: Colors.grey[300], indent: 15.0, endIndent: 15.0),
                                                                              TextButton.icon(
                                                                                  label: Text(
                                                                                    "Edit Message",
                                                                                    style: TextStyle(color: Colors.black, fontSize: 20),
                                                                                  ),
                                                                                  onPressed: () {
                                                                                    Navigator.pop(context);
                                                                                    AuthService.checkTokenStatus(context);
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
                                                                                  icon: const Icon(
                                                                                    Icons.edit,
                                                                                    color: Colors.black,
                                                                                  )),
                                                                              Divider(height: 1, color: Colors.grey[300], indent: 15.0, endIndent: 15.0),
                                                                              if (sendUserId == currentUserId)
                                                                                TextButton.icon(
                                                                                  label: Text("Delete Message", style: TextStyle(fontSize: 20, color: Colors.red)),
                                                                                  onPressed: () async {
                                                                                    if (_selectedMessageIndex != null) {
                                                                                      await _apiSerive.deleteGroupMessage(tGroupMessages![index].id!, widget.channelID!);
                                                                                    }
                                                                                    Navigator.pop(context);
                                                                                  },
                                                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                                                ),
                                                                            ],
                                                                          ),
                                                                        );
                                                                      });
                                                                },
                                                                icon: Icon(
                                                                  Icons
                                                                      .more_vert_outlined,
                                                                )),
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: flutter_html.Html(
                                                      data: message,
                                                      style: {
                                                        "body": flutter_html.Style(
                                                            margin: flutter_html
                                                                .Margins.zero,
                                                            padding: flutter_html
                                                                .HtmlPaddings
                                                                .zero),
                                                        "img":
                                                            flutter_html.Style(
                                                          padding: flutter_html
                                                              .HtmlPaddings
                                                              .zero,
                                                          margin: flutter_html
                                                              .Margins.zero,
                                                        ),
                                                        ".ql-code-block": flutter_html.Style(
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[300],
                                                            padding: flutter_html
                                                                    .HtmlPaddings
                                                                .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        5),
                                                            margin: flutter_html
                                                                    .Margins
                                                                .symmetric(
                                                                    vertical:
                                                                        7)),
                                                        ".highlight":
                                                            flutter_html.Style(
                                                          display: flutter_html
                                                              .Display
                                                              .inlineBlock,
                                                          backgroundColor:
                                                              Colors.grey[300],
                                                          color: Colors.red,
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 5),
                                                        ),
                                                        "blockquote":
                                                            flutter_html.Style(
                                                          border: const Border(
                                                              left: BorderSide(
                                                                  color: Colors
                                                                      .grey,
                                                                  width: 5.0)),
                                                          margin: flutter_html
                                                                  .Margins
                                                              .symmetric(
                                                                  vertical:
                                                                      10.0),
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .only(left: 10),
                                                        ),
                                                        "ol":
                                                            flutter_html.Style(
                                                          margin: flutter_html
                                                                  .Margins
                                                              .symmetric(
                                                                  horizontal:
                                                                      10),
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .symmetric(
                                                                  horizontal:
                                                                      10),
                                                        ),
                                                        "ul":
                                                            flutter_html.Style(
                                                          display: flutter_html
                                                              .Display
                                                              .inlineBlock,
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .symmetric(
                                                                  horizontal:
                                                                      10),
                                                          margin: flutter_html
                                                              .Margins.all(0),
                                                        ),
                                                        "pre":
                                                            flutter_html.Style(
                                                          backgroundColor:
                                                              Colors.grey[300],
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 5),
                                                        ),
                                                        "code":
                                                            flutter_html.Style(
                                                          display: flutter_html
                                                              .Display
                                                              .inlineBlock,
                                                          backgroundColor:
                                                              Colors.grey[300],
                                                          color: Colors.red,
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 5),
                                                        )
                                                      },
                                                    ),
                                                  ),
                                                  if (files!.length == 1)
                                                    Center(
                                                      child: singleFile
                                                          .buildSingleFile(
                                                              files[0],
                                                              context,
                                                              platform,
                                                              fileNames
                                                                      ?.first ??
                                                                  ''),
                                                    ),

                                                  if (files.length >= 2)
                                                    mulitFile
                                                        .buildMultipleFiles(
                                                            files,
                                                            platform,
                                                            context,
                                                            fileNames ?? []),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 9.0),
                                                            child: RichText(
                                                              text: TextSpan(
                                                                text: '$count',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          15,
                                                                          15,
                                                                          15),
                                                                ),
                                                                children: const [
                                                                  WidgetSpan(
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsets.only(
                                                                          left:
                                                                              4.0),
                                                                      child:
                                                                          Icon(
                                                                        Icons
                                                                            .reply,
                                                                        size:
                                                                            16,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          Icon(Icons.star,
                                                              color: isStared
                                                                  ? Colors
                                                                      .yellow
                                                                  : Colors.grey,
                                                              size: 18),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            created_at,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 10,
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      14,
                                                                      13,
                                                                      13),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          //Showing Emoji
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.5,
                                            child: Wrap(
                                                direction: Axis.horizontal,
                                                spacing: 7,
                                                children: List.generate(
                                                    emojiCounts!.length,
                                                    (index) {
                                                  bool show = false;
                                                  List userIds = [];
                                                  List reactUsernames = [];

                                                  if (emojiCounts![index]
                                                          .groupmsgid ==
                                                      messageId) {
                                                    for (dynamic reactUser
                                                        in reactUserData!) {
                                                      if (reactUser
                                                                  .groupmsgid ==
                                                              emojiCounts![
                                                                      index]
                                                                  .groupmsgid &&
                                                          emojiCounts![index]
                                                                  .emoji ==
                                                              reactUser.emoji) {
                                                        userIds.add(
                                                            reactUser.userid);
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
                                                      i < emojiCounts!.length;
                                                      i++) {
                                                    if (emojiCounts![i]
                                                            .groupmsgid ==
                                                        messageId) {
                                                      for (int j = 0;
                                                          j <
                                                              reactUserData!
                                                                  .length;
                                                          j++) {
                                                        if (userIds.contains(
                                                            reactUserData![j]
                                                                .userid)) {
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
                                                                await _apiSerive.groupMessageReaction(
                                                                    emoji: emojiCounts![
                                                                            index]
                                                                        .emoji!,
                                                                    msgId: emojiCounts![
                                                                            index]
                                                                        .groupmsgid!,
                                                                    sChannelId:
                                                                        widget
                                                                            .channelID,
                                                                    status: 1);
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
                                                                '${emojiCounts![index].emoji} ${emojiCounts![index].emojiCount}',
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
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else //For Other User
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.8,
                                            decoration: const BoxDecoration(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(10),
                                                topRight: Radius.circular(10),
                                                bottomRight:
                                                    Radius.circular(10),
                                                bottomLeft: Radius.zero,
                                              ),
                                              color: Color.fromARGB(
                                                  111, 113, 81, 228),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 10.0,
                                                  right: 10.0,
                                                  top: 5,
                                                  bottom: 5),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    constraints: BoxConstraints(
                                                        maxHeight: 25),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Container(
                                                              height: 20,
                                                              width: 20,
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            5),
                                                                border:
                                                                    Border.all(
                                                                  width: 1,
                                                                  color: Colors
                                                                      .amber
                                                                      .shade100,
                                                                ),
                                                              ),
                                                              child: FittedBox(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          1.0),
                                                                  child: profileImage ==
                                                                              null ||
                                                                          profileImage
                                                                              .isEmpty
                                                                      ? const Icon(
                                                                          Icons
                                                                              .person)
                                                                      : CircleAvatar(
                                                                          radius:
                                                                              20,
                                                                          backgroundImage:
                                                                              NetworkImage(profileImage),
                                                                        ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(sendername,
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .black,
                                                                ))
                                                          ],
                                                        ),
                                                        //Created Time and More Icon for Other User
                                                        Row(
                                                          children: [
                                                            IconButton(
                                                              onPressed:
                                                                  () async {
                                                                setState(() {
                                                                  _selectedMessageIndex =
                                                                      channelStar[
                                                                              index]
                                                                          .id;
                                                                });
                                                                await showModalBottomSheet(
                                                                    //for other user
                                                                    constraints: BoxConstraints(
                                                                        maxHeight:
                                                                            MediaQuery.of(context).size.height *
                                                                                0.2,
                                                                        minWidth:
                                                                            MediaQuery.of(context).size.width *
                                                                                10),
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (BuildContext
                                                                            context) {
                                                                      return Container(
                                                                        child:
                                                                            Column(
                                                                          children: [
                                                                            TextButton.icon(
                                                                              label: Text(
                                                                                "Add Star",
                                                                                style: TextStyle(fontSize: 20, color: Colors.black),
                                                                              ),
                                                                              icon: Icon(
                                                                                Icons.star,
                                                                                color: isStared ? Colors.yellow : Colors.grey,
                                                                              ),
                                                                              onPressed: () async {
                                                                                Navigator.pop(context);
                                                                                if (_selectedMessageIndex != null) {
                                                                                  if (isStared) {
                                                                                    await _apiSerive.deleteGroupStarMessage(tGroupMessages![index].id!, widget.channelID!);
                                                                                  } else {
                                                                                    await _apiSerive.getMessageStar(tGroupMessages![index].id!, widget.channelID!);
                                                                                  }
                                                                                }
                                                                              },
                                                                            ),
                                                                            Divider(
                                                                                height: 1,
                                                                                color: Colors.grey[300],
                                                                                indent: 15.0,
                                                                                endIndent: 15.0),
                                                                            TextButton.icon(
                                                                              label: Text(
                                                                                "Reply Message",
                                                                                style: TextStyle(fontSize: 20, color: Colors.black),
                                                                              ),
                                                                              onPressed: () async {
                                                                                Navigator.pop(context);
                                                                                Navigator.push(
                                                                                    context,
                                                                                    MaterialPageRoute(
                                                                                        builder: (_) => GpThreadMessage(
                                                                                              channelID: widget.channelID,
                                                                                              channelStatus: widget.channelStatus,
                                                                                              channelName: widget.channelName,
                                                                                              messageID: tGroupMessages![index].id,
                                                                                              message: message,
                                                                                              name: retrieveGroupMessage!.tGroupMessages![index].name.toString(),
                                                                                              time: created_at,
                                                                                              fname: retrieveGroupMessage!.tGroupMessages![index].name.toString(),
                                                                                              activeStatus: activeStatus,
                                                                                              fileNames: fileNames,
                                                                                              files: files,
                                                                                              profileImage: profileImage,
                                                                                            )));
                                                                              },
                                                                              icon: const Icon(
                                                                                Icons.reply,
                                                                                color: Colors.black,
                                                                              ),
                                                                            ),
                                                                            Divider(
                                                                                height: 1,
                                                                                color: Colors.grey[300],
                                                                                indent: 15.0,
                                                                                endIndent: 15.0),
                                                                            TextButton.icon(
                                                                                label: Text(
                                                                                  "Add Reaction",
                                                                                  style: TextStyle(color: Colors.black, fontSize: 20),
                                                                                ),
                                                                                onPressed: () async {
                                                                                  Navigator.pop(context);
                                                                                  showModalBottomSheet(
                                                                                    context: context,
                                                                                    builder: (BuildContext context) {
                                                                                      return EmojiPicker(
                                                                                        onEmojiSelected: (category, Emoji emoji) async {
                                                                                          setState(() {
                                                                                            groupMessageID = tGroupMessages![index].id!.toInt();
                                                                                            selectedEmoji = emoji.emoji;
                                                                                            _seletedEmojiName = emoji.name;
                                                                                            _isEmojiSelected = true;
                                                                                          });

                                                                                          await _apiSerive.groupMessageReaction(emoji: selectedEmoji, msgId: groupMessageID!, sChannelId: widget.channelID, status: 1);

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
                                                                                    },
                                                                                  );
                                                                                },
                                                                                icon: Icon(
                                                                                  Icons.add_reaction_outlined,
                                                                                  color: Colors.black,
                                                                                )),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    });
                                                              },
                                                              icon: Icon(Icons
                                                                  .more_vert_outlined),
                                                            )
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  if (message.isNotEmpty)
                                                    flutter_html.Html(
                                                      data: message,
                                                      style: {
                                                        ".ql-code-block": flutter_html.Style(
                                                            backgroundColor:
                                                                Colors
                                                                    .grey[300],
                                                            padding: flutter_html
                                                                    .HtmlPaddings
                                                                .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        5),
                                                            margin: flutter_html
                                                                    .Margins
                                                                .symmetric(
                                                                    vertical:
                                                                        7)),
                                                        ".highlight":
                                                            flutter_html.Style(
                                                          display: flutter_html
                                                              .Display
                                                              .inlineBlock,
                                                          backgroundColor:
                                                              Colors.grey[300],
                                                          color: Colors.red,
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 5),
                                                        ),
                                                        "blockquote":
                                                            flutter_html.Style(
                                                          border: const Border(
                                                              left: BorderSide(
                                                                  color: Colors
                                                                      .grey,
                                                                  width: 5.0)),
                                                          margin: flutter_html
                                                                  .Margins
                                                              .symmetric(
                                                                  vertical:
                                                                      10.0),
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .only(left: 10),
                                                        ),
                                                        "ol":
                                                            flutter_html.Style(
                                                          margin: flutter_html
                                                                  .Margins
                                                              .symmetric(
                                                                  horizontal:
                                                                      10),
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .symmetric(
                                                                  horizontal:
                                                                      10),
                                                        ),
                                                        "ul":
                                                            flutter_html.Style(
                                                          display: flutter_html
                                                              .Display
                                                              .inlineBlock,
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .symmetric(
                                                                  horizontal:
                                                                      10),
                                                          margin: flutter_html
                                                              .Margins.all(0),
                                                        ),
                                                        "pre":
                                                            flutter_html.Style(
                                                          backgroundColor:
                                                              Colors.grey[300],
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 5),
                                                        ),
                                                        "code":
                                                            flutter_html.Style(
                                                          display: flutter_html
                                                              .Display
                                                              .inlineBlock,
                                                          backgroundColor:
                                                              Colors.grey[300],
                                                          color: Colors.red,
                                                          padding: flutter_html
                                                                  .HtmlPaddings
                                                              .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 5),
                                                        )
                                                      },
                                                    ),
                                                  if (files != null &&
                                                      files.isNotEmpty)
                                                    ...files.length == 1
                                                        ? [
                                                            Center(
                                                              child: singleFile
                                                                  .buildSingleFile(
                                                                      files
                                                                          .first,
                                                                      context,
                                                                      platform,
                                                                      fileNames
                                                                              ?.first ??
                                                                          ''),
                                                            )
                                                          ]
                                                        : [
                                                            Center(
                                                              child: mulitFile
                                                                  .buildMultipleFiles(
                                                                      files,
                                                                      platform,
                                                                      context,
                                                                      fileNames ??
                                                                          []),
                                                            )
                                                          ],
                                                  // const SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 6),
                                                            child: RichText(
                                                              text: TextSpan(
                                                                text: '$count',
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          15,
                                                                          15,
                                                                          15),
                                                                ),
                                                                children: const [
                                                                  WidgetSpan(
                                                                    child:
                                                                        Padding(
                                                                      padding: EdgeInsets.only(
                                                                          left:
                                                                              4.0),
                                                                      child: Icon(
                                                                          Icons
                                                                              .reply,
                                                                          size:
                                                                              16),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          Icon(Icons.star,
                                                              color: isStared
                                                                  ? Colors
                                                                      .yellow
                                                                  : Colors.grey,
                                                              size: 18)
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            created_at,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 10,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.8,
                                            child: Wrap(
                                                direction: Axis.horizontal,
                                                spacing: 7,
                                                children: List.generate(
                                                    emojiCounts!.length,
                                                    (index) {
                                                  bool show = false;
                                                  List userIds = [];
                                                  List reactUsernames = [];

                                                  if (emojiCounts![index]
                                                          .groupmsgid ==
                                                      messageId) {
                                                    for (dynamic reactUser
                                                        in reactUserData!) {
                                                      if (reactUser
                                                                  .groupmsgid ==
                                                              emojiCounts![
                                                                      index]
                                                                  .groupmsgid &&
                                                          emojiCounts![index]
                                                                  .emoji ==
                                                              reactUser.emoji) {
                                                        userIds.add(
                                                            reactUser.userid);
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
                                                      i < emojiCounts!.length;
                                                      i++) {
                                                    if (emojiCounts![i]
                                                            .groupmsgid ==
                                                        messageId) {
                                                      for (int j = 0;
                                                          j <
                                                              reactUserData!
                                                                  .length;
                                                          j++) {
                                                        if (userIds.contains(
                                                            reactUserData![j]
                                                                .userid)) {
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

                                                                await _apiSerive.groupMessageReaction(
                                                                    emoji: emojiCounts![
                                                                            index]
                                                                        .emoji!,
                                                                    msgId: emojiCounts![
                                                                            index]
                                                                        .groupmsgid!,
                                                                    sChannelId:
                                                                        widget
                                                                            .channelID,
                                                                    status: 1);
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
                                                                '${emojiCounts![index].emoji} ${emojiCounts![index].emojiCount}',
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
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )),
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
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                            SystemChannels.textInput.invokeMethod(
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
                                          color: Colors.white,
                                          onPressed: () {
                                            print("Pressing Check");
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
                                              isEdit = false;
                                            });

                                            _apiSerive.editGroupMessage(
                                                htmlContent,
                                                _selectedMessageIndex!,
                                                mentionnames);

                                            _clearEditor();
                                            SystemChannels.textInput.invokeMethod(
                                                'TextInput.hide'); // Hide the keyboard
                                          },
                                          icon: const Icon(Icons.check)),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  width: 40,
                                  height: 40,
                                  margin:
                                      const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 24, 103, 167),
                                      borderRadius: BorderRadius.circular(5)),
                                  child: IconButton(
                                      onPressed: () {
                                        int channelId = widget.channelID;
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
                                          htmlContent =
                                              htmlContent.replaceAll("<p>", "");
                                          htmlContent = htmlContent.replaceAll(
                                              "</p>", "");
                                        }

                                        if (htmlContent.contains("<code>")) {
                                          htmlContent = htmlContent.replaceAll(
                                              "<code>",
                                              "<span class='highlight'>");
                                          htmlContent = htmlContent.replaceAll(
                                              "</code>", "</span>");
                                        }

                                        if (htmlContent.contains("<pre>")) {
                                          htmlContent = htmlContent.replaceAll(
                                              "<pre>",
                                              "<div class='ql-code-block'>");
                                          htmlContent = htmlContent.replaceAll(
                                              "</pre>", "</div>");
                                          htmlContent = htmlContent.replaceAll(
                                              "\n", "<br/>");
                                        }

                                        setState(() {
                                          mentionnames.clear();
                                          mentionnames.addAll(currentMentions);
                                          isClickedTextFormat = false;
                                        });

                                        if (!htmlContent.startsWith("<br/>") ||
                                            files.isNotEmpty) {
                                          sendGroupMessageData(
                                              htmlContent,
                                              channelId,
                                              mentionnames,
                                              draftStatus);
                                          _clearEditor();
                                        }

                                        // sendGroupMessageData(
                                        //     htmlContent,
                                        //     channelId,
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
                      Visibility(
                        visible:
                            isSelectText || isClickedTextFormat ? true : false,
                        child: Container(
                          color: Colors.grey[300],
                          padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 10.0),
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
                                                icon: Icon(Icons.format_bold))
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
                                                        .formatSelection(quill
                                                            .Attribute.bold);
                                                  } else {
                                                    _quilcontroller
                                                        .formatSelection(quill
                                                                .Attribute
                                                            .clone(
                                                                quill.Attribute
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
                                                icon: Icon(Icons.format_italic))
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
                                                        .formatSelection(quill
                                                            .Attribute.italic);
                                                  } else {
                                                    _quilcontroller
                                                        .formatSelection(quill
                                                                .Attribute
                                                            .clone(
                                                                quill.Attribute
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
                                                icon:
                                                    Icon(Icons.strikethrough_s))
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
                                                                quill.Attribute
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
                                                icon: const Icon(Icons.link),
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
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.ol);
                                            } else {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute.ol,
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
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.ul);
                                            } else {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute.ul,
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
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.blockQuote);
                                            } else {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill
                                                          .Attribute.blockQuote,
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
                                                icon: const Icon(Icons.code),
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
                                                        .formatSelection(quill
                                                            .Attribute
                                                            .inlineCode);
                                                  } else {
                                                    _quilcontroller
                                                        .formatSelection(quill
                                                                .Attribute
                                                            .clone(
                                                                quill.Attribute
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
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.codeBlock);
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute.bold,
                                                      null));
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute.italic,
                                                      null));
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill
                                                          .Attribute.inlineCode,
                                                      null));
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute
                                                          .strikeThrough,
                                                      null));
                                            } else {
                                              _quilcontroller.formatSelection(
                                                  quill.Attribute.clone(
                                                      quill.Attribute.codeBlock,
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
                                          15, 0, 10, 0),
                                      decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: IconButton(
                                          color: Colors.white,
                                          onPressed: () {
                                            // _quilcontroller.clear();
                                            _clearEditor();
                                            SystemChannels.textInput.invokeMethod(
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
                                          color: Colors.white,
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
                                              isEdit = false;
                                            });

                                            _apiSerive.editGroupMessage(
                                                htmlContent,
                                                _selectedMessageIndex!,
                                                mentionnames);

                                            _clearEditor();
                                            SystemChannels.textInput.invokeMethod(
                                                'TextInput.hide'); // Hide the keyboard
                                          },
                                          icon: const Icon(Icons.check)),
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  width: 40,
                                  height: 40,
                                  margin:
                                      const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  decoration: BoxDecoration(
                                      color: const Color.fromARGB(
                                          255, 24, 103, 167),
                                      borderRadius: BorderRadius.circular(5)),
                                  child: IconButton(
                                      onPressed: () {
                                        int channelId = widget.channelID;
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
                                          htmlContent =
                                              htmlContent.replaceAll("<p>", "");
                                          htmlContent = htmlContent.replaceAll(
                                              "</p>", "");
                                        }

                                        if (htmlContent.contains("<code>")) {
                                          htmlContent = htmlContent.replaceAll(
                                              "<code>",
                                              "<span class='highlight'>");
                                          htmlContent = htmlContent.replaceAll(
                                              "</code>", "</span>");
                                        }

                                        if (htmlContent.contains("<pre>")) {
                                          htmlContent = htmlContent.replaceAll(
                                              "<pre>",
                                              "<div class='ql-code-block'>");
                                          htmlContent = htmlContent.replaceAll(
                                              "</pre>", "</div>");
                                          htmlContent = htmlContent.replaceAll(
                                              "\n", "<br/>");
                                        }

                                        setState(() {
                                          mentionnames.clear();
                                          mentionnames.addAll(currentMentions);
                                          isClickedTextFormat = false;
                                        });

                                        if (!htmlContent.startsWith("<br/>") ||
                                            files.isNotEmpty) {
                                          sendGroupMessageData(
                                              htmlContent,
                                              channelId,
                                              mentionnames,
                                              draftStatus);
                                          _clearEditor();
                                        }

                                        // sendGroupMessageData(
                                        //     htmlContent,
                                        //     channelId,
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
                ],
              ),
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
            ]));
  }
}
