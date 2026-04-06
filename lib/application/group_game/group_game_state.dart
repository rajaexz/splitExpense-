import 'package:equatable/equatable.dart';
import '../../data/models/group_game_model.dart';

abstract class GroupGameState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GroupGameInitial extends GroupGameState {}

class GroupGameLoading extends GroupGameState {}

class GroupGameNotFound extends GroupGameState {}

class GroupGameError extends GroupGameState {
  final String message;
  GroupGameError(this.message);
  @override
  List<Object?> get props => [message];
}

class GroupGameLoaded extends GroupGameState {
  final GroupGameModel game;
  final bool aiGenerating;
  final Map<String, String> displayNames;

  GroupGameLoaded(
    this.game, {
    this.aiGenerating = false,
    this.displayNames = const {},
  });

  GroupGameLoaded copyWith({
    GroupGameModel? game,
    bool? aiGenerating,
    Map<String, String>? displayNames,
  }) {
    return GroupGameLoaded(
      game ?? this.game,
      aiGenerating: aiGenerating ?? this.aiGenerating,
      displayNames: displayNames ?? this.displayNames,
    );
  }

  @override
  List<Object?> get props => [game, aiGenerating, displayNames];
}
