import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma_study/model.dart';
import 'package:luma_study/store.dart';

void main() {
  late J seed;
  setUp(() {
    seed = parsePackage(File('assets/seed.json').readAsStringSync());
  });
  test('Imports the original course, including fenced AI output', () {
    expect(parsePackage('```json\n${jsonEncode(seed)}\n```')['temas'],
        hasLength(1));
    expect(rows(seed['temas']).first['tarjetas'], hasLength(5));
  });
  test('Rejects out of range correct option before any mutation', () {
    seed['temas'][0]['preguntas'][0]['indiceCorrecto'] = 4;
    expect(() => validateCourse(seed), throwsFormatException);
  });
  test('Rejects duplicate question IDs', () {
    seed['temas'][0]['preguntas'].add(clone(seed['temas'][0]['preguntas'][0]));
    expect(() => validateCourse(seed), throwsFormatException);
  });
  test('Merging preserves existing content when replace is disabled', () {
    final incoming = clone(seed);
    incoming['temas'][0]['tarjetas'][0]['respuesta'] = 'Nueva respuesta';
    final before = jsonEncode(seed);
    final result = mergeCourses(seed, incoming, replace: false);
    expect(result['temas'][0]['tarjetas'][0]['respuesta'],
        seed['temas'][0]['tarjetas'][0]['respuesta']);
    expect(jsonEncode(seed), before);
  });
  test('Updating matches keeps other elements and adds new IDs', () {
    final incoming = clone(seed);
    incoming['temas'][0]['tarjetas'] = [
      {'id': 'new-card', 'pregunta': 'Q', 'respuesta': 'A', 'fuente': ''}
    ];
    final result = mergeCourses(seed, incoming, replace: true);
    expect(result['temas'][0]['tarjetas'], hasLength(6));
  });
  test('Updating replaces the matching card only', () {
    final incoming = clone(seed);
    incoming['temas'][0]['tarjetas'][0]['respuesta'] = 'Updated';
    final result = mergeCourses(seed, incoming, replace: true);
    expect(result['temas'][0]['tarjetas'][0]['respuesta'], 'Updated');
    expect(result['temas'][0]['tarjetas'], hasLength(5));
  });
  test('Backup rejects missing progress fields', () {
    seed['id'] = 'course';
    expect(
        () => Store.validateBackup({
              'courses': [seed],
              'progress': {'bad': {}},
              'dark': false
            }),
        throwsFormatException);
  });
  test('Backup roundtrip preserves course and progress', () {
    seed['id'] = 'course';
    final data = {
      'courses': [seed],
      'progress': {
        'course/preguntas/q': {
          'attempts': 2,
          'correct': 1,
          'known': false,
          'favorite': true,
          'last': false
        }
      },
      'dark': true
    };
    final restored = jsonDecode(jsonEncode(data)) as J;
    Store.validateBackup(restored);
    expect(restored['progress'], data['progress']);
  });
}
