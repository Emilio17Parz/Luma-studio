# ✨ Luma Study

**Tu espacio para aprender, practicar y repasar, incluso sin conexión.**

Luma Study es una aplicación desarrollada con **Flutter y Dart** que permite organizar materiales por cursos, estudiar con tarjetas y practicar mediante cuestionarios.

Incluye material inicial de **Zscaler EDU-200** y permite añadir otras materias, certificaciones o apuntes personales.

## 📱 Funcionalidades

- **Cursos y temas:** organiza apuntes, objetivos y conceptos.
- **Tarjetas de estudio:** consulta la respuesta y marca lo que recuerdas o necesitas repasar.
- **Cuestionarios:** practica con preguntas y opciones en orden aleatorio.
- **Explicaciones:** revisa la respuesta correcta y su fuente.
- **Repaso de errores:** vuelve a practicar las preguntas cuya última respuesta fue incorrecta.
- **Favoritos:** guarda tarjetas y preguntas para consultarlas después.
- **Progreso local:** registra intentos, aciertos y tarjetas aprendidas.
- **Edición manual:** crea y modifica cursos, temas, tarjetas y preguntas.
- **Importación:** añade material desde archivos JSON, TXT o texto JSON pegado.
- **Prompt para IA:** copia las instrucciones para generar material compatible a partir de tus fuentes.
- **Respaldos:** exporta cursos o guarda y restaura todos tus datos.
- **Apariencia:** temas claro y oscuro, con ajustes de área segura para la navegación del teléfono.

## 📚 Material incluido

El paquete inicial de Zscaler EDU-200 contiene:

| Contenido | Cantidad |
|---|---:|
| Temas | 12 |
| Tarjetas de estudio | 67 |
| Preguntas de práctica | 55 |

El contenido inicial se encuentra en `assets/seed.json`.

> Este material es de práctica independiente. Luma Study no es una aplicación oficial de Zscaler ni está afiliada a la empresa. Las preguntas no se presentan como preguntas oficiales del examen. Revisa el contenido con las fuentes oficiales antes de utilizarlo para preparar una certificación.

## 📴 Funcionamiento sin conexión

Una vez instalada y cargado el material, la app permite estudiar, editar contenido y consultar el progreso sin internet.

No requiere cuenta, servidor ni suscripción. Los datos se guardan en el dispositivo.

La generación de contenido con una IA se realiza fuera de la app. Después puedes importar el resultado y estudiarlo sin conexión.

## 🛠️ Tecnologías

- Flutter y Dart.
- Material Design 3.
- `file_picker` para importar y exportar archivos.
- `path_provider` para localizar el almacenamiento de la aplicación.
- JSON para materiales, progreso y respaldos.

## 🚀 Ejecutar el proyecto

### Requisitos

- Flutter instalado y disponible en el PATH.
- Android SDK y licencias aceptadas para compilar Android.
- Un dispositivo Android con depuración USB o un emulador.
- En Windows, Modo de desarrollador habilitado para los enlaces simbólicos que utilizan los plugins.

Comprueba tu entorno:

```bash
flutter doctor
```

### Descargar el repositorio

```bash
git clone https://github.com/Emilio17Parz/Luma-studio.git
cd Luma-studio
```

### Instalar dependencias y ejecutar

```bash
flutter pub get
flutter devices
flutter run -d ID_DEL_DISPOSITIVO
```

Sustituye `ID_DEL_DISPOSITIVO` por el identificador que muestre `flutter devices`.

La preparación y compilación inicial pueden necesitar internet para descargar dependencias y herramientas.

### Preparación con PowerShell

También puedes ejecutar el script incluido:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Preparar.ps1
```

El script prepara las plataformas si faltan, descarga dependencias, formatea el código y ejecuta el análisis y las pruebas.

## 📦 Generar una APK

Desde la carpeta que contiene `pubspec.yaml`:

```bash
flutter build apk --release
```

La APK se genera en:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Esta APK puede utilizarse para pruebas en dispositivos Android compatibles.

> La configuración de desarrollo utiliza firma de depuración para la compilación release. Antes de publicar en una tienda, configura una clave de firma propia y conserva su respaldo.

## ➕ Agregar material

### Desde la aplicación

1. Abre **Añadir**.
2. Selecciona **Importar archivo** o **Pegar contenido**.
3. Revisa los temas, tarjetas y preguntas detectados.
4. Elige crear un curso nuevo o añadir el contenido a uno existente.
5. Decide si deseas actualizar las coincidencias por identificador.
6. Confirma la importación.

También puedes crear material manualmente mediante los formularios.

### Con ayuda de una IA

1. En **Añadir**, pulsa **Instrucciones para IA**.
2. Pega el prompt en la herramienta de IA que utilices junto con tus fuentes.
3. Solicita el contenido en el formato JSON indicado.
4. Revisa la exactitud del material.
5. Importa el resultado en Luma Study.

La aplicación valida la estructura del archivo; esta validación no garantiza que su contenido académico sea correcto.

### Formato básico

```json
{
  "version": "1.0.0",
  "titulo": "Mi curso",
  "descripcion": "Descripción del material",
  "temas": [
    {
      "id": "tema_01",
      "titulo": "Primer tema",
      "objetivos": [
        "Comprender los conceptos principales"
      ],
      "resumen": "Contenido del tema.",
      "conceptos": [
        {
          "termino": "Concepto",
          "definicion": "Explicación del concepto."
        }
      ],
      "tarjetas": [
        {
          "id": "tarjeta_01",
          "pregunta": "¿Qué se estudia en este tema?",
          "respuesta": "Los conceptos principales.",
          "fuente": "Apuntes, tema 1"
        }
      ],
      "preguntas": [
        {
          "id": "pregunta_01",
          "enunciado": "¿Cuál es la respuesta correcta?",
          "opciones": [
            "Respuesta correcta",
            "Alternativa B",
            "Alternativa C",
            "Alternativa D"
          ],
          "indiceCorrecto": 0,
          "explicacion": "Explicación de por qué la primera opción es correcta.",
          "dificultad": "fácil",
          "fuente": "Apuntes, tema 1"
        }
      ]
    }
  ]
}
```

Cada pregunta debe tener cuatro opciones. `indiceCorrecto` utiliza valores de **0 a 3**.

Usa identificadores únicos dentro del curso y consérvalos cuando actualices un mismo elemento.

## 🔄 Material inicial y actualizaciones

`assets/seed.json` se carga cuando la app se inicia sin datos locales.

**Instalar una APK nueva sobre una instalación existente no reemplaza automáticamente los cursos guardados.**

Para actualizar el material en una instalación existente:

1. Copia el JSON actualizado al teléfono.
2. Impórtalo desde **Añadir**.
3. Selecciona el curso de destino.
4. Activa **Actualizar coincidencias** si deseas actualizar elementos con el mismo ID.

Los avances asociados a esos identificadores se conservan. Un resultado anterior puede corresponder a una versión previa de la pregunta.

Los archivos añadidos a `assets` solo se incluyen y utilizan si están declarados y referenciados por la aplicación. Colocarlos en la carpeta no los importa automáticamente.

## 💾 Respaldos

Desde **Ajustes** puedes:

- Exportar un curso sin incluir tus resultados.
- Exportar un respaldo completo con cursos, avances y favoritos.
- Restaurar un respaldo completo.

**Restaurar un respaldo reemplaza los datos actuales tras tu confirmación.**

Exporta un respaldo antes de desinstalar la app, borrar sus datos o cambiar de teléfono. Los cursos añadidos desde la app no se incorporan automáticamente a una APK generada después.

## 🧪 Verificación

```bash
flutter analyze
flutter test
```

Las pruebas incluyen validación de materiales, combinación de cursos, respaldos y comportamiento de las sesiones de estudio.

## 📂 Estructura principal

```text
lib/
  main.dart          Interfaz y sesiones de estudio
  model.dart         Validación, combinación y prompt para IA
  store.dart         Persistencia local

assets/
  seed.json          Material inicial
  modulo_*.json      Material organizado por módulo

test/
  model_test.dart    Pruebas del formato y los datos
  study_test.dart    Pruebas de sesiones de estudio

android/             Configuración e iconos de Android
ios/                 Proyecto nativo de iOS
windows/             Proyecto nativo de Windows
Preparar.ps1         Preparación y verificaciones
Iniciar.ps1          Ejecución desde PowerShell
```

## 📌 Alcance actual

La versión actual trabaja con contenido de texto. No incluye lectura directa de PDF, OCR, imágenes dentro de los temas, chat con IA integrado, sincronización entre dispositivos ni repetición espaciada automática.

La compilación y las pruebas en dispositivo se han trabajado para Android. iOS requiere macOS, Xcode y configuración de firma; las demás plataformas necesitan su propia validación.

---

**Luma Study — Un tema a la vez, a tu ritmo.**
