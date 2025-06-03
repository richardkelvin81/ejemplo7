import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:geolocator/geolocator.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Inicializar alarm manager
  await AndroidAlarmManager.initialize();
  
  runApp(const MyApp());
}

@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Iniciar servicio de ubicación
  await _startLocationService();
  
  runApp(const OverlayPage());
}

@pragma("vm:entry-point")
Future<void> _startLocationService() async {
  // Configuración para Android
  final androidSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 20,
    foregroundNotificationConfig: ForegroundNotificationConfig(
      notificationTitle: "TaxiCorp en movimiento",
      notificationText: "Obteniendo ubicación actual",
      notificationIcon: AndroidResource(name: 'ic_notification'),
    ),
  );
  
  // Verificar permisos
  final hasPermission = await _checkLocationPermission();
  if (!hasPermission) return;
  
  // Obtener posición actual inmediatamente
  await _updateLocation();
  
  // Configurar temporizador para actualizaciones periódicas
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    await _updateLocation();
  });
}

@pragma("vm:entry-point")
Future<bool> _checkLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return false;
  
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return false;
    }
  }
  
  return permission == LocationPermission.whileInUse;
}

@pragma("vm:entry-point")
Future<void> _updateLocation() async {
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    
    await FirebaseDatabase.instance
        .ref("usuarios/richardaparicio")
        .update({
          "latitud": position.latitude,
          "longitud": position.longitude,
          "timestamp": ServerValue.timestamp,
        });
  } catch (e) {
    print('Error updating location: $e');
  }
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
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
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
      height: 120,
      width: 120,
    );
    
    // Programar alarma periódica como respaldo
    await AndroidAlarmManager.periodic(
      const Duration(minutes: 15),
      0,
      _updateLocation,
      exact: true,
      wakeup: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TaxiCorp Driver')),
      body: Center(
        child: ElevatedButton(
          onPressed: _showOverlay,
          child: const Text('Activar Overlay'),
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
  bool _isActive = true;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    // Actualización inmediata
    _updateLocation();
    
    // Configurar temporizador para actualizaciones periódicas
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateLocation();
    });
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      await FirebaseDatabase.instance
          .ref("usuarios/richardaparicio")
          .update({
            "latitud": position.latitude,
            "longitud": position.longitude,
            "timestamp": ServerValue.timestamp,
          });
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  void _toggleService() {
    setState(() {
      _isActive = !_isActive;
      if (_isActive) {
        _startLocationUpdates();
      } else {
        _locationTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _toggleService,
        child: Container(
          width: double.infinity,
          height: double.infinity,
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