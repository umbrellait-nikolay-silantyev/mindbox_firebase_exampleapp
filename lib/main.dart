import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mindbox/mindbox.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final prefs = await SharedPreferences.getInstance();
  print('onBackground');
  print(message.toMap());
  await prefs.setString('message', message.data.toString());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('onMessage: ${message.toMap()}');
  });
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final config = Configuration(
      domain: "api.mindbox.ru",
      endpointIos: "endpoint для iOs",
      endpointAndroid: "endpoint для Android",
      shouldCreateCustomer: true,
      subscribeCustomerIfCreated: false);
  Mindbox.instance.init(configuration: config);
  Mindbox.instance.getDeviceUUID((uuid) => print('UUID = $uuid'));
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('fcmToken = $fcmToken');
  Mindbox.instance.getToken((token) => print('token = $token'));

  SharedPreferences.getInstance().then((value) async {
    print(value.getString('message').toString());
    Fluttertoast.showToast(
        msg: value.getString('message').toString(),
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.black,
        textColor: Colors.white,
        fontSize: 16.0);
    (await SharedPreferences.getInstance()).clear();
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  String _counter = '';

  @override
  void initState() {
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      setState(() {
        _counter = event.toMap().toString();
      });
      print('onMessageOpenedApp: ${event.toMap()}');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              _counter,
            ),
            FutureBuilder<RemoteMessage?>(
              future: FirebaseMessaging.instance.getInitialMessage(),
              builder: (context, snapshot) {
                return snapshot.data == null
                    ? const Text('null')
                    : Text(snapshot.data!.toMap().toString());
              },
            ),
          ],
        ),
      ),
    );
  }
}
