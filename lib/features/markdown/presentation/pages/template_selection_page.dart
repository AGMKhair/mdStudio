import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_templates.dart';
import '../../../../core/services/ad_service.dart';
import '../providers/markdown_file_provider.dart';
import '../providers/editor_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/premium_paywall_popup.dart';
import 'editor_page.dart';

class TemplateSelectionPage extends ConsumerStatefulWidget {
  final int? folderId;
  final bool bypassAdCheck;

  const TemplateSelectionPage({
    super.key,
    this.folderId,
    this.bypassAdCheck = false,
  });

  @override
  ConsumerState<TemplateSelectionPage> createState() => _TemplateSelectionPageState();
}

class _TemplateSelectionPageState extends ConsumerState<TemplateSelectionPage> {
  final _titleController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  TemplateItem _selectedTemplate = AppTemplates.list.first;
  String _searchQuery = '';
  String? _titleError;

  final List<String> _categories = [
    'All',
    'Blank',
    'CV',
    'Cover Letter',
    'Leave Application',
    'Invoice',
    'Agreement',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleCreate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleError = 'Please enter a document title';
      });
      return;
    }

    setState(() {
      _titleError = null;
    });

    final subState = ref.read(subscriptionProvider);
    
    Future<void> proceedCreation() async {
      final newFile = await ref.read(markdownFileProvider.notifier).createFile(
        title,
        _selectedTemplate.content,
        folderId: widget.folderId,
      );

      if (mounted) {
        ref.read(editorProvider.notifier).openFile(newFile);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EditorPage()),
        );
      }
    }

    if (subState.isSubscribed || widget.bypassAdCheck) {
      await proceedCreation();
      return;
    }

    final fileState = ref.read(markdownFileProvider);
    final totalFiles = fileState.statistics['totalFiles'] as int? ?? 0;

    if (totalFiles >= 3) {
      final prefs = await SharedPreferences.getInstance();
      final hasShownDialog = prefs.getBool('has_shown_limit_choice_dialog') ?? false;

      if (!hasShownDialog) {
        if (mounted) {
          _showFileLimitChoiceDialog(context, () async {
            await AdService.showRewardedVideoAd(context, 'Create File', () async {
              await proceedCreation();
            });
          });
        }
      } else {
        if (mounted) {
          await AdService.showRewardedVideoAd(context, 'Create File', () async {
            await proceedCreation();
          });
        }
      }
    } else {
      await AdService.showRewardedVideoAd(context, 'Create File', () async {
        await proceedCreation();
      });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subState = ref.watch(subscriptionProvider);

    // Filter templates based on category and search query
    final filteredTemplates = AppTemplates.list.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Template',
          style: GoogleFonts.saira(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Configuration Box (Title & Ad Note)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161F38) : Colors.grey.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Document Title',
                      hintText: 'e.g. My Freelance Invoice',
                      prefixIcon: const Icon(Icons.title_rounded),
                      errorText: _titleError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) {
                      if (_titleError != null && val.trim().isNotEmpty) {
                        setState(() => _titleError = null);
                      }
                    },
                  ),
                  if (!subState.isSubscribed) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Free Mode: Watching a short ad is required to create your document.',
                              style: GoogleFonts.saira(
                                fontSize: 11,
                                color: Colors.amber.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Search Bar & Filter categories
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search templates...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

            // Categories horizontal list
            SizedBox(
              height: 54,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _categories.length,
                itemBuilder: (ctx, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: GoogleFonts.saira(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: isDark ? const Color(0xFF1D2640) : Colors.grey.shade200,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            // Templates list/grid
            Expanded(
              child: filteredTemplates.isEmpty
                  ? Center(
                      child: Text(
                        'No templates found matching filters.',
                        style: GoogleFonts.saira(color: AppColors.grey500),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredTemplates.length,
                      itemBuilder: (ctx, index) {
                        final item = filteredTemplates[index];
                        final isSelected = _selectedTemplate == item;

                        return Card(
                          elevation: isSelected ? 4 : 1,
                          color: isSelected
                              ? (isDark ? const Color(0xFF223055) : Colors.blue.shade50)
                              : (isDark ? const Color(0xFF161F38) : Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() {
                                _selectedTemplate = item;
                                // Auto-fill title if empty or matches a default template name
                                if (_titleController.text.trim().isEmpty ||
                                    AppTemplates.list.any((t) => t.title == _titleController.text.trim())) {
                                  _titleController.text = item.title;
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary.withOpacity(0.2)
                                              : (isDark ? Colors.white10 : Colors.grey.shade100),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          item.icon,
                                          size: 24,
                                          color: isSelected ? AppColors.primary : AppColors.grey500,
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.primary,
                                          size: 20,
                                        )
                                      else if (!subState.isSubscribed)
                                        const Icon(
                                          Icons.ondemand_video_rounded,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    item.title,
                                    style: GoogleFonts.saira(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: Text(
                                      item.description,
                                      style: GoogleFonts.saira(
                                        fontSize: 10.5,
                                        color: isDark ? Colors.white70 : AppColors.grey500,
                                      ),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161F38) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Selected Template:',
                    style: GoogleFonts.saira(fontSize: 11, color: AppColors.grey500),
                  ),
                  Text(
                    _selectedTemplate.title,
                    style: GoogleFonts.saira(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _handleCreate,
              icon: const Icon(Icons.create_rounded, color: Colors.white),
              label: Text(
                'Create Document',
                style: GoogleFonts.saira(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
