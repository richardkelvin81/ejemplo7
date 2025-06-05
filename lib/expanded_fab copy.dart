import 'package:flutter/material.dart';
import 'dart:math';

class FuturisticFABApp extends StatelessWidget {
  const FuturisticFABApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FABHomePage(),
    );
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
  // Aumentamos el radio para que los botones queden fuera del círculo
  static const double maxButtonRadius = (containerSize / 2) + (fabSize / 2);

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
    setState(() => gpsActive = true);
    toggle();
  }

  void apagarGPS() {
    setState(() => gpsActive = false);
    toggle();
  }

  Widget buildActionButton({
    required IconData icon,
    required double angleDeg,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final double angleRad = angleDeg * pi / 180;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final double offsetX = cos(angleRad) * controller.value * maxButtonRadius;
        final double offsetY = sin(angleRad) * controller.value * maxButtonRadius;

        return Positioned(
          // Centramos la posición teniendo en cuenta el nuevo radio
          left: (containerSize / 2) - (fabSize / 2) + offsetX,
          top: (containerSize / 2) - (fabSize / 2) + offsetY,
          child: Opacity(
            opacity: controller.value,
            child: FloatingActionButton(
              backgroundColor: color,
              onPressed: onPressed,
              elevation: 6, // Aumentamos la elevación para mejor visibilidad
              child: Icon(
                icon,
                color: Colors.white,
                size: fabSize * 0.7,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: containerSize * 1.8, // Aumentamos el espacio contenedor
          height: containerSize * 1.8,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none, // Permitimos que los botones salgan del área
            children: [
              // Fondo del círculo central
              Positioned(
                child: Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOpen ? Colors.white.withOpacity(0.3) : Colors.transparent,
                  ),
                ),
              ),

              // Botones de acción (solo cuando está abierto)
              if (isOpen) ...[
                buildActionButton(
                  icon: Icons.close,
                  angleDeg: 90,
                  color: Colors.orange,
                  onPressed: toggle,
                ),
                buildActionButton(
                  icon: Icons.app_settings_alt,
                  angleDeg: 270,
                  color: Colors.blue,
                  onPressed: () {
                    print('Abrir APP');
                    toggle();
                  },
                ),
                buildActionButton(
                  icon: Icons.location_off_rounded,
                  angleDeg: 180,
                  color: Colors.red,
                  onPressed: apagarGPS,
                ),
                buildActionButton(
                  icon: Icons.location_on_outlined,
                  angleDeg: 0,
                  color: Colors.green,
                  onPressed: encenderGPS,
                ),
              ],

              // Botón central (siempre visible)
              Positioned(
                child: GestureDetector(
                  onTap: toggle,
                  child: Container(
                    width: isOpen ? fabSize : containerSize,
                    height: isOpen ? fabSize : containerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gpsActive ? Colors.transparent : Colors.red,
                    ),
                    child: Center(
                      child: gpsActive
                          ? Image.asset('assets/iconoubicacion.gif')
                          : Icon(
                              Icons.location_off,
                              color: Colors.white,
                              size: isOpen ? fabSize * 0.8 : containerSize * 0.5,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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