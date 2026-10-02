import 'package:flutter/material.dart';

import '../../../core/presentation/chat_ui.dart';
import 'media_scope.dart';

class MediaImage extends StatefulWidget {
  const MediaImage({
    required this.reference,
    this.fit = BoxFit.cover,
    this.fallback,
    super.key,
  });
  final String reference;
  final BoxFit fit;
  final Widget? fallback;
  @override
  State<MediaImage> createState() => _MediaImageState();
}

class _MediaImageState extends State<MediaImage> {
  Future<String>? _url;
  Object? _repository;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = MediaScope.maybeOf(context);
    if (_url == null || _repository != repository) {
      _repository = repository;
      _url = repository?.downloadUrl(widget.reference);
    }
  }

  @override
  void didUpdateWidget(MediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reference != widget.reference) {
      _url = MediaScope.maybeOf(context)?.downloadUrl(widget.reference);
    }
  }

  Widget _failed() =>
      widget.fallback ??
      Center(
        child: TextButton.icon(
          onPressed: () => setState(
            () =>
                _url = MediaScope.maybeOf(context)
                    ?.downloadUrl(widget.reference),
          ),
          icon: const MingleIcon(MingleGlyph.photo),
          label: const Text('Retry image'),
        ),
      );
  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _url,
    builder: (context, snapshot) => snapshot.hasError || _url == null
        ? _failed()
        : !snapshot.hasData
        ? widget.fallback ??
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
        : Image.network(
            snapshot.data!,
            fit: widget.fit,
            errorBuilder: (_, _, _) => _failed(),
          ),
  );
}

class ImageViewerPage extends StatelessWidget {
  const ImageViewerPage({required this.reference, super.key});
  final String reference;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const MingleBackButton(),
      title: const Text('Photo'),
    ),
    body: SafeArea(
      child: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: MediaImage(reference: reference, fit: BoxFit.contain),
        ),
      ),
    ),
  );
}
