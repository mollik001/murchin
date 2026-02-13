// lib/features/terms_privacy/screens/terms_privacy_screen.dart
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
      appBar:CustomAppbar2(title: 'Terms and Privacy Policy',
     
      ),
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
              
              // Effective Date
              Text(
                'Effective Date: December 29, 2025',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: AppColors.gray600,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
              
              Text(
                'Last Updated: December 29, 2025',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: AppColors.gray600,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.sp,
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Introduction
              Text(
                'This Privacy Policy describes how Pickfair ("we," "us," or "our") collects, uses, discloses, and protects your personal information when you visit our website, use our mobile application, or engage with our services (collectively, the "Services"). We are committed to protecting your privacy and complying with applicable data protection laws worldwide, including but not limited to the General Data Protection Regulation (GDPR) in the European Union, the California Consumer Privacy Act (CCPA) as amended by the California Privacy Rights Act (CPRA), the Brazilian General Data Protection Law (LGPD), and comprehensive consumer privacy laws in various US states (as detailed below). We also adhere to other global frameworks where applicable, such as PIPEDA (Canada), FADP (Switzerland), PDPA (Singapore), POPIA (South Africa), and equivalents in regions like Australia (Privacy Act), Japan (APPI), and India (DPDP Act).',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                  height: 1.6,
                ),
              ),
              
              SizedBox(height: 16.h),
              
              Text(
                'If you are a resident of a specific jurisdiction, additional provisions may apply as outlined in the sections below. This policy may be updated periodically; we will notify you of significant changes via email or a prominent notice on our Services.',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                  height: 1.6,
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Section 1: Contact Information
              _buildSectionTitle('1. Contact Information'),
              
              SizedBox(height: 12.h),
              
              _buildBulletPoint('Data Controller/Owner: Pickfair'),
              _buildBulletPoint('Email: privacy@pickfair.com'),
              _buildBulletPoint('Phone: +1 (555) 123-4567'),
              _buildBulletPoint('Data Protection Officer (if required under GDPR/LGPD): privacy@pickfair.com'),
              
              SizedBox(height: 8.h),
              
              Text(
                'For any privacy-related inquiries or to exercise your rights, contact us at the above details. We respond within legally required timelines (e.g., 30 days under GDPR, 45 days under CCPA, 15 days under LGPD).',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                  height: 1.6,
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Section 2: Types of Data Collected
              _buildSectionTitle('2. Types of Data Collected'),
              
              SizedBox(height: 12.h),
              
              Text(
                'We collect the following types of personal data, which may include:',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                  height: 1.6,
                ),
              ),
              
              SizedBox(height: 8.h),
              
              _buildBulletPoint('Identifiers: First name, last name, email address, phone number, postal address, username, unique identifiers.'),
              _buildBulletPoint('Internet or Network Activity: IP address, browser type, device information, usage data (e.g., pages viewed, time spent), cookies, trackers.'),
              _buildBulletPoint('Geolocation Data: Approximate location (if enabled; precise data only with consent where required).'),
              _buildBulletPoint('Sensitive Data: Only if necessary and with explicit consent/opt-in where mandated (e.g., health, racial/ethnic origin, biometrics, genetic data, sexual orientation; payment details via secure third parties). We minimize collection of sensitive data per laws like GDPR, LGPD, and US state requirements.'),
              _buildBulletPoint('Commercial Information: Purchase history, preferences.'),
              _buildBulletPoint('Inferences: Derived from other data (e.g., profiles for marketing, with opt-out rights).'),
              
              SizedBox(height: 8.h),
              
              Text(
                'Data may be provided voluntarily by you (e.g., via forms) or collected automatically (e.g., via cookies). We do not knowingly collect data from children under 13 (or higher ages per local law, e.g., 16 under GDPR/CPRA) without verifiable parental consent, in compliance with laws like COPPA (US), GDPR, and state-specific child protections.',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                  height: 1.6,
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Section 3: How We Collect Data
              _buildSectionTitle('3. How We Collect Data'),
              
              SizedBox(height: 12.h),
              
              _buildBulletPoint('Directly from You: When you register, subscribe, contact us, or make a purchase.'),
              _buildBulletPoint('Automatically: Through cookies, analytics tools (e.g., Google Analytics), and device logs.'),
              _buildBulletPoint('From Third Parties: Such as social media platforms, advertising partners, or payment processors, with appropriate consent and in compliance with applicable laws.'),
              
              SizedBox(height: 32.h),
              
              // Continue Section (Placeholder for more content)
              _buildSectionTitle('4. How We Use Your Data'),
              
              SizedBox(height: 12.h),
              
              Text(
                'We use your personal data for the following purposes:',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                ),
              ),
              
              SizedBox(height: 8.h),
              
              _buildBulletPoint('To provide and maintain our Services'),
              _buildBulletPoint('To notify you about changes to our Services'),
              _buildBulletPoint('To allow you to participate in interactive features when you choose to do so'),
              _buildBulletPoint('To provide customer support'),
              _buildBulletPoint('To gather analysis or valuable information so that we can improve our Services'),
              _buildBulletPoint('To monitor the usage of our Services'),
              _buildBulletPoint('To detect, prevent and address technical issues'),
              _buildBulletPoint('To provide you with news, special offers and general information about other goods, services and events which we offer that are similar to those that you have already purchased or enquired about unless you have opted not to receive such information'),
              
              SizedBox(height: 32.h),
              
              // Continue Section
              _buildSectionTitle('5. Data Sharing and Disclosure'),
              
              SizedBox(height: 12.h),
              
              Text(
                'We may share your personal data in the following situations:',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                ),
              ),
              
              SizedBox(height: 8.h),
              
              _buildBulletPoint('With Service Providers: We may share your personal data with Service Providers to monitor and analyze the use of our Service, to contact you.'),
              _buildBulletPoint('For Business transfers: We may share or transfer your personal data in connection with, or during negotiations of, any merger, sale of company assets, financing, or acquisition of all or a portion of our business to another company.'),
              _buildBulletPoint('With Affiliates: We may share your information with our affiliates, in which case we will require those affiliates to honor this Privacy Policy.'),
              _buildBulletPoint('With Business partners: We may share your information with our business partners to offer you certain products, services or promotions.'),
              _buildBulletPoint('With other users: when you share personal data or otherwise interact in the public areas with other users, such information may be viewed by all users and may be publicly distributed outside.'),
              _buildBulletPoint('With your consent: We may disclose your personal data for any other purpose with your consent.'),
              
              SizedBox(height: 32.h),
              
              // Continue Section
              _buildSectionTitle('6. Your Data Protection Rights'),
              
              SizedBox(height: 12.h),
              
              Text(
                'Depending on your location, you may have the following data protection rights:',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                ),
              ),
              
              SizedBox(height: 8.h),
              
              _buildBulletPoint('The right to access, update or delete the information we have on you.'),
              _buildBulletPoint('The right of rectification.'),
              _buildBulletPoint('The right to object.'),
              _buildBulletPoint('The right of restriction.'),
              _buildBulletPoint('The right to data portability.'),
              _buildBulletPoint('The right to withdraw consent.'),
              
              SizedBox(height: 8.h),
              
              Text(
                'If you wish to exercise any of these rights, please contact us using the contact information provided. We will respond to your request within the timeframe required by applicable law.',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                  height: 1.6,
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Continue Section
              _buildSectionTitle('7. Cookies and Tracking Technologies'),
              
              SizedBox(height: 12.h),
              
              Text(
                'We use cookies and similar tracking technologies to track the activity on our Service and we hold certain information. Cookies are files with a small amount of data which may include an anonymous unique identifier.',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                  height: 1.6,
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Continue Section
              _buildSectionTitle('8. Security of Your Data'),
              
              SizedBox(height: 12.h),
              
              Text(
                'The security of your data is important to us but remember that no method of transmission over the Internet or method of electronic storage is 100% secure. While we strive to use commercially acceptable means to protect your Personal Data, we cannot guarantee its absolute security.',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                  height: 1.6,
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Continue Section
              _buildSectionTitle('9. International Data Transfers'),
              
              SizedBox(height: 12.h),
              
              Text(
                'Your information, including Personal Data, may be transferred to — and maintained on — computers located outside of your state, province, country or other governmental jurisdiction where the data protection laws may differ from those of your jurisdiction.',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                  height: 1.6,
                ),
              ),
              
              SizedBox(height: 32.h),
              
              // Continue Section
              _buildSectionTitle('10. Changes to This Privacy Policy'),
              
              SizedBox(height: 12.h),
              
              Text(
                'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date at the top of this Privacy Policy.',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                  height: 1.6,
                ),
              ),
              
              SizedBox(height: 8.h),
              
              Text(
                'You are advised to review this Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted on this page.',
                style: AppTextStyles.bodyMedium?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                  height: 1.6,
                ),
              ),
              
              SizedBox(height: 40.h),
              
              // Contact Info Box
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.gray200 ?? const Color(0xFFE0E0E0),
                    width: 1.w,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Us',
                      style: AppTextStyles.headlineSmall?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                      ),
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    _buildContactInfo('Email:', 'privacy@pickfair.com'),
                    _buildContactInfo('Phone:', '+1 (555) 123-4567'),
                    _buildContactInfo('Address:', '123 Tech Street, San Francisco, CA 94107'),
                    
                    SizedBox(height: 16.h),
                    
                    Text(
                      'If you have any questions about this Privacy Policy, please contact us.',
                      style: AppTextStyles.bodySmall?.copyWith(
                        color: AppColors.gray600,
                        fontWeight: FontWeight.w400,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for section titles
  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.headlineSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 18.sp,
        ),
      ),
    );
  }

  // Helper method for bullet points
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4.h, right: 8.w),
            child: Container(
              width: 4.w,
              height: 4.w,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
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

  // Helper method for contact info
  Widget _buildContactInfo(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium?.copyWith(
              color: AppColors.gray700,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w400,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}