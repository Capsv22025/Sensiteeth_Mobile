import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter =
        await Interpreter.fromAsset('assets/oral_disease_model.tflite');
  }

  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    img.Image image = img.decodeImage(await imageFile.readAsBytes())!;
    img.Image resizedImage = img.copyResize(image, width: 128, height: 128);

    List<List<List<List<double>>>> input = _imageToFloat32(resizedImage);
    var output =
        List.filled(1 * 6, 0.0).reshape([1, 6]); // Assuming 6 output classes

    _interpreter.run(input, output);

    List<double> probabilities = output[0]; // Extract confidence scores
    int predictedClass = _argMax(probabilities);
    double confidence =
        probabilities[predictedClass]; // Get highest confidence score

    return {"classIndex": predictedClass, "confidence": confidence};
  }

  List<List<List<List<double>>>> _imageToFloat32(img.Image image) {
    return [
      List.generate(128, (y) {
        return List.generate(128, (x) {
          img.Pixel pixel = image.getPixel(x, y);
          return [
            pixel.r.toDouble() / 255.0,
            pixel.g.toDouble() / 255.0,
            pixel.b.toDouble() / 255.0,
            pixel.a.toDouble() / 255.0,
          ];
        });
      })
    ];
  }

  int _argMax(List<double> array) {
    return array
        .indexWhere((val) => val == array.reduce((a, b) => a > b ? a : b));
  }
}
