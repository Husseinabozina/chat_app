import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:image_picker/image_picker.dart';

class Image_Picker extends StatefulWidget {
  const Image_Picker(this.imagepickfn);
  final void Function(XFile image) imagepickfn;

  @override
  State<Image_Picker> createState() => _Image_PickerState();
}

class _Image_PickerState extends State<Image_Picker> {
  XFile? image;
  void _imagePikcer() async {
    XFile? pickedimage = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 150,
    );
    setState(() {
      image = pickedimage;
    });
    widget.imagepickfn(image!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: image != null ? FileImage(File(image!.path)) : null,
        ),
        ElevatedButton.icon(
          onPressed: _imagePikcer,
          icon: Icon(
            Icons.image,
          ),
          label: Text('Add Image'),
        )
      ],
    );
  }
}
