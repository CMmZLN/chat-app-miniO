import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/componnets/Nav.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/screens/draftmessage/draftWidgets/direct_draft.dart';
import 'package:flutter_frontend/screens/draftmessage/draftWidgets/direct_thread_draft.dart';
import 'package:flutter_frontend/screens/draftmessage/draftWidgets/group_draft.dart';
import 'package:flutter_frontend/screens/draftmessage/draftWidgets/group_thread_draft.dart';
import 'package:flutter_frontend/screens/home/workspacehome.dart';

class DraftMessageView extends StatefulWidget {
  const DraftMessageView({super.key});

  @override
  State<DraftMessageView> createState() => _DraftMessageViewState();
}

class _DraftMessageViewState extends State<DraftMessageView> {
  int? isSelected = 1;
  static List<Widget> pages = [
    const DirectDraft(),
    const DirectThreadDraft(),
    const GroupDraft(),
    const GroupThreadDraft()
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPriamrybackground,
      appBar: AppBar(
        systemOverlayStyle:const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // Transparent status bar
          statusBarIconBrightness: Brightness.light, // Light icons on the status bar
          // systemNavigationBarColor: Colors.black, // Navigation bar color
          // systemNavigationBarIconBrightness: Brightness.light, // Light icons on the navigation bar
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Nav()),
            );
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          "Draft Lists",
          style:
              TextStyle(color: kPriamrybackground, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: themeColor,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilledButton(
                    onPressed: () {
                      setState(() {
                        isSelected = 1;
                      });
                    },
                    style: ButtonStyle(
                        backgroundColor: isSelected == 1
                            ? MaterialStateProperty.all<Color>(navColor)
                            : MaterialStateProperty.all<Color>(kbtn),
                        minimumSize:
                            MaterialStateProperty.all(const Size(120, 50))),
                    child: const Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Text("Direct Draft"),
                    )),
                const SizedBox(
                  width: 20.0,
                ),
                FilledButton(
                    onPressed: () {
                      setState(() {
                        isSelected = 2;
                      });
                    },
                    style: ButtonStyle(
                        backgroundColor: isSelected == 2
                            ? MaterialStateProperty.all<Color>(navColor)
                            : MaterialStateProperty.all<Color>(kbtn),
                        minimumSize:
                            MaterialStateProperty.all(const Size(120, 50))),
                    child: const Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Text("Direct Thread Draft"),
                    )),
                const SizedBox(
                  width: 20.0,
                ),
                FilledButton(
                    onPressed: () {
                      setState(() {
                        isSelected = 3;
                      });
                    },
                    style: ButtonStyle(
                        backgroundColor: isSelected == 3
                            ? MaterialStateProperty.all<Color>(navColor)
                            : MaterialStateProperty.all<Color>(kbtn),
                        minimumSize:
                            MaterialStateProperty.all(const Size(120, 50))),
                    child: const Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: const Text("Group Draft"),
                    )),
                const SizedBox(
                  width: 20.0,
                ),
                FilledButton(
                    onPressed: () {
                      setState(() {
                        isSelected = 4;
                      });
                    },
                    style: ButtonStyle(
                        backgroundColor: isSelected == 4
                            ? MaterialStateProperty.all<Color>(navColor)
                            : MaterialStateProperty.all<Color>(kbtn),
                        minimumSize:
                            MaterialStateProperty.all(const Size(120, 50))),
                    child: const Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: const Text("Group Thread Draft"),
                    )),
              ],
            ),
          ),
          if (isSelected != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: pages[isSelected! - 1],
              ),
            )
        ],
      ),
    );
  }
}
