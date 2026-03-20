import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mecca/core/theme/app_colors.dart';
import 'package:mecca/core/widgets/currency_input_formatter.dart';
import 'package:mecca/core/widgets/custom_textform_field.dart';

import 'package:mecca/features/companies/domain/company.dart';
import 'package:mecca/features/jobs/data/job_photos_repository.dart';
import 'package:mecca/features/jobs/domain/job.dart';
import 'package:mecca/features/jobs/domain/job_calculator.dart';
import 'package:mecca/features/jobs/storage/job_photo_storage_service.dart';
import 'package:mecca/features/jobs/ui/draft_job_controller.dart';
import 'package:mecca/features/jobs/ui/helpers/format_currency.dart';
import 'package:mecca/features/jobs/ui/helpers/parse_currency.dart';
import 'package:mecca/features/jobs/ui/job_notifier.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({
    super.key,
    required this.company,
    required this.jobNotifier,
    this.initialJob,
  });

  final Company company;
  final JobNotifier jobNotifier;
  final Job? initialJob;

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _hoursChargedController = TextEditingController();
  final TextEditingController _valuePerHourController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController();
  final List<JobExtra> _extras = <JobExtra>[];
  final ImagePicker _picker = ImagePicker();
  late DraftJobController draftController;
  bool _manualMode = true;
  bool _usarSaldo = false;

  int get _extrasTotal => _extras.fold<int>(0, (sum, item) => sum + item.value);

  static final RegExp _timeRegex = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  @override
  void initState() {
    super.initState();

    final job = widget.initialJob;

    draftController = DraftJobController(
      photosRepository: JobPhotosRepository(),
      storageService: JobPhotoStorageService(),
    );

    if (widget.initialJob != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        draftController.loadFromDb(widget.initialJob!.id!);
      });
    }

    if (job != null) {
      _dateController.text = job.date;
      _startTimeController.text = job.startTime;
      _endTimeController.text = job.endTime;
      _valuePerHourController.text = formatCurrency(job.valuePerHour);
      _hoursChargedController.text = job.hoursCharged.toString();
      _extras.addAll(job.extras);
      _serviceController.text = widget.initialJob!.service;
      _manualMode = true;
    }

    _dateController.addListener(_onFormChanged);
    _startTimeController.addListener(_onFormChanged);
    _endTimeController.addListener(_onFormChanged);
    _hoursChargedController.addListener(_onFormChanged);
    _valuePerHourController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  JobCalculationResult? get _previewCalculation {
    final startTimeTrim = _startTimeController.text;
    final endTimeTrim = _endTimeController.text;
    final valuePerHour = parseCurrency(_valuePerHourController.text);
    if (valuePerHour <= 0) return null;

    if (!_timeRegex.hasMatch(startTimeTrim) ||
        !_timeRegex.hasMatch(endTimeTrim)) {
      return null;
    }
    if (valuePerHour <= 0) {
      return null;
    }

    final startMinutes = _parseTimeToMinutes(startTimeTrim);
    final endMinutes = _parseTimeToMinutes(endTimeTrim);
    if (endMinutes <= startMinutes) {
      return null;
    }

    final minutosTrabajados = endMinutes - startMinutes;

    if (_manualMode) {
      final horasACobrar = int.tryParse(_hoursChargedController.text.trim());
      if (horasACobrar == null || horasACobrar < 0) {
        return null;
      }

      return calculateJobManualHours(
        saldoActual: widget.company.minutesBalance,
        minutosTrabajados: minutosTrabajados,
        horasACobrar: horasACobrar,
        valorHora: valuePerHour,
        valorAnexos: _extrasTotal,
      );
    }

    return calculateJob(
      saldoActual: widget.company.minutesBalance,
      minutosTrabajados: minutosTrabajados,
      valorHora: valuePerHour,
      valorAnexos: _extrasTotal,
      usarSaldo: _usarSaldo,
    );
  }

  @override
  void dispose() {
    widget.jobNotifier.removeListener(_onFormChanged);
    _dateController.removeListener(_onFormChanged);
    _startTimeController.removeListener(_onFormChanged);
    _endTimeController.removeListener(_onFormChanged);
    _hoursChargedController.removeListener(_onFormChanged);
    _valuePerHourController.removeListener(_onFormChanged);
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _hoursChargedController.dispose();
    _valuePerHourController.dispose();
    _serviceController.dispose();
    draftController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    if (images.isEmpty) return;

    final error = await draftController.addPhotos(images);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  int _parseTimeToMinutes(String value) {
    final parts = value.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return (hour * 60) + minute;
  }

  Future<void> _showAddExtraDialog() async {
    String description = '';
    String valueText = '';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Agregar extra',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextformField(
                label: 'Descripción',
                fillColor: AppColors.background,
                onChanged: (val) => description = val,
              ),
              const SizedBox(height: 12),
              CustomTextformField(
                label: 'Valor',
                fillColor: AppColors.background,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (val) => valueText = val,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(fontSize: 16)),
            ),
            TextButton(
              onPressed: () {
                final parsed = parseCurrency(valueText);

                if (description.trim().isEmpty || parsed < 0) {
                  return;
                }

                setState(() {
                  _extras.add(
                    JobExtra(description: description.trim(), value: parsed),
                  );
                });

                Navigator.pop(context);
              },
              child: const Text(
                'Guardar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay initialTime = TimeOfDay.now();

    if (controller.text.isNotEmpty) {
      final parts = controller.text.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          initialTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) return;

    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

    controller.text = formatted;
  }

  Future<void> _selectDate() async {
    DateTime initialDate = DateTime.now();

    if (_dateController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_dateController.text);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    final formatted =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';

    _dateController.text = formatted;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final dateTrim = _dateController.text.trim();
    final startTimeTrim = _startTimeController.text.trim();
    final endTimeTrim = _endTimeController.text.trim();
    final valuePerHour = parseCurrency(_valuePerHourController.text);

    if (valuePerHour <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Value per hour must be greater than 0')),
      );
      return;
    }

    final result = _previewCalculation;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos incompletos o inválidos')),
      );
      return;
    }

    final job = Job(
      id: null,
      companyId: widget.company.id!,
      date: dateTrim,
      startTime: startTimeTrim,
      endTime: endTimeTrim,
      minutesWorked: result.minutesWorked,
      hoursCharged: result.hoursCharged,
      valuePerHour: valuePerHour,
      extras: List<JobExtra>.from(_extras),
      totalDay: result.totalDay,
      status: Job.draft,
      service: _serviceController.text.trim(),
    );

    if (widget.initialJob == null) {
      // 🔹 CREAR
      final (jobId, error) = await widget.jobNotifier.createDraftJob(job);

      if (error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }

      final syncError = await draftController.sync(jobId!);

      if (syncError != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(syncError)));
        return;
      }

      if (!mounted) return;
      Navigator.pop(context);
    } else {
      // 🔹 EDITAR
      final updatedJob = job.copyWith(id: widget.initialJob!.id);

      final error = await widget.jobNotifier.updateDraftJob(updatedJob);

      if (error != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }

      final syncError = await draftController.sync(updatedJob.id!);

      if (syncError != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(syncError)));
        return;
      }

      if (!mounted) return;
      Navigator.pop(context);
    }
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
            'Nuevo Trabajo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        body: SafeArea(
          bottom: true,
          maintainBottomViewPadding: true,
          top: true,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ExpansionTile(
                    initiallyExpanded: true,
                    title: const Text(
                      'Datos del servicio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    children: [
                      CustomTextformField(
                        controller: _dateController,
                        label: 'Fecha',
                        readOnly: true,
                        onTap: _selectDate,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecciona una fecha';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomTextformField(
                        controller: _startTimeController,
                        label: 'Hora de inicio',
                        readOnly: true,
                        onTap: () => _selectTime(_startTimeController),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Selecciona la hora';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomTextformField(
                        controller: _endTimeController,
                        label: 'Hora de finalización',
                        readOnly: true,
                        onTap: () => _selectTime(_endTimeController),
                        validator: (value) {
                          final endText = value?.trim() ?? '';
                          if (!_timeRegex.hasMatch(endText)) {
                            return 'Use HH:mm format';
                          }

                          final startText = _startTimeController.text.trim();
                          if (!_timeRegex.hasMatch(startText)) {
                            return null;
                          }

                          final startMinutes = _parseTimeToMinutes(startText);
                          final endMinutes = _parseTimeToMinutes(endText);
                          if (endMinutes <= startMinutes) {
                            return 'End time must be after start time';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomTextformField(
                        controller: _serviceController,
                        label: 'Descripción del servicio',
                        maxLines: 6,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La descripción es obligatoria';
                          }
                          if (value.trim().length < 10) {
                            return 'Describe mejor el servicio realizado';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text(
                      'Fotos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    children: [
                      AnimatedBuilder(
                        animation: draftController,
                        builder: (context, _) {
                          final photos = draftController.photos;

                          if (photos.isEmpty) {
                            return const Text('Sin fotos');
                          }

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: photos
                                .where((p) => !p.markedForDeletion)
                                .map((photo) {
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(photo.path),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: GestureDetector(
                                          onTap: () {
                                            draftController.markForDeletion(
                                              photo,
                                            );
                                          },
                                          child: Container(
                                            color: Colors.black54,
                                            child: const Icon(
                                              Icons.close,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                })
                                .toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _pickImages,
                          label: const Text(
                            'Agregar fotos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          icon: Icon(Icons.photo, size: 20),
                        ),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text(
                      'Facturación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Definir horas manualmente'),
                        value: _manualMode,
                        onChanged: (value) {
                          setState(() {
                            _manualMode = value;
                          });
                        },
                      ),
                      CustomTextformField(
                        controller: _valuePerHourController,
                        label: 'Valor por hora',
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(),
                        ],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final parsed = parseCurrency(value ?? '');
                          if (parsed <= 0) {
                            return 'Value per hour must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_manualMode)
                        CustomTextformField(
                          controller: _hoursChargedController,
                          label: 'Horas a cobrar',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final parsed = int.tryParse(value?.trim() ?? '');
                            if (parsed == null || parsed < 0) {
                              return 'Hours charged must be 0 or more';
                            }
                            return null;
                          },
                        )
                      else
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Usar saldo'),
                          value: _usarSaldo,
                          onChanged: (value) {
                            setState(() {
                              _usarSaldo = value;
                            });
                          },
                        ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text(
                      'Extras',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showAddExtraDialog,
                                child: const Text('Agregar extra'),
                              ),
                            ),
                            if (_extras.isEmpty)
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Sin extras'),
                              )
                            else
                              Column(
                                children: _extras.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final extra = entry.value;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      extra.description,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${formatCurrency(extra.value)} \$',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        setState(() {
                                          _extras.removeAt(index);
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _CustomInputText(
                                title: 'Total extras:',
                                text: '${formatCurrency(_extrasTotal)} \$',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Resumen',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _CustomInputText(
                            title: 'Minutos trabajados:',
                            text:
                                '${_previewCalculation?.minutesWorked ?? '-'} min ',
                          ),
                          _CustomInputText(
                            title: 'Horas a cobrar:',
                            text:
                                '${_previewCalculation?.hoursCharged ?? '-'} h ',
                          ),
                          _CustomInputText(
                            title: 'Nuevo saldo:',
                            text:
                                '${_previewCalculation?.newBalance ?? '-'} min',
                          ),
                          _CustomInputText(
                            title: 'Total:',
                            text: _previewCalculation == null
                                ? '-'
                                : '${formatCurrency(_previewCalculation!.totalDay)} \$',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      onPressed: widget.jobNotifier.isCreating ? null : _save,
                      label: widget.jobNotifier.isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          text,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
