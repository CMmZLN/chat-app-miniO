import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  runApp(const LoadingForUserManage());
}

class LoadingForUserManage extends StatelessWidget {
  const LoadingForUserManage({super.key});

  @override
  Widget build(BuildContext context) {
    // return Center(
    //   child: CircularProgressIndicator(),
    // );
    return Skeletonizer(
      enabled: true,
      child: Scaffold(
          body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: ListView.builder(
                itemCount: 8,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Padding(
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
                    title: const Text("User Name"),
                    subtitle: const Text("This is allofuser@gmail.com"),
                    trailing: const Switch(
                      value: true,
                      onChanged: null,
                    ),
                  );
                }),
          ),
        ),
      )),
    );
  }
}
