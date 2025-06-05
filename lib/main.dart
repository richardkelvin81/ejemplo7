import 'dart:async';

import 'package:ejemplo7/expanded_fab.dart';
import 'package:ejemplo7/expanded_fab2.dart';
import 'package:ejemplo7/location_service.dart';
import 'package:ejemplo7/overlay_page.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
   const  MyApp());
}
// overlay entry point
@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp( const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FuturisticFABApp2()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
   
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
  }
  @override
  void dispose() {


    super.dispose();
  }

  Future<void> showOverlay() async {
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
      height: 300,
      width: 300,
    );
  }

    Future<void> closeOverlay() async {
   
    await FlutterOverlayWindow.closeOverlay();
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TaxiCorp OVELAY')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: (){
                showOverlay();
              },
              child: const Text('Activar Overlay'),
            ),
           const  SizedBox(height: 10,),
            
             ElevatedButton(
              onPressed: (){
                closeOverlay();
              },
              child: const Text('Cerrar Overlay'),
            ),

            const  SizedBox(height: 10,),
             ElevatedButton(
              onPressed: () async {
                  LocationService().startService();
              },
              child: const Text('Start Background location'),
            ),
              const  SizedBox(height: 10,),
             ElevatedButton(
              onPressed: () async {
                
                 LocationService().stopService();
                
              },
              child: const Text('STOP Background location'),
            ),
          ],
        ),
      ),
    );
  }


}
