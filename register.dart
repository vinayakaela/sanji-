import 'package:flutter/material.dart';
import 'admin_ui.dart';

class MyRegister extends StatefulWidget {
  const MyRegister({super.key});

  @override
  _MyRegisterState createState() => _MyRegisterState();
}

class _MyRegisterState extends State<MyRegister> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serviceTypeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  String _selectedRole = 'user';
  bool _isLoading = false;
  bool _isPasswordHidden = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _serviceTypeController.dispose();
    _descriptionController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);

    final String name = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String serviceType = _serviceTypeController.text.trim();
    final String description = _descriptionController.text.trim();
    final int experienceYears = int.tryParse(_experienceController.text.trim()) ?? 0;

    String? result = await AuthService().signup(
      name: name,
      email: email,
      password: password,
      role: _selectedRole,
      serviceType: serviceType,
      description: description,
      experienceYears: experienceYears,
    );

    setState(() => _isLoading = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful!")),
      );
      Navigator.pushNamed(context, 'login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $result")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        title: const Text("Register"),
        backgroundColor: Colors.blueGrey[800],
        centerTitle: true,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(_usernameController, "Name", Icons.person),
                  const SizedBox(height: 15),
                  _buildTextField(_emailController, "Email", Icons.email),
                  const SizedBox(height: 15),
                  _buildPasswordField(),
                  const SizedBox(height: 20),
                  _buildDropdown(),
                  if (_selectedRole == 'technician') ...[
                    const SizedBox(height: 15),
                    _buildTextField(_serviceTypeController, "Service Type", Icons.build),
                    const SizedBox(height: 15),
                    _buildTextField(_descriptionController, "Description", Icons.description),
                    const SizedBox(height: 15),
                    _buildTextField(_experienceController, "Years of Experience", Icons.timelapse, isNumber: true),
                  ],
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Register", style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, 'login'),
                    child: const Text("Already have an account? Sign In"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _isPasswordHidden,
      decoration: InputDecoration(
        labelText: "Password",
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      onChanged: (newValue) => setState(() => _selectedRole = newValue!),
      items: ['user', 'technician']
          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
          .toList(),
      decoration: InputDecoration(
        labelText: "Role",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}