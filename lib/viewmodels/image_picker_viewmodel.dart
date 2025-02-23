import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerViewModel extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _imageUrl;

  File? get selectedImage => _selectedImage;
  String? get imageUrl => _imageUrl;

  Future<void> pickImage({required bool fromCamera}) async {
    final XFile? image = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );

    if (image != null) {
      _selectedImage = File(image.path);
      notifyListeners(); // ✅ Update UI after image selection
    }
  }
}
