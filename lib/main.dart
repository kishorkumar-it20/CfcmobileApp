import 'package:cfcapp/IntroScreen.dart';
import 'package:cfcapp/Screens/PostTask.dart';
import 'package:cfcapp/Screens/ReviewSystem/ClientReview.dart';
import 'package:cfcapp/Screens/TaskScreen.dart';
import 'package:cfcapp/Screens/Widgets/Freelancers.dart';
import 'package:cfcapp/Screens/Widgets/ProfileSetup.dart';
import 'package:cfcapp/SignIn/Login.dart';
import 'package:cfcapp/SplashScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const SplashScreen(),
        '/introScreen': (context) => IntroScreen(),
        '/login': (context) => const LoginScreen(),
        '/taskScreen': (context) => TaskScreen(),
        '/PostTask': (context) => const TaskSubmission(),
        '/profileSetup': (context) => const ProfileSetupScreen(),
        '/topfreelancers':(context)=> const Freelanscer(),
        '/ClientReview':(context)=>  ClientReview(),

      },
    );
  }
}
