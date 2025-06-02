import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:geolocator/geolocator.dart';

const platform = MethodChannel('flutter_overlay_channel');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayPage());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool _isOverlayActive = false;
  StreamSubscription<Position>? _locationStream;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("usuarios");
  final ReceivePort _receivePort = ReceivePort();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupOverlayListener();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    WidgetsBinding.instance.removeObserver(this);
    IsolateNameServer.removePortNameMapping('overlay_channel');
    _receivePort.close();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final perm = await Geolocator.checkPermission();
    if (perm != LocationPermission.whileInUse && perm != LocationPermission.always) {
      await Geolocator.requestPermission();
    }
  }

  void _setupOverlayListener() {
    IsolateNameServer.registerPortWithName(_receivePort.sendPort, 'overlay_channel');

    _receivePort.listen((message) async {
      debugPrint('Mensaje desde overlay: $message');
      
      if (message == 'request_location') {
        _sendCurrentLocation();
      } else if (message == 'overlay_closed') {
        setState(() => _isOverlayActive = false);
        _stopLocationUpdates();
      }
    });
  }

  Future<void> _sendCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      
      _dbRef.child('richardaparicio').update({
        'latitud': position.latitude,
        'longitud': position.longitude,
        'ultima_actualizacion': ServerValue.timestamp,
      });
      
      debugPrint('Ubicación enviada: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
    }
  }

  void _startLocationUpdates() {
    _locationStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      ),
    ).listen((position) {
      _dbRef.child('richardaparicio').update({
        'latitud': position.latitude,
        'longitud': position.longitude,
        'ultima_actualizacion': ServerValue.timestamp,
      });
    });
  }

  void _stopLocationUpdates() {
    _locationStream?.cancel();
    _locationStream = null;
  }

  Future<void> _showOverlay() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
      if (!await FlutterOverlayWindow.isPermissionGranted()) return;
    }

    if (await FlutterOverlayWindow.isActive()) return;

    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "TAXICORP",
      overlayContent: 'Estás activo',
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.auto,
      height: 200,
      width: WindowSize.matchParent,
    );

    setState(() => _isOverlayActive = true);
    _startLocationUpdates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TaxiCorp')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _showOverlay,
              child: const Text('Activar Overlay'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await FlutterOverlayWindow.closeOverlay();
                setState(() => _isOverlayActive = false);
                _stopLocationUpdates();
              },
              child: const Text('Cerrar Overlay'),
            ),
          ],
        ),
      ),
    );
  }
}

class OverlayPage extends StatefulWidget {
  const OverlayPage({super.key});

  @override
  State<OverlayPage> createState() => _OverlayPageState();
}

class _OverlayPageState extends State<OverlayPage> {
  Timer? _locationRequestTimer;
  final SendPort? _sendPort = IsolateNameServer.lookupPortByName('overlay_channel');

  @override
  void initState() {
    super.initState();
    
  }

  @override
  void dispose() {
    _locationRequestTimer?.cancel();
    _sendPort?.send('overlay_closed');
    super.dispose();
  }

  void _startRequestingLocation() {
    // Enviar primera solicitud inmediatamente
    _sendPort?.send('request_location');
    
    // Configurar timer para solicitudes periódicas
    _locationRequestTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _sendPort?.send('request_location');
      debugPrint('Solicitando ubicación...');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: (){
            //_sendPort?.send('overlay_tapped')
            _startRequestingLocation();
          },
          child: Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.blue[800],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, size: 50, color: Colors.white),
                  Text(
                    'ACTIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}