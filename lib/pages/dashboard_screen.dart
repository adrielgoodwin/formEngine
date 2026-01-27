import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../data/case_repository.dart';
import '../demo_seed.dart';
import '../models/case_record.dart';
import '../report/case_report_pdf.dart';
import '../state/form_state.dart';
import '../logging/app_logger.dart';
import '../models/sort_option.dart';
import '../utils/log_helper.dart';
import 'dashboard_helper.dart';
import 'form_editor_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showArchived = false;
  SortOption _currentSort = SortOption.newestUpdated;
  late TextEditingController _searchController;

  /// Creates executor info and asset indicators for the case
  Widget _buildCaseIndicators(CaseRecord caseRecord) {
    final formInstance = caseRecord.formInstance;

    // Get executor instances for left side
    final executorInstances = formInstance.getGroupInstances('executor_other_info');

    // Count asset items for right side
    final rrspCount = formInstance.getGroupInstances('rrsp_account_group').length;
    final realEstateCount = formInstance.getGroupInstances('realestate_group').length;
    final nonRegCount = formInstance.getGroupInstances('nonreg_account_group').length;
    final otherAssetCount = formInstance.getGroupInstances('other_asset_group').length;

    // Build executor widgets (left side)
    final executorWidgets = <Widget>[];
    for (int index = 0; index < executorInstances.length; index++) {
      final executor = executorInstances[index];
      final name = (executor.values['executor_name'] ?? '').toString();
      final contact = (executor.values['executor_contact'] ?? '').toString();

      executorWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          margin: EdgeInsets.only(right: index < executorInstances.length - 1 ? 8 : 0),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person,
                size: 20,
                color: Color(0xFFFF9800),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF9800),
                    ),
                  ),
                  if (contact.isNotEmpty)
                    Text(
                      contact,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Build asset icons (right side)
    final assetWidgets = <Widget>[];
    if (rrspCount > 0) {
      assetWidgets.addAll(List.generate(rrspCount, (index) => const Padding(
        padding: EdgeInsets.only(right: 2),
        child: Icon(Icons.account_balance, size: 20, color: Color(0xFF4CAF50)),
      )));
    }
    if (realEstateCount > 0) {
      assetWidgets.addAll(List.generate(realEstateCount, (index) => const Padding(
        padding: EdgeInsets.only(right: 2),
        child: Icon(Icons.home, size: 20, color: Color(0xFF4CAF50)),
      )));
    }
    if (nonRegCount > 0) {
      assetWidgets.addAll(List.generate(nonRegCount, (index) => const Padding(
        padding: EdgeInsets.only(right: 2),
        child: Icon(Icons.savings, size: 20, color: Color(0xFF4CAF50)),
      )));
    }
    if (otherAssetCount > 0) {
      assetWidgets.addAll(List.generate(otherAssetCount, (index) => Padding(
        padding: EdgeInsets.only(right: index < otherAssetCount - 1 ? 2 : 0),
        child: const Icon(Icons.inventory_2, size: 20, color: Color(0xFF4CAF50)),
      )));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Executors on the left
        Row(
          mainAxisSize: MainAxisSize.min,
          children: executorWidgets,
        ),
        // Assets on the right
        Row(
          mainAxisSize: MainAxisSize.min,
          children: assetWidgets,
        ),
      ],
    );
  }

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
    final sortedCases = _sortCases(filteredCases);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const EstateIntakeIcon(width: 240, height: 240),
            const SizedBox(width: 12),
            const Text('Deceased Estate Intake'),
          ],
        ),
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
        ],
      ),
      body: Column(
        children: [
          // Search and new case button row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Search field - constrained width (left)
                SizedBox(
                  width: 400,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search cases...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const Spacer(),
                
                // New Case button (right)
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
                    elevation: 2,
                    shadowColor: Colors.black26,
                    surfaceTintColor: Colors.transparent,
                    overlayColor: MaterialStateColor.resolveWith((states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Colors.transparent;
                      }
                      if (states.contains(MaterialState.hovered)) {
                        return Colors.black.withOpacity(0.04);
                      }
                      return Colors.transparent;
                    }),
                  ),
                ),
              ],
            ),
          ),
          
          // Sort and archive controls row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                // Archive toggle (left)
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Active'),
                      selected: !_showArchived,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _showArchived = false;
                          });
                        }
                      },
                      backgroundColor: !_showArchived ? Colors.green.withOpacity(0.2) : null,
                      selectedColor: Colors.green.withOpacity(0.3),
                      showCheckmark: false,
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Archived'),
                      selected: _showArchived,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _showArchived = true;
                          });
                        }
                      },
                      backgroundColor: _showArchived ? Colors.yellow.withOpacity(0.2) : null,
                      selectedColor: Colors.yellow.withOpacity(0.3),
                      showCheckmark: false,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Container(
                  width: 1,
                  height: 30,
                  color: const Color.fromARGB(59, 194, 23, 23),
                ),
                const SizedBox(width: 16),
                
                // Sort buttons (right, scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: SortOption.values.map((option) {
                        final isSelected = _currentSort == option;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(option.label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _currentSort = option;
                                });
                              }
                            },
                            backgroundColor: isSelected ? Colors.blue.withOpacity(0.2) : null,
                            selectedColor: Colors.blue.withOpacity(0.3),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
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
                    itemCount: sortedCases.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final caseRecord = sortedCases[index];
                      return Card(
                        child: ListTile(
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Container 1: Case info column - fixed width to prevent wrapping
                              Container(
                                constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      caseRecord.title,
                                      style: Theme.of(context).textTheme.titleMedium,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    const SizedBox(height: 2),
                                    // Date of Death from form data
                                    Builder(
                                      builder: (context) {
                                        final dod = caseRecord.formInstance.getValue<String>('deceased_dod');
                                        if (dod != null && dod.isNotEmpty) {
                                          return Text(
                                            'Date of Death: $dod',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                    Text(
                                      'Created: ${_formatDate(caseRecord.createdAt)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    Text(
                                      'Updated: ${_formatDate(caseRecord.updatedAt)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Container 2: Indicators - scrollable when space is limited
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: _buildCaseIndicators(caseRecord),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Container 3: Action buttons row
                              Container(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                onPressed: () => _openCase(context, caseRecord),
                                style: TextButton.styleFrom(
                                  overlayColor: MaterialStateColor.resolveWith((states) {
                                    if (states.contains(MaterialState.pressed)) {
                                      return Colors.transparent;
                                    }
                                    if (states.contains(MaterialState.hovered)) {
                                      return Colors.black.withOpacity(0.04);
                                    }
                                    return Colors.transparent;
                                  }),
                                ),
                                child: const Text('Open'),
                              ),
                                    TextButton(
                                onPressed: () => _runReport(context, caseRecord),
                                style: TextButton.styleFrom(
                                  overlayColor: MaterialStateColor.resolveWith((states) {
                                    if (states.contains(MaterialState.pressed)) {
                                      return Colors.transparent;
                                    }
                                    if (states.contains(MaterialState.hovered)) {
                                      return Colors.black.withOpacity(0.04);
                                    }
                                    return Colors.transparent;
                                  }),
                                ),
                                child: const Text('PDF Report'),
                              ),
                                    TextButton(
                                onPressed: () {
                                  repository.archive(
                                    caseRecord.id,
                                    !caseRecord.isArchived,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  overlayColor: MaterialStateColor.resolveWith((states) {
                                    if (states.contains(MaterialState.pressed)) {
                                      return Colors.transparent;
                                    }
                                    if (states.contains(MaterialState.hovered)) {
                                      return Colors.black.withOpacity(0.04);
                                    }
                                    return Colors.transparent;
                                  }),
                                ),
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
    try {
      final formState = context.read<FormStateProvider>();
      final def = await formState.loadDefinition();

      if (Platform.isWindows) {
        final filePath = await createCasePdfFileForWindows(caseRecord, def);
        final opened = await openPdfFileOnWindows(filePath);
        if (!opened && mounted) {
          _showPdfOpenFailedDialog(filePath);
        }
        return;
      }

      await previewCasePdf(caseRecord, def);
    } catch (e, st) {
      AppLogger.instance.error(
        'report',
        'PDF report failed for case=${caseRecord.id}: ${e.runtimeType}',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF Report Failed'),
          content: const Text(
            'The PDF could not be generated on this machine. Please try again, or contact support and include the logs.',
          ),
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

  void _showPdfOpenFailedDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Created'),
        content: const Text(
          'The PDF was created, but Windows could not open it automatically. You can copy the file path or open the folder.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: filePath));
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Copy Path'),
          ),
          TextButton(
            onPressed: () async {
              await openPdfFolderOnWindows(filePath);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Open Folder'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  List<CaseRecord> _sortCases(List<CaseRecord> cases) {
    final sortedCases = List<CaseRecord>.from(cases);
    
    switch (_currentSort) {
      case SortOption.alphabeticalAZ:
        sortedCases.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.alphabeticalZA:
        sortedCases.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortOption.oldestCreated:
        sortedCases.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.newestCreated:
        sortedCases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.oldestUpdated:
        sortedCases.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case SortOption.newestUpdated:
        sortedCases.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }
    
    return sortedCases;
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
            style: TextButton.styleFrom(
              overlayColor: MaterialStateColor.resolveWith((states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.transparent;
                }
                if (states.contains(MaterialState.hovered)) {
                  return Colors.black.withOpacity(0.04);
                }
                return Colors.transparent;
              }),
            ),
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
            style: TextButton.styleFrom(
              overlayColor: MaterialStateColor.resolveWith((states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.transparent;
                }
                if (states.contains(MaterialState.hovered)) {
                  return Colors.black.withOpacity(0.04);
                }
                return Colors.transparent;
              }),
            ),
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
              overlayColor: MaterialStateColor.resolveWith((states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.transparent;
                }
                if (states.contains(MaterialState.hovered)) {
                  return Colors.red.withOpacity(0.04);
                }
                return Colors.transparent;
              }),
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}
