import 'package:flutter/material.dart';

import '../../../core/presentation/chat_ui.dart';
import '../domain/media_repository.dart';
import 'media_scope.dart';

/// Keeps chosen bytes/ready media during retries; no duplicate message IDs.
class PhotoDraftSheet extends StatefulWidget {
  const PhotoDraftSheet({
    required this.purpose,
    required this.onUploaded,
    this.conversationId,
    super.key,
  });
  final String purpose;
  final String? conversationId;
  final Future<void> Function(String mediaId, String caption) onUploaded;
  @override
  State<PhotoDraftSheet> createState() => _PhotoDraftSheetState();
}

class _PhotoDraftSheetState extends State<PhotoDraftSheet> {
  final _caption = TextEditingController();
  SelectedPhoto? _photo;
  String? _mediaId;
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick(PhotoSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final photo = await MediaScope.maybeOf(context)!.pickPhoto(source);
      if (mounted && photo != null) {
        setState(() {
          _photo = photo;
          _mediaId = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    if (_busy || _photo == null) return;
    if (_caption.text.trim().runes.length > 4000) {
      setState(() => _error = 'Use at most 4,000 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _mediaId ??= await MediaScope.maybeOf(context)!.uploadPhoto(
        _photo!,
        purpose: widget.purpose,
        conversationId: widget.conversationId,
      );
      if (!mounted) return;
      await widget.onUploaded(_mediaId!, _caption.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.purpose == 'avatar'
                          ? 'Profile photo'
                          : 'Send a photo',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const MingleIcon(MingleGlyph.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 220,
                    child: Image.memory(
                      _photo!.bytes,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Text('Could not preview this image.'),
                    ),
                  ),
                ),
              Wrap(
                spacing: 12,
                children: [
                  TextButton.icon(
                    onPressed: _busy ? null : () => _pick(PhotoSource.gallery),
                    icon: const MingleIcon(MingleGlyph.photo),
                    label: const Text('Photos'),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : () => _pick(PhotoSource.camera),
                    icon: const MingleIcon(MingleGlyph.camera),
                    label: const Text('Camera'),
                  ),
                ],
              ),
              if (widget.purpose == 'message' && _photo != null)
                TextField(
                  controller: _caption,
                  enabled: !_busy,
                  maxLength: 4000,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Caption (optional)',
                  ),
                ),
              if (_error != null)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(
                    semanticsLabel: 'Preparing photo',
                  ),
                ),
              FilledButton(
                onPressed: _busy || _photo == null ? null : _send,
                child: Text(
                  _busy
                      ? 'Please wait…'
                      : widget.purpose == 'avatar'
                      ? 'Use photo'
                      : 'Send photo',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
