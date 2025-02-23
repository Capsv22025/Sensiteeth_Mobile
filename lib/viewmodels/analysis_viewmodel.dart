import 'dart:io';
import 'package:flutter/material.dart';
import '../services/tflite_service.dart';

class AnalysisViewModel extends ChangeNotifier {
  final TFLiteService _tfliteService = TFLiteService();

  String? _analysisResult;
  double? _confidenceScore;

  String? get analysisResult => _analysisResult;
  double? get confidenceScore => _confidenceScore;

  final List<String> _classLabels = [
    "Calculus",
    "Caries",
    "Gingivitis",
    "Hypodontia",
    "Discoloration",
    "Ulcers"
  ];

  AnalysisViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _tfliteService.loadModel();
  }

  Future<void> analyzeImage(File image, BuildContext context) async {
    try {
      Map<String, dynamic> result = await _tfliteService.analyzeImage(image);

      int predictedClass = result["classIndex"];
      _confidenceScore = result["confidence"];

      _analysisResult = (predictedClass >= 0 &&
              predictedClass < _classLabels.length)
          ? "${_classLabels[predictedClass]} (${(_confidenceScore! * 100).toStringAsFixed(2)}%)"
          : "Unknown";

      notifyListeners();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Analysis complete: $_analysisResult")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Analysis failed. Please try again.")),
      );
    }
  }
}
