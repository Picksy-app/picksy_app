import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../user/home_screen.dart'; // Make sure this exists
import '../admin/admin_home_screen.dart';
import '../super_admin/super_admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  String? verificationId;
  bool otpSent = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void sendOTP() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91${phoneController.text.trim()}',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        await _handlePostLogin();
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Verification Failed: ${e.message}")),
          );
        }
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          otpSent = true;
          verificationId = verId;
        });
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
  }

  void verifyOTP() async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otpController.text.trim(),
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _handlePostLogin(userCredential: userCredential);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid OTP: $e")),
        );
      }
    }
  }

  // Handles Firestore user doc creation/updating and role-based navigation after login
  Future<void> _handlePostLogin({UserCredential? userCredential}) async {
    final user = userCredential?.user ?? _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final mobileNo = '+91${phoneController.text.trim()}';
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final userDoc = await userRef.get();

    if (userDoc.exists) {
      // Update lastLoggedIn and mobileNo on each login
      await userRef.update({
        'mobileNo': mobileNo,
        'lastLoggedIn': FieldValue.serverTimestamp(),
      });
    } else {
      // New user document creation
      await userRef.set({
        'userId': uid,
        'mobileNo': mobileNo,
        'uname': '',
        'area': '',
        'city': '',
        'pincode': '',
        'isAdmin': false,
        'isSuperAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoggedIn': FieldValue.serverTimestamp(),
        'role': 'retailer',
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful!")),
      );

      // Check roles and navigate accordingly
      final data = userDoc.exists ? userDoc.data()! : null;

      // If new user document created, use default roles (false)
      final isAdmin = data != null && data['isAdmin'] == true;
      final isSuperAdmin = data != null && data['isSuperAdmin'] == true;

      if (isSuperAdmin) {
        navigateToSuperAdminHome();
      } else if (isAdmin) {
        navigateToAdminHome();
      } else {
        navigateToUserHome();
      }
    }
  }

  void navigateToUserHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void navigateToAdminHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
    );
  }

  void navigateToSuperAdminHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SuperAdminHomeScreen()),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                prefixText: '+91 ',
              ),
            ),
            const SizedBox(height: 16),
            if (otpSent)
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: otpSent ? verifyOTP : sendOTP,
              child: Text(otpSent ? 'Verify OTP' : 'Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
