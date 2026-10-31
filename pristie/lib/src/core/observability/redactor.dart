/// Deny-by-default redaction engine enforcing strict allowlist sanitization.
final class Redactor {
  const Redactor._();

  /// Allowlist of permissible metadata keys for logging and diagnostic contexts.
  static const Set<String> allowedLogKeys = {
    'event',
    'operation',
    'method',
    'routeTemplate',
    'statusCode',
    'durationMs',
    'retryCount',
    'correlationId',
    'dataset',
    'syncState',
    'appVersion',
    'buildNumber',
    'os',
    'stage',
  };

  /// Sanitizes [fields] by retaining only allowlisted keys, discarding nested collections, and truncating long strings.
  static Map<String, Object?> redact(Map<String, Object?>? fields) {
    if (fields == null || fields.isEmpty) {
      return const <String, Object?>{};
    }

    final sanitized = <String, Object?>{};
    for (final MapEntry(:key, :value) in fields.entries) {
      if (!allowedLogKeys.contains(key)) {
        continue;
      }
      if (value == null) {
        continue;
      }
      if (value is Map || value is Iterable) {
        continue;
      }
      if (value is String) {
        if (value.length > 200) {
          sanitized[key] = value.substring(0, 200);
        } else {
          sanitized[key] = value;
        }
      } else {
        sanitized[key] = value;
      }
    }

    return Map<String, Object?>.unmodifiable(sanitized);
  }
}
