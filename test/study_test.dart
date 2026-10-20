import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luma_study/main.dart';
import 'package:luma_study/store.dart';

void main() {
  testWidgets('Quiz grades the correct text after shuffling, records it once',
      (tester) async {
    final store = Store();
    await tester.pumpWidget(MaterialApp(
        home: StudyPage(
            store: store,
            courseId: 'c',
            kind: 'preguntas',
            items: [
              {
                'id': 'q',
                'enunciado': 'Selecciona la respuesta correcta',
                'opciones': ['Correcta', 'Otra', 'Tercera', 'Cuarta'],
                'indiceCorrecto': 0,
                'explicacion': 'Explicación de ejemplo',
                'fuente': 'Notas',
              }
            ],
            save: (change) async {
              change();
              return true;
            })));
    await tester.tap(find.text('Correcta'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Comprobar respuesta'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Comprobar respuesta'));
    await tester.pumpAndSettle();
    expect(store.state('c/preguntas/q')['correct'], 1);
    expect(store.state('c/preguntas/q')['attempts'], 1);
    expect(find.text('¡Bien hecho!'), findsOneWidget);
  });
  testWidgets('Failed save does not complete a flashcard session',
      (tester) async {
    final store = Store();
    await tester.pumpWidget(MaterialApp(
        home: StudyPage(
            store: store,
            courseId: 'c',
            kind: 'tarjetas',
            items: [
              {
                'id': 't',
                'pregunta': 'Pregunta',
                'respuesta': 'Respuesta',
                'fuente': 'Notas',
              }
            ],
            save: (_) async => false)));
    await tester.tap(find.text('Mostrar respuesta'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('La recuerdo'), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('La recuerdo'));
    await tester.pumpAndSettle();
    expect(find.text('Sesión terminada'), findsNothing);
    expect(find.text('La recuerdo'), findsOneWidget);
  });
}
