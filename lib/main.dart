import 'package:flutter/material.dart';
import 'package:mecca/features/companies/ui/company_notifier.dart';

import 'app/app.dart';

void main() {
  final companyNotifier = CompanyNotifier();
  runApp(App(companyNotifier: companyNotifier));
}
