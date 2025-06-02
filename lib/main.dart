import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
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
  
  Firebase.initializeApp().then((_) {
    runApp(const OverlayPage());
  });
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupOverlayListener();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isOverlayActive) {
      FlutterOverlayWindow.shareData('resume_app');
    }
  }

  Future<void> _checkLocationPermission() async {
    final perm = await Geolocator.checkPermission();
    if (perm != LocationPermission.whileInUse && perm != LocationPermission.always) {
      await Geolocator.requestPermission();
    }
  }

  void _setupOverlayListener() {
    final receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(receivePort.sendPort, 'overlay_channel');

    receivePort.listen((message) async {
      debugPrint('Mensaje desde overlay: $message');
      if (message == 'overlay_closed') {
        setState(() => _isOverlayActive = false);
      }
      await platform.invokeMethod('bringToFront');
    });
  }

  Future<void> _showOverlay() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
      if (!await FlutterOverlayWindow.isPermissionGranted()) {
        debugPrint('Permiso denegado para mostrar overlay');
        return;
      }
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

class _OverlayPageState extends State<OverlayPage> with WidgetsBindingObserver {
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("usuarios");
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 10,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupOverlayListener();
    
  }

  @override
  void dispose() {
    _stopLocationService();
    WidgetsBinding.instance.removeObserver(this);
    IsolateNameServer.removePortNameMapping('overlay_channel');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startLocationService();
    }
  }

  void _setupOverlayListener() {
    FlutterOverlayWindow.overlayListener.listen((event) {
      debugPrint("Evento recibido: $event");
      if (event == 'resume_app') {
        _startLocationService();
      }
    });

    final sendPort = IsolateNameServer.lookupPortByName('overlay_channel');
    if (sendPort != null) {
      sendPort.send('overlay_ready');
    }
  }

  Future<void> _startLocationService() async {
    if (_isTracking) return;

    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      debugPrint('Permisos de ubicación no concedidos');
      return;
    }

    // Configurar servicio en primer plano para Android
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _configureAndroidForegroundService();
    }

    setState(() => _isTracking = true);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen(
      (Position? position) {
        if (position != null) {
          _updateLocation(position);
        }
      },
      onError: (e) {
        debugPrint('Error en geolocalización: $e');
        _stopLocationService();
      },
    );
  }

  Future<void> _configureAndroidForegroundService() async {
    try {
      await platform.invokeMethod('configureForegroundService');
    } on PlatformException catch (e) {
      debugPrint('Error configurando servicio en primer plano: ${e.message}');
    }
  }

  void _stopLocationService() {
    _positionStream?.cancel();
    _positionStream = null;
    setState(() => _isTracking = false);
    debugPrint('Servicio de ubicación detenido');
  }

  void _updateLocation(Position position) {
    _dbRef.child('richardaparicio').update({
      'latitud': position.latitude,
      'longitud': position.longitude,
      'ultima_actualizacion': ServerValue.timestamp,
    }).catchError((e) {
      debugPrint('Error al actualizar ubicación: $e');
    });
  }

  void _sendToMain(String message) {
    final port = IsolateNameServer.lookupPortByName('overlay_channel');
    port?.send(message);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          onTap: (){
            _startLocationService();
          },
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _isTracking ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isTracking ? Icons.location_on : Icons.location_off,
                    size: 40,
                    color: Colors.white,
                  ),
                  Text(
                    _isTracking ? 'ACTIVO' : 'INACTIVO',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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