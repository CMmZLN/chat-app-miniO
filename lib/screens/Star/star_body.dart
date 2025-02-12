import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:flutter_frontend/model/SessionStore.dart';
import 'package:flutter_frontend/componnets/customlogout.dart';
import 'package:flutter_frontend/screens/Star/starsWidget/group_star.dart';
import 'package:flutter_frontend/screens/Star/starsWidget/direct_star.dart';
import 'package:flutter_frontend/screens/Star/starsWidget/group_thread_star.dart';
import 'package:flutter_frontend/screens/Star/starsWidget/direct_thread_star.dart';
import 'package:flutter_frontend/screens/check_token_status.dart';

class StarBody extends StatefulWidget {
  const StarBody({Key? key}) : super(key: key);

  @override
  State<StarBody> createState() => _StarBodyState();
}

class _StarBodyState extends State<StarBody> {
  int? isSelected = 1;
  static List<Widget> pages = [
    const DirectStars(),
    const DirectThreadStars(),
    const GroupStarWidget(),
    const GroupThreadStar()
  ];
  @override
  void dispose() {
    // Dispose any resources here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (SessionStore.sessionData!.currentUser!.memberStatus == true) {
      return Scaffold(
        backgroundColor: kPriamrybackground,
        appBar: AppBar(
          systemOverlayStyle:const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // Transparent status bar
          statusBarIconBrightness: Brightness.light, // Light icons on the status bar
        ),
          title: const Text(
            "Stars List",
            style: TextStyle(
                color: kPriamrybackground, fontWeight: FontWeight.bold),
          ),
          flexibleSpace: Container(
            decoration: themeColor,
          ),
          automaticallyImplyLeading: false,
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
                        AuthService.checkTokenStatus(context);
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
                        child: Text("Direct Star"),
                      )),
                  const SizedBox(
                    width: 20.0,
                  ),
                  FilledButton(
                      onPressed: () {
                        AuthService.checkTokenStatus(context);
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
                        child: Text("Direct Thread Star"),
                      )),
                  const SizedBox(
                    width: 20.0,
                  ),
                  FilledButton(
                      onPressed: () {
                        AuthService.checkTokenStatus(context);
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
                        child: const Text("Group Star"),
                      )),
                  const SizedBox(
                    width: 20.0,
                  ),
                  FilledButton(
                      onPressed: () {
                        AuthService.checkTokenStatus(context);
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
                        child: const Text("Group Thread Star"),
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
    } else {
      return CustomLogOut();
    }
  }
}
