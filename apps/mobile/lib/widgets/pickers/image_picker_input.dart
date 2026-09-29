import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerInput extends StatefulWidget {
  const ImagePickerInput({required this.onImagePicked, super.key});

  final ValueChanged<XFile> onImagePicked;

  @override
  State<ImagePickerInput> createState() => _ImagePickerInputState();
}

class _ImagePickerInputState extends State<ImagePickerInput> {
  final _picker = ImagePicker();

  XFile? _image;

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1024,
    );

    if (pickedImage == null || !mounted) {
      return;
    }

    setState(() {
      _image = pickedImage;
    });

    widget.onImagePicked(pickedImage);
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;

    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: image == null ? null : FileImage(File(image.path)),
          child: image == null ? const Icon(Icons.person_outline) : null,
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Add image'),
        ),
      ],
    );
  }
}
