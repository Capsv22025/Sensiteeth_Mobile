import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'viewmodels/image_picker_viewmodel.dart';
import 'viewmodels/analysis_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/home_screen.dart';
import 'views/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://snvrykahnydcsdvfwfbw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNudnJ5a2FobnlkY3NkdmZ3ZmJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk4OTc4MDMsImV4cCI6MjA1NTQ3MzgwM30.V1AB97SqUL0x9koX20c6mvmiXExnkP0a3zyy-tQaBY0',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImagePickerViewModel()),
        ChangeNotifierProvider(create: (_) => AnalysisViewModel()),
        ChangeNotifierProvider(
            create: (_) => AuthViewModel(Supabase.instance.client)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Dental Health Analysis',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            color: Colors.teal,
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.teal,
            ),
          ),
        ),
        home: Consumer<AuthViewModel>(
          builder: (context, authViewModel, child) {
            return authViewModel.isAuthenticated
                ? const HomeScreen()
                : const AuthScreen();
          },
        ),
      ),
    );
  }
}
