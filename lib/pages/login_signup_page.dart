import 'package:flutter/material.dart';
import '/api_service.dart';
import 'admin_page.dart';
import 'client_page.dart';
import 'constructor_page.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class LoginSignupPage extends StatefulWidget {
  const LoginSignupPage({super.key});

  @override
  State<LoginSignupPage> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _loginUsername = TextEditingController();
  final _loginPassword = TextEditingController();

  final _signupUsername = TextEditingController();
  final _signupPassword = TextEditingController();
  final _signupConfirmPassword = TextEditingController();
  final _signupEmail = TextEditingController();
  String _signupRole = 'CLIENT';

  int _selectedScreen = 0; // 0: welcome, 1: login, 2: signup

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _handleLogin() async {
    if (_loginUsername.text.isEmpty || _loginPassword.text.isEmpty) {
      _showError('Please enter username and password');
      return;
    }

    String? role = await ApiService.login(_loginUsername.text, _loginPassword.text);

    if (role == 'ADMIN') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPage()));
    } else if (role == 'CLIENT') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ClientPage(clientName: _loginUsername.text)));
    } else if (role == 'CONSTRUCTOR') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ConstructorPage(constructorName: _loginUsername.text)));
    } else {
      _showError('Login failed');
    }
  }

  void _handleRegister() async {
    if (_signupUsername.text.isEmpty ||
        _signupPassword.text.isEmpty ||
        _signupConfirmPassword.text.isEmpty ||
        _signupEmail.text.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    if (_signupPassword.text != _signupConfirmPassword.text) {
      _showError('Passwords do not match');
      return;
    }

    bool registered = await ApiService.register(
      _signupUsername.text,
      _signupPassword.text,
      _signupRole,
      _signupEmail.text,
    );

    if (registered) {
      _showError('Registration successful! Please login');
      setState(() {
        _selectedScreen = 1; // Go to login
        _signupUsername.clear();
        _signupPassword.clear();
        _signupConfirmPassword.clear();
        _signupEmail.clear();
        _signupRole = 'CLIENT';
      });
    } else {
      _showError('Registration failed');
    }
  }

  Widget _buildAnimatedText() {
    return SizedBox(
      height: 40,
      child: AnimatedTextKit(
        animatedTexts: [
          ColorizeAnimatedText(
            'Karibu Construction System!',
            textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            colors: [Colors.blue, Colors.orange, Colors.green, Colors.purple],
          ),
          ColorizeAnimatedText(
            'Jenga, Tafuta, Fanya kazi na Wataalamu!',
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            colors: [Colors.red, Colors.yellow, Colors.blue, Colors.green],
          ),
        ],
        repeatForever: true,
        isRepeatingAnimation: true,
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAnimatedText(),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Construction System',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage your construction projects easily!',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedScreen = 1),
              icon: const Icon(Icons.login),
              label: const Text('Already have account? Sign in here'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() => _selectedScreen = 2),
              icon: const Icon(Icons.app_registration),
              label: const Text('New signup here'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Login',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _loginUsername,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _loginPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _handleLogin,
              icon: const Icon(Icons.login),
              label: const Text('Login'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _selectedScreen = 2),
              child: const Text(
                "New signup here",
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedScreen = 0),
              child: const Text(
                "Back to welcome",
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupForm() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sign Up',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _signupEmail,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _signupUsername,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _signupPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _signupConfirmPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _signupRole,
              decoration: InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'CLIENT', child: Text('Client')),
                DropdownMenuItem(value: 'CONSTRUCTOR', child: Text('Constructor')),
              ],
              onChanged: (value) {
                setState(() {
                  _signupRole = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _handleRegister,
              icon: const Icon(Icons.save),
              label: const Text('Sign Up & Save'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _selectedScreen = 1),
              child: const Text(
                "Already have account? Sign in here",
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedScreen = 0),
              child: const Text(
                "Back to welcome",
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images.jpeg', fit: BoxFit.cover),
          Container(color: Colors.black.withOpacity(0.6)),
          Center(
            child: SingleChildScrollView(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _selectedScreen == 0
                    ? _buildWelcomeScreen()
                    : _selectedScreen == 1
                        ? _buildLoginForm()
                        : _buildSignupForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}