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
  String _lastAutoVerifiedCaptcha = '';

  final String baseUrl = "https://ola-7ii1.onrender.com/api";
  

  Future<void> sendCaptcha() async {
    if (emailController.text.isEmpty) {
      showMsg("Enter email");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/send-captcha"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        showMsg(data["message"]);
      } else {
        showMsg(data["message"] ?? "Something went wrong");
      }
    } catch (e) {
      showMsg("Server connection failed");
    }

    setState(() => isLoading = false);
  }

  Future<void> verifyCaptcha() async {
    final captcha = captchaController.text.trim();
    if (captcha.isEmpty) {
      showMsg("Enter captcha");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/verifycaptcha"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "captcha": captcha,
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

  void _onCaptchaChanged(String value) {
    final captcha = value.trim();
    if (isLoading) return;
    if (captcha.length != 6) return;
    if (_lastAutoVerifiedCaptcha == captcha) return;
    _lastAutoVerifiedCaptcha = captcha;
    verifyCaptcha();
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

              const Text(
                "Email Verification",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Enter your email and verify with captcha code",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 35),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => isLoading ? null : sendCaptcha(),
                decoration: InputDecoration(
                  hintText: "Enter email",
                  prefixIcon: const Icon(Icons.email),
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
                  onPressed: isLoading ? null : sendCaptcha,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Send Captcha",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              TextField(
                controller: captchaController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: _onCaptchaChanged,
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
