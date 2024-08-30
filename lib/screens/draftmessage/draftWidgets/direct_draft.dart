import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/const/minio_to_ip.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/dotenv.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/screens/directMessage/direct_message.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;

class DirectDraft extends StatefulWidget {
  const DirectDraft({super.key});

  @override
  State<DirectDraft> createState() => _DirectDraftState();
}

class _DirectDraftState extends State<DirectDraft> {
  final directDraft = SessionStore.sessionData!.tDirectDraft;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPriamrybackground,
      body: ListView.builder(
        itemCount: directDraft!.length,
        itemBuilder: (context, index) {
          String? name = directDraft![index].name;
          String? receiverName = directDraft![index].receiverName;
          String? directMessage = directDraft![index].directmsg;
          int? id = directDraft![index].id;
          String? profileImage = directDraft![index].imageUrl;
          int? senderUserID = directDraft![index].sendUserId;
          bool? senderActiveStatus = directDraft![index].senderActiveStatus;
          bool? receiverActiveStatus = directDraft![index].receiverActiveStatus;

          int? receiverUseriD = directDraft![index].receiverUserId;
          String dateFormat = directDraft![index].createdAt.toString();
          DateTime dateTime = DateTime.parse(dateFormat).toLocal();
          String time = DateFormat('MMM d, yyyy hh:mm a').format(dateTime);
          List<dynamic>? files = [];
          List<dynamic>? fileName = [];

          files = directDraft![index].fileUrls;
          fileName = directDraft![index].fileNames;

          if (profileImage != null && !kIsWeb) {
            profileImage =
                MinioToIP.replaceMinioWithIP(profileImage, ipAddressForMinio);
          }

          return Container(
            padding: const EdgeInsets.only(top: 10),
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
                        child: profileImage == null || profileImage.isEmpty
                            ? const Icon(Icons.person)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
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
                const SizedBox(width: 5),
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
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DirectMessageWidget(
                              user_status: senderActiveStatus,
                              userId: receiverUseriD!,
                              receiverName: receiverName!,
                              activeStatus: senderActiveStatus,
                              profileImage: profileImage,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name!,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: flutter_html.Html(
                              data: directMessage,
                              style: {
                                ".ql-code-block": flutter_html.Style(
                                    backgroundColor: Colors.grey[200],
                                    padding:
                                        flutter_html.HtmlPaddings.symmetric(
                                            horizontal: 10, vertical: 5),
                                    margin: flutter_html.Margins.symmetric(
                                        vertical: 7)),
                                ".highlight": flutter_html.Style(
                                  display: flutter_html.Display.inlineBlock,
                                  backgroundColor: Colors.grey[200],
                                  color: Colors.red,
                                  padding: flutter_html.HtmlPaddings.symmetric(
                                      horizontal: 10, vertical: 5),
                                ),
                                "blockquote": flutter_html.Style(
                                  border: const Border(
                                      left: BorderSide(
                                          color: Colors.grey, width: 5.0)),
                                  margin: flutter_html.Margins.symmetric(
                                      vertical: 10.0),
                                  padding:
                                      flutter_html.HtmlPaddings.only(left: 10),
                                ),
                                "ol": flutter_html.Style(
                                  margin: flutter_html.Margins.symmetric(
                                      horizontal: 10),
                                  padding: flutter_html.HtmlPaddings.symmetric(
                                      horizontal: 10),
                                ),
                                "ul": flutter_html.Style(
                                  display: flutter_html.Display.inlineBlock,
                                  padding: flutter_html.HtmlPaddings.symmetric(
                                      horizontal: 10),
                                  margin: flutter_html.Margins.all(0),
                                ),
                                "pre": flutter_html.Style(
                                  backgroundColor: Colors.grey[300],
                                  padding: flutter_html.HtmlPaddings.symmetric(
                                      horizontal: 10, vertical: 5),
                                ),
                                "code": flutter_html.Style(
                                  display: flutter_html.Display.inlineBlock,
                                  backgroundColor: Colors.grey[300],
                                  color: Colors.red,
                                  padding: flutter_html.HtmlPaddings.symmetric(
                                      horizontal: 10, vertical: 5),
                                )
                              },
                            ),
                          ),
                          Text(
                            time,
                            style: const TextStyle(fontSize: 10),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
