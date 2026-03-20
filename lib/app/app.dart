import 'package:flutter/material.dart';
import 'package:mecca/core/theme/app_theme.dart';
import 'package:mecca/features/companies/ui/companies_page.dart';
import 'package:mecca/features/companies/ui/company_notifier.dart';

class App extends StatelessWidget {
  const App({super.key, required this.companyNotifier});

  final CompanyNotifier companyNotifier;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mecca',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: CompaniesPage(companyNotifier: companyNotifier),
    );
  }
}
