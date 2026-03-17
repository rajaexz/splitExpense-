import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/theme_cubit.dart';
import '../constants/app_dimensions.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return IconButton(
          icon: Icon(
            state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            size: AppDimensions.iconSize24,
          ),
          onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          tooltip: state.isDarkMode ? 'Light Mode' : 'Dark Mode',
        );
      },
    );
  }
}

