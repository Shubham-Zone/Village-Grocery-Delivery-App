import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;

class CurrentLoc extends StatefulWidget {
  const CurrentLoc({Key? key}) : super(key: key);

  @override
  State<CurrentLoc> createState() => _CurrentLocState();
}

class _CurrentLocState extends State<CurrentLoc> {

  String? _currentAddress;
  Position? _currentPosition;

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if(mounted)  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;

  }

  Future<void> _getCurrentPosition() async {
    print("Work 1 ===============================");
    try{
      final hasPermission = await _handleLocationPermission();

      if (!hasPermission){
        print("No permission =========================================");
      }
      await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high , forceAndroidLocationManager: true)
          .then((Position position) {
        setState(() => _currentPosition = position);
        _getAddressFromLatLng(_currentPosition!);
      }).catchError((e) {
        debugPrint(e);
      });
      print("Work 2 ===============================");
    }catch(e){
      print("The erro in location access is ==========================$e");
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    print("Work 3 ===============================");
    await placemarkFromCoordinates(
        _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
        '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
    print("Work 4 ===============================");
  }

  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;

  void _getLastKnownPosition() async {
    final position = await _geolocatorPlatform.getLastKnownPosition();
    if (position != null) {

      setState(() {
        _currentPosition = position;
        _getAddressFromLatLng(_currentPosition!);
      });

    } else {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Something went wrong")));

    }
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      // print('User granted provisional permission');
    } else {
      // print('User declined or has not accepted permission');
    }
  }

  void sendPushMessage(String body, String title) async {
    try {
      // Get the FCM registration token.
      String? registrationToken = await fcm.FirebaseMessaging.instance.getToken();
      print("=============Work1");

      // Send the message.
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-type': 'application/json',
          'Authorization': 'AAAA3-WqAQY:APA91bH2MZUiD02HX7D-6CZnDzYj-VP__pNC-QUbsm-jWclMuBJYEyVuAvlNzP1EMBd2k8E9f3kRhyj47bk67WFR3IDSUV8Q2Krra9s3gK3VbkuqmKUaDqEvqFPgbzl7abssedaN_OsX',
        },
        body: jsonEncode(
          <String, dynamic>{
            'priority': 'high',
            'to': 'cY_Y-HpmQBWwdZlZpQOXx4:APA91bEw6zXTV0VlauIcQf5Nt9Qc7kdWD8CG9SXM0yGy_TT8V7F5Z1y8j5V4yPOuvodYIzA-HR-v0W90uCbCCAjA70G-6kJp1jU4IsjqYz7Qx2nDQJ7dvnuEgphxcm6PEhaLCCfHFvsH' , //'/topics/TTAdmin', // Send the message to the TTAdmin topic.
            'data': <String, dynamic>{
              'click-action': 'FLUTTER_NOTIFICATION_CLICK',
              'Status': 'done',
              'body': body,
              'title': title,
            },
            'notification': <String, dynamic>{
              'title': title,
              'body': body,
              'android_channel_id': 'T&T',
            },
          },
        ),
      );
      print("=============Work2");
    } catch (e) {
      print("=========================$e");
      if (kDebugMode) {
        print('Error sending push notification: $e');
      }
    }
  }




  @override
  void initState() {
    requestPermission();
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location Page")),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('LAT: ${_currentPosition?.latitude ?? ""}'),
              Text('LNG: ${_currentPosition?.longitude ?? ""}'),
              Text('ADDRESS: ${_currentAddress ?? ""}'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _getLastKnownPosition,
                child: const Text("Get Current Location"),
              ),
              const SizedBox(
                height: 20,
              ),
              OutlinedButton(
                  onPressed: (){
                    sendPushMessage("body", "title");
                  },
                  child: const Icon(Icons.notifications)
              )
            ],
          ),
        ),
      ),
    );
  }
}
