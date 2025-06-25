import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:taskova_new/Model/Onboarding/onboarding.dart';
import 'package:taskova_new/View/Authentication/login.dart';
import 'package:taskova_new/View/Language/language_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int currentIndex = 0;
  late List<OnboardingModel> pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _initializePages(BuildContext context) {
    final appLanguage = Provider.of<AppLanguage>(context, listen: false);
    pages = [
      OnboardingModel(
        image: 'assets/undraw_delivery-truck_mjui.png',
        title: appLanguage.get('quick_sign_up_start_earning'),
        description: appLanguage.get('register_in_minutes_and_start_accepting_delivery_jobs_right_away'),
      ),
      OnboardingModel(
        image: 'assets/undraw_take-out-boxes_n094.png',
        title: appLanguage.get('smart_location_matching'),
        description: appLanguage.get('get_delivery_tasks_based_on_your_current_location_no_need_to_travel_far'),
      ),
      OnboardingModel(
        image: 'assets/undraw_package-arrived_twqd.png',
        title: appLanguage.get('join_a_trusted_network'),
        description: appLanguage.get('be_part_of_a_growing_community_of_verified_and_reliable_delivery_partners'),
      ),
    ];
  }

  void _goToNextPage() {
    if (currentIndex < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  Widget _buildPage(OnboardingModel model) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(model.image, height: 300),
        const SizedBox(height: 30),
        Text(
          model.title,
          style: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
            model.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: const Color.fromARGB(255, 102, 101, 101),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pages.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentIndex == index ? 12 : 8,
          height: currentIndex == index ? 12 : 8,
          decoration: BoxDecoration(
            color: currentIndex == index ? Colors.blue : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize pages with current language
    _initializePages(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => currentIndex = index),
                itemBuilder: (context, index) => _buildPage(pages[index]),
              ),
            ),
            _buildDots(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      Provider.of<AppLanguage>(context).get('skip'),
                      style: GoogleFonts.outfit(fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _goToNextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 25,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      currentIndex == pages.length - 1
                          ? Provider.of<AppLanguage>(context).get('get_started')
                          : Provider.of<AppLanguage>(context).get('next'),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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