import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equatable/equatable.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final SharedPreferences _prefs;
  static const String _themeKey = 'theme_mode';
  
  ThemeCubit(this._prefs) : super(ThemeState.initial()) {
    _loadTheme();
  }
  
  void _loadTheme() {
    final isDark = _prefs.getBool(_themeKey) ?? false;
    emit(state.copyWith(isDarkMode: isDark));
  }
  
  void toggleTheme() {
    final newMode = !state.isDarkMode;
    _prefs.setBool(_themeKey, newMode);
    emit(state.copyWith(isDarkMode: newMode));
  }
  
  void setTheme(bool isDark) {
    _prefs.setBool(_themeKey, isDark);
    emit(state.copyWith(isDarkMode: isDark));
  }
}

