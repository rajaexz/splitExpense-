part of 'shared_gallery_cubit.dart';

abstract class SharedGalleryState {}

class SharedGalleryInitial extends SharedGalleryState {}

class SharedGalleryLoading extends SharedGalleryState {}

class SharedGalleryShared extends SharedGalleryState {}

class SharedGalleryError extends SharedGalleryState {
  final String message;
  SharedGalleryError(this.message);
}
