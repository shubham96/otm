import 'package:flutter/material.dart';
import 'package:msgschedule_2/providers/MessageProvider.dart';
import 'package:starflut/starflut.dart';
//import 'package:msgschedule_2/providers/SettingsProvider.dart';
import 'package:msgschedule_2/pages/Whatsappschedulesender.dart';

import 'pages/schedule/SchedulePage.dart';

Future<void> testCallPython() async {
  StarCoreFactory starcore = await Starflut.getFactory();
  StarServiceClass Service = await starcore.initSimple("test", "123", 0, 0, []);
  await starcore.regMsgCallBackP(
      (int serviceGroupID, int uMsg, Object wParam, Object lParam) async {
    print("$serviceGroupID  $uMsg   $wParam   $lParam");
    return null;
  });
  StarSrvGroupClass SrvGroup = await Service["_ServiceGroup"];

  /*---script python--*/
  bool isAndroid = await Starflut.isAndroid();
  if (isAndroid == true) {
    await Starflut.copyFileFromAssets(
        "schedule_message.py",
        "flutter_assets/starfiles/whatsapp-play/wplay",
        "flutter_assets/starfiles/whatsapp-play/wplay");
    await Starflut.copyFileFromAssets(
        "python3.6.zip",
        "flutter_assets/starfiles/whatsapp-play/wplay",
        null); //desRelatePath must be null
    await Starflut.copyFileFromAssets("zlib.cpython-36m.so", null, null);
    await Starflut.copyFileFromAssets("unicodedata.cpython-36m.so", null, null);
    await Starflut.loadLibrary("libpython3.6m.so");
  }

  String docPath = await Starflut.getDocumentPath();
  print("docPath = $docPath");

  String resPath = await Starflut.getResourcePath();
  print("resPath = $resPath");

  dynamic rr1 = await SrvGroup.initRaw("python36", Service);

  print("initRaw = $rr1");
  var Result = await SrvGroup.loadRawModule(
      "python",
      "",
      resPath +
          "/flutter_assets/starfiles/whatsapp-play/wplay" +
          "schedule_message.py",
      false);
  print("loadRawModule = $Result");

  dynamic python = await Service.importRawContext("python", "", false, "");
  print("python = " + await python.getString());

  StarObjectClass retobj = await python.call("tt", ["hello ", "world"]);
  // print(await retobj[0]);
  // print(await retobj[1]);
  //
  // print(await python["g1"]);

  StarObjectClass yy = await python.call("yy", ["hello ", "world", 123]);
  // print(await yy.call("__len__", []));

  StarObjectClass multiply =
      await Service.importRawContext("python", "Multiply", true, "");
  StarObjectClass multiply_inst = await multiply.newObject(["", "", 33, 44]);
  print(await multiply_inst.getString());

  print(await multiply_inst.call("multiply", [11, 22]));

  await SrvGroup.clearService();
  await starcore.moduleExit();
}

Future main() async {
  await WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
  // testCallPython();
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final String _appName = 'MsgSchedule';
  Widget _home;

  _MyAppState();

  @override
  void initState() {
    super.initState();
    _home = SchedulePage(title: _appName);
    // _home = PreviewPage as Widget;
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
}
