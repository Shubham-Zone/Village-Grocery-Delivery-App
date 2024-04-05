import 'dart:convert';
import 'dart:developer';
import 'dart:io';
// import 'dart:js_interop';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_projects/MongoDb/Mongodb.dart';
import 'package:flutter_projects/MongoDb/constants.dart';
import 'package:flutter_projects/Splashscreen.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'NavBar.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart' show DateFormat;
import 'package:intl/date_symbol_data_local.dart' as f;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
// import 'package:location/location.dart' as l;


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // Check internet connection

  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {

    // Display error message and retry button
    runApp(const ErrorScreen());

  } else {

    // Connect to MongoDB and Firebase
    await MongoDatabase.connect();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Run the main app
    runApp(const MyApp());
  }
}

MaterialColor buildMaterialColor(Color color) {
  List strengths = <double>[.05];
  Map<int, Color> swatch = {};
  final int r = color.red, g = color.green, b = color.blue;

  for (int i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final double ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.value, swatch);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'T&T',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primarySwatch:
                Colors.green //buildMaterialColor(const Color(0xFFDE6262)),
            ),
        home: const SplashScreen()
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

  static dynamic d, userCollection , offerCollection;
  TextEditingController order = TextEditingController();
  TextEditingController loc = TextEditingController();
  int mobileNo = 0;
  // DatabaseReference db = FirebaseDatabase.instance.ref().child("Orders");
  bool currLoc = false;
  bool isRec = false;
  String audioUrl = "";
  double long = 0.0;
  double lat = 0.0;
  var token="";
  String currentOffer = "";
  // l.Location location = new l.Location();
  String? addUsingLocation = "Fetching...";
  final DatabaseReference offerDb = FirebaseDatabase.instance.ref().child('Offer');
  final DatabaseReference dbRef=FirebaseDatabase.instance.ref().child("status");
  String status="5";

  savingOrderDetails(final id, String foodlist, String loc ) async {

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('id', id.toString());
    prefs.setString('foodlist', foodlist);
    prefs.setString('Loc', loc);

    // print("id : $id , Foodlist : $foodlist , Loc : $loc");


  }


  Future<void> checkAndRequestPermissions() async {
    final permissions = [
      Permission.storage,
      Permission.notification,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();
    Geolocator.requestPermission();

    statuses.forEach((permission, status) {
      if (status.isDenied) {
        // Permission is denied, handle it as needed
        handlePermissionDenied(permission);
      }
    });
  }

  void handlePermissionDenied(Permission permission) {
    // You can customize the behavior for each denied permission here
    if (permission == Permission.storage) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Storage permission is denied")));
    } else if (permission == Permission.microphone) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("microphone permission is denied")));
    } else if (permission == Permission.notification) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification permission is denied")));
    }

  }


  // Functions for getting location

  String? _currentAddress;
  Position? _currentPosition;

  // Future<bool> _handleLocationPermission() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;
  //
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     if(mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //         content: Text(
  //             'Location services are disabled. Please enable the services')));
  //     }
  //     return false;
  //   }
  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
  //       return false;
  //     }
  //   }
  //   if (permission == LocationPermission.deniedForever) {
  //     if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
  //     return false;
  //   }
  //   return true;
  // }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
        _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress = '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
        loc.text = _currentAddress!;
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  // final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  //
  // void _getLastKnownPosition() async {
  //   final hasPermission = await _handleLocationPermission();
  //
  //   if (!hasPermission){
  //     if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location permission is denied")));
  //   }
  //   final position = await _geolocatorPlatform.getLastKnownPosition();
  //   if (position != null) {
  //
  //     setState(() {
  //       _currentPosition = position;
  //       _getAddressFromLatLng(_currentPosition!);
  //     });
  //
  //   } else {
  //
  //     final position = await _geolocatorPlatform.getCurrentPosition();
  //
  //     if(position != null){
  //
  //       setState(() {
  //         _currentPosition = position;
  //         _getAddressFromLatLng(_currentPosition!);
  //       });
  //
  //     } else {
  //       if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Something went wrong")));
  //     }
  //
  //   }
  // }

  fetchPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    // l.LocationData _locationData;
    Position? position;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {

      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.Please enable the services')));
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // return Future.error('Location permissions are denied');
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
      }
    }

    if (permission == LocationPermission.deniedForever) {
      //return Future.error('Location permissions are permanently denied, we cannot request permissions.');
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));

    }

    // Initialize a timeout duration in milliseconds (adjust as needed)
    const int locationTimeoutMs = 4000; // 4 seconds

    // Use the location package to get the location with a timeout
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high , forceAndroidLocationManager: true).timeout(const Duration(milliseconds: locationTimeoutMs));
      setState(() {
        long = position!.longitude;
        lat = position.latitude;
      });
    } catch (e) {
      // Location package didn't provide a location within the timeout, so use Geolocator
      Position? lastKnownLocation = await Geolocator.getLastKnownPosition();
      if (lastKnownLocation != null) {
        setState(() {
          long = lastKnownLocation.longitude;
          lat = lastKnownLocation.latitude;
        });
      } else {
        // Handle the case where Geolocator also didn't provide a location
        // return Future.error('Unable to retrieve location.');
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to retrieve location.')));

      }
    }

    // Getting current address
    await placemarkFromCoordinates(lat, long)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        addUsingLocation =
        '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
        loc.text = addUsingLocation!;
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }


  static connect() async {
    d = await mongo.Db.create(MONGO_URL);
    await d.open();
    userCollection = d.collection(COLLECTION_NAME);
    offerCollection = d.collection(offCollection);
    inspect(d);
    // ignore: unused_local_variable
    var status = d.serverStatus();

    // final data = await offerCollection.findOne({"_id":"offer"});
    // currentOffer = data['offer'];

    // var collection = db.collection(COLLECTION_NAME);
    // print(await collection.find().toList());

    // var document = {
    //   "_id": ObjectId(),  // Create a new ObjectId
    //   "name": "John",
    //   // ... other fields
    // };
    //
    // collection.insertOne(document);
    //
    // print(collection.findOne({"name":"John"}));
    //
    // print("done");

  }

  // Future<String> getOffer() async {
  //   try {
  //     final data = await offerCollection.findOne({"_id": "offer"});
  //     final offerText = data['offer'];
  //     return offerText;
  //   } catch (e) {
  //     // Handle any errors, e.g., return a default offer text or throw an exception.
  //     // print("Error fetching offer: $e");
  //     return "Fetching offer..."; // Replace with your default offer text.
  //   }
  // }

  void getOffer() async {
    try {
      // final data = await offerCollection.findOne({"_id": "offer"});
      // final offerText = data['offer'];
      offerDb.onValue.listen((event) {
        setState(() {
          final offerText = event.snapshot.value.toString();
          currentOffer = offerText;
        });
      });


      // Timer(const Duration(seconds: 4), () {
      //   setState(() {
      //     currentOffer = offerText;
      //   });
      // });

    } catch (e) {
      // Handle any errors, e.g., return a default offer text or throw an exception.
      // print("Error fetching offer: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fetching offer...")));
    }
  }

  _gettingMobileNo() async {
    // Obtain shared preferences.
    final prefs = await SharedPreferences.getInstance();
    int? phNo = prefs.getInt('phoneNo');

    phNo ??= 0;
    setState(() {
      mobileNo = phNo!;
    });
  }

  //Functions for audio recorder

  late FlutterSoundRecorder _recordingSession;
  final recordingPlayer = AssetsAudioPlayer();
  late String pathToAudio;
  bool _playAudio = false;
  String _timerText = '00:00:00';

  Future<void> getPathToAudio() async {
    try {
      // Get the external storage directory for your app's files
      Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        pathToAudio = '${externalDir.path}/Download/temp.wav';
      } else {
        // Handle the case where external storage is not available
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('External storage not available')));
      }
    } catch (e) {
      // Handle any errors
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error : $e')));
    }


  }

  void initializer() async {
    // pathToAudio = '/sdcard/Download/temp.wav';
    getPathToAudio();
    _recordingSession = FlutterSoundRecorder();
    await _recordingSession.openAudioSession(
      focus: AudioFocus.requestFocusAndStopOthers,
      category: SessionCategory.playAndRecord,
      mode: SessionMode.modeDefault,
      device: AudioDevice.speaker,
    );
    await _recordingSession.setSubscriptionDuration(const Duration(milliseconds: 10));
    await f.initializeDateFormatting();

    // Request permission for the microphone
    // final microphonePermissionStatus = await Permission.microphone.request();
    // if (microphonePermissionStatus.isGranted) {
    //   // Microphone permission is granted.
    // } else {
    //   // Handle the case where the user denied microphone permission.
    //   await Permission.microphone.request();
    //   if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied')));
    // }

    // Request permission for storage
    // final storagePermissionStatus = await Permission.storage.request();
    // if (storagePermissionStatus.isGranted) {
    //   // Storage permission is granted.
    // } else {
    //   // Handle the case where the user denied storage permission.
    //   await Permission.storage.request();
    //   if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage permission denied')));
    // }

    // Continue with the initialization even if permissions are denied.
  }

  reqForRecorder() async {
    // Request permission for the microphone
    final microphonePermissionStatus = await Permission.microphone.request();
    if (microphonePermissionStatus.isGranted) {
      // Microphone permission is granted.
    } else {
      // Handle the case where the user denied microphone permission.
      await Permission.microphone.request();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied')));
    }

      final plugin = DeviceInfoPlugin();
      final android = await plugin.androidInfo;

      final storageStatus = android.version.sdkInt < 33
          ? await Permission.storage.request()
          : PermissionStatus.granted;

      if (storageStatus == PermissionStatus.granted) {
        // print("granted");
      }
      if (storageStatus == PermissionStatus.denied) {
        // print("denied");
      }
      if (storageStatus == PermissionStatus.permanentlyDenied) {
        openAppSettings();
      }

  }

  StreamSubscription? _recorderSubscription;
  bool _isRecordingPaused = false;

  Future<void> startRecording() async {
    if (_isRecordingPaused) {
      // Resume recording
      _recordingSession.resumeRecorder();
    } else {
      Directory directory = Directory(path.dirname(pathToAudio));
      if (!directory.existsSync()) {
        directory.createSync();
      }

      _recordingSession.openAudioSession();

      // Set up a stream subscription to continuously update the timer text
      _recorderSubscription = _recordingSession.onProgress!.listen((e) {
        var date = DateTime.fromMillisecondsSinceEpoch(
            e.duration.inMilliseconds,
            isUtc: true);
        var timeText = DateFormat('mm:ss:SS', 'en_GB').format(date);
        if (mounted) {
          setState(() {
            _timerText = timeText.substring(0, 8);
          });
        }
      });

      await _recordingSession.startRecorder(
        toFile: pathToAudio,
        codec: Codec.pcm16WAV,
      );
    }

    setState(() {
      _isRecordingPaused = false;
    });
  }

  Future<void> stopRecording() async {
    if (_recorderSubscription != null) {
      _recorderSubscription!.cancel();
    }

    await _recordingSession.stopRecorder();

    setState(() {
      _isRecordingPaused = false;
    });
  }

  void pauseRecording() {
    if (_isRecordingPaused) {
      _recordingSession.resumeRecorder();
    } else {
      _recordingSession.pauseRecorder();
    }

    setState(() {
      _isRecordingPaused = !_isRecordingPaused;
    });
  }

  Future<void> playFunc() async {
    recordingPlayer.open(
      Audio.file(pathToAudio),
      autoStart: true,
      showNotification: true,
    );
  }

  Future<void> stopPlayFunc() async {
    recordingPlayer.stop();
  }

  Future<void> deleteAudioFile() async {
    final file = File(pathToAudio);
    if (await file.exists()) {
      await file.delete();
    } else {
    }
  }

  //Functions for Sending the notification

  _gettingFcmToken() async {

    // final fcmtoken = await FirebaseAuth.instance.currentUser?.getIdToken();
    final fcmtoken = await fcm.FirebaseMessaging.instance.getToken();
    token=fcmtoken.toString();


  }

  void requestPermission() async {
    // Get the Firebase Messaging instance.
    fcm.FirebaseMessaging messaging = fcm.FirebaseMessaging.instance;

    // Request permission to send notifications.
    fcm.NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == fcm.AuthorizationStatus.authorized) {
      // print('User granted permission');
    } else if (settings.authorizationStatus ==
        fcm.AuthorizationStatus.provisional) {
      // print('User granted provisional permission');
    } else {
      // print('User declined or has not accepted permission');
    }
  }

  void sendPushMessage(String body,String title) async{
    try{
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers:<String,String>{
          'Content-type': 'application/json',
          'Authorization': 'AAAA3-WqAQY:APA91bEiVxfQI-rZyXLTHBqb3vXoS0fSobXZ8mVJWyEUOEt_q932cSsx0sNgst-FI8P0kuauRoOmG-cRUE19GFiwWz24rqph3-ZxU5D91JhQswI63cZHBN7HKaIZ0J8wBeioGskPiouE'

        },
        body:jsonEncode(
          <String,dynamic>{
            'priority':'high',
            'to': '/topics/TTAdmin',
            'data':<String,dynamic>{
              'click-action':'FLUTTER_NOTIFICATION_CLICK',
              'Status':'done',
              'body':body,
              'title':title,
            },

            "notification":<String,dynamic>{
              "title":title,
              "body":body,
              "android_channel_id":"T&T"
            },
          },
        ),
      );
    }catch(e){
      if(kDebugMode){
        print("error push notification");
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Fetch the offer text using getOffer function and update the state.
    // Future<String?> offerFuture = getOffer();
    getOffer();

    // offerFuture.then((offerText) {
    //   // Ensure the widget is still mounted before updating the state.
    //   if (mounted) {
    //     setState(() {
    //       currentOffer = offerText ?? "Fetching offer..."; // Use a default if offerText is null
    //     });
    //   }
    // }).catchError((error) {
    //   // Handle any errors if the fetch operation fails.
    //   // print("Error fetching offer: $error");
    // });
    // Request permission to access the user's location.
    // Geolocator.requestPermission();
    // reqForRecorder();
    // _getCurrentPosition();

    Geolocator.requestPermission(); //Requesting for location permission
    // checkAndRequestPermissions();
    initializer(); //Requesting for storage permission
    requestPermission(); //Requesting for notification permission
    // _getLastKnownPosition();
    fetchPosition(); //Fetching the current location
    // checkAndRequestPermissions();
    // checkAndRequestPermissions();
    _gettingMobileNo();

    connect();
    _gettingFcmToken();

    //customising error screen
    RenderErrorBox.backgroundColor = Colors.transparent;
    RenderErrorBox.textStyle = ui.TextStyle(color: Colors.transparent);
    ErrorWidget.builder = (FlutterErrorDetails details) => const Center(
      child: Text("SOMETHING WENT WRONG ):"),
    );

  }

  @override
  void dispose(){
    super.dispose();
    if(_timerText != '00:00:00'){
      deleteAudioFile();
    }

  }


  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);

    return WillPopScope(

      onWillPop: () async {
        onBackPress(); // Action to perform on back pressed
        return false;
      },

      child: Scaffold(
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [

              SizedBox(
                height: mediaQuery.size.height * 0.25,
                width: double.infinity,
                child: Image.asset(
                  "assets/images/mainbanner.jpg",
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // Offer Card
              FlipCard(
                fill: Fill.fillBack,
                direction: FlipDirection.HORIZONTAL,
                side: CardSide.FRONT,
                front: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Colors.orangeAccent,
                  child: Container(
                    width: double.infinity,
                    // height: 100,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.lightBlueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Today's Special Offer",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentOffer ?? "Fetching offer...", // Use a default if snapshot.data is null
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
                back:  Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Colors.orangeAccent,
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.lightBlueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Text(
                          "Limited time Offer",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),


                      ],
                    ),
                  ),
                )
              ),

              const SizedBox(
                height: 20,
              ),

              // Order TextField
              TextField(
                controller: order,
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.fastfood), // Food-related icon
                  hintText: "e.g., 5kg dal, 1L mustard oil ...",
                  labelText: "Your Order",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // Location TextField
              TextField(
                controller: loc,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Delivery Address",
                  hintText: "Enter your address",
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // Current Location Button (only visible when currLoc is true)
              Visibility(
                visible: currLoc,
                child: const Card(
                  elevation: 6,
                  color: Colors.green, // A food-related color
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.done_all,
                          color: Colors.white,
                        ),
                        Text(
                          "Use Current Location",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Done",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // Enter Current Location Button
              InkWell(
                onTap: () async {
                  // _getCurrentPosition;
                  // setState(() {
                  //   currLoc = true;
                  //   loc.text = _currentAddress ?? "Location not loaded, press again";
                  // });
                  // print("1================");
                  // Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                  // print(position.latitude);
                  // _getLastKnownPosition();
                  bool serviceEnabled;

                  serviceEnabled = await Geolocator.isLocationServiceEnabled();
                  if (!serviceEnabled) {
                    if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.Please enable the services'),backgroundColor: Colors.red,));

                  } else {
                    await fetchPosition();
                    setState(() {
                      loc.text = addUsingLocation ?? "Location not loaded, press again";
                      currLoc = true;
                    });
                  }


                },
                child: const Text(
                  "Set Current Location",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      _timerText,
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.green,
                        fontWeight: FontWeight.bold, // Added font weight
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton.icon(
                        onPressed: () {
                          reqForRecorder();
                          startRecording();
                        },
                        icon: const Icon(Icons.mic),
                        label: const Text("Record"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Colors.green, // Text color
                          elevation: 6, // Increased button elevation
                          padding: const EdgeInsets.symmetric(horizontal: 20), // Added padding
                        ),
                      ),
                      const SizedBox(width: 30),
                      ElevatedButton.icon(
                        onPressed: () {
                          stopRecording();
                        },
                        icon: const Icon(Icons.stop),
                        label: const Text("Stop"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Colors.red, // Text color
                          elevation: 6, // Increased button elevation
                          padding: const EdgeInsets.symmetric(horizontal: 20), // Added padding
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _playAudio ? Colors.red : Colors.green,
                      elevation: 9.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Rounded button shape
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _playAudio = !_playAudio;
                      });
                      if (_playAudio) playFunc();
                      if (!_playAudio) stopPlayFunc();
                    },
                    icon: _playAudio
                        ? const Icon(
                      Icons.stop,
                    )
                        : const Icon(Icons.play_arrow),
                    label: _playAudio
                        ? const Text(
                      "Stop",
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    )
                        : const Text(
                      "Play",
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              SizedBox(
                width: mediaQuery.size.width * 0.5,
                child: ElevatedButton(
                  onPressed: () async {

                      if(order.text.trim().isNotEmpty || _timerText != '00:00:00'){

                        if(loc.text.trim().isNotEmpty){

                         if(_timerText != '00:00:00'){
                           // Storing the audio to Firestore

                           // Unique id
                           String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();

                           // Step 1: Pick file from gallery
                           final File audioFile = File(pathToAudio);

                           // Step 2: Upload to Firebase Storage

                           // Get the reference to storage root
                           Reference refenceroot = FirebaseStorage.instance.ref();

                           // Create a reference for the audio file to be stored
                           Reference refToAudio = refenceroot.child(uniqueFileName);

                           // Store the file
                           try {
                             await refToAudio.putFile(audioFile);
                             // Get the download URL
                             audioUrl = await refToAudio.getDownloadURL();
                           } catch (e) {

                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                 content: Text(e.toString()),backgroundColor: Colors.red,
                               ),
                             );
                             // print("The error is ============ $e");
                           }
                         }

                          String myOrder = "";

                          if(order.text.trim().isEmpty){
                            setState(() {
                              myOrder = "Order is recorded";
                            });
                          } else {
                            setState(() {
                              myOrder = order.text;
                            });
                          }

                          final id = mongo.ObjectId();

                          var document = {
                            "_id": id,
                            "Order": myOrder,
                            "Location": loc.text,
                            'LAT': lat,
                            'LNG': long,
                            "Mobile no": mobileNo.toString(),
                            "Audio file": audioUrl.toString(),
                            "token" : token

                          };

                          try {

                            userCollection.insertOne(document).whenComplete(() {
                              sendPushMessage( "please check", "New order arrived");
                              savingOrderDetails(id, myOrder, loc.text);
                              order.clear();
                              loc.clear();
                              deleteAudioFile();
                              setState(() {
                                currLoc = false;
                                _timerText = '00:00:00';
                              });
                              dbRef.child(id.toString()).child("status").set(status);
                              showDialog(
                                context: context,
                                builder: (context) {
                                  // Show the AlertDialog
                                  AlertDialog alertDialog = AlertDialog(
                                    content: RichText(
                                      text: const TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Order Placed',
                                            style: TextStyle(
                                              color: Colors.blue, // Color for "Order Placed"
                                              fontWeight: FontWeight.bold, // Bold style for "Order Placed"
                                              fontSize: 18.0, // Font size for "Order Placed"
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                            '- Fresh groceries on their way to your doorstep (:',
                                            style: TextStyle(
                                              color: Colors.green, // Color for the positive message
                                              fontSize: 18.0, // Font size for the positive message
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );

                                  Future.delayed(const Duration(seconds: 3), () {
                                    // Close the AlertDialog after 3 seconds
                                    Navigator.of(context).pop();
                                  });

                                  return alertDialog;
                                },
                              );
                            });
                            // sendPushMessage( "please check", "New order arrived");
                          } catch (e) {
                            if(mounted)  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())),);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your location") , backgroundColor: Colors.red,));
                        }

                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please either record or type your order"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }

                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.green, // Text color
                    elevation: 6, // Button elevation
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded button shape
                    ),
                  ),
                  child: const Text("Order", style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

            ],
          ),
        ),
      ),
    );
  }

  void onBackPress() {
    exit(0);
  }

}

class ErrorScreen extends StatefulWidget{

  const ErrorScreen({super.key});

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {

  bool _isLoading = false;

  void _simulateLoading() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 3)); // Delay for 3 seconds

    setState(() {
      _isLoading = false;
    });

    // Execute the next process here
    // print('Next process is executed');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[200],
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2.0,
                  blurRadius: 5.0,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.signal_wifi_statusbar_connected_no_internet_4_rounded , color: Colors.grey,size: 100,),
                const SizedBox(height: 20.0),
                const Text(
                  'No Internet Connection',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20.0),
                const Text(
                  'Please check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: ()async{
                    _simulateLoading();

                    // Check internet connection again and reload the app
                    var connectivityResult = await Connectivity().checkConnectivity();
                    if (connectivityResult == ConnectivityResult.none) {
                      // Display error message and retry button
                      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No internet connection'), backgroundColor: Colors.red,));
                    } else {
                      // Connect to MongoDB and Firebase
                      await MongoDatabase.connect();
                      await Firebase.initializeApp(
                        options: DefaultFirebaseOptions.currentPlatform,
                      );

                      // Run the main app
                      runApp(const MyApp());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
                const SizedBox(
                  height: 20,
                ),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.green,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
