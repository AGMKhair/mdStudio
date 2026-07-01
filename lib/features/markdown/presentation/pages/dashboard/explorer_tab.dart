import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../domain/entities/markdown_file.dart';
import '../../../domain/entities/folder.dart';
import '../../providers/markdown_file_provider.dart';
import '../../providers/editor_provider.dart';
import '../../providers/security_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../../../../core/services/ad_service.dart';
import '../../widgets/premium_paywall_popup.dart';
import '../editor_page.dart';
import '../template_selection_page.dart';
import 'security_helpers.dart';

class ExplorerTab extends ConsumerStatefulWidget {
  const ExplorerTab({super.key});

  @override
  ConsumerState<ExplorerTab> createState() => _ExplorerTabState();
}

class _ExplorerTabState extends ConsumerState<ExplorerTab> {
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
                  final subState = ref.read(subscriptionProvider);
                  final fileState = ref.read(markdownFileProvider);
                  final totalFiles = fileState.statistics['totalFiles'] as int? ?? 0;
                  final totalFolders = fileState.folders.length;
                  final totalItems = totalFiles + totalFolders;

                  if (!subState.isSubscribed && totalItems >= 3) {
                    if (context.mounted) {
                      await AdService.showRewardedVideoAd(context, 'Create Folder', () async {
                        await ref.read(markdownFileProvider.notifier).createFolder(title);
                      });
                    }
                  } else {
                    await ref.read(markdownFileProvider.notifier).createFolder(title);
                  }
                } else {
                  final subState = ref.read(subscriptionProvider);
                  final fileState = ref.read(markdownFileProvider);
                  final totalFiles = fileState.statistics['totalFiles'] as int? ?? 0;

                  Future<void> proceedFileCreate() async {
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

                  if (!subState.isSubscribed && totalFiles >= 3) {
                    final prefs = await SharedPreferences.getInstance();
                    final hasShownDialog = prefs.getBool('has_shown_limit_choice_dialog') ?? false;

                    if (!hasShownDialog) {
                      if (context.mounted) {
                        _showFileLimitChoiceDialog(context, () async {
                          await AdService.showRewardedVideoAd(context, 'Create File', () async {
                            await proceedFileCreate();
                          });
                        });
                      }
                    } else {
                      if (context.mounted) {
                        await AdService.showRewardedVideoAd(context, 'Create File', () async {
                          await proceedFileCreate();
                        });
                      }
                    }
                  } else {
                    await proceedFileCreate();
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
    final subState = ref.read(subscriptionProvider);
    final fileState = ref.read(markdownFileProvider);
    final totalFiles = fileState.statistics['totalFiles'] as int? ?? 0;

    Future<void> proceedPicker() async {
      try {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['md'],
          withData: true,
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.single;
          final name = file.name;
          
          final lowerName = name.toLowerCase();
          if (!lowerName.endsWith('.md') && !lowerName.endsWith('.markdown')) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Only Markdown (.md, .markdown) files are allowed.'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            return;
          }
          
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

          Future<void> proceedImport() async {
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

          final subState = ref.read(subscriptionProvider);
          final fileState = ref.read(markdownFileProvider);
          final totalFiles = fileState.statistics['totalFiles'] as int? ?? 0;
          final totalFolders = fileState.folders.length;
          final totalItems = totalFiles + totalFolders;

          if (!subState.isSubscribed && totalItems >= 3) {
            if (context.mounted) {
              await AdService.showRewardedVideoAd(context, 'Import File', () async {
                await proceedImport();
              });
            }
          } else {
            await proceedImport();
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

    if (!subState.isSubscribed && totalFiles >= 3) {
      final prefs = await SharedPreferences.getInstance();
      final hasShownDialog = prefs.getBool('has_shown_limit_choice_dialog') ?? false;

      if (!hasShownDialog) {
        if (context.mounted) {
          _showFileLimitChoiceDialog(context, () async {
            await AdService.showRewardedVideoAd(context, 'Import File', () async {
              await proceedPicker();
            });
          });
        }
      } else {
        if (context.mounted) {
          await AdService.showRewardedVideoAd(context, 'Import File', () async {
            await proceedPicker();
          });
        }
      }
    } else {
      await proceedPicker();
    }
  }

  void _showFileLimitChoiceDialog(BuildContext context, VoidCallback onAdOptionSelected) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(
              'File Limit Reached',
              style: GoogleFonts.saira(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'You have reached the limit of 3 free files.\n\nSubscribe to MDStudio Premium for unlimited files and an ad-free experience, or watch a short video ad to create this file for free!',
          style: GoogleFonts.saira(fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('has_shown_limit_choice_dialog', true);
              onAdOptionSelected();
            },
            child: Text(
              'Watch Ad & Create',
              style: GoogleFonts.saira(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              showDialog(
                context: context,
                builder: (context) => const PremiumPaywallPopup(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade600,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Go Premium',
              style: GoogleFonts.saira(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
                onPressed: () async {
                  final subState = ref.read(subscriptionProvider);
                  final fileState = ref.read(markdownFileProvider);
                  final totalFiles = fileState.statistics['totalFiles'] as int? ?? 0;

                  if (!subState.isSubscribed && totalFiles >= 3) {
                    final prefs = await SharedPreferences.getInstance();
                    final hasShownDialog = prefs.getBool('has_shown_limit_choice_dialog') ?? false;

                    if (!hasShownDialog) {
                      if (context.mounted) {
                        _showFileLimitChoiceDialog(context, () async {
                          await AdService.showRewardedVideoAd(context, 'Create File', () async {
                            if (context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => TemplateSelectionPage(
                                    folderId: ref.read(markdownFileProvider).currentFolderId,
                                    bypassAdCheck: true,
                                  ),
                                ),
                              );
                            }
                          });
                        });
                      }
                    } else {
                      if (context.mounted) {
                        await AdService.showRewardedVideoAd(context, 'Create File', () async {
                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TemplateSelectionPage(
                                  folderId: ref.read(markdownFileProvider).currentFolderId,
                                  bypassAdCheck: true,
                                ),
                              ),
                            );
                          }
                        });
                      }
                    }
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TemplateSelectionPage(
                          folderId: ref.read(markdownFileProvider).currentFolderId,
                          bypassAdCheck: false,
                        ),
                      ),
                    );
                  }
                },
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
