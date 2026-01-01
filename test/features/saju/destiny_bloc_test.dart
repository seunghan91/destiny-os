import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:destiny_os/features/saju/presentation/bloc/destiny_bloc.dart';

void main() {
  group('DestinyBloc', () {
    late DestinyBloc bloc;

    setUp(() {
      bloc = DestinyBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('초기 상태는 DestinyInitial이다', () {
      expect(bloc.state, isA<DestinyInitial>());
    });

    group('AnalyzeFortune', () {
      blocTest<DestinyBloc, DestinyState>(
        '분석 성공 시 DestinyAnalyzing -> DestinySuccess를 emit한다',
        build: () => DestinyBloc(),
        act: (bloc) => bloc.add(AnalyzeFortune(
          birthDateTime: DateTime(1990, 5, 15, 10, 0),
          isLunar: false,
          mbtiType: 'ENFP',
          gender: 'male',
        )),
        expect: () => [
          isA<DestinyAnalyzing>(),
          isA<DestinyAnalyzing>(),
          isA<DestinyAnalyzing>(),
          isA<DestinyAnalyzing>(),
          isA<DestinyAnalyzing>(),
          isA<DestinySuccess>(),
        ],
        wait: const Duration(seconds: 3),
      );

      blocTest<DestinyBloc, DestinyState>(
        'DestinySuccess에 모든 분석 결과가 포함된다',
        build: () => DestinyBloc(),
        act: (bloc) => bloc.add(AnalyzeFortune(
          birthDateTime: DateTime(1990, 5, 15, 10, 0),
          isLunar: false,
          mbtiType: 'ENFP',
          gender: 'male',
        )),
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<DestinySuccess>());
          if (state is DestinySuccess) {
            expect(state.sajuChart, isNotNull);
            expect(state.tenGods, isNotNull);
            expect(state.daewoonChart, isNotNull);
            expect(state.mbtiType, isNotNull);
            expect(state.fortune2026, isNotNull);
            expect(state.gapAnalysis, isNotNull);
          }
        },
        wait: const Duration(seconds: 3),
      );

      blocTest<DestinyBloc, DestinyState>(
        '야자시 옵션이 적용된다',
        build: () => DestinyBloc(),
        act: (bloc) => bloc.add(AnalyzeFortune(
          birthDateTime: DateTime(1990, 5, 15, 23, 30),
          isLunar: false,
          mbtiType: 'INTJ',
          gender: 'female',
          useNightSubhour: true,
        )),
        verify: (bloc) {
          final state = bloc.state;
          expect(state, isA<DestinySuccess>());
        },
        wait: const Duration(seconds: 3),
      );
    });

    group('UpdateBirthData', () {
      blocTest<DestinyBloc, DestinyState>(
        '초기 상태에서 DestinyInputProgress를 emit한다',
        build: () => DestinyBloc(),
        act: (bloc) => bloc.add(UpdateBirthData(
          birthDateTime: DateTime(1995, 3, 10),
          isLunar: false,
        )),
        expect: () => [
          isA<DestinyInputProgress>()
              .having((s) => s.birthDateTime, 'birthDateTime', DateTime(1995, 3, 10))
              .having((s) => s.isLunar, 'isLunar', false),
        ],
      );

      blocTest<DestinyBloc, DestinyState>(
        '기존 DestinyInputProgress를 업데이트한다',
        build: () => DestinyBloc(),
        seed: () => const DestinyInputProgress(mbtiType: 'ENFP'),
        act: (bloc) => bloc.add(UpdateBirthData(
          birthDateTime: DateTime(1995, 3, 10),
          isLunar: true,
        )),
        expect: () => [
          isA<DestinyInputProgress>()
              .having((s) => s.birthDateTime, 'birthDateTime', DateTime(1995, 3, 10))
              .having((s) => s.isLunar, 'isLunar', true)
              .having((s) => s.mbtiType, 'mbtiType', 'ENFP'),
        ],
      );
    });

    group('UpdateMbti', () {
      blocTest<DestinyBloc, DestinyState>(
        '초기 상태에서 DestinyInputProgress를 emit한다',
        build: () => DestinyBloc(),
        act: (bloc) => bloc.add(const UpdateMbti(mbtiType: 'INFJ')),
        expect: () => [
          isA<DestinyInputProgress>()
              .having((s) => s.mbtiType, 'mbtiType', 'INFJ'),
        ],
      );

      blocTest<DestinyBloc, DestinyState>(
        '기존 DestinyInputProgress를 업데이트한다',
        build: () => DestinyBloc(),
        seed: () => DestinyInputProgress(birthDateTime: DateTime(1990, 1, 1)),
        act: (bloc) => bloc.add(const UpdateMbti(mbtiType: 'ENTP')),
        expect: () => [
          isA<DestinyInputProgress>()
              .having((s) => s.mbtiType, 'mbtiType', 'ENTP')
              .having((s) => s.birthDateTime, 'birthDateTime', DateTime(1990, 1, 1)),
        ],
      );
    });

    group('ResetDestinyData', () {
      blocTest<DestinyBloc, DestinyState>(
        'DestinyInitial로 초기화한다',
        build: () => DestinyBloc(),
        seed: () => const DestinyInputProgress(mbtiType: 'ENFP'),
        act: (bloc) => bloc.add(ResetDestinyData()),
        expect: () => [isA<DestinyInitial>()],
      );
    });
  });

  group('DestinyInputProgress', () {
    test('isComplete는 모든 필드가 채워졌을 때 true를 반환한다', () {
      const incomplete = DestinyInputProgress(
        birthDateTime: null,
        mbtiType: 'ENFP',
      );
      expect(incomplete.isComplete, false);

      final complete = DestinyInputProgress(
        birthDateTime: DateTime(1990, 1, 1),
        isLunar: false,
        mbtiType: 'ENFP',
        gender: 'male',
      );
      expect(complete.isComplete, true);
    });

    test('copyWith는 지정된 필드만 업데이트한다', () {
      final original = DestinyInputProgress(
        birthDateTime: DateTime(1990, 1, 1),
        isLunar: false,
        mbtiType: 'ENFP',
        gender: 'male',
      );

      final updated = original.copyWith(mbtiType: 'INTJ');

      expect(updated.birthDateTime, DateTime(1990, 1, 1));
      expect(updated.isLunar, false);
      expect(updated.mbtiType, 'INTJ');
      expect(updated.gender, 'male');
    });
  });

  group('GapAnalysisResult', () {
    test('hasSignificantGap는 gapScore >= 50일 때 true', () {
      const lowGap = GapAnalysisResult(
        sajuBasedMbti: 'ENFP',
        actualMbti: 'ENFP',
        gapScore: 25,
        interpretation: '',
        hiddenPotential: '',
      );
      expect(lowGap.hasSignificantGap, false);

      const highGap = GapAnalysisResult(
        sajuBasedMbti: 'ENFP',
        actualMbti: 'ISTJ',
        gapScore: 75,
        interpretation: '',
        hiddenPotential: '',
      );
      expect(highGap.hasSignificantGap, true);
    });

    test('matchCount와 mismatchCount를 올바르게 계산한다', () {
      const result = GapAnalysisResult(
        sajuBasedMbti: 'ENFP',
        actualMbti: 'INFP',
        gapScore: 25,
        interpretation: '',
        hiddenPotential: '',
        dimensionGaps: [
          DimensionGap(
            dimension: 'E/I',
            sajuValue: 'E',
            actualValue: 'I',
            hasGap: true,
            description: '',
            insight: '',
          ),
          DimensionGap(
            dimension: 'N/S',
            sajuValue: 'N',
            actualValue: 'N',
            hasGap: false,
            description: '',
            insight: '',
          ),
          DimensionGap(
            dimension: 'T/F',
            sajuValue: 'F',
            actualValue: 'F',
            hasGap: false,
            description: '',
            insight: '',
          ),
          DimensionGap(
            dimension: 'J/P',
            sajuValue: 'P',
            actualValue: 'P',
            hasGap: false,
            description: '',
            insight: '',
          ),
        ],
      );

      expect(result.matchCount, 3);
      expect(result.mismatchCount, 1);
    });
  });

  group('DimensionGap', () {
    test('props가 올바르게 작동한다', () {
      const gap1 = DimensionGap(
        dimension: 'E/I',
        sajuValue: 'E',
        actualValue: 'I',
        hasGap: true,
        description: 'test',
        insight: 'insight',
      );
      const gap2 = DimensionGap(
        dimension: 'E/I',
        sajuValue: 'E',
        actualValue: 'I',
        hasGap: true,
        description: 'test',
        insight: 'insight',
      );

      expect(gap1, equals(gap2));
    });
  });

  group('DestinyEvent', () {
    test('AnalyzeFortune props가 올바르게 작동한다', () {
      final event1 = AnalyzeFortune(
        birthDateTime: DateTime(1990, 5, 15),
        isLunar: false,
        mbtiType: 'ENFP',
        gender: 'male',
      );
      final event2 = AnalyzeFortune(
        birthDateTime: DateTime(1990, 5, 15),
        isLunar: false,
        mbtiType: 'ENFP',
        gender: 'male',
      );

      expect(event1.props, equals(event2.props));
    });

    test('UpdateBirthData props가 올바르게 작동한다', () {
      final event = UpdateBirthData(
        birthDateTime: DateTime(1990, 5, 15),
        isLunar: false,
      );

      expect(event.props, contains(DateTime(1990, 5, 15)));
      expect(event.props, contains(false));
    });

    test('UpdateMbti props가 올바르게 작동한다', () {
      const event = UpdateMbti(mbtiType: 'ENFP');

      expect(event.props, contains('ENFP'));
    });

    test('ResetDestinyData props는 비어있다', () {
      final event = ResetDestinyData();

      expect(event.props, isEmpty);
    });
  });

  group('DestinyState', () {
    test('DestinyAnalyzing message를 가진다', () {
      const state = DestinyAnalyzing(message: '분석 중...');

      expect(state.message, '분석 중...');
      expect(state.props, contains('분석 중...'));
    });

    test('DestinyFailure errorMessage를 가진다', () {
      const state = DestinyFailure(errorMessage: '에러 발생');

      expect(state.errorMessage, '에러 발생');
      expect(state.props, contains('에러 발생'));
    });
  });
}
