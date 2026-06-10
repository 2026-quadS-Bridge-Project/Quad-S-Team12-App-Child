import 'dart:async';

import 'package:bridge_k/core/models/result.dart';
import 'package:bridge_k/core/services/photo_upload_service.dart';
import 'package:bridge_k/features/mission/data/models/mission.dart';
import 'package:bridge_k/features/mission/data/repositories/mission_repository.dart';
import 'package:bridge_k/features/mission/state/mission_controller.dart';
import 'package:dio/dio.dart';
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

  test('submit exposes loading while photo submission is in flight', () async {
    final Completer<Result<MissionSubmissionResult>> submitCompleter =
        Completer<Result<MissionSubmissionResult>>();
    final MissionController controller = MissionController(
      missionId: '1',
      repository: _DelayedSubmissionMissionRepository(submitCompleter),
      uploadService: const _EchoPhotoUploadService(),
    );
    addTearDown(controller.dispose);

    controller.goToCameraPrompt();
    await controller.addCapturedPhoto('/tmp/proof.jpg');
    expect(controller.step, MissionFlowStep.photoPreview);

    final Future<void> submission = controller.submit(aiAutoApprove: false);

    expect(controller.isLoading, isTrue);
    expect(controller.canSubmit, isFalse);
    controller.goBack();
    expect(controller.step, MissionFlowStep.photoPreview);

    submitCompleter.complete(
      Result<MissionSubmissionResult>.success(
        const MissionSubmissionResult(
          status: MissionStatus.reviewing,
          performanceId: '301',
        ),
      ),
    );
    await submission;

    expect(controller.isLoading, isFalse);
    expect(controller.mission.performanceId, '301');
    expect(controller.step, MissionFlowStep.submitted);
  });

  test(
    'api photo upload service preserves local path for multipart submit',
    () async {
      final ApiPhotoUploadService service = ApiPhotoUploadService(Dio());

      final Result<String> result = await service.uploadPhoto('/tmp/proof.jpg');

      switch (result) {
        case Success<String>(data: final String path):
          expect(path, '/tmp/proof.jpg');
        case Failure<String>(message: final String message):
          fail('uploadPhoto should preserve the local path, got $message');
      }
    },
  );

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

class _DelayedSubmissionMissionRepository implements MissionRepository {
  const _DelayedSubmissionMissionRepository(this.submitCompleter);

  final Completer<Result<MissionSubmissionResult>> submitCompleter;

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
  }) {
    return submitCompleter.future;
  }
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
