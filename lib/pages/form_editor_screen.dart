import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/case_repository.dart';
import '../models/form_instance.dart';
import '../state/form_state.dart';
import '../ui_rendering/rendering.dart';

class FormEditorScreen extends StatelessWidget {
  const FormEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formState = context.watch<FormStateProvider>();
    final repository = context.read<CaseRepository>();
    final currentCase = formState.currentCase;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentCase?.title ?? 'Edit Case'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Update case before leaving
            if (currentCase != null) {
              // Derive title from name field
              final formInstance = formState.formInstance;
              if (formInstance != null) {
                final nameValue = _deriveTitleFromInstance(formInstance);
                if (nameValue != null) {
                  currentCase.title = nameValue;
                }
              }
              repository.update(currentCase);
            }
            formState.unloadCase();
            Navigator.of(context).pop();
          },
        ),
        actions: [],
      ),
      body: formState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: renderForm(formState.assembledForm, context),
            ),
    );
  }
}

String? _deriveTitleFromInstance(FormInstance instance) {
  for (final entry in instance.values.entries) {
    if (entry.key.contains('name') && entry.value is String) {
      final name = entry.value as String;
      if (name.trim().isNotEmpty) {
        return name.trim();
      }
    }
  }
  return null;
}
