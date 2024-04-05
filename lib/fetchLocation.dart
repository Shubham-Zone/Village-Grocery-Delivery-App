import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as l;

class LocationWidget extends StatefulWidget {
  const LocationWidget({Key? key}) : super(key: key);

  @override
  _LocationWidgetState createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget> {
  Position? position;
  String? _currentAddress = "";
  String? _lastKnownAddress = "";
  String? addUsingLocation = "";
  l.Location location = new l.Location();
  double long = 0.0;
  double lat = 0.0;


  fetchPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    l.LocationData _locationData;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    Position currentposition = await Geolocator.getCurrentPosition();
    setState(() {
      position = currentposition;
    });

    _getAddressFromLatLng(position!);

    //Getting location using location package
    _locationData = await location.getLocation();
    setState(() {
      long = _locationData.longitude!;
      lat = _locationData.latitude!;
    });


  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
        position.latitude, position.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
        '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  // Future<void> checkAndRequestPermissions() async {
  //   final permissions = [
  //     Permission.storage,
  //     Permission.notification,
  //   ];
  //
  //   Map<Permission, PermissionStatus> statuses = await permissions.request();
  //   // Geolocator.requestPermission();
  //
  //   statuses.forEach((permission, status) {
  //     if (status.isDenied) {
  //       // Permission is denied, handle it as needed
  //       handlePermissionDenied(permission);
  //     }
  //   });
  // }
  //
  // void handlePermissionDenied(Permission permission) {
  //   // You can customize the behavior for each denied permission here
  //   if (permission == Permission.storage) {
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Storage permission is denied")));
  //   } else if (permission == Permission.microphone) {
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("microphone permission is denied")));
  //   } else if (permission == Permission.notification) {
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification permission is denied")));
  //   }
  //
  // }
  //
  // void test() async {
  //   final plugin = DeviceInfoPlugin();
  //   final android = await plugin.androidInfo;
  //
  //   final storageStatus = android.version.sdkInt < 33
  //       ? await Permission.storage.request()
  //       : PermissionStatus.granted;
  //
  //   if (storageStatus == PermissionStatus.granted) {
  //     print("granted");
  //   }
  //   if (storageStatus == PermissionStatus.denied) {
  //     print("denied");
  //   }
  //   if (storageStatus == PermissionStatus.permanentlyDenied) {
  //     openAppSettings();
  //   }
  // }

  @override
  void initState() {
    // checkAndRequestPermissions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location')),
      body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center,crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(position == null ? 'Location' : position.toString()),
            const SizedBox(
              height: 20,
            ),
            Text("Current address is : $_currentAddress"),
            ElevatedButton(
                onPressed: () => fetchPosition(), child: const Text('Find Location')),
            const SizedBox(
              height: 20,
            ),
            Text("Last know address is : $_lastKnownAddress"),
            ElevatedButton(
                onPressed: () async {
                  try{

                    Position? position = await Geolocator.getLastKnownPosition();
                    await placemarkFromCoordinates(
                        position!.latitude, position!.longitude)
                        .then((List<Placemark> placemarks) {
                      Placemark place = placemarks[0];
                      setState(() {
                        _lastKnownAddress =
                        '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
                      });
                    }).catchError((e) {
                      debugPrint(e);
                    });

                  }
                  catch(e){

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("The error while requesting storage permission is : $e")));

                  }
                },
                child: const Icon(Icons.storage)
            ),
            const SizedBox(
              height: 20,
            ),
            const Text("Location using location package"),
            const SizedBox(
              height: 10,
            ),
            Text("Longitude : $long , Latitude : $lat"),
            Text("Address : $addUsingLocation"),
            ElevatedButton(
                onPressed: () async {

                  await placemarkFromCoordinates(lat!, long!)
                      .then((List<Placemark> placemarks) {
                    Placemark place = placemarks[0];
                    setState(() {
                      addUsingLocation =
                      '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
                    });
                  }).catchError((e) {
                    debugPrint(e);
                  });


                }, child:const Icon(Icons.location_on)
            )

          ])),
    );
  }
}