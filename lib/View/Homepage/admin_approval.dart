import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:taskova_new/View/BottomNavigation/bottomnavigation.dart';
import 'package:taskova_new/View/Language/language_provider.dart';

class DocumentVerificationPendingScreen extends StatefulWidget {
  const DocumentVerificationPendingScreen({Key? key}) : super(key: key);

  @override
  State<DocumentVerificationPendingScreen> createState() => _DocumentVerificationPendingScreenState();
}

class _DocumentVerificationPendingScreenState extends State<DocumentVerificationPendingScreen> {
  late AppLanguage appLanguage;

  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
  }
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1A535C),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // App Logo
                  Center(
                    child: Text(
                      appLanguage.get('app_name'),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Verification Illustration
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Lottie.asset(
                        'assets/Animation - 1745663024143.json',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Verification Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        Text(
                          appLanguage.get("Your_Document_Verification_is_in_Progress"),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                color: CupertinoColors.systemYellow,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.clock,
                                    color: CupertinoColors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    appLanguage.get("Pending"),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          appLanguage.get("Our_team_is_reviewing_your_submitted_documents._We'll_notify_you_once_the_verification_is_complete."),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: CupertinoColors.white.withOpacity(0.9),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Go to Homepage Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: CupertinoButton(
                      onPressed: () {
                        // Use the root navigator to replace the entire stack
                        Navigator.of(context, rootNavigator: true)
                            .pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const MainWrapper(),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.home,
                            color: const Color(0xFF1A535C),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            appLanguage.get("Go_to_Homepage"),
                            style: TextStyle(
                              color: const Color(0xFF1A535C),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Estimated Time
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CupertinoColors.white.withOpacity(0.2),
                      ),
                    ),
                    margin: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 24,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.clock,
                            color: CupertinoColors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                               appLanguage.get ("Please_wait"),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CupertinoColors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          onPressed: () {
                            // Contact support action
                          },
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: CupertinoColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          child: Text(
                            appLanguage.get("Contact_Support"),
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}