import 'package:bridge_k/core/models/result.dart';
import 'package:bridge_k/core/services/photo_upload_service.dart';
import 'package:bridge_k/features/mission/data/models/mission.dart';
import 'package:bridge_k/features/mission/data/repositories/mission_repository.dart';
import 'package:bridge_k/features/mission/state/mission_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unknown backend mission id starts from neutral placeholder', () async {
    final MissionController controller = MissionController(
      missionId: '42',
      repository: _FailingMissionRepository(),
    );
    addTearDown(controller.dispose);

    expect(controller.mission.id, '42');
    expect(controller.mission.title, '미션 정보를 불러오는 중');
    expect(controller.mission.title, isNot('방청소 하기'));

    await controller.reload();

    expect(controller.mission.id, '42');
    expect(controller.mission.title, '미션 정보를 불러오는 중');
    expect(controller.errorMessage, '미션을 불러오지 못했습니다.');
  });

  test('submit keeps backend performance id on the mission', () async {
    final MissionController controller = MissionController(
      missionId: '1',
      repository: _SubmissionMissionRepository(
        result: const MissionSubmissionResult(
          status: MissionStatus.reviewing,
          performanceId: '201',
        ),
      ),
      uploadService: const _EchoPhotoUploadService(),
    );
    addTearDown(controller.dispose);

    await controller.addCapturedPhoto('/tmp/proof.jpg');
    await controller.submit(aiAutoApprove: false);

    expect(controller.mission.performanceId, '201');
    expect(controller.mission.photoUrls, <String>['/tmp/proof.jpg']);
  });

  test('reload updates flow step from backend mission status', () async {
    final MissionController controller = MissionController(
      missionId: '42',
      repository: const _LoadedMissionRepository(
        Mission(
          id: '42',
          title: '알림 미션',
          rewardHours: 0,
          rewardMinutes: 30,
          status: MissionStatus.reviewing,
          performanceId: '201',
        ),
      ),
    );
    addTearDown(controller.dispose);

    expect(controller.step, MissionFlowStep.info);

    await controller.reload();

    expect(controller.mission.performanceId, '201');
    expect(controller.step, MissionFlowStep.submitted);
  });
}

class _FailingMissionRepository implements MissionRepository {
  @override
  Future<Result<Mission>> fetchMission(String id) async {
    return Result<Mission>.failure('미션을 불러오지 못했습니다.');
  }

  @override
  Future<Result<List<Mission>>> listMissions() async {
    return Result<List<Mission>>.success(const <Mission>[]);
  }

  @override
  Future<Result<MissionSubmissionResult>> submitMission({
    required String id,
    required List<String> photoPaths,
  }) async {
    return Result<MissionSubmissionResult>.failure('미션 제출에 실패했습니다.');
  }
}

class _SubmissionMissionRepository implements MissionRepository {
  const _SubmissionMissionRepository({required this.result});

  final MissionSubmissionResult result;

  @override
  Future<Result<Mission>> fetchMission(String id) async {
    return Result<Mission>.failure('미션을 불러오지 못했습니다.');
  }

  @override
  Future<Result<List<Mission>>> listMissions() async {
    return Result<List<Mission>>.success(const <Mission>[]);
  }

  @override
  Future<Result<MissionSubmissionResult>> submitMission({
    required String id,
    required List<String> photoPaths,
  }) async {
    return Result<MissionSubmissionResult>.success(result);
  }
}

class _LoadedMissionRepository implements MissionRepository {
  const _LoadedMissionRepository(this.mission);

  final Mission mission;

  @override
  Future<Result<Mission>> fetchMission(String id) async {
    return Result<Mission>.success(mission);
  }

  @override
  Future<Result<List<Mission>>> listMissions() async {
    return Result<List<Mission>>.success(<Mission>[mission]);
  }

  @override
  Future<Result<MissionSubmissionResult>> submitMission({
    required String id,
    required List<String> photoPaths,
  }) async {
    return Result<MissionSubmissionResult>.failure('미션 제출에 실패했습니다.');
  }
}

class _EchoPhotoUploadService implements PhotoUploadService {
  const _EchoPhotoUploadService();

  @override
  Future<Result<String>> uploadPhoto(String localPath) async {
    return Result<String>.success(localPath);
  }
}
