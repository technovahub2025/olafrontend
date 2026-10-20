import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:taxiuuse/core/config.dart';
import 'package:taxiuuse/tokenmagemet/tokenstorage.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final String userId;
  const ProfileDetailsScreen({super.key, required this.userId});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  late final TextEditingController businessNameController;
  late final TextEditingController socialLinkController;
  late final TextEditingController websiteController;
  late final TextEditingController addressController;
  late final TextEditingController notesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    businessNameController = TextEditingController();
    socialLinkController = TextEditingController();
    websiteController = TextEditingController();
    addressController = TextEditingController();
    notesController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final local = await SessionManager.getProfileDetails();
      if (local != null) {
        final data = json.decode(local) as Map<String, dynamic>;
        businessNameController.text = (data['businessName'] ?? '').toString();
        socialLinkController.text = (data['socialLink'] ?? '').toString();
        websiteController.text = (data['website'] ?? '').toString();
        addressController.text = (data['address'] ?? '').toString();
        notesController.text = (data['notes'] ?? '').toString();
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/profile-details/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        setState(() {
          businessNameController.text = (data['businessName'] ?? '').toString();
          socialLinkController.text = (data['socialLink'] ?? '').toString();
          websiteController.text = (data['website'] ?? '').toString();
          addressController.text = (data['address'] ?? '').toString();
          notesController.text = (data['notes'] ?? '').toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveData() async {
    setState(() => _saving = true);
    try {
      final payload = {
        'id': widget.userId,
        'businessName': businessNameController.text.trim(),
        'socialLink': socialLinkController.text.trim(),
        'website': websiteController.text.trim(),
        'address': addressController.text.trim(),
        'notes': notesController.text.trim(),
      };

      await SessionManager.saveProfileDetails(json.encode(payload));
      await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/profile-details'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business details saved')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    businessNameController.dispose();
    socialLinkController.dispose();
    websiteController.dispose();
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Details'),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _field('Business Name', businessNameController),
                  _field('Social Link', socialLinkController),
                  _field('Website', websiteController),
                  _field('Address', addressController),
                  _field('Notes / Anything else', notesController),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: Text(_saving ? 'Saving...' : 'Save Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

