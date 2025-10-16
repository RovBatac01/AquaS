import 'package:flutter/material.dart';
import 'package:aqua/components/colors.dart';

class TermsAndConditionsDialog {
  static void show(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.article_rounded,
                    color: Colors.blue,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'Terms and Conditions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Data Privacy Policy',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Scrollable content
                Container(
                  height: 400,
                  child: SingleChildScrollView(
                    child: Text(
                      _getPrivacyPolicyContent(),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[300] : Colors.black87,
                        fontFamily: 'Poppins',
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'I Understand',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _getPrivacyPolicyContent() {
    return '''Sanitary Office of City Health Office of General Trias - Data Privacy Policy

By agreeing to these terms and conditions, you acknowledge and consent that the Sanitary Office of City Health Office of General Trias will have access to certain personal data you provide during the use of this application. This data is collected and processed solely for the purpose of efficient public health management, sanitation monitoring, and related governmental functions within General Trias.

The data collected may include, but is not limited to:

Personal Identifiable Information: Name, address, contact details (phone number, email address), and other demographic information.

Health-Related Data: Information pertaining to sanitation practices, health inspections, and relevant health records necessary for public health interventions.

Usage Data: Information about how you interact with the application, such as login times and features accessed, to improve service delivery.

Your data will be used to:

• Facilitate inspections and monitoring by the Sanitary Office.
• Communicate important health advisories and updates.
• Generate reports and statistics for public health planning (data will be anonymized where possible for reporting).
• Respond to inquiries and provide support related to sanitation and public health services.

The Sanitary Office of City Health Office of General Trias is committed to protecting your privacy and ensuring the security of your data in accordance with the Data Privacy Act of 2012 (Republic Act No. 10173) of the Philippines. Your data will not be shared with third parties for commercial purposes. Access to your data will be limited to authorized personnel only, who are bound by confidentiality agreements.

You have the right to access, correct, and object to the processing of your personal data, subject to legal limitations. For any concerns regarding your data privacy, please contact the Sanitary Office of City Health Office of General Trias.

By proceeding, you signify your understanding and acceptance of these terms.''';
  }
}
