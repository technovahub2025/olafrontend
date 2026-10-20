import 'package:flutter/material.dart';
import 'package:taxiuuse/presentation/screen/bottomnavbar.dart';

class Welcomescreen extends StatefulWidget {
  

  const Welcomescreen({super.key, });

  @override
  State<Welcomescreen> createState() => _WelcomescreenState();
}

class _WelcomescreenState extends State<Welcomescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
       
        child: SingleChildScrollView(
          child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/taxtgif.gif'),
              const SizedBox(height: 100),
              SizedBox(
                width: 400,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DashboardScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Get Started",
                    style: TextStyle(color: Colors.white),
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
