import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  String otpCode = "------";
  int _secondsRemaining = 0;
  Timer? _timer;
  StreamSubscription<DatabaseEvent>? _otpSubscription;
  
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _listenToFirebase();
  }

  void _listenToFirebase() {
    // Lắng nghe cả mã OTP và thời điểm hết hạn từ Firebase
    _otpSubscription = _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (mounted && data != null) {
        setState(() {
          otpCode = data['current_otp']?.toString() ?? "------";
          
          // Tính toán lại giây còn lại dựa trên timestamp trên Cloud
          int expiry = data['expiry_time'] ?? 0;
          int now = DateTime.now().millisecondsSinceEpoch;
          _secondsRemaining = ((expiry - now) / 1000).round();

          if (_secondsRemaining > 0 && otpCode != "expired") {
            _startLocalTimer();
          } else {
            otpCode = "EXPIRED";
            _secondsRemaining = 0;
          }
        });
      }
    });
  }

  void _startLocalTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void generateOTP() {
    String newCode = (Random().nextInt(900000) + 100000).toString();
    // Tính thời điểm hết hạn = Hiện tại + 5 phút (300,000 milliseconds)
    int expiryTime = DateTime.now().millisecondsSinceEpoch + 300000;

    // Đẩy cả 2 giá trị lên Firebase để mọi thiết bị đều thấy chung một mốc thời gian
    _dbRef.update({
      "current_otp": newCode,
      "expiry_time": expiryTime,
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mã mở cửa tạm thời")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.blue),
            const SizedBox(height: 30),
            const Text("MÃ OTP THỜI GIAN THỰC", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                otpCode,
                style: const TextStyle(fontSize: 50, letterSpacing: 5, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 20),
            if (_secondsRemaining > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_sharp, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  "Hiệu lực còn: ${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
                  style: TextStyle(fontSize: 18, color: _secondsRemaining < 30 ? Colors.red : Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: generateOTP,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
              child: const Text("TẠO MÃ MỚI"),
            ),
          ],
        ),
      ),
    );
  }
}