import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/community/data/datasources/shared_gallery_datasource.dart';
import '../../data/models/shared_gallery_model.dart';

part 'shared_gallery_state.dart';

class SharedGalleryCubit extends Cubit<SharedGalleryState> {
  final SharedGalleryDataSource _dataSource;

  SharedGalleryCubit(this._dataSource) : super(SharedGalleryInitial());

  Future<void> shareGallery({
    required List<File> imageFiles,
    required List<String> sharedWithUserIds,
  }) async {
    emit(SharedGalleryLoading());
    try {
      await _dataSource.createGalleryShare(
        imageFiles: imageFiles,
        sharedWithUserIds: sharedWithUserIds,
      );
      emit(SharedGalleryShared());
    } catch (e) {
      emit(SharedGalleryError(e.toString()));
    }
  }

  Stream<List<SharedGalleryModel>> getGalleriesSharedWithMe(String userId) {
    return _dataSource.getGalleriesSharedWithMe(userId);
  }
}
