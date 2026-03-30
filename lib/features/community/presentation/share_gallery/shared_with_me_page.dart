import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
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
        backgroundColor: AppColors.stemBackground,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _StemShareGalleryTopBar(
                    title: 'Shared Gallery',
                    onSearch: () {},
                    onMenu: () {},
                  ),
                  _StemShareGallerySubTabs(
                    tabController: _tabController,
                    activeColor: AppColors.stemEmerald,
                    inactiveColor: AppColors.stemMutedText,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 96),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _SharedWithMeTab(userId: userId, isDark: isDark),
                          _SharedByMeTab(userId: userId, isDark: isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            
              Positioned(
                right: 24,
                bottom: 24,
                child: _StemShareFab(
                  onTap: () => context.push(AppRoutes.shareGallery),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StemShareGalleryTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onMenu;
  final VoidCallback onSearch;

  const _StemShareGalleryTopBar({
    required this.title,
    required this.onMenu,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            icon: const Icon(
              Icons.menu,
              size: 22,
              color: AppColors.stemMutedText,
            ),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.stemEmerald,
                letterSpacing: -0.6,
              ),
            ),
          ),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(
              Icons.search,
              size: 22,
              color: AppColors.stemMutedText,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _StemShareGallerySubTabs extends StatelessWidget {
  final TabController tabController;
  final Color activeColor;
  final Color inactiveColor;

  const _StemShareGallerySubTabs({
    required this.tabController,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(48, 0, 24, 0),
      child: TabBar(
        controller: tabController,
        isScrollable: false,
        indicatorColor: activeColor,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.borderGreyDark.withValues(alpha: 0.15),
        labelColor: activeColor,
        unselectedLabelColor: inactiveColor.withValues(alpha: 0.95),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          SizedBox(
            width: 125,
            child: Tab(text: 'Shared With Me'),
          ),
          SizedBox(
            width: 115,
            child: Tab(text: 'Shared By Me'),
          ),
        ],
      ),
    );
  }
}

class _StemShareFab extends StatelessWidget {
  final VoidCallback onTap;

  const _StemShareFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [AppColors.stemEmerald, AppColors.primaryGreenDark],
            transform: GradientRotation(2.877), // ~164.7deg
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.share,
              size: 18,
              color: AppColors.stemButtonText,
            ),
            const SizedBox(width: 10),
            Text(
              'Share Gallery',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.stemButtonText,
                letterSpacing: 1.2,
              ),
            )
          ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          _RecentActivityHeader(),
          const SizedBox(height: AppDimensions.margin24),
          Expanded(
            child: StreamBuilder<List<SharedGalleryModel>>(
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
                        Icon(Icons.error_outline,
                            size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}',
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                final galleries = snapshot.data ?? [];
                if (galleries.isEmpty) {
                  return EmptyGalleryState(
                    title: 'No galleries shared with you yet',
                    subtitle:
                        'When friends share their gallery with you,\nyou\'ll see them here',
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.zero,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedByMeTab extends StatelessWidget {
  final String userId;
  final bool isDark;

  const _SharedByMeTab({required this.userId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          _RecentActivityHeader(),
          const SizedBox(height: AppDimensions.margin24),
          Expanded(
            child: StreamBuilder<List<SharedGalleryModel>>(
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
                        Icon(Icons.error_outline,
                            size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}',
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }

                final galleries = snapshot.data ?? [];
                if (galleries.isEmpty) {
                  return EmptyGalleryState(
                    title: 'You haven\'t shared any gallery yet',
                    subtitle:
                        'Tap "Share Gallery" to share photos with friends',
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: galleries.length,
                  itemBuilder: (context, index) {
                    final g = galleries[index];
                    return _SharedByMeCard(gallery: g, isDark: isDark);
                  },
                );
              },
            ),
          ),
        ],
      ),
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

    return GalleryCard(
      gallery: g,
      isDark: widget.isDark,
      onTap: () => context.push('${AppRoutes.galleryViewer}/${g.id}'),
      onDelete: _deleteGallery,
    );
  }
}

class _RecentActivityHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT ACTIVITY',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.stemMutedText.withValues(alpha: 0.6),
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mutual Vaults',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.stemLightText,
          ),
        ),
      ],
    );
  }
}

