import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CaptchaScreen extends StatefulWidget {
  const CaptchaScreen({super.key});

  @override
  State<CaptchaScreen> createState() => _CaptchaScreenState();
}

class _CaptchaScreenState extends State<CaptchaScreen> {
  final emailController = TextEditingController();
  final captchaController = TextEditingController();

  bool isLoading = false;

  final String baseUrl = "https://ola-7ii1.onrender.com/api";
  // For Android emulator use:
  // final String baseUrl = "http://10.0.2.2:3000/api";

  Future<void> verifyCaptcha() async {
    if (emailController.text.isEmpty || captchaController.text.isEmpty) {
      showMsg("Enter email and captcha");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/verifycaptcha"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text.trim(),
          "captcha": captchaController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        showMsg(data["message"]);

        // Navigate next screen here
        // Navigator.pushReplacement(context,
        //   MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        showMsg(data["message"] ?? "Invalid captcha");
      }
    } catch (e) {
      showMsg("Server connection failed");
    }

    setState(() => isLoading = false);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.black,
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    captchaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const yellow = Color(0xffFFD600);

    return Scaffold(
      backgroundColor: const Color(0xffFFF8D6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

            
            

             

              TextField(
                controller: captchaController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "Enter captcha",
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : verifyCaptcha,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: yellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xffFFD600),
                        )
                      : const Text(
                          "Verify Captcha",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}