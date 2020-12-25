
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
import 'package:shared_preferences/shared_preferences.dart';


enum MessageMode {
  create,
  edit
}

class CreateOrEditSmsMessagePage extends StatefulWidget {
  final MessageMode messageMode;
  final Message message;

  /// Constructs the message mode.
  /// If [messageMode] == [MessageMode.edit] then [message] should be set.
  const CreateOrEditSmsMessagePage(this.messageMode, [this.message]);

  @override
  _CreateOrEditSmsMessagePageState createState() => _CreateOrEditSmsMessagePageState();
}

class _CreateOrEditSmsMessagePageState extends State<CreateOrEditSmsMessagePage> {

  final _contactPicker = ContactPicker();
  final _messagesBloc = MessageBloc() ;
  Settings _settings = SettingsProvider.getDefaultSettings();
  DateTime _date;
  TimeOfDay _time;

  final _phoneNumberCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  final _mailSubjectCtrl = TextEditingController();
  final _gmailMailId = TextEditingController();
  final _gmailMailPassword = TextEditingController();

  MessageDriver _driverCtrl = MessageDriver.SMS;

  String _phoneNumberError;
  String _dateError;
  String _timeError;
  String _messageError;


  @override
  void initState() { 
    super.initState();

    if (widget.messageMode == MessageMode.edit) {
      if(widget.message.driver == MessageDriver.Email)
        _emailCtrl.text = widget.message.endpoint;
      else
        _phoneNumberCtrl.text = widget.message.endpoint;

      _dateCtrl.text = DateTimeFormator.formatDate(DateTime.fromMillisecondsSinceEpoch(widget.message.executedAt));
      _timeCtrl.text = DateTimeFormator.formatTime(TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(widget.message.executedAt)));
      _messageCtrl.text = widget.message.content;
      _mailSubjectCtrl.text = widget.message.subject;

      _date = DateTime.fromMillisecondsSinceEpoch(widget.message.executedAt);
      _time = TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(widget.message.executedAt));
    }
    else {
      _phoneNumberCtrl.text = '';
      _emailCtrl.text = '';
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

    _loadSettings();
    _validate();
  }

  void _loadSettings() async {
    final Settings settings = await SettingsProvider.getInstance().getSettings();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(prefs.containsKey('mailid'));
    setState( () => _settings = settings );
    if(prefs.containsKey('mailid')){
      _gmailMailId.text = prefs.getString('mailid');
      _gmailMailPassword.text = prefs.getString('mailpassword');
    }

  }

  @override
  void dispose() {
    super.dispose();
    _messagesBloc.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text((widget.messageMode == MessageMode.edit ? 'Edit' : 'Create New') + ' Message'),
      ),

      body: Padding(
        padding: EdgeInsets.only(left: 10, right: 10, top: 15, bottom: 15),
        child: ListView(
          children: <Widget>[

            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Scheduling message for: ${getSchedulingFor()}'),
                IconButton(
                  icon: Icon(FontAwesomeIcons.sms, color: _driverCtrl == MessageDriver.SMS ? Colors.blue: Colors.grey),
                  tooltip: 'SMS',
                  onPressed: () {
                    setState(() {
                      _driverCtrl = MessageDriver.SMS;
                      _validate();

                    });
                  },
                ),
                IconButton(
                  icon: Icon(FontAwesomeIcons.whatsapp, color: _driverCtrl == MessageDriver.Whatsapp ? Colors.blue: Colors.grey),
                  tooltip: 'Whatsapp',
                  onPressed: () {
                    setState(() {
                      _driverCtrl = MessageDriver.Whatsapp;
                      _validate();

                    });
                  },
                ),
                IconButton(
                  icon: Icon(FontAwesomeIcons.envelope, color: _driverCtrl == MessageDriver.Email ? Colors.blue: Colors.grey),
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
            _driverCtrl == MessageDriver.Email ?
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Using Sender Mail ID: ${_gmailMailId.text}'),
                IconButton(
                  icon: Icon(Icons.edit),
                  tooltip: 'Change',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => new AlertDialog(
                        title: new Text('Add GMAIL Mail ID'),
                        content: Column(
                          children: <Widget>[
                            TextField(
                              controller: _gmailMailId,
                              decoration: InputDecoration(
                                icon: Icon(Icons.account_circle),
                                labelText: 'Gmail Email ID',
                              ),
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
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                prefs.setString('mailid', _gmailMailId.text);
                                prefs.setString('mailpassword', _gmailMailPassword.text);
                                setState(() {
                                  _gmailMailId.text = _gmailMailId.text;
                                  _gmailMailPassword.text = _gmailMailPassword.text;
                                });
                                // _gmailMailId.text = '';
                                // _gmailMailPassword.text = '';
                                Navigator.pop(context);
                              })
                        ],
                      ),
                    );
                  },
                ),
              ]
            )
            :
            Text(''),
            _driverCtrl == MessageDriver.Email ?
            TextFormField(
              controller: _emailCtrl,
              // inputFormatters: [
              //   WhitelistingTextInputFormatter(RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")) // don't allow any input
              // ],
              maxLength: null,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email ID',
                labelText: 'Email ID',
                errorText: _phoneNumberError,
                icon: Icon(Icons.contact_phone),
              ),
            )
            :
            TextFormField(
              controller: _phoneNumberCtrl,
              inputFormatters: [
                WhitelistingTextInputFormatter(RegExp(r"^[+]?\d*$")) // don't allow any input
              ],
              maxLength: 15,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  hintText: 'Phone Number',
                  labelText: 'Phone Number',
                  errorText: _phoneNumberError,
                  icon: Icon(Icons.contact_phone),
                  suffixIcon: GestureDetector(
                      onTap: () async {
                        final Contact contact = await _contactPicker.selectContact();
                        // String number
                        setState(() => _phoneNumberCtrl.text = contact.phoneNumber.number.toString());
                      },
                      child: Icon(Icons.person_add)
                  )
              ),
            ),
            _driverCtrl == MessageDriver.Email ? TextFormField(
              controller: _mailSubjectCtrl,
              maxLines: null,
              maxLength: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                  labelText: 'Subject',
                  icon: Icon(Icons.textsms)
              ),
            )
            :
            Text(''),
            TextFormField(
              controller: _messageCtrl,
              maxLines: null,
              maxLength: _settings.sms.maxSmsCount * SmsSettings.maxSmsLength,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                errorText: _messageError,
                labelText: 'Message',
                icon: Icon(Icons.textsms)
              ),
            ),
            
            TextFormField(
              controller: _dateCtrl,
              inputFormatters: [
                BlacklistingTextInputFormatter(RegExp(r".*")) // don't allow any input
              ],
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: 'Date',
                errorText: _dateError,
                icon: Icon(Icons.calendar_today),
                suffixIcon: GestureDetector(
                  child: Icon(Icons.more_horiz),
                  onTap: () async {
                    final DateTime date = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 30 * 12* 2)),
                      initialDate: DateTime.now()
                    );
                    _date = date;
                    setState(() {
                      _dateCtrl.text = DateTimeFormator.formatDate(date);
                    });
                  },
                )
              ),
            ),

            TextFormField(
              controller: _timeCtrl,
              inputFormatters: [
                BlacklistingTextInputFormatter(RegExp(r".*"))
              ],
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: 'Time',
                errorText: _timeError,
                icon: Icon(Icons.access_time),
                suffixIcon: GestureDetector(
                  child: Icon(Icons.more_horiz),
                  onTap: () async {
                    final TimeOfDay time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(DateTime.now().add(Duration(minutes: 2)))
                    );
                    _time = time;
                    setState(() {
                      _timeCtrl.text = _time.format(context);
                    });
                  },
                )
              ),
            ),

          ],
        )
      ),

      floatingActionButton: FloatingActionButton(
        child: Icon(
          widget.messageMode == MessageMode.create ? Icons.create : Icons.edit,
          color: Colors.white
        ),
        onPressed: !_validate() ? null : () => widget.messageMode == MessageMode.edit ? _onEditMessage() : _onCreateMessage(),
        backgroundColor: _validate() ? Colors.deepOrange : Colors.grey,
      ),
    );
  }

  getSchedulingFor(){
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

    if(_driverCtrl==MessageDriver.Email){
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
      }else if(!regex.hasMatch(_emailCtrl.text)){
        status = false;
        setState(() {
          _phoneNumberError = 'Enter valid Email ID.';
        });
      }else{
        setState(() {
          _phoneNumberError = '';
        });
      }
    }else{
      if (_phoneNumberCtrl.text.isEmpty) {
        status = false;
        _phoneNumberError = 'Enter a phone number.';
      }
    }

    return status;
  }

  /// Creates a message based on the form (user input).
  Message _getFinalMessage() =>
      _driverCtrl == MessageDriver.Email ?
    Message(
      id: widget?.message?.id,
      content: _messageCtrl.text,
      subject: _mailSubjectCtrl.text,
      createdAt: widget?.message?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
      attempts: widget?.message?.attempts ?? 0,
      endpoint: _emailCtrl.text,
      driver: _driverCtrl,
      status: widget?.message?.status ?? MessageStatus.PENDING,
      isArchived: widget?.message?.isArchived ?? false,
      executedAt: DateTime(
        _date.year, _date.month, _date.day,
        _time.hour, _time.minute
      ).millisecondsSinceEpoch
    ) :
      Message(
          id: widget?.message?.id,
          content: _messageCtrl.text,
          subject: '',
          createdAt: widget?.message?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
          attempts: widget?.message?.attempts ?? 0,
          endpoint: _phoneNumberCtrl.text,
          driver: _driverCtrl,
          status: widget?.message?.status ?? MessageStatus.PENDING,
          isArchived: widget?.message?.isArchived ?? false,
          executedAt: DateTime(
              _date.year, _date.month, _date.day,
              _time.hour, _time.minute
          ).millisecondsSinceEpoch
      )
  ;

  void _onEditMessage() async {
    if (await _messagesBloc.updateMessage(_getFinalMessage())) {
      Navigator.pop(context);
    }
    else {
      await DialogProvider.showMessage(
        context: context,
        title: Icon(Icons.error),
        content: Text('Error updating message.')
      );
    }
  }

  void _onCreateMessage() async {
    print(_mailSubjectCtrl.text);
    if (await _messagesBloc.addMessage(_getFinalMessage())) {
      Navigator.pop(context);
    }
    else {
      await DialogProvider.showMessage(
        context: context,
        title: Icon(Icons.error),
        content: Text('Error creating message.')
      );
    }
  }
}