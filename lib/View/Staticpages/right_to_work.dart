// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';

// class RightToWork extends StatelessWidget {
//   const RightToWork({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Professional color scheme
//     const Color primaryBlue = Color(0xFF1565C0);
//     const Color accentBlue = Color(0xFF2196F3);
//     const Color lightBlue = Color(0xFFE3F2FD);
//     const Color darkBlue = Color(0xFF0D47A1);
//     const Color successGreen = Color(0xFF4CAF50);
//     const Color textPrimary = Color(0xFF212121);
//     const Color textSecondary = Color(0xFF757575);
//     const Color backgroundColor = Color(0xFFFAFAFA);

//     return CupertinoPageScaffold(
//       backgroundColor: backgroundColor,
//       navigationBar: CupertinoNavigationBar(
//         backgroundColor: primaryBlue,
//         border: null,
//         middle: const Text(
//           'Right to Work Verification',
//           style: TextStyle(
//             color: CupertinoColors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//             letterSpacing: 0.5,
//           ),
//         ),
//         leading: CupertinoButton(
//           padding: EdgeInsets.zero,
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Icon(
//             CupertinoIcons.back,
//             color: CupertinoColors.white,
//             size: 24,
//           ),
//         ),
//       ),
//       child: SafeArea(
//         child: SingleChildScrollView(
//           physics: const BouncingScrollPhysics(),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 32),

//                 // Professional header section
//                 Center(
//                   child: Column(
//                     children: [
//                       // Logo container with professional styling
//                       Container(
//                         width: 120,
//                         height: 120,
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                             colors: [
//                               primaryBlue.withOpacity(0.1),
//                               accentBlue.withOpacity(0.1),
//                             ],
//                           ),
//                           borderRadius: BorderRadius.circular(60),
//                           border: Border.all(
//                             color: primaryBlue.withOpacity(0.2),
//                             width: 2,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: primaryBlue.withOpacity(0.1),
//                               blurRadius: 20,
//                               offset: const Offset(0, 8),
//                             ),
//                           ],
//                         ),
//                         child: ClipRRect(
//                           borderRadius: BorderRadius.circular(58),
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(58),
//                             ),
//                             child:Image.asset(
//                               'assets/appicon-removebg-preview.png',
//                               fit: BoxFit.contain,
//                             ),
//                           ),
//                         ),
//                       ),
                      
//                       const SizedBox(height: 16),
                      
//                       // Trust indicator
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: successGreen.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(
//                             color: successGreen.withOpacity(0.3),
//                             width: 1,
//                           ),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               CupertinoIcons.checkmark_seal_fill,
//                               size: 16,
//                               color: successGreen,
//                             ),
//                             const SizedBox(width: 6),
//                             Text(
//                               'Legal Compliance',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                                 color: successGreen,
//                                 letterSpacing: 0.3,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 40),

//                 // Professional title
//                 const Text(
//                   'Proof of Right to Work in the UK',
//                   style: TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.w700,
//                     color: textPrimary,
//                     letterSpacing: -0.5,
//                     height: 1.2,
//                   ),
//                 ),

//                 const SizedBox(height: 8),

//                 Text(
//                   'Verify your work eligibility to continue',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                     color: textSecondary,
//                     letterSpacing: 0.2,
//                   ),
//                 ),

//                 const SizedBox(height: 32),

//                 // Professional content card
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(16),
//                     border: Border.all(
//                       color: Colors.grey.withOpacity(0.1),
//                       width: 1,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.04),
//                         blurRadius: 16,
//                         offset: const Offset(0, 4),
//                       ),
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.02),
//                         blurRadius: 4,
//                         offset: const Offset(0, 1),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Section header
//                       Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: lightBlue,
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Icon(
//                               CupertinoIcons.info_circle_fill,
//                               size: 20,
//                               color: primaryBlue,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           const Text(
//                             'Legal Requirement',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w600,
//                               color: textPrimary,
//                               letterSpacing: 0.2,
//                             ),
//                           ),
//                         ],
//                       ),
                      
//                       const SizedBox(height: 20),
                      
//                       // Main explanation
//                       const Text(
//                         'To work legally as a delivery driver with Taskova, you must have the Right to Work in the UK. This verification ensures compliance with UK employment laws and helps maintain a fair, lawful working environment for all drivers on our platform.',
//                         style: TextStyle(
//                           fontSize: 16,
//                           height: 1.6,
//                           color: textPrimary,
//                           letterSpacing: 0.1,
//                         ),
//                       ),
                      
//                       const SizedBox(height: 20),
                      
//                       // Benefits list
//                       _buildBenefitItem(
//                         CupertinoIcons.checkmark_seal_fill,
//                         'Mandatory for all UK workers',
//                         successGreen,
//                       ),
//                       const SizedBox(height: 12),
//                       _buildBenefitItem(
//                         CupertinoIcons.shield_fill,
//                         'Ensures legal compliance',
//                         successGreen,
//                       ),
//                       const SizedBox(height: 12),
//                       _buildBenefitItem(
//                         CupertinoIcons.lock_fill,
//                         'Protects against unlawful employment',
//                         successGreen,
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // Accepted documents section
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: lightBlue.withOpacity(0.5),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: primaryBlue.withOpacity(0.2),
//                       width: 1,
//                     ),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(
//                             CupertinoIcons.checkmark_alt_circle_fill,
//                             size: 20,
//                             color: successGreen,
//                           ),
//                           const SizedBox(width: 8),
//                           const Text(
//                             'Accepted Documents',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: textPrimary,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       _buildDocumentItem('UK Passport'),
//                       _buildDocumentItem('Biometric Residence Permit'),
//                       _buildDocumentItem('UK Birth Certificate + NI Number'),
//                       _buildDocumentItem('EU/EEA Passport or ID Card'),
//                       _buildDocumentItem('Valid UK Visa with work rights'),
//                       _buildDocumentItem('Home Office approval letter'),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // Additional note
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: lightBlue.withOpacity(0.3),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: accentBlue.withOpacity(0.2),
//                       width: 1,
//                     ),
//                   ),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(
//                         CupertinoIcons.exclamationmark_circle_fill,
//                         size: 20,
//                         color: accentBlue,
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           'Documents must be current and show your right to work in the UK. Expired documents cannot be accepted.',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: textSecondary,
//                             height: 1.5,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // Privacy and security note
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: lightBlue.withOpacity(0.3),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: primaryBlue.withOpacity(0.1),
//                       width: 1,
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       Icon(
//                         CupertinoIcons.lock_shield,
//                         size: 24,
//                         color: primaryBlue,
//                       ),
//                       const SizedBox(height: 12),
//                       Text(
//                         'Your Privacy Matters',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: textPrimary,
//                           letterSpacing: 0.2,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Your documents are encrypted end-to-end and stored securely in compliance with GDPR regulations. We never share your immigration status with third parties.',
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: textSecondary,
//                           height: 1.5,
//                           letterSpacing: 0.1,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 40),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBenefitItem(IconData icon, String text, Color color) {
//     return Row(
//       children: [
//         Icon(
//           icon,
//           size: 16,
//           color: color,
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Text(
//             text,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               color: Color(0xFF424242),
//               letterSpacing: 0.1,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDocumentItem(String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.only(top: 3),
//             child: Icon(
//               CupertinoIcons.smallcircle_fill_circle,
//               size: 8,
//               color: Color(0xFF757575),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(
//                 fontSize: 14,
//                 color: Color(0xFF424242),
//                 height: 1.4,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskova_new/View/Language/language_provider.dart';

class RightToWork extends StatelessWidget {
  const RightToWork({super.key});

  @override
  Widget build(BuildContext context) {
    final appLanguage = Provider.of<AppLanguage>(context);
    
    // Professional color scheme
    const Color primaryBlue = Color(0xFF1565C0);
    const Color accentBlue = Color(0xFF2196F3);
    const Color lightBlue = Color(0xFFE3F2FD);
    const Color darkBlue = Color(0xFF0D47A1);
    const Color successGreen = Color(0xFF4CAF50);
    const Color textPrimary = Color(0xFF212121);
    const Color textSecondary = Color(0xFF757575);
    const Color backgroundColor = Color(0xFFFAFAFA);

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: primaryBlue,
        border: null,
        middle: Text(
          appLanguage.get('Right_to_Work_Verification'),
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.white,
            size: 24,
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // Professional header section
                Center(
                  child: Column(
                    children: [
                      // Logo container with professional styling
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryBlue.withOpacity(0.1),
                              accentBlue.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(60),
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.2),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(58),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(58),
                            ),
                            child: Image.asset(
                              'assets/appicon-removebg-preview.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Trust indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: successGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.checkmark_seal_fill,
                              size: 16,
                              color: successGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              appLanguage.get('Legal_Compliance'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: successGreen,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Professional title
                Text(
                  appLanguage.get('Proof_of_Right_to_Work_in_the_UK'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  appLanguage.get('Verify_your_work_eligibility_to_continue'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 32),

                // Professional content card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              CupertinoIcons.info_circle_fill,
                              size: 20,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            appLanguage.get('Legal_Requirement'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Main explanation
                      Text(
                        appLanguage.get('To_work_legally_as_a_delivery_driver_with_Taskova_you_must_have_the_Right_to_Work_in_the_UK_This_verification_ensures_compliance_with_UK_employment_laws_and_helps_maintain_a_fair_lawful_working_environment_for_all_drivers_on_our_platform'),
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: textPrimary,
                          letterSpacing: 0.1,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Benefits list
                      _buildBenefitItem(
                        CupertinoIcons.checkmark_seal_fill,
                        appLanguage.get('Mandatory_for_all_UK_workers'),
                        successGreen,
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(
                        CupertinoIcons.shield_fill,
                        appLanguage.get('Ensures_legal_compliance'),
                        successGreen,
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(
                        CupertinoIcons.lock_fill,
                        appLanguage.get('Protects_against_unlawful_employment'),
                        successGreen,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Accepted documents section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: lightBlue.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_alt_circle_fill,
                            size: 20,
                            color: successGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            appLanguage.get('Accepted_Documents'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDocumentItem(appLanguage.get('UK_Passport')),
                      _buildDocumentItem(appLanguage.get('Biometric_Residence_Permit')),
                      _buildDocumentItem(appLanguage.get('UK_Birth_Certificate_NI_Number')),
                      _buildDocumentItem(appLanguage.get('EU_EEA_Passport_or_ID_Card')),
                      _buildDocumentItem(appLanguage.get('Valid_UK_Visa_with_work_rights')),
                      _buildDocumentItem(appLanguage.get('Home_Office_approval_letter')),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Additional note
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accentBlue.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_circle_fill,
                        size: 20,
                        color: accentBlue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          appLanguage.get('Documents_must_be_current_and_show_your_right_to_work_in_the_UK_Expired_documents_cannot_be_accepted'),
                          style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Privacy and security note
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: lightBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryBlue.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        CupertinoIcons.lock_shield,
                        size: 24,
                        color: primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        appLanguage.get('Your_Privacy_Matters'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appLanguage.get('Your_documents_are_encrypted_end-to-end_and_stored_securely_in_compliance_with_GDPR_regulations_We_never_share_your_personal_information_with_third_parties'),
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                          height: 1.5,
                          letterSpacing: 0.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              CupertinoIcons.smallcircle_fill_circle,
              size: 8,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF424242),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}