import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_frontend/constants.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  runApp(const LoadingForMulti());
}

class LoadingForMulti extends StatelessWidget {
  const LoadingForMulti({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Scaffold(
          appBar: AppBar(
            systemOverlayStyle:const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // Transparent status bar
          statusBarIconBrightness: Brightness.light, // Light icons on the status bar
        ),
            title: const Text("This is sample title"),
            flexibleSpace: Container(
              decoration: themeColor,
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    TextButton(
                        onPressed: null,
                        child: Container(
                          width: 160,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        )),
                    TextButton(
                        onPressed: null,
                        child: Container(
                          width: 160,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        )),
                  ],
                ),
                const SizedBox(
                  width: 20,
                ),
                Container(
                  height: 600,
                  padding: const EdgeInsets.all(10.0),
                  child: ListView.builder(
                      itemCount: 8,
                      itemBuilder: (context, idx) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ),
                              Container(
                                width: 300,
                                height: 100,
                                color: Colors.grey,
                              )
                            ],
                          ),
                        );
                      }),
                ),
              ],
            ),
          )),
    );
  }
}
