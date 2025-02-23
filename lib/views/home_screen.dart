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
    if (session == null) {
      print("No session found, returning empty list");
      return [];
    }

    final email = session.user.email;
    print('Fetching Dentist ID for emails: $email');
    final dentistResponse = await Supabase.instance.client
        .from('Dentist')
        .select('id')
        .eq('Email', email!)
        .maybeSingle();
    print('Dentist response: $dentistResponse');
    final dentistId = dentistResponse?['id']?.toString();

    if (dentistId == null) {
      print('No Dentist ID found for $email, returning empty list');
      return [];
    }

    print('Fetching approved consultations for Dentist ID: $dentistId');
    final consultationResponse = await Supabase.instance.client
        .from('Consultation')
        .select('id, AppointmentDate, Status, Patient(FirstName, LastName)')
        .eq('DentistId', dentistId)
        .eq('Status', 'approved'); // Filter to only "approved" consultations
    final consultations = consultationResponse as List<Map<String, dynamic>>;
    print(
        'Fetched ${consultations.length} approved consultations: $consultations');
    return consultations;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dental Health Analysis",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authViewModel =
                  Provider.of<AuthViewModel>(context, listen: false);
              await authViewModel.signOut();
            },
          ),
        ],
      ),
      body: Container(
        width: screenWidth, // Ensure full width
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.02), // 2% of screen height
              Icon(
                Icons.local_hospital,
                size: screenHeight * 0.1, // 10% of screen height
                color: Colors.teal,
              ),
              SizedBox(height: screenHeight * 0.02), // 2% of screen height
              Text(
                "Analyze Your Dental Health",
                style: TextStyle(
                  fontSize: screenHeight * 0.035, // 3.5% of screen height
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.01), // 1% of screen height
              Text(
                "Select an approved consultation to upload or capture an image",
                style: TextStyle(
                  fontSize: screenHeight * 0.02, // 2% of screen height
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.03), // 3% of screen height
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _consultationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading consultations'));
                  }
                  final consultations = snapshot.data ?? [];
                  if (consultations.isEmpty) {
                    return const Center(
                        child: Text('No approved consultations found'));
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            screenWidth * 0.05), // Internal padding for content
                    child: SizedBox(
                      width: double.infinity, // Full width within padding
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedConsultationId,
                          hint: Text(
                            "Select an Approved Consultation",
                            style: TextStyle(
                              color: Colors.teal,
                              fontSize:
                                  screenHeight * 0.02, // 2% of screen height
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal:
                                  screenWidth * 0.04, // 4% of screen width
                              vertical:
                                  screenHeight * 0.015, // 1.5% of screen height
                            ),
                          ),
                          style: TextStyle(
                            fontSize:
                                screenHeight * 0.02, // 2% of screen height
                            color: Colors.black87,
                          ),
                          items: consultations.map((consultation) {
                            return DropdownMenuItem<String>(
                              value: consultation['id'].toString(),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth *
                                        0.02), // 2% of screen width
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "${consultation['Patient']['FirstName']} ${consultation['Patient']['LastName']} - ${DateTime.parse(consultation['AppointmentDate']).toLocal().toString().split(' ')[0]}",
                                        style: TextStyle(
                                          fontSize: screenHeight *
                                              0.018, // 1.8% of screen height
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                        width: screenWidth *
                                            0.02), // 2% of screen width
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth *
                                            0.02, // 2% of screen width
                                        vertical: screenHeight *
                                            0.005, // 0.5% of screen height
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(
                                            0.2), // Always approved
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color:
                                              Colors.green, // Always approved
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'approved', // Fixed to "approved"
                                        style: TextStyle(
                                          color:
                                              Colors.green, // Always approved
                                          fontSize: screenHeight *
                                              0.015, // 1.5% of screen height
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedConsultationId = value;
                            });
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: screenHeight * 0.05), // 5% of screen height
              _buildAnimatedButton(
                context: context,
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
                isDisabled: _selectedConsultationId == null,
              ),
              SizedBox(height: screenHeight * 0.03), // 3% of screen height
              _buildAnimatedButton(
                context: context,
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
                isDisabled: _selectedConsultationId == null,
              ),
            ],
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
    bool isDisabled = false,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: screenWidth * 0.7, // Reduced from 90% to 70%
      child: ElevatedButton.icon(
        icon: Icon(icon, size: screenHeight * 0.025), // Reduced from 3% to 2.5%
        label: Text(
          label,
          style: TextStyle(
              fontSize: screenHeight * 0.02), // Reduced from 2.5% to 2%
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: isDisabled ? Colors.grey : Colors.teal,
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.015, // Reduced from 2% to 1.5%
            horizontal: screenWidth * 0.04, // Reduced from 6% to 4%
          ),
          minimumSize: Size(
              screenWidth * 0.7,
              screenHeight *
                  0.05), // Reduced from 80% width, 6% height to 70% width, 5% height
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: Colors.teal.withOpacity(0.5),
        ),
      ),
    );
  }
}
