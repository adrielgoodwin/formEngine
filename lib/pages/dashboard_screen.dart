import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/case_repository.dart';
import '../demo_seed.dart';
import '../models/case_record.dart';
import '../report/case_report_pdf.dart';
import '../state/form_state.dart';
import '../logging/app_logger.dart';
import '../utils/log_helper.dart';
import 'form_editor_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showArchived = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<CaseRepository>();
    final formState = context.read<FormStateProvider>();
    final cases = _showArchived 
        ? repository.getAll(includeArchived: true).where((c) => c.isArchived).toList()
        : repository.getAll(includeArchived: false);
    final filteredCases = cases.where((c) =>
        c.title.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cases'),
        actions: [
          if (LogHelper.canOpenLogFolder)
            IconButton(
              icon: const Icon(Icons.folder_open),
              tooltip: 'Open Logs Folder',
              onPressed: _openLogsFolder,
            ),
          if (LogHelper.canCopyLogs)
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy Recent Logs',
              onPressed: _copyRecentLogs,
            ),
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Seed Demo Cases',
              onPressed: _seedDemoCases,
            ),
          ElevatedButton.icon(
            onPressed: () async {
              final def = await formState.loadDefinition();
              final newCase = repository.createNew(def);
              if (context.mounted) {
                _openCase(context, newCase);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text(
              'New Case',
              style: TextStyle(color: Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search cases...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Active')),
                ButtonSegment(value: true, label: Text('Archived')),
              ],
              selected: {_showArchived},
              onSelectionChanged: (selection) {
                setState(() {
                  _showArchived = selection.first;
                });
              },
            ),
          ),
          Expanded(
            child: cases.isEmpty
                ? Center(
                    child: Text(
                      _showArchived
                          ? 'No archived cases'
                          : 'No active cases',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredCases.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final caseRecord = filteredCases[index];
                      return Card(
                        child: ListTile(
                          title: Text(caseRecord.title),
                          subtitle: Text(
                            'Updated: ${_formatDate(caseRecord.updatedAt)}',
                          ),
                          isThreeLine: true,
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => _openCase(context, caseRecord),
                                child: const Text('Open'),
                              ),
                              TextButton(
                                onPressed: () => _runReport(context, caseRecord),
                                child: const Text('Report'),
                              ),
                              TextButton(
                                onPressed: () {
                                  repository.archive(
                                    caseRecord.id,
                                    !caseRecord.isArchived,
                                  );
                                },
                                child: Text(
                                  caseRecord.isArchived
                                      ? 'Unarchive'
                                      : 'Archive',
                                ),
                              ),
                              // Only show delete button for archived cases
                              if (caseRecord.isArchived)
                                _DeletableCaseButton(
                                  caseRecord: caseRecord,
                                  repository: repository,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCase(BuildContext context, CaseRecord caseRecord) async {
    final formState = context.read<FormStateProvider>();
    await formState.loadCase(caseRecord);
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const FormEditorScreen(),
        ),
      );
    }
  }

  Future<void> _runReport(BuildContext context, CaseRecord caseRecord) async {
    final formState = context.read<FormStateProvider>();
    final def = await formState.loadDefinition();
    await previewCasePdf(caseRecord, def);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Future<void> _openLogsFolder() async {
    final success = await LogHelper.openLogFolder();
    if (!success && mounted) {
      _showLogUnavailableDialog();
    }
  }

  Future<void> _copyRecentLogs() async {
    final logs = await LogHelper.getRecentLogs();
    if (logs == null) {
      if (mounted) {
        _showLogUnavailableDialog();
      }
      return;
    }

    await LogHelper.copyToClipboard(logs);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recent logs copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _seedDemoCases() async {
    final repository = context.read<CaseRepository>();
    final formState = context.read<FormStateProvider>();

    try {
      final def = await formState.loadDefinition();
      await seedDemoCasesIfEmpty(def, repository, force: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seeded demo cases')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seed failed')),
        );
      }
    }
  }

  void _showLogUnavailableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logs Unavailable'),
        content: const Text('No log file available.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Deletable Case Button Widget
// =============================================================================

class _DeletableCaseButton extends StatefulWidget {
  final CaseRecord caseRecord;
  final CaseRepository repository;

  const _DeletableCaseButton({
    required this.caseRecord,
    required this.repository,
  });

  @override
  State<_DeletableCaseButton> createState() => _DeletableCaseButtonState();
}

class _DeletableCaseButtonState extends State<_DeletableCaseButton> {
  bool isHovered = false;
  bool isConfirming = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: () {
          if (isConfirming) {
            _deleteCase();
          } else {
            setState(() => isConfirming = true);
            // Auto-reset confirmation after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (context.mounted) {
                setState(() => isConfirming = false);
              }
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isConfirming ? 32 : 24,
          height: isConfirming ? 32 : 24,
          decoration: BoxDecoration(
            color: isConfirming 
                ? const Color.fromARGB(255, 172, 52, 43)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(isConfirming ? 16 : 12),
          ),
          child: Center(
            child: Icon(
              Icons.delete_forever,
              size: isConfirming ? 20 : 16,
              color: isConfirming 
                  ? Colors.black 
                  : (isHovered 
                      ? const Color.fromARGB(255, 172, 52, 43) 
                      : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteCase() {
    AppLogger.instance.info('dashboard', 'Initiating delete case flow for case=${widget.caseRecord.id}');
    // Show confirmation dialog before permanent deletion
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete Case'),
        content: Text(
          'Are you sure you want to permanently delete "${widget.caseRecord.title}"?\n\n'
          'This action cannot be undone and will remove all case data from the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppLogger.instance.info('dashboard', 'User confirmed delete case=${widget.caseRecord.id}');
              widget.repository.delete(widget.caseRecord.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Case permanently deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}
