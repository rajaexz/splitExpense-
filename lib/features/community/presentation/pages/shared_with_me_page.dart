import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../data/datasources/shared_gallery_datasource.dart';
import '../../../../data/models/shared_gallery_model.dart';
import '../../../../application/sheredGallery/shared_gallery_cubit.dart';

class SharedWithMePage extends StatefulWidget {
  const SharedWithMePage({Key? key}) : super(key: key);

  @override
  State<SharedWithMePage> createState() => _SharedWithMePageState();
}

class _SharedWithMePageState extends State<SharedWithMePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
        body: SafeArea(
          child: Center(
            child: Text(
              'Please login to see shared galleries',
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
        ),
      );
    }

    return BlocProvider(
      create: (_) => di.sl<SharedGalleryCubit>(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundWhite,
        appBar: AppBar(
          title: const Text('Shared Gallery'),
          backgroundColor: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryGreen,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.textGrey,
            tabs: const [
              Tab(text: 'Shared With Me'),
              Tab(text: 'Shared By Me'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.shareGallery),
          backgroundColor: AppColors.primaryGreen,
          icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
          label: const Text('Share Gallery', style: TextStyle(color: Colors.white)),
        ),
        body: SafeArea(
          child: TabBarView(
          controller: _tabController,
          children: [
            _SharedWithMeTab(userId: userId, isDark: isDark),
            _SharedByMeTab(userId: userId, isDark: isDark),
          ],
        ),
        ),
      ),
    );
  }
}

class _SharedWithMeTab extends StatelessWidget {
  final String userId;
  final bool isDark;

  const _SharedWithMeTab({required this.userId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SharedGalleryModel>>(
      stream: di.sl<SharedGalleryDataSource>().getGalleriesSharedWithMe(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
              ],
            ),
          );
        }
        final galleries = snapshot.data ?? [];
        if (galleries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 80,
                  color: AppColors.textGrey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No galleries shared with you yet',
                  style: TextStyle(
                    fontSize: AppFonts.fontSize16,
                    color: AppColors.textGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'When friends share their gallery with you,\nyou\'ll see them here',
                  style: TextStyle(
                    fontSize: AppFonts.fontSize14,
                    color: AppColors.textGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.padding16),
          itemCount: galleries.length,
          itemBuilder: (context, index) {
            final g = galleries[index];
            return _GalleryCard(
              gallery: g,
              isDark: isDark,
              onTap: () => context.push('${AppRoutes.galleryViewer}/${g.id}'),
            );
          },
        );
      },
    );
  }
}

class _SharedByMeTab extends StatelessWidget {
  final String userId;
  final bool isDark;

  const _SharedByMeTab({required this.userId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SharedGalleryModel>>(
      stream: di.sl<SharedGalleryDataSource>().getGalleriesSharedByMe(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
              ],
            ),
          );
        }
        final galleries = snapshot.data ?? [];
        if (galleries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, size: 80, color: AppColors.textGrey),
                const SizedBox(height: 16),
                Text(
                  'You haven\'t shared any gallery yet',
                  style: TextStyle(fontSize: AppFonts.fontSize16, color: AppColors.textGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap "Share Gallery" to share photos with friends',
                  style: TextStyle(fontSize: AppFonts.fontSize14, color: AppColors.textGrey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.padding16),
          itemCount: galleries.length,
          itemBuilder: (context, index) {
            final g = galleries[index];
            return _SharedByMeCard(gallery: g, isDark: isDark);
          },
        );
      },
    );
  }
}

class _SharedByMeCard extends StatefulWidget {
  final SharedGalleryModel gallery;
  final bool isDark;

  const _SharedByMeCard({required this.gallery, required this.isDark});

  @override
  State<_SharedByMeCard> createState() => _SharedByMeCardState();
}

class _SharedByMeCardState extends State<_SharedByMeCard> {
  Map<String, String>? _names;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    if (widget.gallery.sharedWith.isEmpty) return;
    final names = await di.sl<SharedGalleryDataSource>().getUserNames(widget.gallery.sharedWith);
    if (mounted) setState(() => _names = names);
  }

  Future<void> _deleteGallery() async {
    final g = widget.gallery;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Gallery?'),
        content: Text(
          'This will remove the gallery shared with ${g.sharedWith.length} friend(s). They will no longer see these photos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await di.sl<SharedGalleryDataSource>().deleteGalleryShare(g.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.gallery;
    final sharedWithNames = _names != null
        ? g.sharedWith.map((id) => _names![id] ?? id).join(', ')
        : '${g.sharedWith.length} friend(s)';

    return _GalleryCard(
      gallery: g,
      isDark: widget.isDark,
      title: 'My Gallery',
      subtitle: 'Shared with: $sharedWithNames • ${g.imageUrls.length} photo(s)',
      onTap: () => context.push('${AppRoutes.galleryViewer}/${g.id}'),
      onDelete: _deleteGallery,
    );
  }
}

class _GalleryCard extends StatelessWidget {
  final SharedGalleryModel gallery;
  final bool isDark;
  final VoidCallback onTap;
  final String? title;
  final String? subtitle;
  final VoidCallback? onDelete;

  const _GalleryCard({
    required this.gallery,
    required this.isDark,
    required this.onTap,
    this.title,
    this.subtitle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final thumbUrl = gallery.imageUrls.isNotEmpty ? gallery.imageUrls.first : null;
    final displayTitle = title ?? '${gallery.ownerName}\'s Gallery';
    final hasCustomSubtitle = subtitle != null && subtitle!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.margin16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radius16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radius16),
                bottomLeft: Radius.circular(AppDimensions.radius16),
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: thumbUrl != null
                    ? CachedNetworkImage(
                        imageUrl: thumbUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.backgroundGrey,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.backgroundGrey,
                          child: Icon(Icons.photo_library, color: AppColors.textGrey),
                        ),
                      )
                    : Container(
                        color: AppColors.backgroundGrey,
                        child: Icon(Icons.photo_library, size: 40, color: AppColors.textGrey),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.padding16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library, size: 20, color: AppColors.primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: TextStyle(
                              fontSize: AppFonts.fontSize16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textWhite : AppColors.textBlack,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasCustomSubtitle
                          ? subtitle!
                          : '${gallery.imageUrls.length} photo(s)',
                      style: TextStyle(
                        fontSize: AppFonts.fontSize14,
                        color: AppColors.textGrey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!hasCustomSubtitle) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tap to view & download',
                        style: TextStyle(
                          fontSize: AppFonts.fontSize12,
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline, size: 22, color: AppColors.error),
                onPressed: onDelete,
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textGrey),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
