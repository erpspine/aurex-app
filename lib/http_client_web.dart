import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// Sends the HttpOnly auth cookie with cross-origin API requests.
http.Client createHttpClient() => BrowserClient()..withCredentials = true;
