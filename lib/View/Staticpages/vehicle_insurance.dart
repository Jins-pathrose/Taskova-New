// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';

// class VehicleInsurance extends StatelessWidget {
//   const VehicleInsurance({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Professional color scheme
//     const Color primaryBlue = Color(0xFF1565C0);
//     const Color accentBlue = Color(0xFF2196F3);
//     const Color lightBlue = Color(0xFFE3F2FD);
//     const Color darkBlue = Color(0xFF0D47A1);
//     const Color successGreen = Color(0xFF4CAF50);
//     const Color warningYellow = Color(0xFFFFC107);
//     const Color textPrimary = Color(0xFF212121);
//     const Color textSecondary = Color(0xFF757575);
//     const Color backgroundColor = Color(0xFFFAFAFA);

//     return CupertinoPageScaffold(
//       backgroundColor: backgroundColor,
//       navigationBar: CupertinoNavigationBar(
//         backgroundColor: primaryBlue,
//         border: null,
//         middle: const Text(
//           'Vehicle Verification',
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
//                               'Insurance Verification',
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
//                   'Vehicle Insurance Required',
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
//                   'Verify your vehicle insurance to continue',
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
//                             'Why we need this',
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
//                         'Taskova requires all drivers to provide valid Vehicle Insurance documentation to ensure compliance with UK law and protect both drivers and customers during deliveries. This verification helps maintain the safety and reliability of our delivery network.',
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
//                         'Legal requirement for all UK vehicles',
//                         successGreen,
//                       ),
//                       const SizedBox(height: 12),
//                       _buildBenefitItem(
//                         CupertinoIcons.shield_fill,
//                         'Financial protection in case of accidents',
//                         successGreen,
//                       ),
//                       const SizedBox(height: 12),
//                       _buildBenefitItem(
//                         CupertinoIcons.lock_fill,
//                         'Ensures compliance with delivery regulations',
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
//                       _buildDocumentItem('Certificate of Motor Insurance'),
//                       _buildDocumentItem('Insurance policy document'),
//                       _buildDocumentItem('Cover note (temporary insurance)'),
//                       _buildDocumentItem('Digital insurance certificate'),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 20),

//                 // Important notice
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: warningYellow.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: warningYellow.withOpacity(0.3),
//                       width: 1,
//                     ),
//                   ),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Icon(
//                         CupertinoIcons.exclamationmark_triangle_fill,
//                         size: 20,
//                         color: warningYellow,
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           'Your insurance must be valid for delivery work (hire and reward or business use). Standard personal insurance is not sufficient.',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: textPrimary,
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
//                         'Your insurance documents are encrypted end-to-end and stored securely in compliance with GDPR regulations. We never share your vehicle details with third parties.',
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

class VehicleInsurance extends StatelessWidget {
  const VehicleInsurance({super.key});

  @override
  Widget build(BuildContext context) {
    final appLanguage = Provider.of<AppLanguage>(context);
    
    // Professional color scheme
    const Color primaryBlue = Color(0xFF1565C0);
    const Color accentBlue = Color(0xFF2196F3);
    const Color lightBlue = Color(0xFFE3F2FD);
    const Color darkBlue = Color(0xFF0D47A1);
    const Color successGreen = Color(0xFF4CAF50);
    const Color warningYellow = Color(0xFFFFC107);
    const Color textPrimary = Color(0xFF212121);
    const Color textSecondary = Color(0xFF757575);
    const Color backgroundColor = Color(0xFFFAFAFA);

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: primaryBlue,
        border: null,
        middle: Text(
          appLanguage.get('Vehicle_Verification'),
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
                              appLanguage.get('Insurance_Verification'),
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
                  appLanguage.get('Vehicle_Insurance_Required'),
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
                  appLanguage.get('Verify_your_vehicle_insurance_to_continue'),
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
                            appLanguage.get('Why_we_need_this'),
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
                        appLanguage.get('Taskova_requires_all_drivers_to_provide_valid_Vehicle_Insurance_documentation_to_ensure_compliance_with_UK_law_and_protect_both_drivers_and_customers_during_deliveries_This_verification_helps_maintain_the_safety_and_reliability_of_our_delivery_network'),
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
                        appLanguage.get('Legal_requirement_for_all_UK_vehicles'),
                        successGreen,
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(
                        CupertinoIcons.shield_fill,
                        appLanguage.get('Financial_protection_in_case_of_accidents'),
                        successGreen,
                      ),
                      const SizedBox(height: 12),
                      _buildBenefitItem(
                        CupertinoIcons.lock_fill,
                        appLanguage.get('Ensures_compliance_with_delivery_regulations'),
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
                      _buildDocumentItem(appLanguage.get('Certificate_of_Motor_Insurance')),
                      _buildDocumentItem(appLanguage.get('Insurance_policy_document')),
                      _buildDocumentItem(appLanguage.get('Cover_note_temporary_insurance')),
                      _buildDocumentItem(appLanguage.get('Digital_insurance_certificate')),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Important notice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: warningYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: warningYellow.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        CupertinoIcons.exclamationmark_triangle_fill,
                        size: 20,
                        color: warningYellow,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          appLanguage.get('Your_insurance_must_be_valid_for_delivery_work_hire_and_reward_or_business_use_Standard_personal_insurance_is_not_sufficient'),
                          style: TextStyle(
                            fontSize: 14,
                            color: textPrimary,
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