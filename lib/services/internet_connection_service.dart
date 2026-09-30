export 'internet_connection_service_stub.dart'
    if (dart.library.html) 'internet_connection_service_web.dart'
    if (dart.library.io) 'internet_connection_service_io.dart';
