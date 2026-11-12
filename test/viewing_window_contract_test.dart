import 'package:flutter_test/flutter_test.dart';
import 'package:universa/app/data/models/subject_model.dart';

/// اختبارات عقد نافذة المشاهدة كما يعيده الـ Django backend.
void main() {
  group('Lesson.fromJson — GET /api/mobile/lessons/<id>/', () {
    test('disabled → تشغيل عادي (الحالة صريحة من الخادم)', () {
      final lesson = Lesson.fromJson({
        'id': 1,
        'title': 'Lesson',
        'order_index': 0,
        'viewing_window_state': 'disabled',
        'viewing_window_remaining_seconds': 0,
        'viewing_window_expires_at': null,
      });

      expect(lesson.viewingWindowState, ViewingWindowStates.disabled);
      expect(lesson.viewingWindowRemainingSeconds, 0);
      expect(lesson.viewingWindowExpiresAt, isNull);
    });

    test('not_started → مودال التأكيد', () {
      final lesson = Lesson.fromJson({
        'id': 1,
        'title': 'Lesson',
        'order_index': 0,
        'viewing_window_state': 'not_started',
        'viewing_window_remaining_seconds': null,
        'viewing_window_expires_at': null,
      });

      expect(lesson.viewingWindowState, ViewingWindowStates.notStarted);
      expect(lesson.viewingWindowRemainingSeconds, isNull);
    });

    test('active → الوقت المتبقي', () {
      final lesson = Lesson.fromJson({
        'id': 1,
        'title': 'Lesson',
        'order_index': 0,
        'viewing_window_state': 'active',
        'viewing_window_remaining_seconds': 10800,
        'viewing_window_expires_at': '2026-11-11T18:30:00Z',
      });

      expect(lesson.viewingWindowState, ViewingWindowStates.active);
      expect(lesson.viewingWindowRemainingSeconds, 10800);
      expect(
        lesson.viewingWindowExpiresAt,
        DateTime.parse('2026-11-11T18:30:00Z'),
      );
    });

    test('expired → منع التشغيل أونلاين', () {
      final lesson = Lesson.fromJson({
        'id': 1,
        'title': 'Lesson',
        'order_index': 0,
        'viewing_window_state': 'expired',
        'viewing_window_remaining_seconds': 0,
        'viewing_window_expires_at': '2026-11-10T10:00:00Z',
      });

      expect(lesson.viewingWindowState, ViewingWindowStates.expired);
      expect(
        lesson.viewingWindowExpiresAt,
        DateTime.parse('2026-11-10T10:00:00Z'),
      );
    });

    test('حقل viewing_window_state غائب → unknown وليس disabled', () {
      final lesson = Lesson.fromJson({
        'id': 1,
        'title': 'Lesson',
        'order_index': 0,
      });

      expect(lesson.viewingWindowState, ViewingWindowStates.unknown);
      expect(lesson.viewingWindowState, isNot(ViewingWindowStates.disabled));
      expect(lesson.viewingWindowRemainingSeconds, isNull);
      expect(lesson.viewingWindowExpiresAt, isNull);
    });

    test('قيمة null أو قيمة غير معروفة → unknown', () {
      final nullState = Lesson.fromJson({
        'id': 1,
        'title': 'Lesson',
        'order_index': 0,
        'viewing_window_state': null,
      });
      final garbage = Lesson.fromJson({
        'id': 1,
        'title': 'Lesson',
        'order_index': 0,
        'viewing_window_state': 'something_else',
      });

      expect(nullState.viewingWindowState, ViewingWindowStates.unknown);
      expect(garbage.viewingWindowState, ViewingWindowStates.unknown);
    });

    test('الحقل القديم viewing_window_status لا يُفسَّر كحالة صالحة', () {
      final lesson = Lesson.fromJson({
        'id': 1,
        'title': 'Lesson',
        'order_index': 0,
        'viewing_window_status': 'disabled',
      });

      expect(lesson.viewingWindowState, ViewingWindowStates.unknown);
    });

    test('الحقول التالفة لا ترمي استثناء', () {
      final lesson = Lesson.fromJson({
        'id': 1,
        'title': 'Lesson',
        'order_index': 0,
        'viewing_window_state': 'active',
        'viewing_window_remaining_seconds': 'not-a-number',
        'viewing_window_expires_at': 'not-a-date',
      });

      expect(lesson.viewingWindowState, ViewingWindowStates.active);
      expect(lesson.viewingWindowRemainingSeconds, isNull);
      expect(lesson.viewingWindowExpiresAt, isNull);
    });
  });

  group('ViewingWindowInfo.fromJson — GET/POST .../viewing-window/', () {
    test('active مع restriction_enabled و remaining_seconds و expires_at', () {
      final info = ViewingWindowInfo.fromJson({
        'state': 'active',
        'restriction_enabled': true,
        'remaining_seconds': 10800,
        'expires_at': '2026-11-11T18:30:00Z',
      });

      expect(info.state, ViewingWindowStates.active);
      expect(info.restrictionEnabled, isTrue);
      expect(info.remainingSeconds, 10800);
      expect(info.expiresAt, DateTime.parse('2026-11-11T18:30:00Z'));
    });

    test('disabled مع restriction_enabled = false', () {
      final info = ViewingWindowInfo.fromJson({
        'state': 'disabled',
        'restriction_enabled': false,
        'remaining_seconds': 0,
        'expires_at': null,
      });

      expect(info.state, ViewingWindowStates.disabled);
      expect(info.restrictionEnabled, isFalse);
      expect(info.expiresAt, isNull);
    });

    test('not_started / expired', () {
      expect(
        ViewingWindowInfo.fromJson({'state': 'not_started'}).state,
        ViewingWindowStates.notStarted,
      );
      expect(
        ViewingWindowInfo.fromJson({'state': 'expired'}).state,
        ViewingWindowStates.expired,
      );
    });

    test('الحقل state غائب أو تالف → unknown', () {
      expect(
        ViewingWindowInfo.fromJson({}).state,
        ViewingWindowStates.unknown,
      );
      expect(
        ViewingWindowInfo.fromJson({'state': 123}).state,
        ViewingWindowStates.unknown,
      );
      expect(
        ViewingWindowInfo.fromJson({'state': 'ACTIVE '}).state,
        ViewingWindowStates.active,
      );
    });

    test('remaining_seconds يقبل num و String', () {
      expect(
        ViewingWindowInfo.fromJson({'remaining_seconds': 3600}).remainingSeconds,
        3600,
      );
      expect(
        ViewingWindowInfo.fromJson({'remaining_seconds': 3600.0})
            .remainingSeconds,
        3600,
      );
      expect(
        ViewingWindowInfo.fromJson({'remaining_seconds': ' 5400 '})
            .remainingSeconds,
        5400,
      );
      expect(
        ViewingWindowInfo.fromJson({'remaining_seconds': 'abc'}).remainingSeconds,
        isNull,
      );
    });
  });

  group('ViewingWindowStates.normalize', () {
    test('يقبل الحالات الأربع فقط', () {
      expect(ViewingWindowStates.normalize('not_started'), 'not_started');
      expect(ViewingWindowStates.normalize('active'), 'active');
      expect(ViewingWindowStates.normalize('expired'), 'expired');
      expect(ViewingWindowStates.normalize('disabled'), 'disabled');
    });

    test('أي شيء آخر → unknown', () {
      expect(ViewingWindowStates.normalize(null), 'unknown');
      expect(ViewingWindowStates.normalize(''), 'unknown');
      expect(ViewingWindowStates.normalize('enabled'), 'unknown');
      expect(ViewingWindowStates.normalize(true), 'unknown');
      expect(ViewingWindowStates.normalize('error'), 'unknown');
    });
  });
}
