# Luma Study — Flutter / Dart

Una biblioteca de estudio personal, en español y sin conexión. Diseño Material 3 con tema claro/oscuro, índigo y menta, diseño de una columna adaptable a teléfonos y ventanas grandes. No utiliza fuentes remotas, cuentas, publicidad ni API de IA.

## Iniciar en Windows / VS Code

1. Extrae este ZIP. Abre la carpeta `Luma_Study` en VS Code.
2. En una terminal PowerShell dentro de esa carpeta ejecuta:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Preparar.ps1
flutter devices
flutter run -d 2c28dea2
```

El identificador `2c28dea2` corresponde al teléfono que habías conectado; si `flutter devices` muestra otro, usa ese. Acepta la autorización USB en el teléfono.

La primera preparación requiere internet para las dependencias, SDK y herramientas de compilación. `Preparar.ps1` genera las carpetas nativas en un temporal y copia solo Android, iOS y Windows; conserva el código y el contenido de Luma. Después ejecuta el formateador, el analizador y las pruebas. Se detiene si alguno falla. Si tu PC tiene otra compilación de Flutter en curso, espera a que termine para evitar el bloqueo de inicio.

Para siguientes ejecuciones:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Iniciar.ps1 -Dispositivo 2c28dea2
```

Para probar en Windows (requiere herramientas de desarrollo de escritorio de Visual Studio): `flutter run -d windows`.

## APK independiente

```powershell
flutter build apk --release
```

Salida: `build/app/outputs/flutter-apk/app-release.apk`. Es una compilación local con la firma de desarrollo configurada por la plantilla Flutter; para publicar debes configurar tu propia firma. La APK instalada no necesita mantener el teléfono conectado ni ejecutar un servidor. Comprueba el funcionamiento en modo avión después de instalarla.

iOS requiere macOS, Xcode, generar/verificar la plataforma y configurar firma. No se incluye una compilación iOS ni APK precompilada. Esta entrega está dirigida a Android, iOS y Windows nativos; no a Chrome/web.

## Qué incluye

- Cursos independientes y búsqueda en la biblioteca.
- Temas con apuntes seleccionables, objetivos y conceptos.
- Tarjetas con respuesta oculta, favoritos y estado aprendido/repasar.
- Cuestionarios con preguntas y opciones mezcladas, corrección y explicación.
- Práctica por curso o por tema; repaso de los últimos errores y favoritos.
- Progreso por elemento: intentos, aciertos y última respuesta. No hay programación de repetición espaciada en esta versión.
- Formularios para crear/editar cursos, temas, conceptos, tarjetas y preguntas; eliminación de elementos y cursos con confirmación.
- Importación JSON/TXT o contenido pegado, incluido un único bloque ```json de una IA.
- Vista de revisión antes de importar, curso de destino y elección de actualizar o conservar coincidencias por ID.
- Botón de copiar instrucciones para IA.
- Exportación de curso o respaldo completo y restauración con confirmación.
- Guardado local con archivo temporal y copia previa `.bak`.

## Tu material de Zscaler

Se incluye el módulo que enviaste: 1 tema, 6 conceptos, 5 tarjetas y 4 preguntas. No se verificó su exactitud frente a las fuentes oficiales ni su cobertura de la certificación. El título se dejó como Zscaler EDU-200 sin afirmar equivalencia de credenciales. El curso inicial se copia al abrir por primera vez; no sobrescribe datos existentes.

Cuando tengas los módulos restantes:

1. Entra en **Añadir → Importar archivo** o **Pegar contenido**.
2. Selecciona **Zscaler EDU-200** como destino.
3. Desactiva “Actualizar coincidencias” para conservar tarjetas existentes; actívalo si quieres sustituir contenido con el mismo ID. Los módulos nuevos siempre se añaden.
4. Revisa las cantidades y confirma.

Mantén IDs estables y únicos dentro del curso. Al actualizar material se conservan los avances vinculados a esos IDs; un acierto antiguo puede corresponder a una versión anterior de la pregunta. El modo “Mis errores” utiliza la última respuesta guardada, no todos los errores históricos.

## Datos y respaldos

Los datos se guardan como `luma_study.json` en el directorio de documentos de la app. La copia previa se llama `luma_study.json.bak`. No se envía contenido a servidores. Exporta un respaldo desde Ajustes antes de desinstalar, borrar datos o cambiar de teléfono. El respaldo completo reemplaza el estado actual al restaurarse; exportar un curso solo incluye material, sin avances.

Límite por importación de archivo: 10 MB. Esta primera versión trabaja con texto; no incluye PDF, OCR, audio, imágenes, chat IA integrado ni sincronización entre dispositivos.

## Verificación de esta entrega

Se comprobó la sintaxis de los archivos Dart mediante un parser y se validó el JSON de origen. Se incluyen pruebas Dart/Flutter para importación, rechazo de IDs/opciones inválidos, combinación de cursos, respaldo, corrección tras mezclar opciones y manejo de guardado fallido.

El entorno de creación no tenía SDK Flutter/Dart: no se ejecutaron `flutter analyze`, `flutter test` ni una compilación Android aquí. `Preparar.ps1` ejecuta las comprobaciones en tu instalación antes del primer arranque. No se realizó una inspección visual de la app ejecutada en un dispositivo. Si aparece un error, comparte la salida completa de la terminal para corregirlo.

## Estructura

- `lib/main.dart`: interfaz, editores, estudio e importación/exportación.
- `lib/model.dart`: formato, validación, combinación y prompt IA.
- `lib/store.dart`: datos locales y respaldo.
- `assets/seed.json`: módulo inicial aportado por ti.
- `test/`: pruebas de integridad y sesiones.

Referencias técnicas consultadas: https://pub.dev/packages/file_picker y https://pub.dev/documentation/path_provider/latest/path_provider/getApplicationDocumentsDirectory.html
