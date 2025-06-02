import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:ejemplo7/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:geolocator/geolocator.dart';


const platform = MethodChannel('flutter_overlay_channel');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

   
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const  OverlayPage(),
    
  );
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
    final LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20,
    );
DatabaseReference ref = FirebaseDatabase.instance.ref("usuarios");
 

  @override
  void initState() {
    super.initState();
    _setupOverlayListener();
   iniciarGeolocalizacion();
  }

  void iniciarGeolocalizacion() async {
     final perm = await Geolocator.checkPermission();
     if (perm != LocationPermission.whileInUse) Geolocator.requestPermission();
  }

  void _setupOverlayListener()  {
       final receivePort = ReceivePort();
  IsolateNameServer.registerPortWithName(receivePort.sendPort, 'overlay_channel');

  receivePort.listen((message) async {
    debugPrint('💬 Mensaje desde overlay: $message');
    // Aquí manejas los datos del overlay
    // await platform.invokeMethod('bringToFront');
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mensaje del overlay: $message')),
      );

      if (message=='transmitir'){
        transmitir();
      }
  });
    
  }


  Future<void> _showOverlay() async {
    final hasPermission = await FlutterOverlayWindow.isPermissionGranted();

    if (!hasPermission) {
      await FlutterOverlayWindow.requestPermission();
    }

    if (await FlutterOverlayWindow.isPermissionGranted()) {
      if (await FlutterOverlayWindow.isActive()) {
        return;
      }
       
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "TAXICORP",
        overlayContent: 'Estas activo',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: (MediaQuery.of(context).size.height * 0.6).toInt(),
        width: WindowSize.matchParent,
        startPosition: const OverlayPosition(0, -259),
      );
    } else {
      debugPrint('Permiso DENEGADO: Mostrar sobre otras apps');
    }
  }

  transmitir () async {

     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transmitiendo posicion')),
      );
   Position position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Posicion ${position.latitude},${position.longitude} ')),
      );
   await ref.child('richardaparicio').set({
        "nombre": "Richard Aparicio",
        "tipo": "auto",
        "latitud":position.latitude,
        "longitud":position.longitude,
       
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overlay Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _showOverlay,
              child: const Text('Show Overlay'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await FlutterOverlayWindow.closeOverlay();
              },
              child: const Text('Close Overlay'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                try {
                  debugPrint("Intentando enviar mensaje al overlay");
                  await FlutterOverlayWindow.shareData('Mensaje desde principal');
                } on Error  {
                  debugPrint("Error al enviar mensaje");
                }
              },
              child: const Text('Mensaje al Overlay'),
            ),
             const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
               transmitir();
              },
              child: const Text('Transmitir ubicacion'),
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



  @override
  void initState() {
    super.initState();
    _setupOverlayListener();
    

  }

  @override
  void dispose() {
    // TODO: implement dispose

    super.dispose();
  }

  

  void _setupOverlayListener() {
    FlutterOverlayWindow.overlayListener.listen((event) {
      debugPrint("Evento recibido en overlay: $event");
      // Aquí puedes manejar los eventos recibidos del widget principal
    });
  }

void sendToMain(String message) {
  final port = IsolateNameServer.lookupPortByName('overlay_channel');
  if (port != null) {
    port.send(message);
  } else {
    debugPrint('❌ SendPort no encontrado en el overlay');
  }
}


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GestureDetector(
        onTap: (){
          sendToMain("transmitir");
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(Icons.touch_app, size: 50),
            ),
          ),
        ),
      ),
    );
  }
}
