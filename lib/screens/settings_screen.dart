import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_app/screens/sign%20in%20page/sign_in_page.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  Future<void> _cleanupUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'lastSeen': FieldValue.serverTimestamp(),
            'isOnline': false,
          });
        } catch (e) {
          await _firestore.collection('sellers').doc(user.uid).update({
            'lastSeen': FieldValue.serverTimestamp(),
            'isOnline': false,
          });
        }
      }
    } catch (e) {
      print('Error cleaning up user data: $e');
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Show loading indicator first
      if (mounted) {
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) => const CupertinoAlertDialog(
            content: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CupertinoActivityIndicator(),
              ),
            ),
          ),
        );
      }

      // Perform sign out operations
      await _cleanupUserData();
      await _auth.signOut();

      // Navigate to login screen
      if (mounted) {
        // Pop the loading dialog first
        Navigator.of(context).pop();
        
        // Then navigate to login screen
        await Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(
            builder: (context) => LoginPage(
          
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // Handle error safely
      if (mounted) {
        // Pop the loading dialog if it's showing
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        
        // Show error dialog
        await showCupertinoDialog(
          context: context,
          builder: (BuildContext dialogContext) => CupertinoAlertDialog(
            title: const Text('Sign Out Error'),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSignOutConfirmation(BuildContext context) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: _isLoading
                ? null
                : () async {
                    Navigator.pop(dialogContext);
                    await _handleSignOut(context);
                  },
            child: const Text('Sign Out'),
          ),
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(dialogContext),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: '.SF Pro Display', // iOS system font
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none, // Remove underline
          ),
        ),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
      ),
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            children: [
              // Updated Email Section
              CupertinoListSection.insetGrouped(
                backgroundColor: CupertinoColors.systemGroupedBackground,
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                children: [
                  if (user?.email != null)
                    CupertinoListTile.notched(
                      title: const Text(
                        'Email',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 16,
                          color: CupertinoColors.label,
                          decoration: TextDecoration.none, // Remove underline
                        ),
                      ),
                      trailing: Text(
                        user!.email!,
                        style: const TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 15,
                          color: CupertinoColors.secondaryLabel,
                          decoration: TextDecoration.none, // Remove underline
                        ),
                      ),
                      backgroundColor: CupertinoColors.systemBackground,
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Updated Info Section
              CupertinoListSection.insetGrouped(
                backgroundColor: CupertinoColors.systemGroupedBackground,
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                children: [  if (user != null)
                    CupertinoListTile.notched(
                      title: const Text(
                        'Account ID',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 16,
                          color: CupertinoColors.label,
                          decoration: TextDecoration.none, // Remove underline
                        ),
                      ),
                      trailing: Text(
                        user.uid,
                        style: const TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 15,
                          color: CupertinoColors.secondaryLabel,
                          decoration: TextDecoration.none, // Remove underline
                        ),
                      ),
                      backgroundColor: CupertinoColors.systemBackground,
                    ),
                  const CupertinoListTile.notched(
                    title: Text(
                      'Version',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 16,
                        color: CupertinoColors.label,
                        decoration: TextDecoration.none, // Remove underline
                      ),
                    ),
                    trailing: Text(
                      '1.0.0',
                      style: TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 15,
                        color: CupertinoColors.secondaryLabel,
                        decoration: TextDecoration.none, // Remove underline
                      ),
                    ),
                    backgroundColor: CupertinoColors.systemBackground,
                  ),

                
                ],
              ),

              const SizedBox(height: 20),

              // Updated Sign Out Section
              CupertinoListSection.insetGrouped(
                backgroundColor: CupertinoColors.systemGroupedBackground,
                margin: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: CupertinoColors.secondarySystemGroupedBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                children: [
                  CupertinoListTile.notched(
                    onTap: _isLoading ? null : () => _showSignOutConfirmation(context),
                    title: const Center(
                      child: Text(
                        'Sign Out',
                        style: TextStyle(
                          fontFamily: '.SF Pro Text',
                          fontSize: 16,
                          color: CupertinoColors.destructiveRed,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.none, // Remove underline
                        ),
                      ),
                    ),
                    backgroundColor: CupertinoColors.systemBackground,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
