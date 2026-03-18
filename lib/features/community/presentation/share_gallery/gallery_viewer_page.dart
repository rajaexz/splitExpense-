import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../data/models/shared_gallery_model.dart';
import '../../../../core/widgets/error_state_with_action.dart';
import 'widgets/share_gallery_widgets.dart';

class GalleryViewerPage extends StatefulWidget {
  final String shareId;

  const GalleryViewerPage({Key? key, required this.shareId}) : super(key: key);

  @override
  State<GalleryViewerPage> createState() => _GalleryViewerPageState();
}

class _GalleryViewerPageState extends State<GalleryViewerPage> {
  SharedGalleryModel? _gallery;
  bool _loading = true;
  String? _error;
  final Set<int> _selectedIndices = {};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('gallery_shares')
          .doc(widget.shareId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Gallery not found';
          _loading = false;
        });
        return;
      }

      final gallery = SharedGalleryModel.fromFirestore(doc);
      if (gallery.isExpired()) {
        setState(() {
          _error = 'This gallery has expired';
          _loading = false;
        });
        return;
      }

      setState(() {
        _gallery = gallery;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
      if (_selectedIndices.isEmpty) _selectionMode = false;
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedIndices.clear();
    });
  }

  Future<void> _downloadSelected() async {
    if (_gallery == null || _selectedIndices.isEmpty) return;

    final urls = _gallery!.imageUrls;
    int success = 0;
    String? savePath;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading...')),
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/JobCrakDownloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    savePath = downloadDir.path;

    final dio = Dio();
    for (final i in _selectedIndices) {
      if (i >= urls.length) continue;
      try {
        final response = await dio.get<List<int>>(
          urls[i],
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.statusCode == 200 && response.data != null) {
          final bytes = response.data!;
          final ext = _getExtensionFromUrl(urls[i]);
          final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
          final file = File('$savePath/$fileName');
          await file.writeAsBytes(bytes);
          success++;
        }
      } catch (_) {
        // Skip failed downloads
      }
    }

    if (mounted) {
      setState(() {
        _selectedIndices.clear();
        _selectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success > 0
                ? 'Saved $success image(s) to app folder'
                : 'Failed to download',
          ),
        ),
      );
    }
  }

  String _getExtensionFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      if (path.contains('.')) {
        final ext = path.split('.').last;
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext.toLowerCase())) {
          return ext.toLowerCase();
        }
      }
    } catch (_) {}
    return 'jpg';
  }

  Future<void> _downloadAll() async {
    if (_gallery == null || _gallery!.imageUrls.isEmpty) return;

    setState(() {
      _selectedIndices.clear();
      for (var i = 0; i < _gallery!.imageUrls.length; i++) {
        _selectedIndices.add(i);
      }
    });
    await _downloadSelected();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
        appBar: AppBar(
          title: const Text('Gallery'),
          backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
        ),
        body: SafeArea(
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
        appBar: AppBar(
          title: const Text('Gallery'),
          backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
        ),
        body: SafeArea(
          child: ErrorStateWithAction(
            message: _error!,
            actionLabel: 'Go Back',
            onAction: () => context.pop(),
          ),
        ),
      );
    }

    final gallery = _gallery!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text('${gallery.ownerName}\'s Gallery'),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
        actions: [
          if (_selectionMode)
            TextButton(
              onPressed: _selectedIndices.isEmpty ? null : _downloadSelected,
              child: Text(
                'Download (${_selectedIndices.length})',
                style: const TextStyle(color: AppColors.primaryGreen),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
              tooltip: 'Select images',
            ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadAll,
            tooltip: 'Download all',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.padding16),
            child: Text(
              'Select images and tap Download to save in app folder',
              style: TextStyle(
                fontSize: AppFonts.fontSize14,
                color: AppColors.textGrey,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppDimensions.padding16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: gallery.imageUrls.length,
              itemBuilder: (context, index) {
                final url = gallery.imageUrls[index];
                final selected = _selectedIndices.contains(index);

                return GestureDetector(
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelection(index);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => FullScreenImageViewer(imageUrl: url),
                        ),
                      );
                    }
                  },
                  onLongPress: () {
                    _toggleSelectionMode();
                    _toggleSelection(index);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.backgroundGrey,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.backgroundGrey,
                            child: Icon(Icons.broken_image, color: AppColors.textGrey),
                          ),
                        ),
                      ),
                      if (_selectionMode)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primaryGreen : Colors.white54,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: selected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        ),
      ),
    );
  }
}
