import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/permission_status.dart';

@lazySingleton
class PermissionDataSource {
  Future<LocationAuth> current() async {
      if(!await Geolocator.isLocationServiceEnabled()) {
        return LocationAuth.serviceDisabled;
      }

      final whileInUse = await Permission.locationWhenInUse.status;
      if (whileInUse.isPermanentlyDenied) { return LocationAuth.deniedForever; }
      if (whileInUse.isDenied) { return LocationAuth.denied;}
      
      final always = await Permission.locationAlways.status;
      if (always.isGranted) { return LocationAuth.always;}

      return LocationAuth.whileInUse;
    }


    Future<LocationAuth> requestWhileInUse() async {
      final result = await Permission.locationWhenInUse.request();
      if (result.isGranted) return current();
      if (result.isPermanentlyDenied) return LocationAuth.deniedForever;

      return LocationAuth.denied;
    }

    Future<LocationAuth> requestAlways() async {
      final result = await Permission.locationAlways.request();
      if (result.isGranted) { return LocationAuth.always; }

      return current();
    }

    Future<bool> openSettings() => openAppSettings();
  }