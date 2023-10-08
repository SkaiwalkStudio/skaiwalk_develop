import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'development_screen.dart';
import 'locator.dart';
import 'log_model.dart';
import 'skaios_provider.dart';

const String uid = "developer";
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerLocator();
  requestPermission();
  runApp(const MyApp());
}

void requestPermission() async {
  final permissionStatus = await Permission.storage.status;
  if (permissionStatus.isDenied) {
    // Here just ask for the permission for the first time
    await Permission.storage.request();

    // I noticed that sometimes popup won't show after user press deny
    // so I do the check once again but now go straight to appSettings
    if (permissionStatus.isDenied) {
      print("permission denied");
      await openAppSettings();
    }
  } else if (permissionStatus.isPermanentlyDenied) {
    // Here open app settings for user to manually enable permission in case
    // where permission was permanently denied
    print("permission permanently denied");
    await openAppSettings();
  } else {
    // Do stuff that require permission here
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            lazy: true, create: (context) => locator<SkaiOSProvider>()),
        ChangeNotifierProvider(
            lazy: true, create: (context) => locator<LogModel>()),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
        builder: BotToastInit(), //1. call BotToastInit
        navigatorObservers: [BotToastNavigatorObserver()],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const DevelopmentScreen(),
    );
  }
}
