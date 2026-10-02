enum FailureKind { unauthorized, validation, conflict, network, unknown }

final class AppFailure implements Exception {
  const AppFailure({required this.kind, this.debugMessage, this.userMessage});

  final FailureKind kind;
  final String? debugMessage;
  // Explicit client-authored copy only; never arbitrary server/debug text.
  final String? userMessage;
}
