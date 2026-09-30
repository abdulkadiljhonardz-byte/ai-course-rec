// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> hasInternetConnection() async =>
    html.window.navigator.onLine ?? true;
