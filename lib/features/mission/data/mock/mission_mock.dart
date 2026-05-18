import '../models/mission.dart';

class MissionMock {
  const MissionMock._();

  static const List<Mission> all = [
    Mission(
      id: '1',
      title: '방청소 하기',
      rewardHours: 1,
      rewardMinutes: 0,
      status: MissionStatus.pendingCheck,
      description: '책상과 침대 주변을 정리해주세요.',
      assignedBy: 'parent',
    ),
    Mission(
      id: '2',
      title: '방청소 하기',
      rewardHours: 1,
      rewardMinutes: 0,
      status: MissionStatus.rejected,
      description: '사진을 다시 찍어주세요.',
      assignedBy: 'parent',
    ),
    Mission(
      id: '3',
      title: '방청소 하기',
      rewardHours: 1,
      rewardMinutes: 0,
      status: MissionStatus.reviewing,
      description: '제출되었어요. 확인을 기다려주세요.',
      assignedBy: 'ai',
    ),
    Mission(
      id: '4',
      title: '방청소 하기',
      rewardHours: 1,
      rewardMinutes: 0,
      status: MissionStatus.completed,
      description: '잘했어요!',
      assignedBy: 'parent',
    ),
    Mission(
      id: '5',
      title: '숙제하기',
      rewardHours: 0,
      rewardMinutes: 15,
      status: MissionStatus.pendingCheck,
      description: '수학 문제집 p.32-35 풀고 사진 제출.',
      assignedBy: 'parent',
    ),
  ];

  static Mission byId(String id) =>
      all.firstWhere((m) => m.id == id, orElse: () => all.first);
}
