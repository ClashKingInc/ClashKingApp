import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/core/models/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class AccountManagementPage extends StatefulWidget {
  @override
  AccountManagementPageState createState() => AccountManagementPageState();
}

class AccountManagementPageState extends State<AccountManagementPage> {
  bool _isLoading = false;

  // Form controllers for linking email
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _linkEmailAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.linkEmailAccount(
        _emailController.text.trim(),
        _passwordController.text,
        _usernameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.emailAccountLinkedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _usernameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.accountManagement),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;
          if (user == null) {
            return Center(child: Text('No user data available'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Section
                _buildUserInfoSection(user),

                SizedBox(height: 32),

                // Connected Accounts Section
                _buildConnectedAccountsSection(user),

                SizedBox(height: 32),

                // Link Accounts Section
                if (!user.hasEmailAuth) _buildLinkEmailSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfoSection(User user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(user.avatarUrl),
                  onBackgroundImageError: (_, __) {},
                  child: user.avatarUrl.isEmpty
                      ? Icon(Icons.person, size: 30)
                      : null,
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (user.email != null) ...[
                        SizedBox(height: 4),
                        Text(
                          user.email!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                      SizedBox(height: 4),
                      Text(
                        'User ID: ${user.userId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedAccountsSection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.connectedAccounts,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        SizedBox(height: 16),

        // Discord Account
        Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFF5865F2),
              child: Icon(Icons.discord, color: Colors.white),
            ),
            title: Text(AppLocalizations.of(context)!.discord),
            subtitle: Text(user.hasDiscordAuth
                ? AppLocalizations.of(context)!.connected
                : AppLocalizations.of(context)!.notConnected),
            trailing: user.hasDiscordAuth
                ? Icon(Icons.check_circle, color: Colors.green)
                : Icon(Icons.circle_outlined, color: Colors.grey),
          ),
        ),

        SizedBox(height: 8),

        // Email Account
        Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(Icons.email, color: Colors.white),
            ),
            title: Text(AppLocalizations.of(context)!.emailAndPassword),
            subtitle: Text(user.hasEmailAuth
                ? AppLocalizations.of(context)!.connected
                : AppLocalizations.of(context)!.notConnected),
            trailing: user.hasEmailAuth
                ? Icon(Icons.check_circle, color: Colors.green)
                : Icon(Icons.circle_outlined, color: Colors.grey),
          ),
        ),

        if (user.hasMultipleAuthMethods) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.security, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.accountSecuredMultipleAuth,
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLinkEmailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.linkEmailAccount,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.addEmailPasswordAuth,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.username,
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppLocalizations.of(context)!
                            .pleaseEnterUsername;
                      }
                      if (value.trim().length < 3) {
                        return AppLocalizations.of(context)!.usernameTooShort;
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.email,
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppLocalizations.of(context)!.pleaseEnterEmail;
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return AppLocalizations.of(context)!
                            .pleaseEnterValidEmail;
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.password,
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)!
                            .pleaseEnterPassword;
                      }
                      if (value.length < 8) {
                        return AppLocalizations.of(context)!.passwordTooShort;
                      }
                      // Check for uppercase, lowercase, digit, and special character
                      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(value)) {
                        return AppLocalizations.of(context)!.passwordRequirements;
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 24),

                  // Link Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _linkEmailAccount,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.link),
                                SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!
                                      .linkEmailAccount,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
