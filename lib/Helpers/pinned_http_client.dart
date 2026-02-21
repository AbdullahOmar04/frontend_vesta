import 'package:http/http.dart' as http;

http.Client? _client;

http.Client getPinnedHttpClient() {
  _client ??= http.Client();
  return _client!;
}
