import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerViewModel extends ChangeNotifier {
  File? _selectedImage;
  String? _jawPosition; // "Upper" or "Lower"
  String? _toothType; // e.g., "Central Incisor"

  File? get selectedImage => _selectedImage;
  String? get affectedTooth => _jawPosition != null && _toothType != null
      ? '$_jawPosition $_toothType'
      : null;
  String? get jawPosition => _jawPosition;
  String? get toothType => _toothType;

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

  void setJawPosition(String? position) {
    _jawPosition = position;
    notifyListeners();
  }

  void setToothType(String? tooth) {
    _toothType = tooth;
    notifyListeners();
  }

  void clearImage() {
    _selectedImage = null;
    _jawPosition = null;
    _toothType = null;
    notifyListeners();
  }
}
