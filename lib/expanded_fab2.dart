import 'package:ejemplo7/location_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class FuturisticFABApp2 extends StatelessWidget {
  const FuturisticFABApp2({super.key});

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
             

              isOpen
             ?  GestureDetector(
              onTap: (){
                if (gpsActive){
                  apagarGPS();
                }else{
                  encenderGPS();
                }
              },
               child: Column(
                 children: [
                   Container(
                        width: 40,
                        height: 40,
                        child: 
                        gpsActive
                        ?FloatingActionButton(
                          backgroundColor: Color.fromARGB(255, 252, 57, 8),
                          onPressed: (){
                             if (gpsActive){
                              apagarGPS();
                            }else{
                              encenderGPS();
                            }
                          },
                          elevation: 4,
                          shape: const CircleBorder(),
                          child: AnimatedIcon(
                            icon: AnimatedIcons.menu_close,
                            progress: controller,
                            color: const Color.fromARGB(255, 255, 255, 255),
                            size: containerSize * 0.2,
                          ),
                        )
                        :FloatingActionButton(
                          backgroundColor: Color.fromARGB(255, 72, 248, 2),
                          onPressed: (){
                             if (gpsActive){
                              apagarGPS();
                            }else{
                              encenderGPS();
                            }
                          },
                          elevation: 4,
                          shape: const CircleBorder(),
                          child: AnimatedIcon(
                            icon: AnimatedIcons.pause_play,
                            progress: controller,
                            color: Colors.black,
                            size: containerSize * 0.2,
                          ),
                        ),
                      ),
                  const SizedBox(height: 2,),
                  Badge(
                    backgroundColor:Color.fromARGB(31, 34, 240, 7),
                    label: Text(
                      gpsActive
                      ?'APAGAR'
                      :'ENCENDER',style: const TextStyle(fontSize: 10,fontWeight: FontWeight.bold),))
                 ],
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