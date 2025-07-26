import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taskova_new/Model/Analysis/monthlyjobcount.dart';
import 'package:taskova_new/Model/api_config.dart';
import 'package:taskova_new/View/Authentication/forgot_password.dart';
import 'package:taskova_new/View/Authentication/login.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/View/Profile/drawer.dart';
import 'package:taskova_new/View/Profile/edit_profile.dart';
import 'package:taskova_new/View/Profile/graph.dart';
import 'package:taskova_new/View/appliedjobs.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _drivingDurationController =
      TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? _selectedAddress;
  double? _latitude;
  double? _longitude;

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;

  final Color primaryBlue = Color(0xFF1A5DC1);
  final Color lightBlue = Color(0xFFE6F0FF);
  final Color accentBlue = Color(0xFF0E4DA4);
  final Color whiteColor = CupertinoColors.white;
  List<MonthlyJobCount> _monthlyJobCounts = [];
bool _isLoadingChart = false;
  late AppLanguage appLanguage;
  String? _selectedMonth;
List<MonthlyJobCount> _filteredJobCounts = [];

  @override
  void initState() {
    super.initState();
    appLanguage = Provider.of<AppLanguage>(context, listen: false);
    _loadProfileData();
      _fetchMonthlyJobCounts(); // Add this line

  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('user_email');
      final accessToken = prefs.getString('access_token');

      setState(() {
        if (savedEmail != null && savedEmail.isNotEmpty) {
          _emailController.text = savedEmail;
        }
      });

      if (accessToken == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final url = Uri.parse(ApiConfig.driverProfileUrl);
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone_number'] ?? '';
          _selectedAddress = data['preferred_working_address'] ?? '';
          _addressController.text = _selectedAddress ?? '';
          _drivingDurationController.text = data['driving_duration'] ?? '';
          if (data.containsKey('latitude') && data.containsKey('longitude')) {
            _latitude = double.tryParse(data['latitude'].toString());
            _longitude = double.tryParse(data['longitude'].toString());
          }
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load profile data, but email is loaded from local storage.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading profile: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
Future<void> _fetchMonthlyJobCounts() async {
  setState(() {
    _isLoadingChart = true;
  });

  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse(ApiConfig.driverMonthlyJobCountUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _monthlyJobCounts = data.map((item) => MonthlyJobCount.fromJson(item)).toList();
        // Initialize with all data
        _filteredJobCounts = List.from(_monthlyJobCounts);
      });
    } else {
      throw Exception('Failed to load monthly job counts');
    }
  } catch (e) {
    print('Error fetching monthly job counts: $e');
  } finally {
    setState(() {
      _isLoadingChart = false;
    });
  }
}
void _filterDataByMonth(String? selectedMonth) {
  setState(() {
    _selectedMonth = selectedMonth;
    if (selectedMonth == null || selectedMonth == 'all') {
      _filteredJobCounts = List.from(_monthlyJobCounts);
    } else {
      _filteredJobCounts = _monthlyJobCounts
          .where((item) => item.month.startsWith(selectedMonth))
          .toList();
    }
  });
}
void _showMonthSelector() {
  showCupertinoModalPopup(
    context: context,
    builder: (context) => Container(
      height: 300,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Month',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Icon(
                    CupertinoIcons.xmark,
                    color: CupertinoColors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _getAvailableMonths().length,
              itemBuilder: (context, index) {
                final month = _getAvailableMonths()[index];
                final isSelected = _selectedMonth == month['value'];
                
                return CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    _filterDataByMonth(month['value']);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryBlue.withOpacity(0.1) : null,
                      border: Border(
                        bottom: BorderSide(
                          color: CupertinoColors.separator,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          month['label']!,
                          style: TextStyle(
                            color: isSelected ? primaryBlue : CupertinoColors.label,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            CupertinoIcons.check_mark,
                            color: primaryBlue,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
List<Map<String, String>> _getAvailableMonths() {
  final months = <Map<String, String>>[];
  
  // Add "All Months" option
  months.add({
    'label': 'All Months',
    'value': 'all',
  });
  
  // Get unique months from data
  final uniqueMonths = _monthlyJobCounts
      .map((item) => item.month.substring(0, 7)) // Get YYYY-MM part
      .toSet()
      .toList();
  
  uniqueMonths.sort((a, b) => b.compareTo(a)); // Sort descending (newest first)
  
  for (final month in uniqueMonths) {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final monthNum = int.parse(parts[1]);
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, monthNum));
    
    months.add({
      'label': monthName,
      'value': month,
    });
  }
  
  return months;
}
  void _showLanguageSelectionDialog() {
    String selectedLanguage = appLanguage.currentLanguage ?? 'en';
    showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  margin: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CupertinoTheme(
                    data: CupertinoThemeData(brightness: Brightness.light),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryBlue,
                                primaryBlue.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  CupertinoIcons.globe,
                                  color: CupertinoColors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  appLanguage.get('language'),
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Navigator.pop(context),
                                child: Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  color: CupertinoColors.white.withOpacity(0.8),
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: CupertinoScrollbar(
                            child: ListView.separated(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              itemCount: appLanguage.supportedLanguages.length,
                              separatorBuilder:
                                  (context, index) => Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    height: 0.5,
                                    color: CupertinoColors.separator,
                                  ),
                              itemBuilder: (context, index) {
                                final lang =
                                    appLanguage.supportedLanguages[index];
                                final isSelected =
                                    selectedLanguage == lang['code'];
                                return CupertinoButton(
                                  onPressed: () {
                                    setModalState(() {
                                      selectedLanguage = lang['code']!;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? primaryBlue.withOpacity(0.05)
                                              : CupertinoColors
                                                  .systemBackground,
                                      border:
                                          isSelected
                                              ? Border(
                                                left: BorderSide(
                                                  color: primaryBlue,
                                                  width: 4,
                                                ),
                                              )
                                              : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? primaryBlue.withOpacity(
                                                      0.1,
                                                    )
                                                    : CupertinoColors
                                                        .systemGrey6,
                                            borderRadius: BorderRadius.circular(
                                              25,
                                            ),
                                            border:
                                                isSelected
                                                    ? Border.all(
                                                      color: primaryBlue
                                                          .withOpacity(0.3),
                                                      width: 2,
                                                    )
                                                    : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              _getLanguageFlag(lang['code']!),
                                              style: TextStyle(fontSize: 24),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                lang['nativeName']!,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.w600
                                                          : FontWeight.w500,
                                                  color:
                                                      isSelected
                                                          ? primaryBlue
                                                          : CupertinoColors
                                                              .label,
                                                ),
                                              ),
                                              SizedBox(height: 3),
                                              Text(
                                                lang['name']!,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      CupertinoColors
                                                          .secondaryLabel,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            padding: EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: primaryBlue,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Icon(
                                              CupertinoIcons.check_mark,
                                              color: CupertinoColors.white,
                                              size: 16,
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: EdgeInsets.all(6),
                                            child: Icon(
                                              CupertinoIcons.chevron_right,
                                              color:
                                                  CupertinoColors.tertiaryLabel,
                                              size: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: CupertinoButton(
                              onPressed: () {
                                appLanguage.changeLanguage(selectedLanguage);
                                Navigator.pop(context);
                                setState(() {});
                              },
                              padding: EdgeInsets.symmetric(vertical: 16),
                              color: primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                              child: Text(
                                appLanguage.get('confirm'),
                                style: GoogleFonts.poppins(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  String _getLanguageFlag(String code) {
    switch (code) {
      case 'en':
        return '🇺🇸';
      case 'hi':
        return '🇮🇳';
      case 'pl':
        return '🇵🇱';
      case 'bn':
        return '🇧🇩';
      case 'ro':
        return '🇷🇴';
      case 'de':
        return '🇩🇪';
      default:
        return '🌐';
    }
  }

  

  Future<void> logout(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        CupertinoPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: Text("Error"),
              content: Text("Logout failed"),
              actions: [
                CupertinoDialogAction(
                  child: Text("OK"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
      );
    }
  }

  void _showLogoutConfirmation() {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoTheme(
            data: CupertinoThemeData(brightness: Brightness.light),
            child: CupertinoAlertDialog(
              title: Text(
                appLanguage.get('logout_confirmation'),
                style: TextStyle(color: primaryBlue),
              ),
              content: Text(appLanguage.get('are_you_sure_you_want_to_logout')),
              actions: [
                CupertinoDialogAction(
                  child: Text(
                    appLanguage.get('cancel'),
                    style: TextStyle(color: primaryBlue),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: Text(appLanguage.get('logout')),
                  onPressed: () {
                    Navigator.pop(context);
                    logout(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showSettingsDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: CupertinoColors.black.withOpacity(0.4),
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder:
          (context, animation, secondaryAnimation) => SettingsDrawer(
            appLanguage: appLanguage,
            primaryBlue: primaryBlue,
            onEdit: () {
              Navigator.pop(context);
              setState(() {
                _isEditing = true;
              });
            },
            onAppliedJobs:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AppliedJobsPage()),
                ),
            onChangePassword:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ForgotPasswordScreen(),
                  ),
                ),
            onLanguage: _showLanguageSelectionDialog,
            onLogout: _showLogoutConfirmation,
          ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        middle: Text(
          appLanguage.get('profile'),
          style: TextStyle(
            color: CupertinoColors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing:
            _isLoading
                ? null
                : CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    CupertinoIcons.gear,
                    color: primaryBlue,
                    size: 24,
                  ),
                  onPressed: _showSettingsDrawer,
                ),
      ),
      child:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(radius: 20),
                    SizedBox(height: 20),
                    Text(
                      appLanguage.get('loading_profile'),
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
              : CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      margin: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryBlue, accentBlue],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: -20,
                                      top: -20,
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.white
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 20,
                                      top: 40,
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.white
                                              .withOpacity(0.05),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 80,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: CupertinoColors.white,
                                          width: 4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: CupertinoColors.black
                                                .withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Icon(
                                          CupertinoIcons.person_solid,
                                          size: 40,
                                          color: primaryBlue,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 5,
                                      right: 5,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemGreen,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: CupertinoColors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(20, 50, 20, 20),
                            child: Column(
                              children: [
                                Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text
                                      : appLanguage.get('your_name'),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _emailController.text.isNotEmpty
                                      ? _emailController.text
                                      : appLanguage.get('your_email'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _phoneController.text.isNotEmpty
                                      ? _phoneController.text
                                      : appLanguage.get('your_phone'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.location_solid,
                                      size: 14,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        _selectedAddress ??
                                            appLanguage.get('set_location'),
                                        style: TextStyle(
                                          color: CupertinoColors.systemGrey,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGreen
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: CupertinoColors.systemGreen
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.checkmark_seal_fill,
                                        color: CupertinoColors.systemGreen,
                                        size: 16,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        appLanguage.get('active'),
                                        style: TextStyle(
                                          color: CupertinoColors.systemGreen,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
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
                  ),
                  if (_errorMessage != null)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.destructiveRed.withOpacity(
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: CupertinoColors.destructiveRed.withOpacity(
                              0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              CupertinoIcons.exclamationmark_triangle_fill,
                              color: CupertinoColors.destructiveRed,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: CupertinoColors.destructiveRed,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
  child: Container(
    margin: EdgeInsets.all(16),
    padding: EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: CupertinoColors.systemGrey.withOpacity(0.1),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              appLanguage.get('monthly_jobs'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.black,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              onPressed: _showMonthSelector,
              minSize: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    size: 16,
                    color: primaryBlue,
                  ),
                  SizedBox(width: 6),
                  Text(
                    _getSelectedMonthLabel(),
                    style: TextStyle(
                      color: primaryBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 14,
                    color: primaryBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        if (_isLoadingChart)
          Container(
            height: 200,
            child: Center(
              child: CupertinoActivityIndicator(radius: 14),
            ),
          )
        else if (_filteredJobCounts.isEmpty)
          Container(
            height: 200,
            child: Center(
              child: Text(
                appLanguage.get('no_job_data'),
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          Container(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: MonthlyJobsChartPainter(
                monthlyJobCounts: _filteredJobCounts,
                primaryColor: primaryBlue,
                showAll: _selectedMonth == null || _selectedMonth == 'all',
              ),
            ),
          ),
      ],
    ),
  ),
),
                ],
              ),
    );
  }
String _getSelectedMonthLabel() {
  if (_selectedMonth == null || _selectedMonth == 'all') {
    return 'All Months';
  }
  
  final parts = _selectedMonth!.split('-');
  final year = int.parse(parts[0]);
  final monthNum = int.parse(parts[1]);
  return DateFormat('MMM yyyy').format(DateTime(year, monthNum));
}
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    _drivingDurationController.dispose();
    super.dispose();
  }
}



class TimeoutException implements Exception {
  final String? message;
  TimeoutException(this.message);

  @override
  String toString() {
    return message ?? 'Request timed out';
  }
}
