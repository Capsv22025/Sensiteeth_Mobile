// ignore_for_file: unnecessary_cast

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../views/image_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _consultationsFuture;
  String? _selectedConsultationId;

  @override
  void initState() {
    super.initState();
    _consultationsFuture = _fetchDentistAndConsultations();
  }

  Future<List<Map<String, dynamic>>> _fetchDentistAndConsultations() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return [];

    final email = session.user.email;
    final dentistResponse = await Supabase.instance.client
        .from('Dentist')
        .select('id')
        .eq('Email', email!)
        .maybeSingle();
    final dentistId = dentistResponse?['id']?.toString();

    if (dentistId == null) return [];

    final consultationResponse = await Supabase.instance.client
        .from('Consultation')
        .select('id, AppointmentDate, Status, Patient(FirstName, LastName)')
        .eq('DentistId', dentistId)
        .eq('Status', 'approved');
    return consultationResponse as List<Map<String, dynamic>>;
  }

  Future<void> _onRefresh() async {
    setState(() {
      _consultationsFuture = _fetchDentistAndConsultations();
    });
    await _consultationsFuture;
  }

  Future<void> _signOut(BuildContext context) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // Show confirmation dialog
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Confirm Logout',
      message: 'Are you sure you want to log out?',
    );

    if (!confirmed || !mounted)
      return; // Exit if user cancels or widget is disposed

    // Show loading dialog and capture its Navigator context
    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx; // Capture the dialog's context
        return Center(
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
        );
      },
    );

    try {
      await authViewModel.signOut();
      // Dismiss the loading dialog using its specific context
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }
      if (mounted) {
        // Navigate to sign-in screen and clear the stack
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/signin', // Replace with your actual sign-in route name
          (route) => false, // Removes all previous routes
        );
      }
    } catch (e) {
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  // Alternative version using LoadingDialog class (commented out)
  /*
  Future<void> _signOut(BuildContext context) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // Show confirmation dialog
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Confirm Logout',
      message: 'Are you sure you want to log out?',
    );

    if (!confirmed || !mounted) return; // Exit if user cancels or widget is disposed

    // Show loading dialog
    LoadingDialog.show(context);

    try {
      await authViewModel.signOut();
      // Ensure dialog is hidden before navigation
      if (mounted) {
        LoadingDialog.hide(context);
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/signin', // Replace with your actual sign-in route name
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        color: Colors.white,
        child: Column(
          children: [
            _buildHeader(size),
            Expanded(child: _buildContent(size)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Dental Health Analysis',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Size size) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Colors.teal.shade700,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
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
                    'Analyze Your Dental Health',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a consultation to proceed',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildDropdown(size),
                  const SizedBox(height: 24),
                  _buildButton(
                    size: size,
                    icon: Icons.photo_library,
                    label: 'Upload from Gallery',
                    onPressed: _selectedConsultationId == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImagePickerScreen(
                                  fromCamera: false,
                                  consultationId: _selectedConsultationId!,
                                ),
                              ),
                            ),
                  ),
                  const SizedBox(height: 16),
                  _buildButton(
                    size: size,
                    icon: Icons.camera_alt,
                    label: 'Capture with Camera',
                    onPressed: _selectedConsultationId == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImagePickerScreen(
                                  fromCamera: true,
                                  consultationId: _selectedConsultationId!,
                                ),
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(Size size) {
    return Container(
      width: size.width * 0.9,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade900.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _consultationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }
          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Error loading consultations',
                  style: TextStyle(color: Colors.grey)),
            );
          }
          final consultations = snapshot.data ?? [];
          if (consultations.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No approved consultations',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return DropdownButtonFormField<String>(
            value: _selectedConsultationId,
            hint: Text('Select Consultation',
                style: TextStyle(color: Colors.teal.shade700)),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            items: consultations.map((consultation) {
              return DropdownMenuItem<String>(
                value: consultation['id'].toString(),
                child: Text(
                  '${consultation['Patient']['FirstName']} ${consultation['Patient']['LastName']} - '
                  '${DateTime.parse(consultation['AppointmentDate']).toLocal().toString().split(' ')[0]}',
                ),
              );
            }).toList(),
            onChanged: (value) =>
                setState(() => _selectedConsultationId = value),
          );
        },
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
        ),
      ),
    );
  }
}

// Reusable Dialogs
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
                onPressed: () =>
                    Navigator.pop(context, false), // Cancel returns false
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, true), // Confirm returns true
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
        false; // Default to false if dismissed without selection
  }
}

// LoadingDialog class (inlined here, can be moved back to separate file if preferred)
class LoadingDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dismissal by tapping outside
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
