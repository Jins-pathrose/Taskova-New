import 'package:flutter/cupertino.dart';
import 'package:taskova_new/View/Language/language_provider.dart';
import 'package:taskova_new/View/Profile/edit_profile.dart';

class SettingsDrawer extends StatelessWidget {
  final AppLanguage appLanguage;
  final Color primaryBlue;
  final VoidCallback onEdit;
  final VoidCallback onAppliedJobs;
  final VoidCallback onChangePassword;
  final VoidCallback onLanguage;
  final VoidCallback onLogout;

  const SettingsDrawer({
    Key? key,
    required this.appLanguage,
    required this.primaryBlue,
    required this.onEdit,
    required this.onAppliedJobs,
    required this.onChangePassword,
    required this.onLanguage,
    required this.onLogout,
  }) : super(key: key);

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top:
              isFirst
                  ? BorderSide.none
                  : BorderSide(
                    color: CupertinoColors.separator.withOpacity(0.3),
                    width: 0.5,
                  ),
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 16, 20, isLast ? 20 : 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      isDestructive
                          ? CupertinoColors.destructiveRed.withOpacity(0.1)
                          : iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color:
                      isDestructive
                          ? CupertinoColors.destructiveRed
                          : iconColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDestructive
                                ? CupertinoColors.destructiveRed
                                : CupertinoColors.black,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: CupertinoColors.systemGrey2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: double.infinity,
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(-2, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, primaryBlue.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appLanguage.get('account_settings'),
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: CupertinoColors.white.withOpacity(0.8),
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildSettingsItem(
                      icon: CupertinoIcons.pencil,
                      title: appLanguage.get('edit_profile'),
                      subtitle: appLanguage.get(
                        'Modify_your_personal_information',
                      ),
                      iconColor: primaryBlue,
                      isFirst: true,
                      onTap: () {
                        Navigator.pop(context); // Close the drawer
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => EditProfilePage(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsItem(
                      icon: CupertinoIcons.briefcase,
                      title: appLanguage.get('applied_jobs'),
                      subtitle: appLanguage.get('View_jobs_you’ve_applied_for'),
                      iconColor: Color.fromARGB(255, 15, 159, 242),
                      onTap: onAppliedJobs,
                    ),
                    _buildSettingsItem(
                      icon: CupertinoIcons.person,
                      title: appLanguage.get('support_help'),
                      subtitle: appLanguage.get(
                        'Access_help_resources_or_contact_support',
                      ),
                      iconColor: Color.fromARGB(255, 103, 215, 154),
                      onTap: () {},
                    ),
                    _buildSettingsItem(
                      icon: CupertinoIcons.shield_fill,
                      title: appLanguage.get('Privacy_Settings'),
                      subtitle: appLanguage.get(
                        'Adjust_privacy_options,_such_as_location_sharing_or_data_usage',
                      ),
                      iconColor: Color.fromARGB(255, 230, 91, 45),
                      onTap: () {},
                    ),
                    // _buildSettingsItem(
                    //   icon: CupertinoIcons.lock_fill,
                    //   title: appLanguage.get('change_password'),
                    //   subtitle: appLanguage.get('Update_your_account_password'),
                    //   iconColor: CupertinoColors.systemBlue,
                    //   onTap: onChangePassword,
                    // ),
                    _buildSettingsItem(
                      icon: CupertinoIcons.globe,
                      title: appLanguage.get('language'),
                      subtitle: appLanguage.get(
                        'Choose_your_preferred_language',
                      ),
                      iconColor: CupertinoColors.systemPurple,
                      onTap: onLanguage,
                    ),
                    _buildSettingsItem(
                      icon: CupertinoIcons.square_arrow_right,
                      title: appLanguage.get('logout'),
                      subtitle: appLanguage.get('Sign_out_of_your_account'),
                      iconColor: CupertinoColors.destructiveRed,
                      isDestructive: true,
                      isLast: true,
                      onTap: onLogout,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}