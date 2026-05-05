// lib/features/profile/screens/terms_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:murchin/const/theme/app_color.dart';
import 'package:murchin/const/theme/app_theme.dart';
import 'package:murchin/const/widgets/custom_appbar.dart';
import 'package:murchin/const/widgets/custom_appbar_2.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppbar2(title: 'Terms and Privacy Policy'),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),

              // Title
              Container(
                width: double.infinity,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Privacy Policy',
                  style: AppTextStyles.headlineMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 24.sp,
                  ),
                ),
              ),

              SizedBox(height: 8.h),

              // Last Updated Date
              Text(
                'Last Updated: 24 March 2026',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: AppColors.gray600,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),

              SizedBox(height: 24.h),

              // Section 1: Introduction
              _buildSectionTitle('1. Introduction'),
              SizedBox(height: 8.h),
              _buildContentText(
                'Pickfair ("we", "us", "our") is an informational application that aggregates and displays odds data from third-party platforms such as Kalshi, Polymarket, FanDuel, BetMGM, and DraftKings.\nThe platform compares this data with AI-generated predictions to provide analytical insights.\nBy accessing or using Pickfair, you agree to the terms and practices described in this policy.',
              ),

              SizedBox(height: 24.h),

              // Section 2: Nature of the Service
              _buildSectionTitle('2. Nature of the Service'),
              SizedBox(height: 8.h),
              _buildContentText(
                'Pickfair is strictly an informational and analytical tool. The application:',
              ),
              _buildBulletPoint('Displays odds data from external platforms'),
              _buildBulletPoint('Provides AI-based predictions and comparisons'),
              _buildBulletPoint('Does not support or facilitate gambling or financial transactions'),
              SizedBox(height: 8.h),
              _buildContentText(
                'Users cannot place bets, transfer money, or engage in any form of wagering within the app.',
              ),

              SizedBox(height: 24.h),

              // Section 3: Artificial Intelligence Disclaimer
              _buildSectionTitle('3. Artificial Intelligence Disclaimer'),
              SizedBox(height: 8.h),
              _buildContentText(
                'Pickfair uses artificial intelligence models, including GPT-4o mini, to generate predictions and insights.\nAI-generated outputs:',
              ),
              _buildBulletPoint('Are automatically generated'),
              _buildBulletPoint('May be inaccurate, incomplete, or outdated'),
              _buildBulletPoint('Are provided for informational purposes only'),
              SizedBox(height: 8.h),
              _buildContentText(
                'They should not be considered financial, legal, or professional advice. Users are responsible for verifying any information before relying on it.',
              ),

              SizedBox(height: 24.h),

              // Section 4: Third-Party Data Disclaimer
              _buildSectionTitle('4. Third-Party Data Disclaimer'),
              SizedBox(height: 8.h),
              _buildContentText(
                'All odds and related data displayed in Pickfair are obtained from third-party platforms via APIs.\nWe do not:',
              ),
              _buildBulletPoint('Control or influence this data'),
              _buildBulletPoint('Guarantee its accuracy, completeness, or timeliness'),
              SizedBox(height: 8.h),
              _buildContentText(
                'Users should verify information directly with the respective platforms before making any decisions.',
              ),

              SizedBox(height: 24.h),

              // Section 5: No Gambling or Financial Activity
              _buildSectionTitle('5. No Gambling or Financial Activity'),
              SizedBox(height: 8.h),
              _buildContentText(
                'Pickfair does not involve gambling, betting, or real-money transactions of any kind.\nAll content is provided strictly for informational purposes.',
              ),

              SizedBox(height: 24.h),

              // Section 6: Information We Collect
              _buildSectionTitle('6. Information We Collect'),
              SizedBox(height: 8.h),
              _buildContentText(
                'We collect minimal data necessary to operate the platform, which may include:',
              ),
              _buildBulletPoint('Basic usage data (app interactions, features used)'),
              _buildBulletPoint('Device information (device type, operating system, app version)'),
              _buildBulletPoint('Anonymous analytics data'),
              SizedBox(height: 8.h),
              _buildContentText(
                'We do not collect financial information, payment details, or gambling-related data.',
              ),

              SizedBox(height: 24.h),

              // Section 7: How We Use Information
              _buildSectionTitle('7. How We Use Information'),
              SizedBox(height: 8.h),
              _buildContentText(
                'Collected information is used to:',
              ),
              _buildBulletPoint('Operate and maintain the application'),
              _buildBulletPoint('Improve performance and user experience'),
              _buildBulletPoint('Enhance AI predictions and system accuracy'),
              _buildBulletPoint('Monitor system security and prevent misuse'),

              SizedBox(height: 24.h),

              // Section 8: AI Data Processing
              _buildSectionTitle('8. AI Data Processing'),
              SizedBox(height: 8.h),
              _buildContentText(
                'User interactions may be processed by AI systems (including GPT-4o mini) to generate responses and predictions.\nOnly the minimum necessary data is processed to provide functionality.',
              ),

              SizedBox(height: 24.h),

              // Section 9: Data Sharing
              _buildSectionTitle('9. Data Sharing'),
              SizedBox(height: 8.h),
              _buildContentText(
                'We do not sell or rent user data.\nInformation may be shared only:',
              ),
              _buildBulletPoint('With trusted service providers (such as hosting, analytics, and AI infrastructure providers)'),
              _buildBulletPoint('When required by law or legal obligations'),
              _buildBulletPoint('To protect system security or prevent misuse'),

              SizedBox(height: 24.h),

              // Section 10: Data Security
              _buildSectionTitle('10. Data Security'),
              SizedBox(height: 8.h),
              _buildContentText(
                'We implement reasonable technical and organizational measures to protect data, including:',
              ),
              _buildBulletPoint('Secure servers'),
              _buildBulletPoint('Encrypted communication'),
              _buildBulletPoint('Access control mechanisms'),

              SizedBox(height: 24.h),

              // Section 11: Data Retention
              _buildSectionTitle('11. Data Retention'),
              SizedBox(height: 8.h),
              _buildContentText(
                'Information is retained only for as long as necessary to:',
              ),
              _buildBulletPoint('Operate the service'),
              _buildBulletPoint('Maintain performance and security'),
              _buildBulletPoint('Improve functionality'),

              SizedBox(height: 24.h),

              // Section 12: Third-Party Services
              _buildSectionTitle('12. Third-Party Services'),
              SizedBox(height: 8.h),
              _buildContentText(
                'Pickfair integrates with external platforms such as Kalshi, Polymarket, FanDuel, BetMGM, and DraftKings.\nWe are not responsible for the content, accuracy, or privacy practices of these third-party platforms.',
              ),

              SizedBox(height: 24.h),

              // Section 13: User Responsibilities
              _buildSectionTitle('13. User Responsibilities'),
              SizedBox(height: 8.h),
              _buildContentText(
                'By using Pickfair, you agree:',
              ),
              _buildBulletPoint('To use the app only for lawful purposes'),
              _buildBulletPoint('Not to misuse, manipulate, or attempt to disrupt the platform'),
              _buildBulletPoint('Not to rely solely on the app for financial or decision-making purposes'),

              SizedBox(height: 24.h),

              // Section 14: Limitation of Liability
              _buildSectionTitle('14. Limitation of Liability'),
              SizedBox(height: 8.h),
              _buildContentText(
                'Pickfair is provided "as is" without warranties of any kind.\nWe are not liable for:',
              ),
              _buildBulletPoint('Any decisions made based on the app\'s data or AI predictions'),
              _buildBulletPoint('Financial or personal losses'),
              _buildBulletPoint('Errors or inaccuracies in third-party data'),

              SizedBox(height: 24.h),

              // Section 15: Children's Privacy
              _buildSectionTitle('15. Children\'s Privacy'),
              SizedBox(height: 8.h),
              _buildContentText(
                'Pickfair is not intended for users under the age of 13. We do not knowingly collect data from children.',
              ),

              SizedBox(height: 24.h),

              // Section 16: User Rights
              _buildSectionTitle('16. User Rights'),
              SizedBox(height: 8.h),
              _buildContentText(
                'Depending on your location, you may have rights regarding your data, including:',
              ),
              _buildBulletPoint('Access to your data'),
              _buildBulletPoint('Correction of inaccurate data'),
              _buildBulletPoint('Request for deletion'),

              SizedBox(height: 24.h),

              // Section 17: Updates to This Policy
              _buildSectionTitle('17. Updates to This Policy'),
              SizedBox(height: 8.h),
              _buildContentText(
                'We may update this Terms and Privacy Policy from time to time.\nContinued use of Pickfair after updates indicates acceptance of the revised policy.',
              ),

              SizedBox(height: 24.h),

              // Section 18: Contact
              _buildSectionTitle('18. Contact'),
              SizedBox(height: 8.h),
              _buildContentText(
                'For any questions or concerns, please contact:',
              ),
              SizedBox(height: 8.h),
              _buildContactEmail('pickfairsupport@gmail.com'),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.headlineSmall?.copyWith(
        color: Colors.black,
        fontWeight: FontWeight.w700,
        fontSize: 18.sp,
      ),
    );
  }

  Widget _buildContentText(String content) {
    return Text(
      content,
      style: AppTextStyles.bodyMedium?.copyWith(
        color: Colors.black,
        fontWeight: FontWeight.w400,
        fontSize: 14.sp,
        height: 1.6,
      ),
    );
  }

  Widget _buildBulletPoint(String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h, left: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: AppTextStyles.bodyMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w400,
              fontSize: 14.sp,
              height: 1.6,
            ),
          ),
          Expanded(
            child: Text(
              content,
              style: AppTextStyles.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w400,
                fontSize: 14.sp,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactEmail(String email) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodyMedium?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.w400,
          fontSize: 14.sp,
          height: 1.6,
        ),
        children: [
          const TextSpan(text: 'Email: '),
          TextSpan(
            text: email,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
