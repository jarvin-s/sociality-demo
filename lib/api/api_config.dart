import 'package:flutter/foundation.dart' show kIsWeb;

const String _kProductionApiBase = 'https://sociality-api-latest.onrender.com/';

Uri storiesApiBaseUri() {
  const fromEnv = String.fromEnvironment('STORIES_API_URL');
  if (fromEnv.isNotEmpty) {
    final u = Uri.parse(fromEnv);
    return Uri(
      scheme: u.scheme,
      host: u.host,
      port: u.hasPort ? u.port : null,
      path: '/',
    );
  }
  if (kIsWeb) {
    final host = Uri.base.host;
    if (host.contains('vercel.app')) {
      return Uri(
        scheme: Uri.base.scheme,
        host: Uri.base.host,
        port: Uri.base.hasPort ? Uri.base.port : null,
      );
    }
    return Uri.parse(_kProductionApiBase);
  }
  return Uri.parse(_kProductionApiBase);
}
