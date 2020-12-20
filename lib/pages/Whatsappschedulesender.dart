import 'package:android_intent/android_intent.dart';
import 'package:flutter/material.dart';

class PreviewPage extends StatelessWidget {
  final List<Map> msgList;
  final String baseURL = "https://api.whatsapp.com/send?phone=";
  PreviewPage(this.msgList);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Preview Message"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          //msgList = SortedMap(Ordering.byValue());
          // print(msgList["phone"]);
          for (var msg in msgList) {
            print('printing message');
            print(msg["phone"]);
            if (msg["phone"] != null) {
              var url = "${baseURL}91${msg['phone']}&text=${msg['messages']}";
              print(url);
              AndroidIntent intent = AndroidIntent(
                  action: 'action_view',
                  data: Uri.encodeFull(url),
                  // flags: <int>[Flag.FLAG_ACTIVITY_CLEAR_TOP],
                  package: "com.whatsapp.w4b");
              await intent.launch();
            }
          }
        },
        child: Icon(Icons.send),
      ),
    );
  }
}
