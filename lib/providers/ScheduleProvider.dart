import 'dart:async';
import 'dart:convert';

import 'package:android_intent/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:msgschedule_2/models/Message.dart';
import 'package:msgschedule_2/models/Settings.dart';
import 'package:msgschedule_2/providers/MessageProvider.dart';
import 'package:msgschedule_2/providers/SettingsProvider.dart';
import 'package:sms/sms.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Message;
import 'package:is_lock_screen/is_lock_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

///
class ScheduleProvider {
  Timer _timer;
  final StreamController<Message> _ctrlMsg = StreamController();
  final StreamController<Message> _ctrlNotification = StreamController();
  final StreamController<List<Message>> _ctrlMsgs = StreamController();
  StreamSubscription _subMsg;
  StreamSubscription _subMsgNotification;
  StreamSubscription _subMsgs;

  static const platform = const MethodChannel('samples.flutter.dev/battery');

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;


  /// Constructs a sheduler using the given [onMessageProcessed] and [onScheduleProcessed] listeners.
  ScheduleProvider(
      {dynamic Function(Message) onMessageProcessed,dynamic Function(Message) onNotificationTriggered,
      dynamic Function(List<Message>) onScheduleProcessed}) {
    print('lodu');
    print(onMessageProcessed);
    print(onNotificationTriggered);
    print(onScheduleProcessed);

    if (onMessageProcessed != null)
      this.onMessageProcessed = onMessageProcessed;
    if (onScheduleProcessed != null)
      this.onScheduleProcessed = onScheduleProcessed;
  }

  /// Starts executing the schedule periodically according to the given [duration].
  void start(Duration duration) {
    stop();
    _subMsg?.resume();
    _subMsgNotification?.resume();
    _subMsgs?.resume();
    _timer = Timer.periodic(duration, (Timer t) => this._processSchedule());
  }

  /// Stops executing the schedule perdiodically, and stops calling any listeners/callbacks attached.
  /// Note that the listeners attached aren't removed, they just aren't called until start is called again.
  void stop() {
    _timer?.cancel();
    _subMsg?.pause();
    _subMsgNotification?.pause();
    _subMsgs?.pause();
  }

  /// Sets the callback to be invoked whenever a single message has been processed.
  set onMessageProcessed(Function(Message) onData) {
    assert(onData != null);

    _subMsg?.cancel();
    _subMsg = _ctrlMsg.stream.listen((Message message) => onData(message));
  }

  /// Sets the callback to be invoked whenever a single message has been processed.
  set onNotificationTriggered(Function(Message) onData) {
    assert(onData != null);

    _subMsgNotification?.cancel();
    _subMsgNotification = _ctrlNotification.stream.listen((Message message) => onData(message));
  }

  /// Sets the callback to be invoked whenever the entire schedule has been processed.
  set onScheduleProcessed(Function(List<Message>) onDone) {
    assert(onDone != null);

    _subMsgs?.cancel();
    _subMsgs =
        _ctrlMsgs.stream.listen((List<Message> messages) => onDone(messages));
  }

  /// Frees the resources allocated with this object. Making the object un-usable.
  void dispose() {
    _timer.cancel();
    _subMsg?.cancel();
    _subMsgNotification?.cancel();
    _subMsgs?.cancel();
    _ctrlMsg.close();
    _ctrlNotification.close();
    _ctrlMsgs.close();
  }

   String FormatStringAsPhoneNumber(String input) {
    String output;
    switch (input.length) {
      case 11:
        if(input.substring(0,1)=='0')
        output = '+91' + input.substring(1,11);//String.format("%s%s", input.substring(0,3), input.substring(3,7));
        break;
      case 10:
        output = '+91' + input;
        break;
      default:
        return input;
    }
    return output;
  }


  void onClickNotificationTriggerWhatsapp(message){
    print('chal ja bhai');
    print(message);
    // print(json.decode(message));
    // var messageId =  json.decode(message).id;
    // print(messageId);
    // message.content = ;
    var decodedMessage = Message.fromJson(json.decode(message));
    _processWhatsAppMessage(decodedMessage);
  }

  void _processWhatsAppMessage(Message message) async {
    String baseURL = "https://api.whatsapp.com/send?phone=";
    var url = "${baseURL}${FormatStringAsPhoneNumber(message.endpoint.split(" ").join(""))}&text=${message.content}";
    AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: Uri.encodeFull(url),
        package: "com.whatsapp");
    print(intent.toString());
    print(url);
    await intent.launch();
      try {
        print('qweuiop');
        final String result = await platform.invokeMethod('getBatteryLevel');
        print('poiuytr');
        print(result);
        if(result=='done'){
          message.status = MessageStatus.SENT;
          message.attempts++;
          print(message.status);
          _ctrlMsg.sink.add(message);
        }
      } on PlatformException catch (e) {
        print('exception');
        print(e.message);
      }
  }

  void _processEmail(Message message1) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String username = '';
    String password = '';
    if(prefs.containsKey('mailid')){
      username = prefs.getString('mailid');
      password = prefs.getString('mailpassword');
    }
  print('the recipient');
    print(message1.endpoint);

    final smtpServer = gmail(username, password);

    final message = mailer.Message()
      ..from = mailer.Address(username, username)
      ..recipients.add(message1.endpoint)
      // ..ccRecipients.addAll(['destCc1@example.com', 'destCc2@example.com'])
      // ..bccRecipients.add(mailer.Address('bccAddress@example.com'))
      ..subject = message1.subject
      ..text = message1.content;
    print(mailer.Address(username));
    print(message1.endpoint);
    print(message1.subject);
    print(message1.content);

    try {
      final sendReport = await mailer.send(message, smtpServer);
      message1.status = MessageStatus.SENT;
      message1.attempts++;
      _ctrlMsg.sink.add(message1);
      print('Message sent: ' + sendReport.toString());
    } on mailer.MailerException catch (e) {
      print('Message not sent.');
      message1.status = MessageStatus.FAILED;
      message1.attempts++;
      _ctrlMsg.sink.add(message1);
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
    // final Email email = Email(
    //   body: 'Email body',
    //   subject: 'Email subject',
    //   recipients: ['pateldhawal4@gmail.com', message.endpoint],
    //   // cc: ['cc@example.com'],
    //   // bcc: ['bcc@example.com'],
    //   // attachmentPaths: ['/path/to/attachment.zip'],
    //   isHTML: false,
    // );

    // await FlutterEmailSender.send(email);
  }

  void _processSms(Message message) async {
    final provider = SimCardsProvider();
    final int simSlot =
        (await SettingsProvider.getInstance().getSettings()).sms.simcard.index;
    final SimCard simToUse = (await provider.getSimCards())[simSlot];
    // final Settings settings = await SettingsProvider.getInstance().getSettings();

    final sender = SmsSender();
    final SmsMessage smsMessage =
        SmsMessage(message.endpoint, message.content, id: message.id);

    smsMessage.onStateChanged.listen((SmsMessageState state) async {
      if (state == SmsMessageState.Sent) {
        message.status = MessageStatus.SENT;
        message.attempts++;

        _ctrlMsg.sink.add(message);
      } else if (state == SmsMessageState.Fail) {
        message.status = MessageStatus.FAILED;
        message.attempts++;

        _ctrlMsg.sink.add(message);
      }

      // I might use this guy later.
      else if (state == SmsMessageState.Delivered) {}
    });

    await sender.sendSms(smsMessage, simCard: simToUse);
  }

  void _triggershowNotificationWithDefaultSound(Message message) async {
    print("message.endpoint");

    print(message.endpoint);
    _ctrlNotification.sink.add(message);
  }

  void _processSchedule() async {
    final Settings settings =
        await SettingsProvider.getInstance().getSettings();
    final messages = await MessageProvider.getInstance().getMessages();
    bool isLocked = await isLockScreen();

    messages
        .takeWhile((Message message) =>
            (message.status == MessageStatus.PENDING ||
                (message.status == MessageStatus.FAILED &&
                    (settings.message.maxAttempts == null ||
                        message.attempts < settings.message.maxAttempts))) &&
            DateTime.now().millisecondsSinceEpoch >= message.executedAt)
        .forEach((Message message) {

      switch (message.driver) {
        case MessageDriver.SMS:
          _processSms(message);
          // _processWhatsAppMessage(message);

          break;

        case MessageDriver.Email:
          _processEmail(message);
          // _triggershowNotificationWithDefaultSound(message);
          break;

        case MessageDriver.Whatsapp:
          print('islocked');
          print(isLocked);
          if(!isLocked)
            _processWhatsAppMessage(message);
          else{
            _triggershowNotificationWithDefaultSound(message);
          }
      }
    });

    if (messages.length > 0) _ctrlMsgs.sink.add(messages);
  }



}
