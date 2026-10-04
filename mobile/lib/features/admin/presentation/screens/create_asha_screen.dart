import 'package:flutter/material.dart';
import '../controllers/admin_controller.dart';

class CreateAshaScreen extends StatefulWidget {
  final AdminController adminController;

  const CreateAshaScreen({super.key, required this.adminController});

  @override
  State<CreateAshaScreen> createState() => _CreateAshaScreenState();
}

class _CreateAshaScreenState extends State<CreateAshaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _workerCodeController = TextEditingController();
  final _areaController = TextEditingController();
  final _phcController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _workerCodeController.dispose();
    _areaController.dispose();
    _phcController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await widget.adminController.createAsha(
      email: _emailController.text.trim(),
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      workerIdCode: _workerCodeController.text.trim().isNotEmpty ? _workerCodeController.text.trim() : null,
      assignedArea: _areaController.text.trim().isNotEmpty ? _areaController.text.trim() : null,
      primaryHealthCenter: _phcController.text.trim().isNotEmpty ? _phcController.text.trim() : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ASHA worker account provisioned successfully.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = widget.adminController.status == AdminStateStatus.loading;
    final errorMessage = widget.adminController.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provision ASHA Worker'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ASHA Healthcare Worker Account',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create an authorized community healthcare worker account with temporary credentials.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
                ),
                const SizedBox(height: 20),

                if (errorMessage != null && errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[900]?.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[700]!),
                    ),
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red[200], fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  key: const Key('asha_fullname_field'),
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name (e.g. Priya Devi)*',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Please enter full name.' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  key: const Key('asha_email_field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'ASHA Email Address*',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email.' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  key: const Key('asha_phone_field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  key: const Key('asha_workercode_field'),
                  controller: _workerCodeController,
                  decoration: const InputDecoration(
                    labelText: 'ASHA Worker Code / ID',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  key: const Key('asha_area_field'),
                  controller: _areaController,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Village / Ward / Area',
                    prefixIcon: Icon(Icons.map_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  key: const Key('asha_phc_field'),
                  controller: _phcController,
                  decoration: const InputDecoration(
                    labelText: 'Primary Health Center (PHC)',
                    prefixIcon: Icon(Icons.location_city_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  key: const Key('asha_provision_submit_button'),
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF14B8A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Provision ASHA Account',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
