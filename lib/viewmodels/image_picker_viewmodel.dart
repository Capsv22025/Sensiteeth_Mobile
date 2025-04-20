import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerViewModel extends ChangeNotifier {
  File? _selectedImage;
  String? _affectedTooth; // Renamed from _toothAffected

  File? get selectedImage => _selectedImage;
  String? get affectedTooth => _affectedTooth; // Renamed getter

  Future<void> pickImage({required bool fromCamera}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      _selectedImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  void setAffectedTooth(String tooth) {
    // Renamed method
    _affectedTooth = tooth;
    notifyListeners();
  }

  void clearImage() {
    _selectedImage = null;
    _affectedTooth = null; // Clear the affected tooth field
    notifyListeners();
  }
}
