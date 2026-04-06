import 'package:cloud_functions/cloud_functions.dart';

/// Server-side AI via Firebase Callable `generateGameContent`.
abstract class GameContentRemoteDataSource {
  Future<String> generateGameContent(Map<String, dynamic> payload);
}

class GameContentRemoteDataSourceImpl implements GameContentRemoteDataSource {
  final FirebaseFunctions _functions;

  GameContentRemoteDataSourceImpl({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  @override
  Future<String> generateGameContent(Map<String, dynamic> payload) async {
    final callable = _functions.httpsCallable('generateGameContent');
    final result = await callable.call<Map<String, dynamic>>(payload);
    final data = result.data;
    if (data == null) {
      throw Exception('Empty response from AI');
    }
    final text = data['text'];
    if (text is! String || text.trim().isEmpty) {
      throw Exception('Invalid AI response');
    }
    return text.trim();
  }
}
