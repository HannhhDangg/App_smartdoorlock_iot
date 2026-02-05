import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:local_auth/local_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isOpen = false;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
  }

  void _listenToFirebase() {
    _dbRef.child("door_status").onValue.listen((event) {
      final data = event.snapshot.value;
      if (mounted && data != null) {
        setState(() => isOpen = (data == 1));
      }
    });
  }

  // Yêu cầu vân tay/mật khẩu máy trước khi thực hiện
  Future<void> _handleDoorAction() async {
    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Xác thực để điều khiển cửa nhà',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Cho phép dùng cả mật khẩu máy nếu vân tay lỗi
        ),
      );

      if (authenticated) {
        bool newStatus = !isOpen;
        _dbRef.child("door_status").set(newStatus ? 1 : 0);
        HapticFeedback.mediumImpact();
        
        // Ghi log bảo mật
        _dbRef.child('logs').push().set({
          "name": "Chủ nhà",
          "method": "App (Xác thực)",
          "timestamp": "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2,'0')} - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
        });
      }
    } on PlatformException catch (e) {
      debugPrint("Lỗi bảo mật: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Điều khiển an toàn"), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 40, color: Colors.blue),
            const SizedBox(height: 10),
            const Text("Bảo mật sinh trắc học đang bật", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: _handleDoorAction,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(60),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: isOpen ? Colors.green : Colors.red, width: 2),
                ),
                child: Icon(
                  isOpen ? Icons.lock_open : Icons.lock,
                  size: 100,
                  color: isOpen ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              isOpen ? "CỬA ĐANG MỞ" : "CỬA ĐANG ĐÓNG",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isOpen ? Colors.green : Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}