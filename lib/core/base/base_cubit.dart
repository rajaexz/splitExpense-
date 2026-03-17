import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

abstract class BaseCubit<T extends Equatable> extends Cubit<T> {
  BaseCubit(super.initialState);
  
  void emitLoading() {
    // Override in child classes to emit loading state
  }
  
  void emitError(String message) {
    // Override in child classes to emit error state
  }
  
  void emitSuccess() {
    // Override in child classes to emit success state
  }
}

