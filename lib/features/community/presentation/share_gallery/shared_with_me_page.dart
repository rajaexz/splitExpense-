import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../data/datasources/shared_gallery_datasource.dart';
import '../../../../data/models/shared_gallery_model.dart';
import '../../../../application/sheredGallery/shared_gallery_cubit.dart';
import 'widgets/share_gallery_widgets.dart';

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
          return EmptyGalleryState(
            title: 'No galleries shared with you yet',
            subtitle: 'When friends share their gallery with you,\nyou\'ll see them here',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.padding16),
          itemCount: galleries.length,
          itemBuilder: (context, index) {
            final g = galleries[index];
            return GalleryCard(
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
          return EmptyGalleryState(
            title: 'You haven\'t shared any gallery yet',
            subtitle: 'Tap "Share Gallery" to share photos with friends',
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

    return GalleryCard(
      gallery: g,
      isDark: widget.isDark,
      title: 'My Gallery',
      subtitle: 'Shared with: $sharedWithNames • ${g.imageUrls.length} photo(s)',
      onTap: () => context.push('${AppRoutes.galleryViewer}/${g.id}'),
      onDelete: _deleteGallery,
    );
  }
}

