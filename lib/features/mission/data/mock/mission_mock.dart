import '../models/mission.dart';

class MissionMock {
  const MissionMock._();

  static const List<Mission> all = [
    Mission(
      id: '1',
      title: '방청소 하기',
      rewardHours: 0,
      rewardMinutes: 30,
      status: MissionStatus.pendingCheck,
      description: '방청소하고 깨끗하진 방 사진 찍기',
      assignedBy: 'parent',
      category: '청소',
      confirmationMethod: ConfirmationMethod.childSelf,
    ),
    Mission(
      id: '2',
      title: '방청소 하기',
      rewardHours: 0,
      rewardMinutes: 30,
      status: MissionStatus.rejected,
      description: '사진을 다시 찍어주세요.',
      assignedBy: 'parent',
      category: '청소',
      confirmationMethod: ConfirmationMethod.parentApproval,
    ),
    Mission(
      id: '3',
      title: '방청소 하기',
      rewardHours: 1,
      rewardMinutes: 0,
      status: MissionStatus.reviewing,
      description: '제출되었어요. 확인을 기다려주세요.',
      assignedBy: 'ai',
      category: '청소',
      confirmationMethod: ConfirmationMethod.aiAuto,
    ),
    Mission(
      id: '4',
      title: '방청소 하기',
      rewardHours: 1,
      rewardMinutes: 30,
      status: MissionStatus.completed,
      description: '잘했어요!',
      assignedBy: 'parent',
      category: '청소',
      confirmationMethod: ConfirmationMethod.parentApproval,
    ),
    Mission(
      id: '5',
      title: '숙제하기',
      rewardHours: 0,
      rewardMinutes: 15,
      status: MissionStatus.pendingCheck,
      description: '수학 문제집 p.32-35 풀고 사진 제출.',
      assignedBy: 'parent',
      category: '학습',
      confirmationMethod: ConfirmationMethod.parentApproval,
    ),
  ];

  static Mission byId(String id) =>
      all.firstWhere((m) => m.id == id, orElse: () => all.first);
}
