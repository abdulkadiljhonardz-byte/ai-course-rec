import 'app_database_contract.dart';
import 'app_database_stub.dart'
    if (dart.library.html) 'app_database_web.dart'
    if (dart.library.io) 'app_database_io.dart' as impl;

export 'app_database_contract.dart';

final AppDatabase appDatabaseInstance = impl.createAppDatabase();
