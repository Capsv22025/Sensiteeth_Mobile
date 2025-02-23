import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String imageUrl; // ✅ Image URL from Firebase Storage
  final String result; // ✅ Analysis result (Healthy/Unhealthy)

  const ResultScreen({super.key, required this.imageUrl, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analysis Result")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(imageUrl, height: 250), // ✅ Show uploaded image
            const SizedBox(height: 20),
            Text(
              "Diagnosis: $result",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context), // ✅ Back to home screen
              child: const Text("Go Back"),
            ),
          ],
        ),
      ),
    );
  }
}
