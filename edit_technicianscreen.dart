import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTechnicianScreen extends StatefulWidget {
  final String techId;
  final Map<String, dynamic> techData;

  const EditTechnicianScreen({super.key, required this.techId, required this.techData});

  @override
  _EditTechnicianScreenState createState() => _EditTechnicianScreenState();
}

class _EditTechnicianScreenState extends State<EditTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _serviceTypeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.techData['name']);
    _emailController = TextEditingController(text: widget.techData['email']);
    _phoneController = TextEditingController(text: widget.techData['phone']);
    _serviceTypeController = TextEditingController(text: widget.techData['serviceType']);
  }

  Future<void> _updateTechnician() async {
    if (_formKey.currentState!.validate()) {
      await _firestore.collection('technicians').doc(widget.techId).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'serviceType': _serviceTypeController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Technician Updated Successfully!")),
      );

      Navigator.pop(context); // Return to Admin Dashboard
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _serviceTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Technician")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (value) => value!.isEmpty ? "Enter Name" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (value) => value!.isEmpty ? "Enter Email" : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? "Enter Phone Number" : null,
              ),
              TextFormField(
                controller: _serviceTypeController,
                decoration: const InputDecoration(labelText: "Service Type"),
                validator: (value) => value!.isEmpty ? "Enter Service Type" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateTechnician,
                child: const Text("Update Technician"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
