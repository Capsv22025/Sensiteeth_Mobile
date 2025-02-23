import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/image_picker_viewmodel.dart';
import '../viewmodels/analysis_viewmodel.dart';

class ImagePickerScreen extends StatelessWidget {
  final bool fromCamera;
  final String consultationId;

  const ImagePickerScreen({
    super.key,
    required this.fromCamera,
    required this.consultationId,
  });

  Future<void> _uploadImageAndResult(BuildContext context) async {
    final imagePickerVM =
        Provider.of<ImagePickerViewModel>(context, listen: false);
    final analysisVM = Provider.of<AnalysisViewModel>(context, listen: false);

    if (imagePickerVM.selectedImage == null ||
        analysisVM.analysisResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please analyze an image first')),
      );
      return;
    }

    try {
      print('Attempting to upload image for ConsultationId: $consultationId');
      final fileName =
          'SensiteethImgFiles/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('SensiteethBucket')
          .upload(fileName, imagePickerVM.selectedImage!);

      // Get the full public URL
      final imageUrl = Supabase.instance.client.storage
          .from('SensiteethBucket')
          .getPublicUrl(fileName);

      print('Generated Public URL: $imageUrl'); // Debug log

      final diagnosisData = {
        'ConsultationId': consultationId,
        'InitialDiagnosis': analysisVM.analysisResult,
        'FinalDiagnosis': null,
        'FinalDiagnosisDesc': null,
        'Accuracy': analysisVM.confidenceScore ?? 0.0,
        'Confidence': analysisVM.confidenceScore ?? 0.0,
        'ImageUrl': imageUrl,
      };

      final response = await Supabase.instance.client
          .from('Diagnosis')
          .insert(diagnosisData);

      print('Uploaded diagnosis: $response');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image and result uploaded successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);
    } catch (e) {
      print('Error uploading image and result: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final imagePickerVM = Provider.of<ImagePickerViewModel>(context);
    final analysisVM = Provider.of<AnalysisViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Oral Disease Analysis",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.02),
                Text(
                  "Upload Your Dental Image",
                  style: TextStyle(
                    fontSize: screenHeight * 0.03,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  "Capture or select an image for analysis",
                  style: TextStyle(
                      fontSize: screenHeight * 0.02, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.03),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: imagePickerVM.selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            imagePickerVM.selectedImage!,
                            height: screenHeight * 0.3,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            key: ValueKey(imagePickerVM.selectedImage!.path),
                          ),
                        )
                      : Container(
                          height: screenHeight * 0.3,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.image,
                            size: screenHeight * 0.1,
                            color: Colors.grey,
                          ),
                        ),
                ),
                SizedBox(height: screenHeight * 0.04),
                _buildAnimatedButton(
                  context: context,
                  icon: fromCamera ? Icons.camera_alt : Icons.photo_library,
                  label: fromCamera ? 'Capture Image' : 'Pick Image',
                  onPressed: () async {
                    await imagePickerVM.pickImage(fromCamera: fromCamera);
                  },
                ),
                SizedBox(height: screenHeight * 0.03),
                _buildAnimatedButton(
                  context: context,
                  icon: Icons.analytics,
                  label: 'Analyze Image',
                  onPressed: imagePickerVM.selectedImage == null
                      ? null
                      : () async {
                          await analysisVM.analyzeImage(
                              imagePickerVM.selectedImage!, context);
                        },
                ),
                if (analysisVM.analysisResult != null) ...[
                  SizedBox(height: screenHeight * 0.03),
                  _buildAnimatedButton(
                    context: context,
                    icon: Icons.cloud_upload,
                    label: 'Upload Result',
                    onPressed: () async {
                      await _uploadImageAndResult(context);
                    },
                  ),
                ],
                if (analysisVM.analysisResult != null) ...[
                  SizedBox(height: screenHeight * 0.04),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Analysis Result",
                            style: TextStyle(
                              fontSize: screenHeight * 0.025,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Text(
                            analysisVM.analysisResult!,
                            style: TextStyle(fontSize: screenHeight * 0.02),
                          ),
                          if (analysisVM.confidenceScore != null) ...[
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              "Confidence: ${(analysisVM.confidenceScore! * 100).toStringAsFixed(2)}%",
                              style: TextStyle(
                                  fontSize: screenHeight * 0.02,
                                  color: Colors.green),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: screenWidth * 0.7,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: screenHeight * 0.025),
        label: Text(
          label,
          style: TextStyle(fontSize: screenHeight * 0.02),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.teal,
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.015,
            horizontal: screenWidth * 0.04,
          ),
          minimumSize: Size(screenWidth * 0.7, screenHeight * 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: Colors.teal.withOpacity(0.5),
          disabledBackgroundColor: Colors.grey[400],
        ),
      ),
    );
  }
}
