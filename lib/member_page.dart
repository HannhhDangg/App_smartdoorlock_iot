import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class MemberPage extends StatefulWidget {
  const MemberPage({super.key});

  @override
  State<MemberPage> createState() => _MemberPageState(); // Tên này phải khớp với Class bên dưới
}

class _MemberPageState extends State<MemberPage> { // Đã đổi tên khớp với createState
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  void _startStepByStepRegistration() {
    _dbRef.child("system_command").set("scan_mode");

      // //Ham test
      // Future.delayed(const Duration(seconds: 3), () {
      //   if (mounted) {
      //     _dbRef.child("last_id").set("RFID_TEST_12345"); // Gửi ID giả lên Firebase
      //   }
      // });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StreamBuilder(
          stream: _dbRef.child("last_id").onValue,
          builder: (context, snapshot) {
            String cardId = snapshot.data?.snapshot.value?.toString() ?? "None";
            
            if (cardId == "None" || cardId == "null") {
              return _buildScanningUI(context);
            } 
            
            return _buildInputInfoUI(context, cardId);
          },
        );
      },
    );
  }

  Widget _buildScanningUI(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      height: 350,
      child: Column(
        children: [
          Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 30),
          const Text("QUY TRÌNH: ĐANG QUÉT THẺ", style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Vui lòng quẹt thẻ vào bộ Kit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          const Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 80, height: 80, child: CircularProgressIndicator(strokeWidth: 3)),
              Icon(Icons.contactless, size: 40, color: Colors.blue),
            ],
          ),
          const Spacer(),
          const Text("Đang chờ tín hiệu từ ESP32...", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              _dbRef.child("system_command").set("none");
              Navigator.pop(context);
            }, 
            child: const Text("HỦY BỎ", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Widget _buildInputInfoUI(BuildContext context, String cardId) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
        left: 25, right: 25, top: 20
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text("ĐÃ NHẬN DẠNG THẺ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 10),
          Text("ID: $cardId", style: const TextStyle(color: Colors.grey)),
          const Divider(height: 30),
          const Text("Nhập thông tin thành viên", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "Họ và tên",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Số điện thoại",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _dbRef.child("members").child(cardId).set({
                    "name": nameController.text,
                    "phone": phoneController.text,
                    "registered_at": ServerValue.timestamp,
                  });
                  _dbRef.child("last_id").set("None");
                  Navigator.pop(context);
                }
              },
              child: const Text("HOÀN TẤT ĐĂNG KÝ"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thành viên")),
      body: StreamBuilder(
        stream: _dbRef.child("members").onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> members = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
            return ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                String key = members.keys.elementAt(index);
                var member = members[key];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12, left: 15, right: 15, top: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(member['name'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("ID: $key"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _dbRef.child("members").child(key).remove()
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text("Chưa có thành viên nào"));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startStepByStepRegistration,
        label: const Text("THÊM THẺ MỚI"),
        icon: const Icon(Icons.add_card),
      ),
    );
  }
}