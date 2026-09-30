import 'package:flutter/material.dart';

class MessageComposer extends StatefulWidget {
  const MessageComposer({
    required this.onSend,
    required this.isSending,
    super.key,
  });

  final Future<bool> Function(String message) onSend;
  final bool isSending;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _messageController = TextEditingController();

  String _enteredMessage = '';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _enteredMessage.trim();

    if (message.isEmpty || widget.isSending) {
      return;
    }

    FocusScope.of(context).unfocus();
    final didSend = await widget.onSend(message);

    if (!mounted || !didSend) {
      return;
    }

    _messageController.clear();
    setState(() {
      _enteredMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (value) {
                setState(() {
                  _enteredMessage = value;
                });
              },
              onSubmitted: (_) => _sendMessage(),
              decoration: const InputDecoration(labelText: 'Send a message...'),
            ),
          ),
          IconButton(
            onPressed: _enteredMessage.trim().isEmpty || widget.isSending
                ? null
                : _sendMessage,
            icon: widget.isSending
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
