import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mecca/core/theme/app_colors.dart';
import 'package:mecca/core/widgets/empty_screen_widget.dart';
import 'package:mecca/core/widgets/error_message_widget.dart';
import 'package:mecca/features/companies/ui/create_company_page.dart';
import 'package:mecca/features/jobs/ui/jobs_page.dart';
import 'package:mecca/features/jobs/ui/job_notifier.dart';

import 'company_notifier.dart';

class CompaniesPage extends StatefulWidget {
  const CompaniesPage({super.key, required this.companyNotifier});

  final CompanyNotifier companyNotifier;

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  @override
  void initState() {
    super.initState();
    widget.companyNotifier.loadCompanies();
  }

  Future<bool> _confirmDeleteDraftJob() async {
    final shouldDelete = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar Empresa',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Tota la información contenida en esta empresa se perderá ¿Esta seguro que lo quiere eliminar?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Eliminar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
    return shouldDelete ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.settings),
        title: const Text(
          'MECCA',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: AnimatedBuilder(
        animation: widget.companyNotifier,
        builder: (context, _) {
          Widget child;

          if (widget.companyNotifier.isLoading) {
            child = const Center(child: CircularProgressIndicator());
          } else if (widget.companyNotifier.error != null) {
            child = ErrorMessageWidget(
              text: widget.companyNotifier.error!,
              onPressed: widget.companyNotifier.loadCompanies,
            );
          } else if (widget.companyNotifier.companies.isEmpty) {
            child = EmptyScreenWidget(
              title: 'Todaía no hay empresas agregadas.',
              gift: 'assets/images/factory.png',
            );
          } else {
            child = ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: widget.companyNotifier.companies.length,
              itemBuilder: (context, index) {
                final company = widget.companyNotifier.companies[index];
                return GestureDetector(
                  onLongPress: () async {
                    final shouldDelete = await _confirmDeleteDraftJob();
                    if (!shouldDelete) {
                      return;
                    }

                    await widget.companyNotifier.deleteCompany(company.id!);

                    if (!mounted) {
                      return;
                    }
                  },
                  onTap: () {
                    final jobNotifier = JobNotifier(companyId: company.id!);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JobsPage(
                          company: company,
                          jobNotifier: jobNotifier,
                          companyNotifier: widget.companyNotifier,
                        ),
                      ),
                    );
                  },
                  onDoubleTap: () {
                    if (company.email == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Correo inválido o vacío'),
                        ),
                      );
                      return;
                    }
                    Clipboard.setData(ClipboardData(text: company.email!));

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Correo copiado')),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        if (company.email != null && company.email!.isNotEmpty)
                          Text(
                            'Correo: ${company.email}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        Text(
                          'Balance: ${company.minutesBalance} min',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => SizedBox(height: 12),
            );
          }

          return RefreshIndicator(
            onRefresh: widget.companyNotifier.refresh,
            child: child is ListView
                ? child
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 240),
                      Center(child: child),
                    ],
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CreateCompanyPage(companyNotifier: widget.companyNotifier),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
