import 'package:flutter/material.dart';
import 'package:mecca/core/widgets/custom_textform_field.dart';
import 'package:mecca/features/companies/domain/company.dart';
import 'package:mecca/features/companies/ui/company_notifier.dart';

class CreateCompanyPage extends StatefulWidget {
  const CreateCompanyPage({super.key, required this.companyNotifier});

  final CompanyNotifier companyNotifier;

  @override
  State<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends State<CreateCompanyPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final company = Company(
      id: null,
      email: _emailController.text.trim(),
      name: _nameController.text.trim(),
      minutesBalance: 0,
    );

    await widget.companyNotifier.createCompany(company);

    if (!mounted) {
      return;
    }

    if (widget.companyNotifier.error == null) {
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(widget.companyNotifier.error!)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            style: ButtonStyle(iconSize: WidgetStatePropertyAll(30)),
          ),
          title: const Text(
            'Registrar empresa',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        body: AnimatedBuilder(
          animation: widget.companyNotifier,
          builder: (context, _) {
            final isLoading = widget.companyNotifier.isLoading;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextformField(
                      controller: _nameController,
                      label: 'Name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextformField(
                      controller: _emailController,
                      label: 'Email (opcional)',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null; // es opcional
                        }

                        final email = value.trim();

                        final emailRegex = RegExp(
                          r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@"
                          r"[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+$",
                        );

                        if (!emailRegex.hasMatch(email)) {
                          return 'Formato de correo inválido';
                        }

                        final domain = email.split('@').last;
                        final domainParts = domain.split('.');

                        for (final part in domainParts) {
                          if (part.startsWith('-') || part.endsWith('-')) {
                            return 'Dominio inválido';
                          }
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.save, size: 24),
                        onPressed: isLoading ? null : _save,
                        label: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
