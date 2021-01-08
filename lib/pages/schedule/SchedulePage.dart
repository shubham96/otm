import 'dart:async';
import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:msgschedule_2/blocs/MessageBloc.dart';

import 'package:msgschedule_2/models/Message.dart';
import 'package:msgschedule_2/models/Settings.dart';
import 'package:msgschedule_2/pages/schedule/ArchivedMessages.dart';
import 'package:msgschedule_2/pages/schedule/CreateOrEditSmsMessagePage.dart';
import 'package:msgschedule_2/pages/settings/SettingsPage.dart';
import 'package:msgschedule_2/providers/DialogProvider.dart';
import 'package:msgschedule_2/providers/ScheduleProvider.dart';
import 'package:msgschedule_2/providers/SettingsProvider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './Schedule.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide Message;

import 'package:msgschedule_2/SizeConfig.dart';

class SchedulePage extends StatefulWidget {
  SchedulePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SchedulePageState createState() => _SchedulePageState();
}

enum PopUpMenuValues {
  deleteAll,
  refreshMessages,
  appSettings,
  archivedMessages,
}

class _SchedulePageState extends State<SchedulePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ScheduleProvider _scheduleProvider = ScheduleProvider();
  TabController _tabController;
  final _messageBloc = MessageBloc();
  List<Message> _messages;
  Timer _refreshTimer;

  static const platform = const MethodChannel('samples.flutter.dev/battery');

  static const segmentAll = 1;
  static const segmentDone = 2;

  static const _iconSize = 28.0;

  Settings _settings = SettingsProvider.getDefaultSettings();

  final keyIsFirstLoaded = 'is_first_loaded';

  SharedPreferences prefs;

  void _loadSettings() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('AccessibilitySettingsEnabled') == false) {
      await platform.invokeMethod('checkAccessibility');
      final Settings settings =
          await SettingsProvider.getInstance().getSettings();

      prefs.setString('AccessibilitySettingsEnabled', '1');

      setState(() => _settings = settings);
    }
  }

  /// loads messages.
  void _refreshMessages() => _messageBloc.loadMessages();

  @override
  void initState() {
    super.initState();

    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = new IOSInitializationSettings();
    var initSetttings = new InitializationSettings(android, iOS);
    flutterLocalNotificationsPlugin.initialize(initSetttings,
        onSelectNotification: onSelectNotification);
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _refreshMessages();

    _scheduleProvider.onMessageProcessed =
        (Message message) => _messageBloc.updateMessage(message);
    _scheduleProvider.onNotificationTriggered = (Message message) =>
        _showNotificationWithDefaultSound(
            message, flutterLocalNotificationsPlugin);

    _scheduleProvider.start(Duration(seconds: 15));

    _refreshTimer =
        Timer.periodic(Duration(seconds: 30), (Timer t) => _refreshMessages());

    // _loadSettings();
  }

  _showDialogWhenFirstLoaded(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstLoaded = prefs.getBool(keyIsFirstLoaded);

    if (isFirstLoaded == null) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              child: Container(
                height: MediaQuery.of(context).size.height / 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Welcome to OTM, \n The Mother of all Prophets",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: SizeConfig.safeBlockHorizontal * 5),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "OTM schedules your important messages for you so that you can rest while you communicate.",
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "To Enable the automation of your messages, you need to enable the accessibility settings",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 4),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Your security is our absolute concern, but please note that in order for Email automation, Less Secure app needs to be allowed",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: SizeConfig.safeBlockHorizontal * 4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await _loadSettings();
                        Navigator.of(context).pop();
                        prefs.setBool(keyIsFirstLoaded, false);
                      },
                      child: Container(
                        color: Colors.blueGrey,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Center(
                            child: Text(
                              'Go to Accessibility',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: SizeConfig.safeBlockHorizontal * 5),
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _messageBloc.dispose();
    _refreshTimer.cancel();
    _scheduleProvider.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('state changed: $state');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SchedulePage.build()');
    SizeConfig().init(context);
    Future.delayed(Duration.zero, () => _showDialogWhenFirstLoaded(context));
    return Scaffold(
      appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 4),
          ),
          //  backgroundColor: Colors.orange,
          actions: <Widget>[
            PopupMenuButton<PopUpMenuValues>(
              tooltip: '',
              onSelected: _onPopupSelected,
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<PopUpMenuValues>>[
                PopupMenuItem<PopUpMenuValues>(
                  enabled: _messages != null && _messages.isNotEmpty,
                  value: PopUpMenuValues.deleteAll,
                  child: ListTile(
                      leading: Icon(Icons.delete_forever),
                      title: Text('Delete all messages',
                          style: TextStyle(
                              color: _messages != null && _messages.isNotEmpty
                                  ? Colors.black87
                                  : Colors.grey))),
                ),
                const PopupMenuItem<PopUpMenuValues>(
                  value: PopUpMenuValues.refreshMessages,
                  child: ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('Refresh messages')),
                ),

                /*const PopupMenuItem<PopUpMenuValues>(
                value: PopUpMenuValues.archivedMessages,
                child: ListTile(
                  leading: Icon(Icons.archive),
                  title: Text('Archived messages')
                ),
              ),*/

                const PopupMenuItem<PopUpMenuValues>(
                  value: PopUpMenuValues.appSettings,
                  child: ListTile(
                      leading: Icon(Icons.settings), title: Text('Settings')),
                ),
              ],
            )
          ],
          bottom: TabBar(
            indicatorColor: Colors.black,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.white,
            controller: _tabController,
            tabs: const <Widget>[
              Tab(icon: Icon(Icons.all_inclusive, size: _iconSize)),
              Tab(icon: Icon(Icons.schedule, size: _iconSize)),
              Tab(icon: Icon(Icons.done, size: _iconSize)),
              Tab(icon: Icon(Icons.error, size: _iconSize)),
            ],
          )),
      //   drawer: AppDrawer(),
      body: StreamBuilder<List<Message>>(
        stream: _messageBloc.stream,
        initialData: null,
        builder: (BuildContext context, AsyncSnapshot<List<Message>> snapshot) {
          final List<Message> all = snapshot.data
              ?.takeWhile((msg) => !msg.isArchived)
              ?.toList(); // get non-archived messages.
          final pending = all
              ?.takeWhile((msg) => msg.status == MessageStatus.PENDING)
              ?.toList();
          final failed = all
              ?.takeWhile((msg) => msg.status == MessageStatus.FAILED)
              ?.toList();
          final sent = all
              ?.takeWhile((msg) => msg.status == MessageStatus.SENT)
              ?.toList();

          _messages = snapshot.data; // take all messages.

          return TabBarView(
            controller: _tabController,
            children: <Widget>[
              Schedule(all, () => _refreshMessages()),
              Schedule(pending, () => _refreshMessages()),
              Schedule(sent, () => _refreshMessages()),
              Schedule(failed, () => _refreshMessages()),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreateMessage,
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  void _onPopupSelected(PopUpMenuValues value) {
    switch (value) {
      case PopUpMenuValues.deleteAll:
        DialogProvider.showConfirmation(
            title: Icon(Icons.delete_forever),
            content: Text('Really delete all messages forever?'),
            context: context,
            onYes: () {
              _messageBloc.deleteAllMessages();
              _refreshMessages();
            });
        break;

      case PopUpMenuValues.refreshMessages:
        _refreshMessages();
        break;

      case PopUpMenuValues.archivedMessages:
        final List<Message> messages =
            _messages.takeWhile((message) => message.isArchived).toList();

        Navigator.push(
          context,
          MaterialPageRoute<bool>(
              builder: (context) => ArchivedMessages(messages)),
        ).then((bool result) {
          _refreshMessages();
        });
        break;

      case PopUpMenuValues.appSettings:
        Navigator.push(
          context,
          MaterialPageRoute<bool>(builder: (context) => SettingsPage()),
        ).then((bool result) {
          _refreshMessages();
        });
        break;

      default:
        break;
    }
  }

  Future onSelectNotification(payload) {
    // debugPrint("payload : $payload");
    print('the payload');
    print(payload);
    // Message message = json.decode(payload);
    // print(json.decode(payload));
    // showDialog(
    //   context: context,
    //   builder: (_) => new AlertDialog(
    //     title: new Text('Notification'),
    //     content: new Text('$payload'),
    //   ),
    // );
    _scheduleProvider.onClickNotificationTriggerWhatsapp(payload);
  }

  Future _showNotificationWithDefaultSound(
      Message message, flutterLocalNotificationsPlugin) async {
    var android = new AndroidNotificationDetails(
        'channel id', 'channel NAME', 'CHANNEL DESCRIPTION',
        priority: Priority.High, importance: Importance.Max);
    var iOS = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(android, iOS);
    print('click to send');
    String payload = jsonEncode(message);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Click to send',
      message.content,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  void _onCreateMessage() {
    Navigator.push(
      context,
      MaterialPageRoute<bool>(
          builder: (context) => CreateOrEditSmsMessagePage(MessageMode.create)),
    ).then((bool result) {
      _refreshMessages();
    });
  }
}
