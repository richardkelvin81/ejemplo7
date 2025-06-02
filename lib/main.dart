import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TaxiCorp Overlay')),
      body: Center(
        child: ElevatedButton(
          onPressed: _showOverlay,
          child: const Text('Activar Overlay'),
        ),
      ),
    );
  }

  Future<void> _showOverlay() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
    
    if (await FlutterOverlayWindow.isActive()) return;
    
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "TAXICORP",
      overlayContent: 'Modo conductor activo',
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.auto,
      height: 150,
      width: 150,
    );
  }
}

class OverlayPage extends StatefulWidget {
  const OverlayPage({super.key});

  @override
  State<OverlayPage> createState() => _OverlayPageState();
}

class _OverlayPageState extends State<OverlayPage> {
  final LocationSettings _locationSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 20,
    forceLocationManager: true, // Usar el LocationManager más antiguo pero confiable
    intervalDuration: const Duration(seconds: 10),
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationText: "TaxiCorp está obteniendo tu ubicación",
      notificationTitle: "Modo conductor activo",
      enableWakeLock: true,
    ),
  );
  
  late DatabaseReference _dbRef;
  StreamSubscription<Position>? _positionStream;
  bool _isActive = false;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref("usuarios/richardaparicio");
    _initLocationService();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocationService() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    
    setState(() => _isActive = true);
    _startPeriodicUpdates();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    return permission == LocationPermission.whileInUse;
  }

  void _startPeriodicUpdates() {
    // Actualización inmediata al iniciar
    _updateLocation();
    
    // Configurar actualizaciones periódicas
    _updateTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _updateLocation();
    });
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      await _dbRef.update({
        "latitud": position.latitude,
        "longitud": position.longitude,
        "timestamp": ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error al actualizar ubicación: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      home: GestureDetector(
        onTap: () {
          setState(() => _isActive = !_isActive);
          if (_isActive) {
            _startPeriodicUpdates();
          } else {
            _updateTimer?.cancel();
          }
        },
        child: Container(
          width: 120,
          height: 120,
          alignment: Alignment.center,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _isActive ? Colors.green : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(
              _isActive ? Icons.directions_car : Icons.location_off,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}