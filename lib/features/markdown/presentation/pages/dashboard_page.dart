import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/app_features.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/markdown_file.dart';
import '../../domain/entities/folder.dart';

import '../providers/markdown_file_provider.dart';
import '../providers/editor_provider.dart';
import '../providers/security_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/subscription_provider.dart';
import '../../../../core/services/ad_service.dart';
import '../widgets/premium_paywall_popup.dart';
import '../../../../core/services/update_service.dart';
import 'editor_page.dart';
import 'audit_logs_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _currentTab = 0; // 0: Home, 1: Explorer, 2: Settings

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAppOpenAd();
      _checkAndShowPremiumPopup();
      UpdateService.checkForUpdates(context);
    });
  }

  Future<void> _checkAndShowPremiumPopup() async {
    final subState = ref.read(subscriptionProvider);
    
    // 1. If already subscribed, don't show
    if (subState.isSubscribed) return;

    // 2. Check last shown date in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final lastShownStr = prefs.getString('premium_popup_last_shown');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // TEST MODE: If kDebugMode is true, you might want to show it every time for testing.
    // Replace 'true' with 'false' if you want daily check even in debug.
    const bool forceShowForTest = kDebugMode && true; 

    if (forceShowForTest || lastShownStr != today) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => const PremiumPaywallPopup(),
        );
        // 3. Save today's date as last shown
        await prefs.setString('premium_popup_last_shown', today);
      }
    }
  }

  void _showAppOpenAd() {
    AdService.showAppOpenAd(context);
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    switch (_currentTab) {
      case 0:
        content = _HomeTab(
          onNavigateToExplorer: (filter) {
            if (filter != null) {
              ref.read(markdownFileProvider.notifier).setFilter(filter);
            }
            setState(() => _currentTab = 1);
          },
        );
        break;
      case 1:
        content = const _ExplorerTab();
        break;
      case 2:
        content = const _SettingsTab();
        break;
      default:
        content = _HomeTab(
          onNavigateToExplorer: (filter) {
            if (filter != null) {
              ref.read(markdownFileProvider.notifier).setFilter(filter);
            }
            setState(() => _currentTab = 1);
          },
        );
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTab == 0
              ? 'Dashboard'
              : _currentTab == 1
                  ? 'File Explorer'
                  : 'Settings',
        ),
      ),
      body: content,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.grey500,
        onTap: (index) => setState(() => _currentTab = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_copy_rounded), label: 'Explorer'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

// ─── HELPER FOR FILE/FOLDER DECRYPTION & SECURITY AUTHORIZATION ────
Future<bool> authenticateItem(
  BuildContext context,
  WidgetRef ref, {
  required bool isLocked,
  required String? lockType,
  required int id,
  required String name,
  required bool isFolder,
}) async {
  if (!isLocked) return true;

  final subState = ref.read(subscriptionProvider);
  bool adCompleted = true;

  if (!subState.isSubscribed) {
    adCompleted = false;
    await AdService.showRewardedVideoAd(
      context,
      'Unlock ${isFolder ? "Folder" : "File"}',
      () => adCompleted = true,
    );
  }

  if (!adCompleted) return false;

  if (lockType == 'password') {
    final passwordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(isFolder ? 'Decrypt Folder' : 'Decrypt File', style: GoogleFonts.saira(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter password to authorize action on "$name".',
              style: GoogleFonts.saira(fontSize: 13, color: AppColors.grey500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Enter password',
                prefixIcon: Icon(Icons.key_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text;
              final verified = isFolder
                  ? await ref.read(securityProvider.notifier).unlockFolderWithPassword(id, password)
                  : await ref.read(securityProvider.notifier).unlockFileWithPassword(id, password);
              if (verified) {
                Navigator.of(ctx).pop(true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid password. Access Denied.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Unlock'),
          )
        ],
      ),
    );
    return result ?? false;
  } else if (lockType == 'biometric') {
    final authenticated = await ref
        .read(securityProvider.notifier)
        .authenticateBiometrics('Unlock ${isFolder ? "folder" : "file"} "$name"');
    if (!authenticated) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric verification failed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    return authenticated;
  }
  return true;
}

Future<void> openSecuredFile(BuildContext context, WidgetRef ref, MarkdownFile file) async {
  final authenticated = await authenticateItem(
    context,
    ref,
    isLocked: file.isLocked,
    lockType: file.lockType,
    id: file.id!,
    name: file.title,
    isFolder: false,
  );
  if (authenticated) {
    ref.read(editorProvider.notifier).openFile(file);
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditorPage()));
    }
  }
}

Future<void> openSecuredFolder(BuildContext context, WidgetRef ref, Folder folder) async {
  final authenticated = await authenticateItem(
    context,
    ref,
    isLocked: folder.isLocked,
    lockType: folder.lockType,
    id: folder.id!,
    name: folder.name,
    isFolder: true,
  );
  if (authenticated) {
    ref.read(markdownFileProvider.notifier).setCurrentFolder(folder.id);
  }
}

// ─── HOME OVERVIEW TAB ──────────────────────────────────────────
class _HomeTab extends ConsumerWidget {
  final Function(ExplorerFilter?) onNavigateToExplorer;
  const _HomeTab({required this.onNavigateToExplorer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(markdownFileProvider);
    final stats = state.statistics;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter files
    final recentFiles = state.allFiles.take(5).toList();
    final lockedFiles = state.allFiles.where((f) => f.isLocked).take(5).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(markdownFileProvider.notifier).loadAll(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back',
                style: GoogleFonts.saira(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
              Text(
                'Here is your secure document vault status overview.',
                style: GoogleFonts.saira(fontSize: 13, color: AppColors.grey400),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              
              // Statistics Grid
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.5 : 1.9,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    context,
                    'Total Files',
                    '${stats['totalFiles'] ?? 0}',
                    Icons.description_rounded,
                    AppColors.primary,
                    onTap: () => onNavigateToExplorer(ExplorerFilter.all),
                  ),
                  _buildStatCard(
                    context,
                    'Locked Files',
                    '${stats['lockedFiles'] ?? 0}',
                    Icons.lock_rounded,
                    AppColors.grey500,
                    onTap: () => onNavigateToExplorer(ExplorerFilter.locked),
                  ),
                  _buildStatCard(
                    context,
                    'Total Edits',
                    '${stats['totalEdits'] ?? 0}',
                    Icons.edit_note_rounded,
                    AppColors.warning,
                  ),
                  _buildStatCard(
                    context,
                    'Total Words',
                    '${stats['totalWords'] ?? 0}',
                    Icons.abc_rounded,
                    AppColors.info,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingXL),

              // Activity overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.flash_on_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last Security Audit Event',
                              style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey400, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              stats['lastActivity'] ?? 'No recent logs recorded.',
                              style: GoogleFonts.saira(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.grey800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL),

              // Recent Documents & Locked Documents split Row/Column
              () {
                final showSplit = MediaQuery.of(context).size.width > 600;
                final recentListWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recently Modified',
                      style: GoogleFonts.saira(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (recentFiles.isEmpty)
                      _buildEmptyList('No files in this folder.')
                    else
                      Column(
                        children: () {
                          final List<Widget> items = [];
                          for (int i = 0; i < recentFiles.length; i++) {
                            items.add(_buildFileItem(context, ref, recentFiles[i]));
                            if ((i + 1) % 4 == 0) {
                              items.add(const MockBannerAdCard());
                            }
                          }
                          return items;
                        }(),
                      ),
                  ],
                );

                final lockedListWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locked Crypt Vaults',
                      style: GoogleFonts.saira(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (lockedFiles.isEmpty)
                      _buildEmptyList('No locked documents.')
                    else
                      Column(
                        children: () {
                          final List<Widget> items = [];
                          for (int i = 0; i < lockedFiles.length; i++) {
                            items.add(_buildFileItem(context, ref, lockedFiles[i]));
                            if ((i + 1) % 4 == 0) {
                              items.add(const MockBannerAdCard());
                            }
                          }
                          return items;
                        }(),
                      ),
                  ],
                );

                if (showSplit) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: recentListWidget),
                      const SizedBox(width: 16),
                      Expanded(child: lockedListWidget),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      recentListWidget,
                      const SizedBox(height: 24),
                      lockedListWidget,
                    ],
                  );
                }
              }(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap ?? () => onNavigateToExplorer(null),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.saira(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(icon, color: color, size: 16),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.saira(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.grey900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyList(String text) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.grey200, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.saira(color: AppColors.grey400, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, WidgetRef ref, MarkdownFile file) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          file.isLocked ? Icons.lock_outline_rounded : Icons.description_outlined,
          color: file.isLocked ? AppColors.grey500 : AppColors.primary,
        ),
        title: Text(
          file.title,
          style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Updated: ${DateFormat.yMMMd().add_jm().format(file.updatedAt)}',
          style: GoogleFonts.saira(fontSize: 11, color: AppColors.grey400),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
        onTap: () => openSecuredFile(context, ref, file),
      ),
    );
  }
}

// ─── FILE EXPLORER TAB ──────────────────────────────────────────
class _ExplorerTab extends ConsumerStatefulWidget {
  const _ExplorerTab();

  @override
  ConsumerState<_ExplorerTab> createState() => _ExplorerTabState();
}

class _ExplorerTabState extends ConsumerState<_ExplorerTab> {
  final _searchController = TextEditingController();
  bool _isDragging = false;
  dynamic _draggedItem;

  void _createNewFileOrFolderDialog(BuildContext context, bool isFolder) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isFolder ? 'Create Folder' : 'Create Markdown Document', style: GoogleFonts.saira(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: isFolder ? 'Folder Name' : 'Document Title',
            hintText: isFolder ? 'e.g. Work' : 'e.g. Readme',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                Navigator.of(ctx).pop();
                if (isFolder) {
                  await ref.read(markdownFileProvider.notifier).createFolder(title);
                } else {
                  final newFile = await ref.read(markdownFileProvider.notifier).createFile(
                    title,
                    '# $title\n\nWrite content here...',
                    folderId: ref.read(markdownFileProvider).currentFolderId,
                  );
                  if (mounted) {
                    ref.read(editorProvider.notifier).openFile(newFile);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditorPage()));
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _importExternalFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        final name = file.name;
        
        String content = '';
        if (kIsWeb || file.path == null) {
          if (file.bytes != null) {
            content = utf8.decode(file.bytes!);
          }
        } else {
          final dartFile = File(file.path!);
          content = await dartFile.readAsString();
        }
        
        final title = name.replaceAll(RegExp(r'\.(md|txt|markdown)$'), '');

        final newFile = await ref.read(markdownFileProvider.notifier).createFile(
          title,
          content,
          folderId: ref.read(markdownFileProvider).currentFolderId,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported "${newFile.title}"!'),
              backgroundColor: AppColors.secondary,
            ),
          );
          ref.read(editorProvider.notifier).openFile(newFile);
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditorPage()));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(markdownFileProvider);

    // Get folders currently displayed (in local flat folder setup, we can filter or list all folders)
    // To support subfolders, we check parentId matching currentFolderId
    List<Folder> currentFolders = state.folders.where((f) => f.parentId == state.currentFolderId).toList();
    List<MarkdownFile> currentFiles = state.files;

    // Apply Filters
    if (state.filter == ExplorerFilter.folders) {
      currentFiles = [];
    } else if (state.filter == ExplorerFilter.locked) {
      currentFolders = currentFolders.where((f) => f.isLocked).toList();
      currentFiles = currentFiles.where((f) => f.isLocked).toList();
    } else if (state.filter == ExplorerFilter.unlocked) {
      currentFolders = currentFolders.where((f) => !f.isLocked).toList();
      currentFiles = currentFiles.where((f) => !f.isLocked).toList();
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Action controls
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => ref.read(markdownFileProvider.notifier).search(val),
                  decoration: const InputDecoration(
                    hintText: 'Search files and full-text content...',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () => _createNewFileOrFolderDialog(context, false),
                icon: const Icon(Icons.note_add_rounded),
                tooltip: 'New Markdown Document',
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => _createNewFileOrFolderDialog(context, true),
                icon: const Icon(Icons.create_new_folder_rounded),
                tooltip: 'New Folder',
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => _importExternalFile(context),
                icon: const Icon(Icons.upload_file_rounded),
                tooltip: 'Import Markdown Document',
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Drop Targets Area (Shown when dragging)
          if (_isDragging)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.move_to_inbox_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Drop to Move', style: GoogleFonts.saira(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Move to Root option
                        if (state.currentFolderId != null)
                          _buildDropTargetChip('Root (Move Out)', null),
                        
                        // All other folders as targets
                        ...state.folders.where((f) {
                          if (f.id == state.currentFolderId) return false;
                          if (_draggedItem is Folder && f.id == _draggedItem.id) return false;
                          return true;
                        }).map((f) => _buildDropTargetChip(f.name, f.id)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Category Filter Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', ExplorerFilter.all, state.filter),
                const SizedBox(width: 8),
                _buildFilterChip('Folders', ExplorerFilter.folders, state.filter),
                const SizedBox(width: 8),
                _buildFilterChip('Locked', ExplorerFilter.locked, state.filter),
                const SizedBox(width: 8),
                _buildFilterChip('Unlocked', ExplorerFilter.unlocked, state.filter),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Breadcrumbs navigation
          if (state.currentFolderId != null)
            () {
              Folder? currentFolder;
              for (final f in state.folders) {
                if (f.id == state.currentFolderId) {
                  currentFolder = f;
                  break;
                }
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      onPressed: () => ref.read(markdownFileProvider.notifier).setCurrentFolder(null),
                      tooltip: 'Back to Root',
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Root',
                      style: GoogleFonts.saira(fontSize: 14, color: AppColors.grey500, fontWeight: FontWeight.w500),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.grey400),
                    Expanded(
                      child: Text(
                        currentFolder?.name ?? 'Folder',
                        style: GoogleFonts.saira(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }(),

          // Files & Folders Grid list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : (currentFolders.isEmpty && currentFiles.isEmpty)
                    ? Center(
                        child: Text(
                          'No items found matching filter.',
                          style: GoogleFonts.saira(color: AppColors.grey400, fontSize: 14),
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          ..._buildGridWithAds(currentFolders, currentFiles),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ExplorerFilter filter, ExplorerFilter currentFilter) {
    final isSelected = filter == currentFilter;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.saira(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          ref.read(markdownFileProvider.notifier).setFilter(filter);
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(color: isSelected ? AppColors.primary : AppColors.grey600),
    );
  }

  Widget _buildDropTargetChip(String label, int? folderId) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: DragTarget<Object>(
        onWillAccept: (data) => true,
        onAccept: (data) {
          if (data is MarkdownFile) {
            ref.read(markdownFileProvider.notifier).moveFile(data.id!, folderId);
          } else if (data is Folder) {
            ref.read(markdownFileProvider.notifier).moveFolder(data.id!, folderId);
          }
          setState(() {
            _isDragging = false;
            _draggedItem = null;
          });
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isHovering ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary, width: 1),
              boxShadow: isHovering ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 4)] : null,
            ),
            child: Row(
              children: [
                Icon(
                  folderId == null ? Icons.home_repair_service_rounded : Icons.folder_rounded,
                  size: 14,
                  color: isHovering ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.saira(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHovering ? Colors.white : AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildGridWithAds(List<Folder> folders, List<MarkdownFile> files) {
    final List<dynamic> combinedItems = [...folders, ...files];
    final List<Widget> slivers = [];
    
    for (int i = 0; i < combinedItems.length; i += 4) {
      // Add chunk of 4 items
      final chunk = combinedItems.skip(i).take(4).toList();
      
      slivers.add(
        SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 900
                ? 5
                : MediaQuery.of(context).size.width > 600
                    ? 3
                    : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = chunk[index];
              if (item is Folder) {
                return _buildFolderGridCard(item);
              } else {
                return _buildFileGridCard(item as MarkdownFile);
              }
            },
            childCount: chunk.length,
          ),
        ),
      );

      // Add full-width banner after every 4 items
      if (i + 4 <= combinedItems.length || chunk.length == 4) {
        slivers.add(
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: MockBannerAdCard(),
            ),
          ),
        );
      }
    }

    return slivers;
  }

  Widget _buildFolderGridCard(Folder folder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Draggable<Folder>(
      data: folder,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_rounded, size: 32, color: Colors.amber),
              Text(folder.name, style: GoogleFonts.saira(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
      onDragStarted: () {
        setState(() {
          _isDragging = true;
          _draggedItem = folder;
        });
      },
      onDragEnd: (details) {
        setState(() {
          _isDragging = false;
          _draggedItem = null;
        });
      },
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildFolderCardUI(folder, isDark),
      ),
      child: DragTarget<Object>(
        onWillAccept: (data) {
          if (data is Folder && data.id == folder.id) return false;
          return true;
        },
        onAccept: (data) {
          if (data is MarkdownFile) {
            ref.read(markdownFileProvider.notifier).moveFile(data.id!, folder.id);
          } else if (data is Folder) {
            ref.read(markdownFileProvider.notifier).moveFolder(data.id!, folder.id);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return Container(
            decoration: isHovering
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 2),
                  )
                : null,
            child: _buildFolderCardUI(folder, isDark),
          );
        },
      ),
    );
  }

  Widget _buildFolderCardUI(Folder folder, bool isDark) {
    return GestureDetector(
      onTap: () => openSecuredFolder(context, ref, folder),
      child: Card(
        color: isDark ? AppColors.darkCardBg : AppColors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    folder.isLocked ? Icons.folder_shared_rounded : Icons.folder_rounded,
                    size: 36,
                    color: folder.isLocked ? AppColors.grey500 : Colors.amber,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) async {
                      final subState = ref.read(subscriptionProvider);
                      if (val == 'delete') {
                        await confirmDeleteFolder(folder);
                      } else if (val == 'rename') {
                        final authenticated = await authenticateItem(
                          context,
                          ref,
                          isLocked: folder.isLocked,
                          lockType: folder.lockType,
                          id: folder.id!,
                          name: folder.name,
                          isFolder: true,
                        );
                        if (authenticated) {
                          _showRenameFolderDialog(folder);
                        }
                      } else if (val == 'unlock') {
                        if (subState.isSubscribed) {
                          await ref.read(securityProvider.notifier).removeFolderLock(folder.id!);
                        } else {
                          await AdService.showRewardedVideoAd(context, 'Unlock Folder', () async {
                            await ref.read(securityProvider.notifier).removeFolderLock(folder.id!);
                          });
                        }
                      } else if (val == 'lock_password') {
                        final subState = ref.read(subscriptionProvider);
                        if (subState.isSubscribed) {
                          _showSetFolderPasswordLockDialog(folder.id!);
                        } else {
                          await AdService.showRewardedVideoAd(context, 'Set Folder Password', () {
                            _showSetFolderPasswordLockDialog(folder.id!);
                          });
                        }
                      } else if (val == 'lock_biometric') {
                        if (subState.isSubscribed) {
                          await ref.read(securityProvider.notifier).lockFolderWithBiometrics(folder.id!);
                        } else {
                          await AdService.showRewardedVideoAd(context, 'Lock Folder', () async {
                            await ref.read(securityProvider.notifier).lockFolderWithBiometrics(folder.id!);
                          });
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (folder.isLocked)
                        const PopupMenuItem(value: 'unlock', child: Text('Remove Security Lock'))
                      else ...[
                        const PopupMenuItem(value: 'lock_password', child: Text('Encrypt with Password')),
                        const PopupMenuItem(value: 'lock_biometric', child: Text('Encrypt with Biometrics')),
                      ],
                      const PopupMenuItem(value: 'rename', child: Text('Rename Folder')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete Folder')),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Created: ${DateFormat.yMMMd().format(folder.createdAt)}',
                    style: GoogleFonts.saira(fontSize: 10, color: AppColors.grey400),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileGridCard(MarkdownFile file) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Draggable<MarkdownFile>(
      data: file,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_rounded, size: 32, color: AppColors.primary),
              Text(file.title, style: GoogleFonts.saira(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
      onDragStarted: () {
        setState(() {
          _isDragging = true;
          _draggedItem = file;
        });
      },
      onDragEnd: (details) {
        setState(() {
          _isDragging = false;
          _draggedItem = null;
        });
      },
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildFileCardUI(file, isDark),
      ),
      child: _buildFileCardUI(file, isDark),
    );
  }

  Widget _buildFileCardUI(MarkdownFile file, bool isDark) {
    return GestureDetector(
      onTap: () => openSecuredFile(context, ref, file),
      child: Card(
        color: isDark ? AppColors.darkCardBg : AppColors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    file.isLocked ? Icons.lock_outline_rounded : Icons.description_outlined,
                    size: 32,
                    color: file.isLocked ? AppColors.grey500 : AppColors.primary,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) async {
                      final subState = ref.read(subscriptionProvider);
                      if (val == 'delete') {
                        await confirmDeleteFile(file);
                      } else if (val == 'rename') {
                        final authenticated = await authenticateItem(
                          context,
                          ref,
                          isLocked: file.isLocked,
                          lockType: file.lockType,
                          id: file.id!,
                          name: file.title,
                          isFolder: false,
                        );
                        if (authenticated) {
                          _showRenameFileDialog(file);
                        }
                      } else if (val == 'unlock') {
                        if (subState.isSubscribed) {
                          await ref.read(securityProvider.notifier).removeFileLock(file.id!);
                        } else {
                          await AdService.showRewardedVideoAd(context, 'Unlock File', () async {
                            await ref.read(securityProvider.notifier).removeFileLock(file.id!);
                          });
                        }
                      } else if (val == 'lock_password') {
                        final subState = ref.read(subscriptionProvider);
                        if (subState.isSubscribed) {
                          _showSetPasswordLockDialog(file.id!);
                        } else {
                          await AdService.showRewardedVideoAd(context, 'Set File Password', () {
                            _showSetPasswordLockDialog(file.id!);
                          });
                        }
                      } else if (val == 'lock_biometric') {
                        if (subState.isSubscribed) {
                          await ref.read(securityProvider.notifier).lockFileWithBiometrics(file.id!);
                        } else {
                          await AdService.showRewardedVideoAd(context, 'Lock File', () async {
                            await ref.read(securityProvider.notifier).lockFileWithBiometrics(file.id!);
                          });
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (file.isLocked)
                        const PopupMenuItem(value: 'unlock', child: Text('Remove Security Lock'))
                      else ...[
                        const PopupMenuItem(value: 'lock_password', child: Text('Encrypt with Password')),
                        const PopupMenuItem(value: 'lock_biometric', child: Text('Encrypt with Biometrics')),
                      ],
                      const PopupMenuItem(value: 'rename', child: Text('Rename File')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete File')),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.title,
                    style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Updated: ${DateFormat.yMMMd().format(file.updatedAt)}',
                    style: GoogleFonts.saira(fontSize: 10, color: AppColors.grey400),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> confirmDeleteFolder(Folder folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Folder?', style: GoogleFonts.saira(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete "${folder.name}" and all its contents? This action cannot be undone.',
          style: GoogleFonts.saira(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final authenticated = await authenticateItem(
      context,
      ref,
      isLocked: folder.isLocked,
      lockType: folder.lockType,
      id: folder.id!,
      name: folder.name,
      isFolder: true,
    );

    if (authenticated) {
      await ref.read(markdownFileProvider.notifier).deleteFolder(folder.id!, folder.name);
    }
  }

  Future<void> confirmDeleteFile(MarkdownFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete File?', style: GoogleFonts.saira(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete "${file.title}"? This action cannot be undone.',
          style: GoogleFonts.saira(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final authenticated = await authenticateItem(
      context,
      ref,
      isLocked: file.isLocked,
      lockType: file.lockType,
      id: file.id!,
      name: file.title,
      isFolder: false,
    );

    if (authenticated) {
      await ref.read(markdownFileProvider.notifier).deleteFile(file.id!, file.title);
    }
  }

  void _showRenameFileDialog(MarkdownFile file) {
    final titleController = TextEditingController(text: file.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rename Document', style: GoogleFonts.saira(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Document Title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                Navigator.of(ctx).pop();
                await ref.read(markdownFileProvider.notifier).renameFile(file.id!, title);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showRenameFolderDialog(Folder folder) {
    final titleController = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rename Folder', style: GoogleFonts.saira(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                Navigator.of(ctx).pop();
                await ref.read(markdownFileProvider.notifier).renameFolder(folder.id!, title);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showSetPasswordLockDialog(int fileId) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encrypt with Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Vault Password',
            hintText: 'Enter encryption password',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text;
              if (password.length >= 4) {
                Navigator.of(ctx).pop();
                await ref.read(securityProvider.notifier).lockFileWithPassword(fileId, password);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 4 characters long.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Encrypt'),
          ),
        ],
      ),
    );
  }

  void _showSetFolderPasswordLockDialog(int folderId) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encrypt Folder with Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder Password',
            hintText: 'Enter encryption password',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text;
              if (password.length >= 4) {
                Navigator.of(ctx).pop();
                await ref.read(securityProvider.notifier).lockFolderWithPassword(folderId, password);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 4 characters long.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Encrypt'),
          ),
        ],
      ),
    );
  }
}



// ─── SETTINGS TAB ──────────────────────────────────────────────
class _SettingsTab extends ConsumerWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final isSaving = ref.watch(settingsProvider);
    final double screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 500;

    void _handleGoogleLogin(BuildContext context, WidgetRef ref) async {
      final user = await ref.read(subscriptionProvider.notifier).signInWithGoogle();
      if (user != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, ${user.displayName}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }

    Widget buildThemeOption(
      String label,
      ThemeMode mode,
      bool isSelected,
      IconData icon,
    ) {
      final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
      
      return Expanded(
        child: InkWell(
          onTap: () => ref.read(themeProvider.notifier).setThemeMode(mode),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isDarkTheme ? const Color(0xFF161F38) : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDarkTheme ? const Color(0xFF23305A) : Colors.grey.shade300),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : (isDarkTheme ? Colors.white70 : Colors.black87),
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.saira(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : (isDarkTheme ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final subState = ref.watch(subscriptionProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preferences', style: GoogleFonts.saira(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppDimensions.paddingM),

          // User Authentication Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Account & Sync',
                        style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login with Google to sync your premium subscription across all your devices securely.',
                    style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey500),
                  ),
                  const SizedBox(height: 16),
                  if (subState.user != null)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: subState.user!.photoURL != null 
                            ? NetworkImage(subState.user!.photoURL!) 
                            : null,
                        child: subState.user!.photoURL == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(subState.user!.displayName ?? 'User', style: GoogleFonts.saira(fontWeight: FontWeight.bold)),
                      subtitle: Text(subState.user!.email ?? '', style: GoogleFonts.saira(fontSize: 12)),
                      trailing: TextButton(
                        onPressed: () => ref.read(subscriptionProvider.notifier).signOut(),
                        child: const Text('Logout', style: TextStyle(color: AppColors.error)),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleGoogleLogin(context, ref),
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Sign in with Google'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          
          // Theme selection card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.brightness_medium_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Theme Settings',
                        style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customize the look of mdStudio Secure. Choose between Light Mode, Dark Mode, or match your System Default.',
                    style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      buildThemeOption('Light', ThemeMode.light, theme == ThemeMode.light, Icons.light_mode_rounded),
                      const SizedBox(width: 8),
                      buildThemeOption('Dark', ThemeMode.dark, theme == ThemeMode.dark, Icons.dark_mode_rounded),
                      const SizedBox(width: 8),
                      buildThemeOption('System', ThemeMode.system, theme == ThemeMode.system, Icons.settings_suggest_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Premium Subscription & Monetization Card
          if (AppFeatures.enableSubscriptions) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'mdStudio Premium Pass',
                          style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subState.isSubscribed
                          ? 'Thank you! You are subscribed to the ${subState.planType.toUpperCase()} Plan. All advertisements are disabled and advanced encryption is fully unlocked.'
                          : 'Unlock advanced security features and enjoy a completely ad-free experience by subscribing to a premium plan.',
                      style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey500),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              ElevatedButton(
                                onPressed: () => ref.read(subscriptionProvider.notifier).purchasePlan('monthly'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: subState.isSubscribed && subState.planType == 'monthly'
                                      ? AppColors.success
                                      : AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Monthly - \$0.41 (50 BDT)',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.saira(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              if (subState.isSubscribed && subState.planType == 'monthly')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Active Plan',
                                          style: GoogleFonts.saira(
                                              fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            children: [
                              ElevatedButton(
                                onPressed: () => ref.read(subscriptionProvider.notifier).purchasePlan('lifetime'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: subState.isSubscribed && subState.planType == 'lifetime'
                                      ? AppColors.success
                                      : AppColors.secondary,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Lifetime - \$5.00 (600 BDT)',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.saira(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              if (subState.isSubscribed && subState.planType == 'lifetime')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                                      const SizedBox(width: 4),
                                      Text('Active Plan',
                                          style: GoogleFonts.saira(
                                              fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
          ],

          // Security Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Document Level Security',
                        style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'To protect your sensitive files, you can set individual password or biometric (Face ID / Fingerprint) locks. Open the actions menu (three dots) next to any file in the Explorer to lock, unlock, or manage encryption.',
                    style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // System Audit Logs Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.history_edu_rounded, color: AppColors.primary),
              title: Text('System Audit Trail', style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('View security logs, file activities, and encryption changes', style: GoogleFonts.saira(fontSize: 11, color: AppColors.grey500)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuditLogsPage()),
                );
              },
            ),
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // Backup and Restore Card
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backup & Restore Management',
                    style: GoogleFonts.saira(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manually backup the local SQLite database or import database backups directly from device folders.',
                    style: GoogleFonts.saira(fontSize: 12, color: AppColors.grey500),
                  ),
                  const SizedBox(height: 8),
                  if (!subState.isSubscribed)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Premium feature: Subscribe or watch a short ad to unlock backup/restore.',
                              style: GoogleFonts.saira(fontSize: 11, color: Colors.amber.shade800, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (isSaving)
                    const Center(child: CircularProgressIndicator())
                  else if (isSmallScreen)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              if (subState.isSubscribed) {
                                final success = await ref.read(settingsProvider.notifier).backupDatabase();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Database Backup Exported!' : 'Export Failed.'),
                                      backgroundColor: success ? AppColors.secondary : AppColors.error,
                                    ),
                                  );
                                }
                              } else {
                                await AdService.showRewardedVideoAd(context, 'Unlock Backup', () async {
                                  final success = await ref.read(settingsProvider.notifier).backupDatabase();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success ? 'Database Backup Exported!' : 'Export Failed.'),
                                        backgroundColor: success ? AppColors.secondary : AppColors.error,
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                            icon: Icon(subState.isSubscribed ? Icons.backup_rounded : Icons.play_circle_fill_rounded),
                            label: Text(subState.isSubscribed ? 'Export Backup' : 'Watch Ad to Export'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              if (subState.isSubscribed) {
                                final success = await ref.read(settingsProvider.notifier).restoreDatabase();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Database Restored Successfully!' : 'Restore Aborted.'),
                                      backgroundColor: success ? AppColors.secondary : AppColors.error,
                                    ),
                                  );
                                }
                              } else {
                                await AdService.showRewardedVideoAd(context, 'Unlock Restore', () async {
                                  final success = await ref.read(settingsProvider.notifier).restoreDatabase();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success ? 'Database Restored Successfully!' : 'Restore Aborted.'),
                                        backgroundColor: success ? AppColors.secondary : AppColors.error,
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                            icon: Icon(subState.isSubscribed ? Icons.settings_backup_restore_rounded : Icons.play_circle_fill_rounded),
                            label: Text(subState.isSubscribed ? 'Import Backup' : 'Watch Ad to Import'),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              if (subState.isSubscribed) {
                                final success = await ref.read(settingsProvider.notifier).backupDatabase();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Database Backup Exported!' : 'Export Failed.'),
                                      backgroundColor: success ? AppColors.secondary : AppColors.error,
                                    ),
                                  );
                                }
                              } else {
                                await AdService.showRewardedVideoAd(context, 'Unlock Backup', () async {
                                  final success = await ref.read(settingsProvider.notifier).backupDatabase();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success ? 'Database Backup Exported!' : 'Export Failed.'),
                                        backgroundColor: success ? AppColors.secondary : AppColors.error,
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                            icon: Icon(subState.isSubscribed ? Icons.backup_rounded : Icons.play_circle_fill_rounded),
                            label: Text(subState.isSubscribed ? 'Export Backup' : 'Watch Ad to Export'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              if (subState.isSubscribed) {
                                final success = await ref.read(settingsProvider.notifier).restoreDatabase();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Database Restored Successfully!' : 'Restore Aborted.'),
                                      backgroundColor: success ? AppColors.secondary : AppColors.error,
                                    ),
                                  );
                                }
                              } else {
                                await AdService.showRewardedVideoAd(context, 'Unlock Restore', () async {
                                  final success = await ref.read(settingsProvider.notifier).restoreDatabase();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success ? 'Database Restored Successfully!' : 'Restore Aborted.'),
                                        backgroundColor: success ? AppColors.secondary : AppColors.error,
                                      ),
                                    );
                                  }
                                });
                              }
                            },
                            icon: Icon(subState.isSubscribed ? Icons.settings_backup_restore_rounded : Icons.play_circle_fill_rounded),
                            label: Text(subState.isSubscribed ? 'Import Backup' : 'Watch Ad to Import'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
