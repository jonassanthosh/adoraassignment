import 'package:location_tracking/features/location/data/datasources/permission_datasource.dart';
import 'package:location_tracking/features/location/domain/repositories/location_repository.dart';
import 'package:location_tracking/features/location/domain/usecases/get_last_location.dart';
import 'package:location_tracking/features/location/domain/usecases/start_tracking.dart';
import 'package:location_tracking/features/location/domain/usecases/stop_tracking.dart';
import 'package:location_tracking/features/location/domain/usecases/watch_locations.dart';
import 'package:location_tracking/services/background/background_service_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockLocationRepository extends Mock implements LocationRepository {}

class MockPermissionDataSource extends Mock implements PermissionDataSource {}

class MockStartTracking extends Mock implements StartTracking {}

class MockStopTracking extends Mock implements StopTracking {}

class MockWatchLocations extends Mock implements WatchLocations {}

class MockGetLastLocation extends Mock implements GetLastLocation {}

class MockBackgroundServiceController extends Mock
    implements BackgroundServiceController {}
