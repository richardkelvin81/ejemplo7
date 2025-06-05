import 'package:ejemplo7/location_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class FuturisticFABApp extends StatelessWidget {
  const FuturisticFABApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const  FABHomePage();
  }
}

class FABHomePage extends StatefulWidget {
  const FABHomePage({super.key});

  @override
  State<FABHomePage> createState() => _FABHomePageState();
}

class _FABHomePageState extends State<FABHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  bool isOpen = false;
  bool gpsActive = false;

  static const double containerSize = 100;
  static const double fabSize = 30;
  static const double maxButtonRadius = (containerSize - fabSize) / 2;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void toggle() {
    setState(() {
      isOpen = !isOpen;
      if (isOpen) {
        controller.forward();
      } else {
        controller.reverse();
      }
    });
  }

  void encenderGPS() {
    LocationService().startService();
    setState(() => gpsActive = true);
    toggle();
  }

  apagarGPS() async {
   LocationService().stopService();
    setState(() => gpsActive = false);
    toggle();
  }

  Widget buildActionButton({
    required IconData icon,
    required double angleDeg,
    required Color color,
    required VoidCallback onPressed,
    required double addX,
    required double addY,
    required String titulo

  }) {
    final double angleRad = angleDeg * pi / 180;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final double offsetX = cos(angleRad) * controller.value * maxButtonRadius;
        final double offsetY = sin(angleRad) * controller.value * maxButtonRadius;
    
        return Transform.translate(
          
          offset: Offset(offsetX+addX, offsetY+addY),
          child: Opacity(
            opacity: controller.value,
            child: Column(
              children: [
                Container(
                    width: 30,
                     height: 30,
                  child: FloatingActionButton(
                 
                    backgroundColor: color,
                    onPressed: onPressed,
                    elevation: 4,
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: containerSize * 0.2,
                    ),
                  ),
                ),
                 Badge(
                  backgroundColor:color,
                  label: Text(titulo,style: const TextStyle(fontSize: 8,fontWeight: FontWeight.bold),))
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:  Colors.transparent,
           // color: isOpen ? Colors.white.withOpacity(0.3) : Colors.transparent,
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Botones de acción (solo cuando está abierto)
              if (isOpen) ...[
                buildActionButton(
                  titulo: 'SALIR',
                  addX: 0,
                  addY: 45,
                  icon: Icons.close,
                  angleDeg: 90,
                  color: Colors.orange,
                  onPressed: (){
                    FlutterOverlayWindow.closeOverlay();
                  },
                ),
                buildActionButton(
                  titulo: 'ABRIR APP',
                  addX: 0,
                  addY: 10,
                  icon: Icons.app_settings_alt,
                  angleDeg: 270,
                  color: Colors.blue,
                  onPressed: () {
                    print('Abrir APP');
                    toggle();
                  },
                ),
                buildActionButton(
                  titulo: 'APAGAR',
                  addX: -20,
                  addY: 30,
                  icon: Icons.location_off_rounded,
                  angleDeg: 180,
                  color: Colors.red,
                  onPressed: apagarGPS,
                ),
                buildActionButton(
                  titulo: 'ENCENDER',
                  addX: 20,
                  addY: 30,
                  icon: Icons.location_on_outlined,
                  angleDeg: 0,
                  color: Colors.green,
                  onPressed: encenderGPS,
                ),
              ],

              // Botón central (siempre visible)
              isOpen
             ?  Container(
                  width: 30,
                  height: 30,
                  child: FloatingActionButton(
                    backgroundColor: Colors.red,
                    onPressed: toggle,
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: AnimatedIcon(
                      icon: AnimatedIcons.menu_close,
                      progress: controller,
                      color: Colors.white,
                      size: containerSize * 0.2,
                    ),
                  ),
                )

             : GestureDetector(
                onTap: toggle,
                child: Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gpsActive ? Colors.white : Colors.red,
                  ),
                  child: Center(
                    child: gpsActive
                        ? Image.asset('assets/iconoubicacion.gif')
                        : const Icon(
                            Icons.location_off,
                            color: Colors.white,
                            size: containerSize * 0.8,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
    
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}