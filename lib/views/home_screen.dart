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
    print('Fetching Dentist ID for email: $email');
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

  // Refresh handler for swipe-to-refresh
  Future<void> _onRefresh() async {
    setState(() {
      _consultationsFuture = _fetchDentistAndConsultations();
    });
    await _consultationsFuture; // Wait for refresh to complete
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
        width: screenWidth,
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
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: Colors.teal, // Teal refresh indicator
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(), // Ensure scrollable even when content fits
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
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                      child: SizedBox(
                        width: double.infinity,
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
                                fontSize: screenHeight * 0.02,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.015,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: screenHeight * 0.02,
                              color: Colors.black87,
                            ),
                            items: consultations.map((consultation) {
                              return DropdownMenuItem<String>(
                                value: consultation['id'].toString(),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.02),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          "${consultation['Patient']['FirstName']} ${consultation['Patient']['LastName']} - ${DateTime.parse(consultation['AppointmentDate']).toLocal().toString().split(' ')[0]}",
                                          style: TextStyle(
                                            fontSize: screenHeight * 0.018,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.02,
                                          vertical: screenHeight * 0.005,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          'approved',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: screenHeight * 0.015,
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
                SizedBox(height: screenHeight * 0.05),
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
                SizedBox(height: screenHeight * 0.03),
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
                SizedBox(height: screenHeight * 0.05), // Bottom padding
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
    bool isDisabled = false,
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
          backgroundColor: isDisabled ? Colors.grey : Colors.teal,
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
        ),
      ),
    );
  }
}
