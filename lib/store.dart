import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'model.dart';

class Store {
  late File file;
  J data = {
    'courses': <dynamic>[],
    'progress': <String, dynamic>{},
    'dark': false
  };
  List<J> get courses => rows(data['courses']);
  J get progress => data['progress'] as J;
  Future<void> load() async {
    final dir = await getApplicationDocumentsDirectory();
    file = File('${dir.path}/luma_study.json');
    if (await file.exists()) {
      data = jsonDecode(await file.readAsString()) as J;
      validateBackup(data);
    } else {
      final course =
          parsePackage(await rootBundle.loadString('assets/seed.json'));
      course['id'] = 'zscaler-edu200';
      data['courses'] = [course];
      await save();
    }
  }

  static void validateBackup(J value) {
    if (value['courses'] is! List ||
        value['progress'] is! Map ||
        value['dark'] is! bool)
      throw const FormatException('Respaldo inválido.');
    final ids = <String>{};
    for (final c in rows(value['courses'])) {
      validateCourse(c);
      if (c['id'] is! String || !ids.add(c['id'] as String))
        throw const FormatException('ID de curso inválido o repetido.');
    }
    for (final p in (value['progress'] as Map).values) {
      if (p is! Map ||
          p['attempts'] is! int ||
          p['correct'] is! int ||
          p['known'] is! bool ||
          p['favorite'] is! bool ||
          (p['last'] != null && p['last'] is! bool))
        throw const FormatException('Progreso inválido.');
    }
  }

  Future<void> save() async {
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(data), flush: true);
    // Keep the prior valid state available even if the replacement is interrupted.
    if (await file.exists()) await file.copy('${file.path}.bak');
    await temp.rename(file.path);
  }

  J state(String key) => Map<String, dynamic>.from(progress[key] as Map? ??
      {
        'attempts': 0,
        'correct': 0,
        'known': false,
        'favorite': false,
        'last': null
      });
}
