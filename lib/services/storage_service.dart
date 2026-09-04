import 'dart:io';
import '../models/penalty_model.dart';

/// OWNER: Person A
/// Person B's camera_capture_screen.dart calls uploadPenaltyPhoto() right
/// after image_picker returns a File, then navigates to the leaderboard.
/// Person B's leaderboard_screen.dart calls watchAllPenalties() to render
/// the "wall of shame".
class StorageService {
  /// Uploads to Firebase Storage at penalty_photos/{uid}/{tradeId}.jpg,
  /// then writes a PenaltyModel doc to Firestore "penalties" collection
  /// with the resulting download URL. Returns the created PenaltyModel.
  /// TODO(Person A): implement
  Future<PenaltyModel> uploadPenaltyPhoto({
    required File photo,
    required String uid,
    required String tradeId,
    required double lossAmount,
  }) async {
    throw UnimplementedError('TODO: Person A');
  }

  /// Live stream of ALL users' penalties, newest first, for the shared
  /// leaderboard/wall-of-shame screen.
  /// TODO(Person A): implement via Firestore snapshots(), orderBy createdAt desc
  Stream<List<PenaltyModel>> watchAllPenalties() {
    throw UnimplementedError('TODO: Person A');
  }
}
