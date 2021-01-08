import 'package:android_intent/android_intent.dart';
import 'package:app_settings/app_settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:contact_picker/contact_picker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:msgschedule_2/blocs/MessageBloc.dart';
import 'package:msgschedule_2/models/Message.dart';
import 'package:msgschedule_2/models/Settings.dart';
import 'package:msgschedule_2/providers/DateTimeFormator.dart';
import 'package:msgschedule_2/providers/DialogProvider.dart';
import 'package:msgschedule_2/providers/SettingsProvider.dart';
import 'package:msgschedule_2/SizeConfig.dart';
import 'package:android_intent/android_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../SizeConfig.dart';

enum MessageMode { create, edit }

class CreateOrEditSmsMessagePage extends StatefulWidget {
  final MessageMode messageMode;
  final Message message;

  /// Constructs the message mode.
  /// If [messageMode] == [MessageMode.edit] then [message] should be set.
  const CreateOrEditSmsMessagePage(this.messageMode, [this.message]);

  @override
  _CreateOrEditSmsMessagePageState createState() =>
      _CreateOrEditSmsMessagePageState();
}

class _CreateOrEditSmsMessagePageState
    extends State<CreateOrEditSmsMessagePage> {
  final _contactPicker = ContactPicker();
  final _messagesBloc = MessageBloc();
  Settings _settings = SettingsProvider.getDefaultSettings();
  DateTime _date;
  TimeOfDay _time;

  final _phoneNumberCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  final _mailSubjectCtrl = TextEditingController();
  // final _gmailMailId = TextEditingController(); //endpoint/receiver mail id

  final _gmailSenderMailHost = TextEditingController();
  final _gmailSenderMailId = TextEditingController();
  final _gmailSenderMailPassword = TextEditingController();
  final _gmailSenderMailAttachment = TextEditingController();

  var _currencies = ['Gmail', 'Yahoo', 'Hotmail'];

  MessageDriver _driverCtrl = MessageDriver.SMS;
  static const platform = const MethodChannel('samples.flutter.dev/battery');

  SharedPreferences prefs;

  void openAccessibilitySettings() async {}

  String _phoneNumberError;
  String _dateError;
  String _timeError;
  String _messageError;

  String _gmailSenderMailIdError;
  String _gmailSenderMailPasswordError;

  void getLocalPreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();

    // openAccessibilitySettings();

    getLocalPreferences();

    if (widget.messageMode == MessageMode.edit) {
      if (widget.message.driver == MessageDriver.Email) {
        _emailCtrl.text = widget.message.endpoint;
        _gmailSenderMailHost.text = widget.message.mailHost;
        _gmailSenderMailId.text = widget.message.mailId;
        _gmailSenderMailPassword.text = widget.message.mailPassword;
        _gmailSenderMailAttachment.text = widget.message.mailAttachment;
      } else if (widget.message.driver == MessageDriver.Whatsapp) {
        _phoneNumberCtrl.text = widget.message.endpoint;
        _gmailSenderMailAttachment.text = widget.message.mailAttachment;
      } else
        _phoneNumberCtrl.text = widget.message.endpoint;

      _dateCtrl.text = DateTimeFormator.formatDate(
          DateTime.fromMillisecondsSinceEpoch(widget.message.executedAt));
      _timeCtrl.text = DateTimeFormator.formatTime(TimeOfDay.fromDateTime(
          DateTime.fromMillisecondsSinceEpoch(widget.message.executedAt)));
      _messageCtrl.text = widget.message.content;
      _mailSubjectCtrl.text = widget.message.subject;

      _date = DateTime.fromMillisecondsSinceEpoch(widget.message.executedAt);
      _time = TimeOfDay.fromDateTime(
          DateTime.fromMillisecondsSinceEpoch(widget.message.executedAt));
    } else {
      _phoneNumberCtrl.text = '';
      _emailCtrl.text = '';
      _gmailSenderMailHost.text = 'Gmail';
      _gmailSenderMailId.text = '';
      _gmailSenderMailPassword.text = '';
      _gmailSenderMailAttachment.text = '';
      _dateCtrl.text = '';
      _timeCtrl.text = '';
      _messageCtrl.text = '';
      _mailSubjectCtrl.text = '';
    }

    _messageCtrl.addListener(_validate);
    _dateCtrl.addListener(_validate);
    _timeCtrl.addListener(_validate);
    _phoneNumberCtrl.addListener(_validate);
    _emailCtrl.addListener(_validate);
    _gmailSenderMailId.addListener(_validate);
    _gmailSenderMailPassword.addListener(_validate);

    _loadSettings();
    _validate();
  }

  void _loadSettings() async {
    await platform.invokeMethod('checkAccessibility');
    final Settings settings =
        await SettingsProvider.getInstance().getSettings();

    setState(() => _settings = settings);
  }

  @override
  void dispose() {
    super.dispose();
    _messagesBloc.dispose();
  }

  pickAttachment() async {
    String result = await FilePicker.getFilePath();
    print("result");
    print(result);
    setState(() {
      _gmailSenderMailAttachment.text = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          (widget.messageMode == MessageMode.edit ? 'Edit' : 'Create New') +
              ' Message',
          style: TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3),
        ),
      ),
      body: Padding(
          padding: EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 15),
          child: ListView(
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Scheduling message for: ${getSchedulingFor()}',
                    style: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 2.5),
                  ),
                  IconButton(
                    icon: Icon(FontAwesomeIcons.sms,
                        size: SizeConfig.safeBlockHorizontal * 7.5,
                        color: _driverCtrl == MessageDriver.SMS
                            ? Colors.black
                            : Colors.grey),
                    tooltip: 'SMS',
                    onPressed: () {
                      setState(() {
                        _driverCtrl = MessageDriver.SMS;
                        _validate();
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(FontAwesomeIcons.whatsapp,
                        size: SizeConfig.safeBlockHorizontal * 7.5,
                        color: _driverCtrl == MessageDriver.Whatsapp
                            ? Colors.black
                            : Colors.grey),
                    tooltip: 'Whatsapp',
                    onPressed: () {
                      setState(() {
                        _driverCtrl = MessageDriver.Whatsapp;
                        _validate();
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(FontAwesomeIcons.envelope,
                        size: SizeConfig.safeBlockHorizontal * 7.5,
                        color: _driverCtrl == MessageDriver.Email
                            ? Colors.black
                            : Colors.grey),
                    tooltip: 'Email',
                    onPressed: () {
                      setState(() {
                        _driverCtrl = MessageDriver.Email;
                        _validate();
                      });
                    },
                  ),
                ],
              ),
              _driverCtrl == MessageDriver.Email
                  ? DropdownButton<String>(
                      value: _gmailSenderMailHost.text,
                      onChanged: (String newValue) {
                        setState(() {
                          _gmailSenderMailHost.text = newValue;
                        });
                      },
                      items: _currencies.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    )
                  : Text(''),
              _driverCtrl == MessageDriver.Email
                  ? prefs.getString('email') != null
                      ? SizedBox(
                          height: 0,
                          width: 0,
                        )
                      : TextFormField(
                          controller: _gmailSenderMailId,
                          onChanged: (value) {
                            prefs.setString('email', value);
                          },
                          maxLength: null,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'From Email ID',
                            hintStyle: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                            labelText: 'From Email ID',
                            labelStyle: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                            icon: Icon(
                              Icons.mail,
                              size: SizeConfig.safeBlockHorizontal * 8,
                            ),
                          ),
                        )
                  : Text(''),
              _driverCtrl == MessageDriver.Email
                  ? prefs.getString('password') != null
                      ? SizedBox(
                          height: 0,
                          width: 0,
                        )
                      : TextFormField(
                          onEditingComplete: () {
                            prefs.setString(
                                'password', _gmailSenderMailPassword.text);
                          },
                          controller: _gmailSenderMailPassword,
                          maxLength: null,
                          keyboardType: TextInputType.visiblePassword,
                          decoration: InputDecoration(
                            hintStyle: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                            labelStyle: TextStyle(
                                fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                            labelText: 'From Email Password',
                            icon: Icon(Icons.mail),
                            hintText: 'From Email ID Password',
                          ),
                        )
                  : Text(''),
              _driverCtrl == MessageDriver.Email
                  ? TextFormField(
                      controller: _emailCtrl,
                      maxLength: null,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintStyle: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                        labelStyle: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                        hintText: 'To Email ID',
                        labelText: 'To Email ID',
                        errorText: _phoneNumberError,
                        icon: Icon(Icons.contact_phone),
                      ),
                    )
                  : TextFormField(
                      controller: _phoneNumberCtrl,
                      inputFormatters: [
                        WhitelistingTextInputFormatter(
                            RegExp(r"^[+]?\d*$")) // don't allow any input
                      ],
                      maxLength: 15,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          hintText: 'Phone Number',
                          hintStyle: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                          // errorText: _phoneNumberError,
                          icon: Icon(Icons.contact_phone),
                          suffixIcon: GestureDetector(
                              onTap: () async {
                                final Contact contact =
                                    await _contactPicker.selectContact();
                                // String number
                                setState(() => _phoneNumberCtrl.text =
                                    contact.phoneNumber.number.toString());
                              },
                              child: Icon(Icons.person_add))),
                    ),
              _driverCtrl == MessageDriver.Email
                  ? TextFormField(
                      controller: _mailSubjectCtrl,
                      maxLines: null,
                      maxLength: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                          hintStyle: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                          labelStyle: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                          labelText: 'Subject',
                          icon: Icon(Icons.textsms)),
                    )
                  : Text(''),

              // TextFormField(
              //   controller: _dateCtrl,
              //   inputFormatters: [
              //     BlacklistingTextInputFormatter(
              //         RegExp(r".*")) // don't allow any input
              //   ],
              //   keyboardType: TextInputType.datetime,
              //   decoration: InputDecoration(
              //       labelText: 'Date',
              //       labelStyle: TextStyle(
              //           fontSize: SizeConfig.safeBlockHorizontal * 3.5),
              //       errorText: _dateError,
              //       icon: Icon(Icons.calendar_today),
              //       suffixIcon: GestureDetector(
              //         child: Icon(Icons.more_horiz),
              //         onTap: () async {
              //           final DateTime date = await showDatePicker(
              //               context: context,
              //               firstDate: DateTime.now(),
              //               lastDate:
              //                   DateTime.now().add(Duration(days: 30 * 12 * 2)),
              //               initialDate: DateTime.now());
              //           _date = date;
              //           setState(() {
              //             _dateCtrl.text = DateTimeFormator.formatDate(date);
              //           });
              //         },
              //       )),
              // ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: GestureDetector(
                  onTap: () async {
                    final DateTime date = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(Duration(days: 30 * 12 * 2)),
                        initialDate: DateTime.now());
                    _date = date;
                    setState(() {
                      _dateCtrl.text = DateTimeFormator.formatDate(date);
                    });
                    print(_dateCtrl.text);
                  },
                  child: Container(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: _dateCtrl.text != ''
                            ? Text(
                                _dateCtrl.text,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 4),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                    size: SizeConfig.safeBlockHorizontal * 4,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    "Select Date",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 3),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: BorderRadius.circular(10)),
                    width: double.infinity,
                  ),
                ),
              ),
              // TextFormField(
              //   controller: _timeCtrl,
              //   inputFormatters: [
              //     BlacklistingTextInputFormatter(RegExp(r".*"))
              //   ],
              //   keyboardType: TextInputType.datetime,
              //   decoration: InputDecoration(
              //       labelText: 'Time',
              //       errorText: _timeError,
              //
              //       labelStyle: TextStyle(
              //           fontSize: SizeConfig.safeBlockHorizontal * 3.5),
              //       icon: Icon(Icons.access_time),
              //       suffixIcon: GestureDetector(
              //         child: Icon(Icons.more_horiz),
              //         onTap: () async {
              //           final TimeOfDay time = await showTimePicker(
              //               context: context,
              //               initialTime: TimeOfDay.fromDateTime(
              //                   DateTime.now().add(Duration(minutes: 2))));
              //           _time = time;
              //           setState(() {
              //             _timeCtrl.text = _time.format(context);
              //           });
              //         },
              //       )),
              // ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                child: GestureDetector(
                  onTap: () async {
                    final TimeOfDay time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                            DateTime.now().add(Duration(minutes: 2))));
                    _time = time;
                    setState(() {
                      _timeCtrl.text = _time.format(context);
                    });
                    print(_timeCtrl.text.toString());
                  },
                  child: Container(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: _timeCtrl.text != ''
                            ? Text(
                                _timeCtrl.text,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize:
                                        SizeConfig.safeBlockHorizontal * 4),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.white,
                                    size: SizeConfig.safeBlockHorizontal * 4,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    "Select Time",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            SizeConfig.safeBlockHorizontal * 3),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: BorderRadius.circular(10)),
                    width: double.infinity,
                  ),
                ),
              ),
              TextFormField(
                controller: _messageCtrl,
                maxLines: null,
                // maxLength: _settings.sms.maxSmsCount * SmsSettings.maxSmsLength,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                    // errorText: _messageError,
                    labelStyle: TextStyle(
                        fontSize: SizeConfig.safeBlockHorizontal * 3.5),
                    labelText: 'Message',
                    icon: Icon(Icons.textsms)),
              ),
              ((_driverCtrl == MessageDriver.Email) ||
                      (_driverCtrl == MessageDriver.Whatsapp))
                  ? Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      IconButton(
                        icon: Icon(FontAwesomeIcons.file, color: Colors.grey),
                        tooltip: 'Attachment',
                        onPressed: () {
                          pickAttachment();
                        },
                      ),
                      Text(
                          '${_gmailSenderMailAttachment.text == '' ? 'No attachment added' : 'Attachment added'}'),
                    ])
                  : Text(''),
            ],
          )),
      floatingActionButton: FloatingActionButton(
        child: Icon(
            widget.messageMode == MessageMode.create
                ? Icons.create
                : Icons.edit,
            color: Colors.white),
        onPressed: !_validate()
            ? null
            : () => widget.messageMode == MessageMode.edit
                ? _onEditMessage()
                : _onCreateMessage(),
        backgroundColor: _validate() ? Colors.blueGrey : Colors.grey,
      ),
    );
  }

  getSchedulingFor() {
    switch (_driverCtrl) {
      case MessageDriver.SMS:
        return 'SMS';
        break;
      case MessageDriver.Whatsapp:
        return 'SMS';
        break;
      case MessageDriver.Email:
        return 'Email';
        break;
    }
  }

  bool _validate() {
    bool status = true;

    _messageError = null;
    _phoneNumberError = null;
    _dateError = null;
    _timeError = null;
    _gmailSenderMailIdError = null;
    _gmailSenderMailPasswordError = null;

    if (_messageCtrl.text.trim().isEmpty) {
      status = false;
      _messageError = 'Enter a message.';
    }

    if (_dateCtrl.text.isEmpty) {
      status = false;
      _dateError = 'Select a date.';
    }

    if (_timeCtrl.text.isEmpty) {
      status = false;
      _timeError = 'Select a time.';
    }

    if (_driverCtrl == MessageDriver.Email) {
      Pattern pattern =
          r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]"
          r"{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]"
          r"{0,253}[a-zA-Z0-9])?)*$";
      RegExp regex = new RegExp(pattern);

      if (_emailCtrl.text.isEmpty) {
        status = false;
        setState(() {
          _phoneNumberError = 'Enter the Email ID.';
        });
      } else if (!regex.hasMatch(_emailCtrl.text)) {
        status = false;
        setState(() {
          _phoneNumberError = 'Enter valid Email ID.';
        });
      } else {
        setState(() {
          _phoneNumberError = '';
        });
      }

      if (_gmailSenderMailId.text.isEmpty) {
        status = false;
        setState(() {
          _gmailSenderMailIdError = 'Enter the Email ID.';
        });
      } else if (!regex.hasMatch(_gmailSenderMailId.text)) {
        status = false;
        setState(() {
          _gmailSenderMailIdError = 'Enter valid Email ID.';
        });
      } else {
        setState(() {
          _gmailSenderMailIdError = '';
        });
      }

      if (_gmailSenderMailPassword.text.isEmpty) {
        status = false;
        _gmailSenderMailPasswordError = 'Enter the mail password.';
      }
    } else {
      if (_phoneNumberCtrl.text.isEmpty) {
        status = false;
        _phoneNumberError = 'Enter a phone number.';
      }
    }

    return status;
  }

  /// Creates a message based on the form (user input).
  Message _getFinalMessage() => _driverCtrl == MessageDriver.Email
      ? Message(
          id: widget?.message?.id,
          content: _messageCtrl.text,
          subject: _mailSubjectCtrl.text,
          mailHost: _gmailSenderMailHost.text,
          mailId: prefs.getString('email'),
          mailPassword: prefs.getString('password'),
          mailAttachment: _gmailSenderMailAttachment.text,
          createdAt: widget?.message?.createdAt ??
              DateTime.now().millisecondsSinceEpoch,
          attempts: widget?.message?.attempts ?? 0,
          endpoint: _emailCtrl.text,
          driver: _driverCtrl,
          status: widget?.message?.status ?? MessageStatus.PENDING,
          isArchived: widget?.message?.isArchived ?? false,
          executedAt: DateTime(
                  _date.year, _date.month, _date.day, _time.hour, _time.minute)
              .millisecondsSinceEpoch)
      : Message(
          id: widget?.message?.id,
          content: _messageCtrl.text,
          subject: '',
          mailHost: '',
          mailId: '',
          mailPassword: '',
          mailAttachment: (_driverCtrl == MessageDriver.Whatsapp &&
                  _gmailSenderMailAttachment.text != '')
              ? _gmailSenderMailAttachment.text
              : '',
          createdAt: widget?.message?.createdAt ??
              DateTime.now().millisecondsSinceEpoch,
          attempts: widget?.message?.attempts ?? 0,
          endpoint: _phoneNumberCtrl.text,
          driver: _driverCtrl,
          status: widget?.message?.status ?? MessageStatus.PENDING,
          isArchived: widget?.message?.isArchived ?? false,
          executedAt: DateTime(
                  _date.year, _date.month, _date.day, _time.hour, _time.minute)
              .millisecondsSinceEpoch);

  void _onEditMessage() async {
    if (await _messagesBloc.updateMessage(_getFinalMessage())) {
      Navigator.pop(context);
    } else {
      await DialogProvider.showMessage(
          context: context,
          title: Icon(Icons.error),
          content: Text('Error updating message.'));
    }
  }

  void _onCreateMessage() async {
    print(_mailSubjectCtrl.text);
    // FilePickerResult result = await FilePicker.platform.pickFiles();
    if (await _messagesBloc.addMessage(_getFinalMessage())) {
      Navigator.pop(context);
    } else {
      await DialogProvider.showMessage(
          context: context,
          title: Icon(Icons.error),
          content: Text('Error creating message.'));
    }
  }
}

class RemindersPage extends StatefulWidget {
  @override
  _RemindersPageState createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  final _gmailMailId = TextEditingController();
  final _gmailMailPassword = TextEditingController();
  String _currentSelectedValue = 'Gmail';
  var _currencies = ['Gmail', 'Yahoo', 'Hotmail'];
  void _loadEmails() async {
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // if (prefs.containsKey('mailid')) {
    //   _gmailMailId.text = prefs.getString('mailid');
    //   _gmailMailPassword.text = prefs.getString('mailpassword');
    // }
  }

  @override
  void initState() {
    _loadEmails();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new AlertDialog(
      title: new Text('Add Mail ID'),
      content: Column(
        children: <Widget>[
          DropdownButton<String>(
            value: _currentSelectedValue,
            onChanged: (String newValue) {
              setState(() {
                _currentSelectedValue = newValue;
              });
            },
            items: _currencies.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          TextField(
            controller: _gmailMailId,
            decoration: InputDecoration(
                icon: Icon(Icons.account_circle),
                labelText: 'Email ID',
                labelStyle:
                    TextStyle(fontSize: SizeConfig.safeBlockHorizontal * 3)),
          ),
          TextField(
            obscureText: true,
            controller: _gmailMailPassword,
            decoration: InputDecoration(
              icon: Icon(Icons.lock),
              labelText: 'Password',
            ),
          ),
        ],
      ),
      actions: [
        RaisedButton(
            child: Text("Submit"),
            onPressed: () async {
              print(_gmailMailId.text);
              print(_gmailMailPassword.text);
              // SharedPreferences prefs = await SharedPreferences.getInstance();
              // prefs.setString('mailid', _gmailMailId.text);
              // prefs.setString('mailpassword', _gmailMailPassword.text);
              setState(() {
                _gmailMailId.text = _gmailMailId.text;
                _gmailMailPassword.text = _gmailMailPassword.text;
              });
              // _gmailMailId.text = '';
              // _gmailMailPassword.text = '';
              Navigator.pop(context);
            })
      ],
    );
    throw UnimplementedError();
  }
}
