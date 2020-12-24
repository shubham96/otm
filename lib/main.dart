import 'package:flutter/material.dart';
import 'package:msgschedule_2/providers/MessageProvider.dart';
import 'pages/schedule/SchedulePage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
Future main() async {
  await WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final String _appName = 'OTM';
  Widget _home;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  _MyAppState();

  @override
  void initState() {
    super.initState();
    _home = SchedulePage(title: _appName);

    // _home = PreviewPage as Widget;
  }

  Future onSelectNotification(String payload) {
    debugPrint("payload : $payload");
    showDialog(
      context: context,
      builder: (_) => new AlertDialog(
        title: new Text('Notification'),
        content: new Text('$payload'),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();

    _disposeSingletonProviders();
  }

  void _disposeSingletonProviders() {
    MessageProvider.getInstance().dispose();
  }

  @override
  didPopRoute() async {
    debugPrint('back button pressed.');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _appName,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        accentColor: Colors.orange,
      ),
      home: _home,
    );
  }


  Future _showNotificationWithDefaultSound() async {
    var android = new AndroidNotificationDetails(
        'channel id', 'channel NAME', 'CHANNEL DESCRIPTION',
        priority: Priority.High,importance: Importance.Max
    );
    var iOS = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        android, iOS);
    await flutterLocalNotificationsPlugin.show(
      0,
      'New Post',
      'How to Show Notification in Flutter',
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }
}
