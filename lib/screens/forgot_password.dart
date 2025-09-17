import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quên mật khẩu"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_reset,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 30),
            
            const Text(
              "Nhập email của bạn để đặt lại mật khẩu",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Email input field
            const TextField(
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 30),

            // Reset password button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: () {
                  debugPrint("Reset password button pressed!");
                  // Hiển thị thông báo thành công
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Link đặt lại mật khẩu đã được gửi đến email của bạn!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text("Gửi link đặt lại mật khẩu"),
              ),
            ),

            const SizedBox(height: 20),

            // Back to login link
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Quay lại đăng nhập"),
            ),
          ],
        ),
      ),
    );
  }
}
