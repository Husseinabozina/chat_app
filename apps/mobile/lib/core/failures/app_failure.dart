enum FailureKind {
  unauthorized,
  validation,
  conflict,
  network,
  unknown,
}

final class AppFailure implements Exception {
  const AppFailure({
    required this.kind,
    this.debugMessage,
  });

  final FailureKind kind;
  final String? debugMessage;
}
