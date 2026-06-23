class AurexHttpResponse {
  const AurexHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

class AurexNetworkException implements Exception {
  const AurexNetworkException();
}

Future<AurexHttpResponse> aurexPostJson(
  Uri uri, {
  required Map<String, String> headers,
  required String body,
}) {
  throw const AurexNetworkException();
}

Future<AurexHttpResponse> aurexGet(
  Uri uri, {
  required Map<String, String> headers,
}) {
  throw const AurexNetworkException();
}
