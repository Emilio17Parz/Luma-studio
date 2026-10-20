import 'dart:convert';

typedef J = Map<String, dynamic>;
String uid() => DateTime.now().microsecondsSinceEpoch.toString();
J clone(J x) => jsonDecode(jsonEncode(x)) as J;
List<J> rows(dynamic x) =>
    (x as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

/// Validate the entire package before changing any stored data.
J parsePackage(String input) {
  var text = input.trim().replaceFirst(RegExp(r'^\uFEFF'), '');
  if (text.startsWith('```')) {
    text = text
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '');
  }
  final raw = jsonDecode(text);
  if (raw is! Map<String, dynamic>)
    throw const FormatException('Se esperaba un objeto JSON.');
  validateCourse(raw);
  return raw;
}

void validateCourse(J c) {
  void str(J m, String k) {
    if (m[k] is! String || (m[k] as String).trim().isEmpty)
      throw FormatException('Falta un texto válido en "$k".');
  }

  str(c, 'titulo');
  if (c['descripcion'] != null && c['descripcion'] is! String)
    throw const FormatException('descripcion debe ser texto.');
  if (c['version'] != '1.0.0')
    throw const FormatException('La versión compatible es 1.0.0.');
  if (c['temas'] is! List)
    throw const FormatException('"temas" debe ser una lista.');
  final ids = <String>{};
  for (final t in rows(c['temas'])) {
    for (final k in ['id', 'titulo']) {
      str(t, k);
    }
    if (!ids.add('tema:${t['id']}'))
      throw FormatException('Tema repetido: ${t['id']}');
    if (t['resumen'] is! String) throw const FormatException('Falta resumen.');
    if (t['objetivos'] is! List ||
        (t['objetivos'] as List).any((v) => v is! String))
      throw const FormatException('Objetivos debe ser una lista de textos.');
    for (final kind in ['conceptos', 'tarjetas', 'preguntas']) {
      if (t[kind] is! List) throw FormatException('Falta la lista $kind.');
      for (final r in rows(t[kind])) {
        if (kind == 'conceptos') {
          str(r, 'termino');
          str(r, 'definicion');
          continue;
        }
        str(r, 'id');
        if (r['fuente'] != null && r['fuente'] is! String)
          throw const FormatException('fuente debe ser texto.');
        if (r['dificultad'] != null && r['dificultad'] is! String)
          throw const FormatException('dificultad debe ser texto.');
        if (!ids.add('$kind:${r['id']}'))
          throw FormatException('Identificador repetido: ${r['id']}');
        if (kind == 'tarjetas') {
          str(r, 'pregunta');
          str(r, 'respuesta');
        } else {
          str(r, 'enunciado');
          str(r, 'explicacion');
          final o = r['opciones'];
          final a = r['indiceCorrecto'];
          if (o is! List ||
              o.length != 4 ||
              o.any((v) => v is! String || v.trim().isEmpty))
            throw const FormatException(
                'Cada pregunta necesita cuatro opciones no vacías.');
          if (a is! int || a < 0 || a > 3)
            throw const FormatException(
                'indiceCorrecto debe estar entre 0 y 3.');
        }
      }
    }
  }
}

J mergeCourses(J current, J incoming, {required bool replace}) {
  final result = clone(current);
  final topics = rows(result['temas']);
  for (final next in rows(incoming['temas'])) {
    final i = topics.indexWhere((t) => t['id'] == next['id']);
    if (i < 0) {
      topics.add(clone(next));
      continue;
    }
    final old = topics[i];
    if (replace) {
      old['titulo'] = next['titulo'];
      old['resumen'] = next['resumen'];
      old['objetivos'] = next['objetivos'];
    }
    for (final kind in ['conceptos', 'tarjetas', 'preguntas']) {
      final key = kind == 'conceptos' ? 'termino' : 'id';
      final items = rows(old[kind]);
      for (final item in rows(next[kind])) {
        final j = items.indexWhere((e) => e[key] == item[key]);
        if (j < 0) {
          items.add(clone(item));
        } else if (replace) {
          items[j] = clone(item);
        }
      }
      old[kind] = items;
    }
  }
  result['temas'] = topics;
  validateCourse(result);
  return result;
}

const aiPrompt =
    '''Prepara material de estudio usando exclusivamente mis fuentes. Entrega un objeto JSON válido, sin texto adicional, con version "1.0.0", titulo, descripcion y temas.
Cada tema incluye id único, titulo, objetivos (lista de textos), resumen (texto), conceptos (lista de {termino, definicion}), tarjetas (lista de {id, pregunta, respuesta, fuente}) y preguntas (lista de {id, enunciado, opciones, indiceCorrecto, explicacion, dificultad, fuente}).
opciones tiene exactamente cuatro textos; indiceCorrecto es un entero de 0 a 3. Usa dificultad fácil, intermedio o difícil. fuente es texto: documento y sección, sin inventar páginas. Todos los campos anteriores deben aparecer; usa listas vacías cuando corresponda.
Los identificadores de tarjetas y preguntas deben ser únicos en todo el curso. Para ampliar un curso conserva los IDs existentes y usa nuevos IDs para contenido nuevo. Evita preguntas duplicadas. Varía la posición de la respuesta correcta. Crea ejercicios originales y casos prácticos respaldados por las fuentes; no los presentes como preguntas oficiales de certificación.
No inventes información ni equivalencias entre certificaciones. Todo debe poder consultarse sin internet. Si es demasiado largo, entrega un módulo por respuesta dentro de un objeto completo con version, titulo, descripcion y temas. Nunca cortes el JSON a la mitad.''';
