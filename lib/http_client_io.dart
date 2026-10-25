import 'package:http/http.dart' as http;

/// Native apps authenticate with a bearer token, so a plain client is enough.
http.Client createHttpClient() => http.Client();
