import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:qibla_finder/privacy_policy.dart';
import 'package:qibla_finder/qibla_logic.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _heading = 0;
  double _qiblaDirection = 0;
  String _currentLocation = '';
  String _currentTime = '';
  String _currentDay = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCompass();
    _initQiblaDirection();
    _getCurrentLocation();
    _getCurrentTime();
    _getCurrentDay();
    _startTimeUpdater();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateQiblaDirection(double heading) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      double qiblaDirection = QiblaDirection.getQiblaDirection(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _qiblaDirection = qiblaDirection;
      });
    } catch (e) {
      print('Error getting current position: $e');
    }
  }

  void _startTimeUpdater() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateFormat.jm().format(DateTime.now());
      });
    });
  }

  void _initCompass() {
    FlutterCompass.events?.listen((event) {
      setState(() {
        _heading = event.heading ?? 0;
      });
      _updateQiblaDirection(_heading);
    });
  }

  void _initQiblaDirection() async {
    Position? currentPosition = await QiblaDirection.getCurrentLocation();
    if (currentPosition != null) {
      double qiblaDirection = QiblaDirection.getQiblaDirection(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      setState(() {
        _qiblaDirection = qiblaDirection;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      setState(() {
        _currentLocation =
            '${placemarks.first.locality}, ${placemarks.first.country}';
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  void _getCurrentTime() {
    final String formattedTime =
        DateFormat.jm().format(DateTime.now()); // 12-hour format with AM/PM
    setState(() {
      _currentTime = formattedTime;
    });
  }

  void _getCurrentDay() {
    final String formattedDay = DateFormat('EEEE')
        .format(DateTime.now()); // Full day name (e.g., Monday)
    setState(() {
      _currentDay = formattedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Row(
          children: [
            Image.asset(
              'assets/icon/logos__white.png',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
            const SizedBox(
              width: 2,
            ),
            Text(
              'Qibla Compass',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Container(
            padding: EdgeInsets.all(15),
            child: GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PrivacyPolicyScreen())),
              child: Icon(
                Icons.info,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Qibla background image covering the whole screen
          Image.asset(
            'assets/images/qibla.jpg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Current Location: $_currentLocation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  'Current Time: $_currentTime',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  'Current Day: $_currentDay',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  'Current Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  'Qibla Angle: $_qiblaDirection°', // Display Qibla angle here
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Transform.rotate(
                  angle: -_heading * (math.pi / 180),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        'assets/images/compass.png',
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: -50,
                        child: Transform.rotate(
                          angle: -_qiblaDirection * (math.pi / 180),
                          child: Image.asset(
                            'assets/images/hand2.png',
                            width: 400,
                            height: 400,
                            fit: BoxFit.contain,
                            alignment: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
