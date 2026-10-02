import 'package:flutter/material.dart';

import '../domain/media_repository.dart';

class MediaScope extends InheritedWidget {
  const MediaScope({required this.repository, required super.child, super.key});
  final MediaRepository? repository;
  static MediaRepository? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MediaScope>()?.repository;
  @override
  bool updateShouldNotify(MediaScope oldWidget) =>
      oldWidget.repository != repository;
}
