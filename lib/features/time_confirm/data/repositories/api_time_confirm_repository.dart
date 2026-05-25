import '../../../../core/models/result.dart';
import '../models/time_confirm_data.dart';
import 'time_confirm_repository.dart';

/// HTTP-backed implementation of [TimeConfirmRepository].
///
/// Stub for Phase 2A — every method throws [UnimplementedError] until
/// backend endpoints are confirmed and wired through `DioConfig`.
class ApiTimeConfirmRepository implements TimeConfirmRepository {
  @override
  Future<Result<TimeConfirmData>> fetchCurrentSchedule() async {
    throw UnimplementedError(
      'ApiTimeConfirmRepository.fetchCurrentSchedule: backend not wired yet.',
    );
  }

  @override
  Future<Result<void>> requestModification() async {
    throw UnimplementedError(
      'ApiTimeConfirmRepository.requestModification: backend not wired yet.',
    );
  }

  @override
  Future<Result<void>> acknowledgeSchedule() async {
    throw UnimplementedError(
      'ApiTimeConfirmRepository.acknowledgeSchedule: backend not wired yet.',
    );
  }
}
