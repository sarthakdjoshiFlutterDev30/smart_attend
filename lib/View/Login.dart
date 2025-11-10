import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_attend/View/Home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn');
    if (!mounted) return;
    if (isLoggedIn == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 960;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  Color.alphaBlend(
                    colorScheme.primary.withValues(alpha: 0.35),
                    colorScheme.surface,
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Card(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.all(isWide ? 36 : 28),
                      child: isWide
                          ? Row(
                              children: [
                                Expanded(child: _buildLoginHero(colorScheme)),
                                const SizedBox(width: 48),
                                Expanded(child: _buildLoginForm(onSubmit: _handleLogin)),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLoginHero(colorScheme, compact: true),
                                const SizedBox(height: 32),
                                _buildLoginForm(onSubmit: _handleLogin),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginHero(ColorScheme colorScheme, {bool compact = false}) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        );
    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.fact_check, size: 40, color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(height: 24),
        Text("Welcome 👋", style: headlineStyle, textAlign: compact ? TextAlign.center : TextAlign.start),
        const SizedBox(height: 12),
        Text(
          "Sign in to manage attendance, monitor sessions, and stay on top of your institute's activity.",
          style: subtitleStyle,
          textAlign: compact ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _FeatureChip(icon: Icons.shield_outlined, label: "Secure admin access"),
            _FeatureChip(icon: Icons.timeline, label: "Real-time insights"),
            _FeatureChip(icon: Icons.people_outline, label: "Student overview"),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginForm({required Future<void> Function() onSubmit}) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Admin Login",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            "Use your administrator credentials to access Smart Attend.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: "Email address",
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: password,
            obscureText: !_showPassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: "Password",
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : () {},
              child: const Text("Need help?"),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isLoading ? null : onSubmit,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login_rounded),
            label: Text(_isLoading ? "Signing in..." : "Sign in"),
          ),
          const SizedBox(height: 20),
          Text(
            "© 2025 Smart Attend. All rights reserved.",
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    if (email.text.trim().isEmpty || password.text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Enter your email and password")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (email.text.trim().toUpperCase() == "ADMIN" &&
          password.text.trim().toUpperCase() == "ADMIN123") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        if (!mounted) return;
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
        return;
      }

      messenger.showSnackBar(
        const SnackBar(content: Text("Email or password is incorrect")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
