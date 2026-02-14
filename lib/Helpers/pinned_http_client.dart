import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// SHA-256 hashes of the full DER-encoded certificates for
/// backend-vesta.onrender.com.
/// Includes both the leaf and intermediate CA for resilience
/// when the leaf certificate rotates.
const List<String> _trustedPins = [
  'mEmL9fj0buZspEjR2iKMS79d3Zjmf1xXS3U+71GvNcE=', // Leaf cert
  'HfwWBfutNY2LyET3bRUgP6ycpcGnn9SFf/ryhk++v5Y=', // Intermediate CA
];

/// The backend host that SSL pinning applies to.
const String _pinnedHost = 'backend-vesta.onrender.com';

/// Singleton pinned client instance.
http.Client? _pinnedClient;

/// Returns a singleton [http.Client] with SSL certificate pinning enabled.
///
/// Uses [SecurityContext] with no trusted roots so that every certificate
/// goes through [badCertificateCallback], where we verify the pin.
/// Only connections to [_pinnedHost] are expected.
http.Client getPinnedHttpClient() {
  _pinnedClient ??= _createPinnedHttpClient();
  return _pinnedClient!;
}

http.Client _createPinnedHttpClient() {
  final context = SecurityContext(withTrustedRoots: false);
  final httpClient = HttpClient(context: context)
    ..badCertificateCallback = (X509Certificate cert, String host, int port) {
      if (host != _pinnedHost) return false;
      return _verifyCertificatePin(cert);
    };

  return IOClient(httpClient);
}

/// Verifies the certificate's SHA-256 hash against trusted pins.
bool _verifyCertificatePin(X509Certificate certificate) {
  final derBytes = certificate.der;
  final hash = sha256.convert(derBytes);
  final base64Hash = base64.encode(hash.bytes);

  return _trustedPins.contains(base64Hash);
}
