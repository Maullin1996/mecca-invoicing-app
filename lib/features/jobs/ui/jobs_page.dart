import 'package:flutter/material.dart';
import 'package:mecca/core/theme/app_colors.dart';
import 'package:mecca/core/widgets/empty_screen_widget.dart';
import 'package:mecca/core/widgets/error_message_widget.dart';
import 'package:mecca/features/jobs/ui/helpers/format_currency.dart';
import 'package:mecca/features/pdf/ui/pdf_prview_page.dart';

import 'package:mecca/features/companies/domain/company.dart';
import 'package:mecca/features/companies/ui/company_notifier.dart';
import 'package:mecca/features/jobs/domain/job.dart';
import 'package:mecca/features/jobs/ui/create_job_page.dart';
import 'package:mecca/features/jobs/ui/job_notifier.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({
    super.key,
    required this.company,
    required this.jobNotifier,
    required this.companyNotifier,
  });

  final Company company;
  final JobNotifier jobNotifier;
  final CompanyNotifier companyNotifier;

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  late Company _company;
  int? _generatingJobId;

  @override
  void initState() {
    super.initState();
    _company = widget.company;
    widget.jobNotifier.loadJobs();
  }

  Future<void> _generateAndPreviewPdf(Job job) async {
    if (_generatingJobId != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya se está generando un PDF')),
        );
      }
      return;
    }

    if (job.id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Job id es requerido')));
      return;
    }

    setState(() {
      _generatingJobId = job.id;
    });

    try {
      final bytes = await widget.jobNotifier.generatePdf(job);

      if (bytes == null) {
        throw Exception('No se pudo generar el PDF');
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfPreviewPage(pdfBytes: bytes)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _generatingJobId = null;
        });
      }
    }
  }

  Future<void> _handleDelete(Job job) async {
    final messenger = ScaffoldMessenger.of(context);

    final shouldDelete = await _customAlertDialog(
      title: 'Eliminar borrador',
      content: 'Este trabajo en estado draft se eliminará. ¿Deseas continuar?',
      buttonTitle: 'Eliminar',
    );

    if (!shouldDelete) return;

    await widget.jobNotifier.deleteDraftJob(job: job);

    if (!mounted) return;

    final error = widget.jobNotifier.error;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _handleFinalize(Job job) async {
    final messenger = ScaffoldMessenger.of(context);

    final finishConfirmation = await _customAlertDialog(
      title: 'Finalizar proyecto',
      content:
          '¿Está seguro de finalizar el proyecto? Una vez finalizado no se puede editar.',
      buttonTitle: 'Finalizar',
    );

    if (!finishConfirmation) return;

    final success = await widget.jobNotifier.finalizeDraftJob(job: job);

    if (!mounted) return;

    if (success) {
      await widget.companyNotifier.reloadCompany(_company.id!);

      if (!mounted) return;

      final updated = widget.companyNotifier.companies.firstWhere(
        (c) => c.id == _company.id,
      );

      setState(() {
        _company = updated;
      });
    }

    final error = widget.jobNotifier.error;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<bool> _customAlertDialog({
    required String title,
    required String content,
    required String buttonTitle,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            content,
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
              child: Text(
                buttonTitle,
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
        leading: BackButton(
          style: ButtonStyle(iconSize: WidgetStatePropertyAll(30)),
        ),
        title: Text(
          _company.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.jobNotifier,
          builder: (context, _) {
            if (widget.jobNotifier.isScreenLoading) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 240),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (widget.jobNotifier.error != null) {
              return ErrorMessageWidget(
                text: widget.jobNotifier.error!,
                onPressed: widget.jobNotifier.loadJobs,
              );
            }

            if (widget.jobNotifier.jobs.isEmpty) {
              return ListView(
                padding: EdgeInsets.symmetric(horizontal: 12),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: 240),
                  Center(
                    child: EmptyScreenWidget(
                      title: 'Todavia no hay trabajos generados',
                      gift: 'assets/images/remote-worker.png',
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: widget.jobNotifier.jobs.length,
              itemBuilder: (context, index) {
                final job = widget.jobNotifier.jobs[index];
                final isGeneratingThisJob =
                    job.id != null && _generatingJobId == job.id;
                final isAnyPdfGenerating = _generatingJobId != null;
                final isDeleting =
                    job.id != null && widget.jobNotifier.isDeleting(job.id!);
                final isFinalizing =
                    job.id != null && widget.jobNotifier.isFinalizing(job.id!);
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: job.status == Job.draft
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateJobPage(
                                  company: _company,
                                  jobNotifier: widget.jobNotifier,
                                  initialJob: job,
                                ),
                              ),
                            );
                          }
                        : null,
                    onLongPress: isDeleting
                        ? null
                        : job.status == Job.draft
                        ? () => _handleDelete(job)
                        : null,
                    title: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CustomInputText(text: job.date, title: 'Fecha:'),
                              _CustomInputText(
                                title: 'Entrada:',
                                text: job.startTime,
                              ),
                              _CustomInputText(
                                title: 'Salida:',
                                text: job.endTime,
                              ),
                              _CustomInputText(
                                title: 'Horas facturadas:',
                                text: '${job.hoursCharged} h',
                              ),
                              _CustomInputText(
                                title: 'Valor hora:',
                                text: '${formatCurrency(job.valuePerHour)} \$',
                              ),
                              _CustomInputText(
                                title: 'Total:',
                                text: '${formatCurrency(job.totalDay)} \$',
                              ),
                            ],
                          ),
                        ),
                        job.status == Job.draft
                            ? TextButton(
                                onPressed: isFinalizing
                                    ? null
                                    : () => _handleFinalize(job),
                                child: isFinalizing
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Finalizar',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                              )
                            : job.status == Job.finalized
                            ? TextButton(
                                onPressed: isAnyPdfGenerating
                                    ? null
                                    : () => _generateAndPreviewPdf(job),
                                child: isGeneratingThisJob
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'PDF',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              )
                            : Text(
                                job.status,
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
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateJobPage(
                company: _company,
                jobNotifier: widget.jobNotifier,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CustomInputText extends StatelessWidget {
  final String title;
  final String text;

  const _CustomInputText({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),

        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}

// 
// 
