
import 'package:background_location/background_location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class LocationService {
  LocationService();

DatabaseReference dbRef = FirebaseDatabase.instance.ref("usuarios/richardaparicio");


 Future<bool> startService() async {

     try {
      if (await BackgroundLocation.isServiceRunning()) return false;
      await BackgroundLocation.setAndroidNotification(
                      title: 'TAXICORP El servicio en segundo plano se está ejecutando',
                      message: 'Ubicación en segundo plano en progreso',
                      icon: '@mipmap/ic_launcher',
                    );
      await BackgroundLocation.startLocationService(
                        distanceFilter: 50);
    BackgroundLocation.getLocationUpdates((location) {
                    print('Esta es la ubicación actual ${location.toMap()}');
                     updateLocation (location.latitude!, location.longitude!,location.bearing!);
                      });
    return true;

   } catch (e) {
      debugPrint('Error al inicializar servicio de ubicación: $e');
      return false;
    }
  }
  Future<void> updateLocation(double latitude,double longitude, double bearing) async {
    try {
     
      print('REPORTANDO UBICACION');
      await dbRef.update({
        "latitud": latitude,
        "longitud": longitude,
        "bearing": bearing,
        "timestamp": ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Error al actualizar ubicación: $e');
    }
  
  }

  Future<bool> stopService() async {
     try {
      if (await BackgroundLocation.isServiceRunning()){
         await BackgroundLocation.stopLocationService();
          return true;
      }else{
        return false;
      }
    
     
      } catch (e) {
      debugPrint('Error al parar servicio: $e');
      return false;
    }
    } 

 

}
