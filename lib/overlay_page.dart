import 'package:flutter/material.dart';

class OverlayPage extends StatefulWidget {
  const OverlayPage({super.key});

  @override
  State<OverlayPage> createState() => _OverlayPageState();
}

class _OverlayPageState extends State<OverlayPage> {
  bool menuIsActive = false;
  bool gpsIsActive = false;

  void toggleMenu() {
    setState(() {
      menuIsActive = !menuIsActive;
    });
  }

  void activarGPS() {
    setState(() {
      gpsIsActive = true;
    });
  }

  void desactivarGPS() {
    setState(() {
      gpsIsActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: menuIsActive
            ? Container(
                padding: const EdgeInsets.all(8),
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        toggleMenu();
                        // Aquí puedes abrir tu app principal
                      },
                      child: const Text('Abrir APP'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        activarGPS();
                      },
                      child: const Text('Encender GPS'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        desactivarGPS();
                      },
                      child: const Text('Apagar GPS'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        toggleMenu();
                      },
                      child: const Text('Salir'),
                    ),
                  ],
                ),
              )
            : GestureDetector(
                onTap: toggleMenu,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: gpsIsActive ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                      if (gpsIsActive)
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Center(
                    child: gpsIsActive
                        ? Image.asset('assets/iconoubicacion.gif')
                        : const Icon(
                            Icons.location_off,
                            color: Colors.white,
                            size: 50,
                          ),
                  ),
                ),
              ),
      ),
    );
  }
}
