import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/image_picker_viewmodel.dart';
import '../viewmodels/analysis_viewmodel.dart';

class ImagePickerScreen extends StatelessWidget {
  final bool fromCamera;
  final String consultationId;
  final String consultationStatus;

  const ImagePickerScreen({
    super.key,
    required this.fromCamera,
    required this.consultationId,
    required this.consultationStatus,
  });

  Future<void> _uploadImageAndResult(BuildContext context) async {
    final imagePickerVM =
        Provider.of<ImagePickerViewModel>(context, listen: false);
    final analysisVM = Provider.of<AnalysisViewModel>(context, listen: false);

    if (imagePickerVM.selectedImage == null ||
        analysisVM.analysisResult == null ||
        imagePickerVM.jawPosition == null ||
        imagePickerVM.toothType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please analyze an image and specify the jaw position and tooth type')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Confirm Upload',
      message: 'Are you sure you want to upload this analysis result?',
    );

    if (!confirmed) return;

    // Show loading dialog
    LoadingDialog.show(context);

    try {
      print('Attempting to upload image for ConsultationId: $consultationId');
      final fileName =
          'SensiteethImgFiles/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await Supabase.instance.client.storage
          .from('SensiteethBucket')
          .upload(fileName, imagePickerVM.selectedImage!);

      final imageUrl = Supabase.instance.client.storage
          .from('SensiteethBucket')
          .getPublicUrl(fileName);

      print('Generated Public URL: $imageUrl');

      final diagnosisData = {
        'ConsultationId': consultationId,
        'InitialDiagnosis': analysisVM.analysisResult,
        'FinalDiagnosis': null,
        'FinalDiagnosisDesc': null,
        'Accuracy': analysisVM.confidenceScore ?? 0.0,
        'Confidence': analysisVM.confidenceScore ?? 0.0,
        'ImageUrl': imageUrl,
        'JawPosition': imagePickerVM.jawPosition, // New column
        'ToothType': imagePickerVM.toothType, // New column
      };

      if (consultationStatus.toLowerCase() == 'follow-up') {
        final diagnosisResponse = await Supabase.instance.client
            .from('Diagnosis')
            .insert(diagnosisData);

        print('Created new diagnosis for follow-up: $diagnosisResponse');
      } else {
        final existingDiagnosis = await Supabase.instance.client
            .from('Diagnosis')
            .select()
            .eq('ConsultationId', consultationId)
            .maybeSingle();

        if (existingDiagnosis != null) {
          final diagnosisResponse =
              await Supabase.instance.client.from('Diagnosis').update({
            'InitialDiagnosis': analysisVM.analysisResult,
            'Accuracy': analysisVM.confidenceScore ?? 0.0,
            'Confidence': analysisVM.confidenceScore ?? 0.0,
            'ImageUrl': imageUrl,
            'JawPosition': imagePickerVM.jawPosition, // Update new column
            'ToothType': imagePickerVM.toothType, // Update new column
          }).eq('id', existingDiagnosis['id']);

          print('Updated existing diagnosis: $diagnosisResponse');
        } else {
          final diagnosisResponse = await Supabase.instance.client
              .from('Diagnosis')
              .insert(diagnosisData);

          print('Created new diagnosis: $diagnosisResponse');
        }

        final consultationResponse = await Supabase.instance.client
            .from('Consultation')
            .update({'Status': 'partially complete'}).eq('id', consultationId);

        print(
            'Updated Consultation status to partially complete: $consultationResponse');
      }

      imagePickerVM.clearImage();
      analysisVM.clearResult();

      LoadingDialog.hide(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image and result uploaded successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      print('Error uploading image and result: $e');
      LoadingDialog.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading: $e')),
      );
    }
  }

  void _showAnalysisModal(
      BuildContext context, Size size, AnalysisViewModel analysisVM) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Analysis Result',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                analysisVM.analysisResult!,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              if (analysisVM.confidenceScore != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Confidence: ${(analysisVM.confidenceScore! * 100).toStringAsFixed(2)}%',
                  style: const TextStyle(fontSize: 16, color: Colors.green),
                ),
              ],
              const SizedBox(height: 24),
              _buildButton(
                size: size,
                icon: Icons.cloud_upload,
                label: 'Upload Result',
                onPressed: () async => await _uploadImageAndResult(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imagePickerVM = Provider.of<ImagePickerViewModel>(context);
    final analysisVM = Provider.of<AnalysisViewModel>(context);

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        color: Colors.white,
        child: Column(
          children: [
            _buildHeader(context, size),
            Expanded(
                child: _buildContent(context, size, imagePickerVM, analysisVM)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Size size) {
    return Container(
      width: size.width,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.teal.shade800,
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade900.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Text(
        'Oral Disease Analysis',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Size size,
    ImagePickerViewModel imagePickerVM,
    AnalysisViewModel analysisVM,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: size.height - (MediaQuery.of(context).padding.top + 48),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Icon(Icons.local_hospital,
                    size: 64, color: Colors.teal.shade800),
                const SizedBox(height: 16),
                const Text(
                  'Upload Your Dental Image',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Capture or select an image for analysis',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: imagePickerVM.selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            imagePickerVM.selectedImage!,
                            height: size.height * 0.3,
                            width: size.width * 0.9,
                            fit: BoxFit.cover,
                            key: ValueKey(imagePickerVM.selectedImage!.path),
                          ),
                        )
                      : Container(
                          height: size.height * 0.3,
                          width: size.width * 0.9,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.image,
                              size: 64, color: Colors.grey.shade600),
                        ),
                ),
                const SizedBox(height: 16),
                if (imagePickerVM.selectedImage != null) ...[
                  SizedBox(
                    width: size.width * 0.9,
                    child: DropdownButtonFormField<String>(
                      value: imagePickerVM.jawPosition,
                      hint: Text(
                        'Select Jaw Position',
                        style: TextStyle(color: Colors.teal.shade800),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Jaw Position',
                        labelStyle: TextStyle(color: Colors.teal.shade800),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.teal.shade800),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.teal.shade800, width: 2),
                        ),
                      ),
                      items: ['Upper', 'Lower'].map((position) {
                        return DropdownMenuItem<String>(
                          value: position,
                          child: Text(position),
                        );
                      }).toList(),
                      onChanged: (value) {
                        imagePickerVM.setJawPosition(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: size.width * 0.9,
                    child: DropdownButtonFormField<String>(
                      value: imagePickerVM.toothType,
                      hint: Text(
                        'Select Tooth Type',
                        style: TextStyle(color: Colors.teal.shade800),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Tooth Type',
                        labelStyle: TextStyle(color: Colors.teal.shade800),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.teal.shade800),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.teal.shade800, width: 2),
                        ),
                      ),
                      items: [
                        'Central Incisor',
                        'Lateral Incisor',
                        'Canine/Cuspid',
                        'First Premolar',
                        'Second Premolar',
                        'First Molar',
                        'Second Molar',
                        'Wisdom Tooth/Third Molar',
                      ].map((tooth) {
                        return DropdownMenuItem<String>(
                          value: tooth,
                          child: Text(tooth),
                        );
                      }).toList(),
                      onChanged: (value) {
                        imagePickerVM.setToothType(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
                _buildButton(
                  size: size,
                  icon: fromCamera ? Icons.camera_alt : Icons.photo_library,
                  label: fromCamera ? 'Capture Image' : 'Pick Image',
                  onPressed: () async =>
                      await imagePickerVM.pickImage(fromCamera: fromCamera),
                ),
                const SizedBox(height: 16),
                _buildButton(
                  size: size,
                  icon: Icons.analytics,
                  label: 'Analyze Image',
                  onPressed: imagePickerVM.selectedImage == null ||
                          imagePickerVM.jawPosition == null ||
                          imagePickerVM.toothType == null
                      ? null
                      : () async {
                          await analysisVM.analyzeImage(
                              imagePickerVM.selectedImage!, context);
                          if (analysisVM.analysisResult != null) {
                            _showAnalysisModal(context, size, analysisVM);
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required Size size,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size.width * 0.9,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              onPressed == null ? Colors.grey.shade600 : Colors.teal.shade800,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
          shadowColor: Colors.teal.shade900.withOpacity(0.4),
          disabledBackgroundColor: Colors.grey.shade600,
        ),
      ),
    );
  }
}

class LoadingDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.shade900.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.pop(context);
  }
}

class ConfirmationDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white,
            title: Text(
              title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal),
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade800,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Confirm',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
