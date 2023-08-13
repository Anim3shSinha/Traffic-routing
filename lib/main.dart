import 'dart:async';
//import 'dart:math';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:sensors_plus/sensors_plus.dart';
// ignore: depend_on_referenced_packages
//import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:device_info/device_info.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const MaterialApp(home: Position()),
  );
}

class Position extends StatefulWidget {
  const Position({super.key});
  @override
  State<Position> createState() => _PositionState();
}

class _PositionState extends State<Position> {
  /*Various state value */
  double _latitude = 0.0;   //langitude and latitude of the device 
  double _longitude = 0.0;   
  double _accx = 0.0;    //acc in x , y and z direction
  double _accy = 0.0;    
  double _accz = 0.0;
  double _gyx = 0.0;
  double _gyy = 0.0;
  double _gyz = 0.0;
  double _speed = 0.0;
  String _deviceId = "";  //unique device id correspoding to each vehicle 
  bool _isPanick = false;  //state of the device whether in any accident or not 
  double radius = 10000; // Radius in meters within which each hospital will be notified

  final Location _location = Location();
  final _geo = Geoflutterfire();

  late StreamSubscription<LocationData> _locationSubscription;
  //the realtime databse tracking all vehicles on road 
  final _onroad = FirebaseDatabase.instance.ref().child('onroad');

/*Firebase function to send realtime data to the realtime database  */
  void sendLocation(String deviceId, double longitude, double latitude,
      double speed, String type) async {
    final geofirepoint = _geo.point(latitude: latitude, longitude: longitude);
    _onroad.child(deviceId).set({
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'type': type,
      'hash': geofirepoint.hash
    });
  }

  final fstore = FirebaseFirestore.instance.collection('hospitals');

//not implemented for test purpose
/*
  bool panickstatus(
      double ax, double ay, double az, double vx, double vy, double vz) {
    double totalAcc = sqrt(ax * ax + ay * ay + az * az);
    /*More sofisticated algorithm using Kalman Filter can be applied to reduce noise 
    to this for accident detection along with gyroscopic data to detect rollover  */
    return totalAcc >
        50; //if the total acceleration is greater than 50 i.e 5g , panic mode is triggered
  }


/*Stall status is triggered whenever there the car speed and acceleration are low*/
  bool stallstatus(
      double ax, double ay, double az, double vx, double vy, double vz) {
    double totalAcc = sqrt(ax * ax + ay * ay + az * az);
    double totalVelocity = sqrt(vx * vx + vy * vy + vz * vz);
    if (totalVelocity < 1.39 && totalAcc < 1) return true;
    return false;
  }

*/
//Dropdown menu items 
  List<String> list = <String>['Car', 'Truck', 'Medical', 'Motorcycle'];
  String _vehicletype = 'Car';
  void erase(String deviceId) async {
    _onroad.child(deviceId).remove();
  }

  List<Map<String, dynamic>> onRoadVehicles = [];

//function to get the device id and set it as state 
  void getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

      setState(() {
        _deviceId = androidInfo.androidId;
      });
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      setState(() {
        _deviceId = iosInfo.identifierForVendor;
      });
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    getDeviceId();
    //code below was used to add entires to the firestore databse no longer in use 
/*
    final geofirepoint1 =
        _geo.point(latitude: 22.973936212313525, longitude: 88.45203683205422);
    fstore.add({
      'position': geofirepoint1.data,
      'gmail': 'akashparua999@gmail.com',
      'name': 'Kalyani ESI Hospital'
    });

    final geofirepoint2 =
        _geo.point(latitude: 22.979003254703244, longitude: 88.45770142178989);
    fstore.add({
      'position': geofirepoint2.data,
      'gmail': 'akashparua@gmail.com',
      'name': 'Kalyani General Hospital'
    });

    final geofirepoint3 =
        _geo.point(latitude: 22.976632638455538, longitude: 88.45890305142603);
    fstore.add({
      'position': geofirepoint3.data,
      'gmail': 'akashparua999@gmail.com',
      'name': 'Pasupatinath Hospital'
    });
*/
//realtime tracking of location
    _locationSubscription =
        _location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _speed = double.parse(currentLocation.speed!.toStringAsFixed(3));
        _latitude = double.parse(currentLocation.latitude!.toStringAsFixed(5));
        _longitude =
            double.parse(currentLocation.longitude!.toStringAsFixed(5));
        sendLocation(_deviceId, _longitude, _latitude, _speed, _vehicletype);
      });
      sendLocation(_deviceId, _longitude, _latitude, _speed, _vehicletype);
    });

    // [UserAccelerometerEvent (x: 0.0, y: 0.0, z: 0.0)]
    userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      setState(() {
        _accx = double.parse(event.x.toStringAsFixed(3));
        _accy = double.parse(event.x.toStringAsFixed(3));
        _accz = double.parse(event.x.toStringAsFixed(3));
      });
    });

    // [GyroscopeEvent (x: 0.0, y: 0.0, z: 0.0)]
    gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyx = double.parse(event.x.toStringAsFixed(3));
        _gyy = double.parse(event.x.toStringAsFixed(3));
        _gyz = double.parse(event.x.toStringAsFixed(3));
      });
    });
  }
//UI elements 
  final style1 = const TextStyle(
      fontWeight: FontWeight.bold, color: Colors.black, fontSize: 12);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isPanick? Colors.red : Colors.green,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            onPressed: () {
              erase(_deviceId);
              Navigator.pop(context);
            },
          ),
          backgroundColor: Colors.grey,
          title: Text(
            'VANET INTERFACE $_deviceId',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Center(
              child: Text(
                'Location',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(10),
              color: Colors.grey,
              child: Text('Latitude: $_latitude', style: style1),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(10),
              color: Colors.grey,
              child: Text(
                'Longitude: $_longitude',
                style: style1,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(10),
              color: Colors.grey,
              child: Text(
                'Speed: $_speed',
                style: style1,
              ),
            ),
            const Center(
              child: Text(
                'Accelerometer',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(10),
              color: Colors.grey,
              child: Text('Acc. X-axis $_accx', style: style1),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(10),
              color: Colors.grey,
              child: Text('Acc. Y-axis $_accy', style: style1),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(10),
              color: Colors.grey,
              child: Text('Acc. Z-axis $_accz', style: style1),
            ),
            const Center(
              child: Text(
                'Gyroscope',
                style: TextStyle(fontSize: 20, color: Colors.black),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(10),
              color: Colors.grey,
              child: Text('Gyro. X-axis $_gyx', style: style1),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(10),
              color: Colors.grey,
              child: Text('Gyro. Y-axis $_gyy', style: style1),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(10),
              color: Colors.grey,
              child: Text('Gyro. Z-axis $_gyz', style: style1),
            ),
            /////////
            DropdownButton<String>(
              value: _vehicletype,
              icon: const Icon(Icons.arrow_downward),
              elevation: 16,
              style: const TextStyle(
                color: Colors.deepPurple,
              ),
              underline: Container(
                height: 2,
                color: Colors.deepPurpleAccent,
              ),
              onChanged: (String? value) {
                _onroad.child(_deviceId).set({'type': _vehicletype});
                setState(() {
                  _vehicletype = value!;
                });
              },
              items: list.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            TextButton(
              style: ButtonStyle(
                foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.deepPurple),
                   // backgroundColor: _isPanick ? Colors.red : Colors.green 
              ),
              onPressed: () {
                //toggles the values of is_Panick
                setState(() {
                  _isPanick = !_isPanick;
                });
                //send message to nearby hospital
                if (_isPanick == true) {
                  final currentpos =
                      _geo.point(latitude: _latitude, longitude: _longitude);
                  Stream<List<DocumentSnapshot>> stream = _geo
                      .collection(collectionRef: fstore)
                      .within(
                          center: currentpos,
                          radius: radius,
                          field: 'position');

                  stream.listen((List<DocumentSnapshot> documentList) {
                    for (DocumentSnapshot document in documentList) {
                      String email = document['gmail'];
                      //print(email);
                      final Email sendEmail = Email(
                        body:
                            'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude',
                        subject: 'Emergency Send Help',
                        recipients: [email],
                        isHTML: false,
                      );
                      FlutterEmailSender.send(sendEmail);
                    }
                  });
                }
              },
              child: const Text('Panick'),
            )
          ],
        )));
  }

  @override
  void dispose() {
    _locationSubscription.cancel();
    super.dispose();
  }
}
