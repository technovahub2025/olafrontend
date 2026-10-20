import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Privacy Policy",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
                    Colors.grey[900]!,
                    Colors.black87,
                  ]
                : [
                    primaryColor.withOpacity(0.03),
                    Colors.white,
                  ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.privacy_tip_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Your Privacy Matters",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "We are committed to protecting your personal information and being transparent about how we collect, use, and protect your data.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.update,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Last Updated: ${_getFormattedDate()}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Introduction
              _buildSectionHeader(
                title: "Introduction",
                icon: Icons.info_outline_rounded,
                color: primaryColor,
              ),
              _buildContentCard(
                content: "Your privacy is important to us. This Privacy Policy explains how our taxi service app collects, uses, and protects your personal information. This policy applies to all services offered through our application.",
                context: context,
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 25),
              
              // Section 1: Information Collection
              _buildSectionHeader(
                title: "1. Information We Collect",
                icon: Icons.collections_bookmark_rounded,
                color: primaryColor,
              ),
              _buildBulletCard(
                items: [
                  "Personal Information: Name, phone number, email address, and payment details",
                  "Location Data: GPS coordinates to provide accurate taxi services and track rides",
                  "Device Information: Device type, operating system, and app usage statistics",
                  "Trip Information: Pickup/drop-off locations, time stamps, and fare details",
                  "Communications: Records of customer support interactions and feedback",
                ],
                context: context,
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 25),
              
              // Section 2: How We Use Information
              _buildSectionHeader(
                title: "2. How We Use Your Information",
                icon: Icons.analytics_outlined,
                color: primaryColor,
              ),
              _buildBulletCard(
                items: [
                  "To provide, maintain, and improve our taxi services",
                  "To process payments and send transaction receipts",
                  "To communicate important updates, offers, and service notifications",
                  "To enhance user experience through personalized features",
                  "To ensure safety and security during rides",
                  "To comply with legal obligations and respond to legal requests",
                ],
                context: context,
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 25),
              
              // Section 3: Data Protection
              _buildSectionHeader(
                title: "3. Data Protection & Security",
                icon: Icons.security_rounded,
                color: primaryColor,
              ),
              _buildBulletCard(
                items: [
                  "We use industry-standard encryption to secure your data",
                  "Regular security audits and vulnerability assessments",
                  "Access controls limit employee access to personal information",
                  "Secure data storage with backup and disaster recovery systems",
                  "We do not share personal information with third parties without your explicit consent",
                  "Regular employee training on data protection best practices",
                ],
                context: context,
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 25),
              
              // Section 4: Data Sharing
              _buildSectionHeader(
                title: "4. Data Sharing & Third Parties",
                icon: Icons.share_outlined,
                color: primaryColor,
              ),
              _buildContentCard(
                content: "We only share your information when necessary to provide our services, comply with the law, or protect our rights. This includes sharing with drivers to facilitate rides, payment processors for transactions, and when required by law enforcement.",
                context: context,
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 25),
              
              // Section 5: Your Rights
              _buildSectionHeader(
                title: "5. Your Privacy Rights",
                icon: Icons.gpp_good_outlined,
                color: primaryColor,
              ),
              _buildBulletCard(
                items: [
                  "Right to access your personal information we hold",
                  "Right to correct inaccurate or incomplete data",
                  "Right to request deletion of your personal information",
                  "Right to opt-out of marketing communications",
                  "Right to data portability",
                  "Right to withdraw consent at any time",
                ],
                context: context,
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 25),
              
              // Section 6: Cookies & Tracking
              _buildSectionHeader(
                title: "6. Cookies & Tracking Technologies",
                icon: Icons.cookie_outlined,
                color: primaryColor,
              ),
              _buildContentCard(
                content: "We use cookies and similar tracking technologies to enhance your app experience, analyze usage patterns, and deliver personalized content. You can control cookie preferences through your device settings.",
                context: context,
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 25),
              
              // Section 7: Policy Updates
              _buildSectionHeader(
                title: "7. Policy Updates",
                icon: Icons.update_rounded,
                color: primaryColor,
              ),
              _buildContentCard(
                content: "We may update this privacy policy periodically. We will notify you of significant changes through app notifications or email. Continued use of our services after changes constitutes acceptance of the updated policy.",
                context: context,
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 30),
              
              // Consent Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Your Consent",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "By using our app, you consent to the collection and use of your information as described in this Privacy Policy. If you have any concerns about how we handle your data, please contact us before using our services.",
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 25),
              
              // Contact Section
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.contact_support_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Contact Our Privacy Team",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "privacy@taxiservice.com\n+1 (555) 123-4567\nMon-Fri, 9AM-6PM EST",
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${monthNames[now.month - 1]} ${now.day}, ${now.year}';
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard({
    required String content,
    required BuildContext context,
    required bool isDarkMode,
  }) {
    final Color primaryColor = Theme.of(context).primaryColor;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: primaryColor.withOpacity(0.7),
            size: 16,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletCard({
    required List<String> items,
    required BuildContext context,
    required bool isDarkMode,
  }) {
    final Color primaryColor = Theme.of(context).primaryColor;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: primaryColor.withOpacity(0.8),
                  size: 18,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}