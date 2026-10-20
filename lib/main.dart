import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'model.dart';
import 'store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Luma());
}

const ink = Color(0xFF5254D9);
const mint = Color(0xFFBFF2DE);

class Luma extends StatefulWidget {
  const Luma({super.key});
  @override
  State<Luma> createState() => _LumaState();
}

class _LumaState extends State<Luma> {
  final store = Store();
  bool ready = false;
  String? error;
  @override
  void initState() {
    super.initState();
    boot();
  }

  Future<void> boot() async {
    try {
      await store.load();
      setState(() => ready = true);
    } catch (e) {
      setState(() => error = '$e');
    }
  }

  ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: ink, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF111420) : const Color(0xFFF5F6FA),
      appBarTheme: const AppBarTheme(
          centerTitle: false, elevation: 0, scrolledUnderElevation: 0),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none)),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)))),
      textTheme: const TextTheme(
          headlineLarge: TextStyle(
              fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.2),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          titleLarge: TextStyle(fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(fontSize: 16, height: 1.6),
          bodyMedium: TextStyle(height: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
      debugShowCheckedModeBanner: false,
// LUMA_SAFE_AREA
      builder: (context, child) => ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              top: false,
              left: true,
              right: true,
              bottom: true,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
      title: 'Luma Study',
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      themeMode: store.data['dark'] == true ? ThemeMode.dark : ThemeMode.light,
      home: ready
          ? Home(store: store, onTheme: () => setState(() {}))
          : Scaffold(
              body: Center(
                  child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: error == null
                          ? const CircularProgressIndicator()
                          : SelectableText(
                              'No se pudieron abrir tus datos. No se sobrescribieron.\n$error\nConserva luma_study.json y su archivo .bak para recuperarlos.')))));
}

class Home extends StatefulWidget {
  final Store store;
  final VoidCallback onTheme;
  const Home({super.key, required this.store, required this.onTheme});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Store get s => widget.store;
  int tab = 0;
  String search = '';
  bool busy = false;
  void toast(String t) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<bool> commit(VoidCallback change) async {
    if (busy) return false;
    bool success = true;
    final before = clone(s.data);
    setState(() => busy = true);
    try {
      change();
      await s.save();
    } catch (e) {
      success = false;
      s.data = before;
      toast('No se guardó el cambio: $e');
    }
    if (mounted) setState(() => busy = false);
    return success;
  }

  Future<void> openCourse(String id) async {
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CoursePage(store: s, id: id, save: commit)));
    if (mounted) setState(() {});
  }

  Future<void> newCourse() async {
    final v = await editFields(
        context, 'Nuevo curso', {'titulo': '', 'descripcion': ''},
        long: {'descripcion'});
    if (v == null) return;
    final c = <String, dynamic>{
      ...v,
      'version': '1.0.0',
      'id': uid(),
      'temas': <dynamic>[]
    };
    await commit(() => s.data['courses'] = [...s.courses, c]);
  }

  Future<String?> readFile() async {
    final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
        withData: true);
    if (r == null) return null;
    if (r.files.single.size > 10 * 1024 * 1024)
      throw const FormatException(
          'El límite por archivo es 10 MB. Divide el material en módulos.');
    return utf8.decode(r.files.single.bytes!);
  }

  Future<void> importMaterial({bool paste = false}) async {
    try {
      String? text;
      if (paste) {
        final v = await editFields(context, 'Pegar material JSON', {'JSON': ''},
            long: {'JSON'});
        text = v?['JSON'];
      } else {
        text = await readFile();
      }
      if (text == null || !mounted) return;
      final c = parsePackage(text);
      final topics = rows(c['temas']);
      final nCards =
          topics.fold<int>(0, (n, t) => n + (t['tarjetas'] as List).length);
      final nQuiz =
          topics.fold<int>(0, (n, t) => n + (t['preguntas'] as List).length);
      String target = 'new';
      bool replace = false;
      final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => StatefulBuilder(
              builder: (ctx, set) => AlertDialog(
                      title: const Text('Revisar importación'),
                      content: SizedBox(
                          width: 440,
                          child: SingleChildScrollView(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(c['titulo'],
                                    style: Theme.of(ctx).textTheme.titleLarge),
                                const SizedBox(height: 12),
                                Text(
                                    '${topics.length} temas · $nCards tarjetas · $nQuiz preguntas'),
                                const SizedBox(height: 20),
                                DropdownButtonFormField<String>(
                                    value: target,
                                    isExpanded: true,
                                    items: [
                                      const DropdownMenuItem(
                                          value: 'new',
                                          child: Text('Crear un curso nuevo')),
                                      ...s.courses.map((e) => DropdownMenuItem(
                                          value: e['id'] as String,
                                          child: Text(e['titulo'],
                                              overflow: TextOverflow.ellipsis)))
                                    ],
                                    onChanged: (v) => set(() => target = v!),
                                    decoration: const InputDecoration(
                                        labelText: 'Destino')),
                                if (target != 'new')
                                  SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text(
                                          'Actualizar coincidencias'),
                                      subtitle: const Text(
                                          'Por ID. Desactivado: conserva los elementos existentes. Se mantienen tus avances.'),
                                      value: replace,
                                      onChanged: (v) => set(() => replace = v)),
                              ]))),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar')),
                        FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Importar'))
                      ])));
      if (ok != true) return;
      await commit(() {
        final list = s.courses;
        if (target == 'new') {
          c['id'] = uid();
          list.add(c);
        } else {
          final i = list.indexWhere((x) => x['id'] == target);
          list[i] = mergeCourses(list[i], c, replace: replace);
        }
        s.data['courses'] = list;
      });
    } catch (e) {
      toast('No se importó el material. $e');
    }
  }

  Future<void> exportData(J value, String filename) async {
    try {
      final bytes = Uint8List.fromList(
          utf8.encode(const JsonEncoder.withIndent('  ').convert(value)));
      final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Guardar archivo',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['json'],
          bytes: bytes);
      if (path == null) return;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
        await File(path).writeAsBytes(bytes, flush: true);
      toast('Archivo exportado.');
    } catch (e) {
      toast('No se pudo exportar: $e');
    }
  }

  Future<void> restore() async {
    try {
      final text = await readFile();
      if (text == null) return;
      final data = jsonDecode(text) as J;
      Store.validateBackup(data);
      if (!mounted) return;
      if (await confirm(context, 'Restaurar respaldo',
          'Se reemplazarán tus cursos y avances actuales con ${rows(data['courses']).length} cursos del respaldo. Exporta primero si quieres conservar los actuales.')) {
        await commit(() => s.data = clone(data));
        widget.onTheme();
      }
    } catch (e) {
      toast('No se restauró el respaldo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = s.courses
        .where((c) => '${c['titulo']} ${c['descripcion']}'
            .toLowerCase()
            .contains(search.toLowerCase()))
        .toList();
    final ps = s.progress.values.whereType<Map>().toList();
    final attempts = ps.fold<int>(0, (n, p) => n + (p['attempts'] as int));
    final correct = ps.fold<int>(0, (n, p) => n + (p['correct'] as int));
    final known = ps.where((p) => p['known'] == true).length;
    return Scaffold(
      appBar: AppBar(
          title: const Row(children: [
            Icon(Icons.auto_awesome_rounded, color: ink),
            SizedBox(width: 10),
            Text('Luma', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(' study',
                style:
                    TextStyle(fontWeight: FontWeight.w400, color: Colors.grey))
          ]),
          actions: [
            IconButton(
                tooltip: 'Cambiar tema',
                onPressed: busy
                    ? null
                    : () async {
                        await commit(
                            () => s.data['dark'] = !(s.data['dark'] as bool));
                        widget.onTheme();
                      },
                icon: Icon(s.data['dark'] == true
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined)),
            const SizedBox(width: 12)
          ]),
      body: AbsorbPointer(
          absorbing: busy,
          child: Column(children: [
            if (busy) const LinearProgressIndicator(),
            Expanded(
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: ListView(
                            padding: const EdgeInsets.fromLTRB(22, 12, 22, 100),
                            children: tab == 0
                                ? [
                                    Text('Tu próximo logro\nempieza aquí.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge),
                                    const SizedBox(height: 10),
                                    const Text(
                                        'Un tema a la vez. A tu ritmo, sin conexión.'),
                                    const SizedBox(height: 24),
                                    Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF5558D9),
                                                  Color(0xFF7775E9)
                                                ]),
                                            borderRadius:
                                                BorderRadius.circular(26)),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Row(children: [
                                                Icon(Icons.offline_bolt_rounded,
                                                    color: mint),
                                                SizedBox(width: 8),
                                                Text('TU ESPACIO DE ESTUDIO',
                                                    style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 11,
                                                        letterSpacing: 1.5,
                                                        fontWeight:
                                                            FontWeight.bold))
                                              ]),
                                              const SizedBox(height: 12),
                                              Text(
                                                  s.courses.isEmpty
                                                      ? 'Dale espacio a tu curiosidad'
                                                      : 'Todo listo para avanzar',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                              const SizedBox(height: 8),
                                              Text(
                                                  '${s.courses.length} cursos en tu biblioteca · $known tarjetas aprendidas',
                                                  style: const TextStyle(
                                                      color: Colors.white)),
                                              const SizedBox(height: 18),
                                              FilledButton.tonal(
                                                  onPressed: s.courses.isEmpty
                                                      ? newCourse
                                                      : () => openCourse(s
                                                          .courses.first['id']),
                                                  child: const Text(
                                                      'Abrir mi curso  →'))
                                            ])),
                                    const SizedBox(height: 26),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Mis cursos',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall),
                                          TextButton.icon(
                                              onPressed: newCourse,
                                              icon: const Icon(Icons.add),
                                              label: const Text('Crear'))
                                        ]),
                                    const SizedBox(height: 12),
                                    TextField(
                                        onChanged: (v) =>
                                            setState(() => search = v),
                                        decoration: const InputDecoration(
                                            hintText: 'Buscar en tu biblioteca',
                                            prefixIcon:
                                                Icon(Icons.search_rounded))),
                                    const SizedBox(height: 16),
                                    if (courses.isEmpty)
                                      const Empty(
                                          icon: Icons.menu_book_rounded,
                                          title: 'Un nuevo comienzo',
                                          text:
                                              'Crea un curso o importa tus apuntes desde Añadir.'),
                                    ...courses.map((c) => Panel(
                                        child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: const CircleAvatar(
                                                backgroundColor:
                                                    Color(0xFFE8E8FC),
                                                child: Icon(
                                                    Icons.school_outlined,
                                                    color: ink)),
                                            title: Text(c['titulo'],
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            subtitle: Text(
                                                '${(c['temas'] as List).length} temas · disponible sin conexión'),
                                            trailing: const Icon(
                                                Icons.arrow_forward_rounded),
                                            onTap: () => openCourse(c['id'])))),
                                  ]
                                : tab == 1
                                    ? [
                                        Text('Hazlo tuyo.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineLarge),
                                        const SizedBox(height: 8),
                                        const Text(
                                            'Trae tus apuntes o empieza desde cero.'),
                                        const SizedBox(height: 24),
                                        action(
                                            Icons.file_upload_outlined,
                                            'Importar archivo',
                                            'JSON o TXT generado con el formato compatible.',
                                            () => importMaterial()),
                                        action(
                                            Icons.content_paste_rounded,
                                            'Pegar contenido',
                                            'Copia directamente la respuesta JSON de tu IA.',
                                            () => importMaterial(paste: true)),
                                        action(
                                            Icons.auto_awesome_outlined,
                                            'Instrucciones para IA',
                                            'Copia el prompt y úsalo con tus propias fuentes.',
                                            () async {
                                          await Clipboard.setData(
                                              const ClipboardData(
                                                  text: aiPrompt));
                                          toast('Instrucciones copiadas.');
                                        }),
                                        action(
                                            Icons.add_circle_outline,
                                            'Crear curso manualmente',
                                            'Añade temas, tarjetas y preguntas con formularios.',
                                            newCourse),
                                        const SizedBox(height: 16),
                                        const Panel(
                                            child: Text(
                                                'La IA se usa fuera de Luma. Una vez importado el material, puedes estudiar y editar sin internet. Los archivos se validan antes de guardarlos.')),
                                      ]
                                    : tab == 2
                                        ? [
                                            Text('Cada repaso cuenta.',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineLarge),
                                            const SizedBox(height: 22),
                                            Wrap(
                                                spacing: 12,
                                                runSpacing: 12,
                                                children: [
                                                  metric(
                                                      'Respuestas',
                                                      '$attempts',
                                                      Icons.quiz_outlined),
                                                  metric(
                                                      'Aciertos',
                                                      attempts == 0
                                                          ? '—'
                                                          : '${(correct / attempts * 100).round()}%',
                                                      Icons.track_changes),
                                                  metric('Aprendidas', '$known',
                                                      Icons.style_outlined)
                                                ]),
                                            const SizedBox(height: 24),
                                            const Text(
                                                'Los aciertos incluyen todos tus intentos. Las tarjetas aprendidas son las que marcaste como “La recuerdo”.'),
                                            const SizedBox(height: 20),
                                            ...s.courses.map((c) => action(
                                                Icons.insights_rounded,
                                                c['titulo'],
                                                'Abre el curso para repasar tarjetas o errores.',
                                                () => openCourse(c['id']))),
                                          ]
                                        : [
                                            Text('Tu biblioteca, contigo.',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineLarge),
                                            const SizedBox(height: 24),
                                            action(
                                                Icons.save_alt_rounded,
                                                'Exportar respaldo completo',
                                                'Cursos, avances, favoritos y apariencia.',
                                                () => exportData(s.data,
                                                    'luma_respaldo.json')),
                                            action(
                                                Icons.restore_rounded,
                                                'Restaurar respaldo',
                                                'Reemplaza los datos actuales tras tu confirmación.',
                                                restore),
                                            const SizedBox(height: 18),
                                            Text('Compartir material',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineSmall),
                                            const SizedBox(height: 10),
                                            ...s.courses.map((c) => action(
                                                Icons.ios_share_rounded,
                                                c['titulo'],
                                                'Exportar solo contenido, sin tus resultados.',
                                                () => exportData(c,
                                                    'luma_curso_${c['id']}.json'))),
                                            const SizedBox(height: 18),
                                            const Panel(
                                                child: Text(
                                                    'Tus datos se guardan en este dispositivo. Exporta un respaldo antes de desinstalar o cambiar de teléfono. Luma no requiere cuenta ni servidor.\n\nLuma Study 1.0 · Material de práctica independiente.')),
                                          ]))))
          ])),
      bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.grid_view_rounded), label: 'Cursos'),
            NavigationDestination(
                icon: Icon(Icons.add_box_outlined), label: 'Añadir'),
            NavigationDestination(
                icon: Icon(Icons.insights_outlined), label: 'Progreso'),
            NavigationDestination(
                icon: Icon(Icons.tune_rounded), label: 'Ajustes')
          ]),
    );
  }

  Widget action(
          IconData icon, String title, String sub, VoidCallback tap) =>
      Panel(
          child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: ink),
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(sub),
              trailing: const Icon(Icons.chevron_right),
              onTap: tap));
  Widget metric(String label, String value, IconData icon) => SizedBox(
      width: 170,
      child: Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: ink),
        const SizedBox(height: 12),
        Text(value, style: Theme.of(context).textTheme.headlineLarge),
        Text(label)
      ])));
}

class CoursePage extends StatefulWidget {
  final Store store;
  final String id;
  final Future<bool> Function(VoidCallback) save;
  const CoursePage(
      {super.key, required this.store, required this.id, required this.save});
  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  J get course => widget.store.courses.firstWhere((c) => c['id'] == widget.id);
  Future<void> update(J c) async {
    await widget.save(() {
      final list = widget.store.courses;
      list[list.indexWhere((v) => v['id'] == widget.id)] = c;
      widget.store.data['courses'] = list;
    });
    if (mounted) setState(() {});
  }

  Future<void> addTopic() async {
    final v = await editFields(
        context, 'Nuevo tema', {'titulo': '', 'resumen': '', 'objetivos': ''},
        long: {'resumen', 'objetivos'}, optional: {'resumen', 'objetivos'});
    if (v == null) return;
    final c = clone(course);
    (c['temas'] as List).add({
      ...v,
      'id': uid(),
      'objetivos': v['objetivos']!
          .split('\n')
          .where((v) => v.trim().isNotEmpty)
          .toList(),
      'conceptos': [],
      'tarjetas': [],
      'preguntas': []
    });
    await update(c);
  }

  List<J> items(String kind) =>
      rows(course['temas']).expand((t) => rows(t[kind])).toList();
  Future<void> study(String kind,
      {bool mistakes = false, bool favorites = false}) async {
    var list = items(kind);
    if (mistakes)
      list = list
          .where((q) =>
              widget.store.state('${widget.id}/preguntas/${q['id']}')['last'] ==
              false)
          .toList();
    if (favorites)
      list = list
          .where((q) =>
              widget.store.state('${widget.id}/$kind/${q['id']}')['favorite'] ==
              true)
          .toList();
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Todavía no hay elementos en esta selección.')));
      return;
    }
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => StudyPage(
                store: widget.store,
                courseId: widget.id,
                kind: kind,
                items: list,
                save: widget.save)));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('Mi curso'), actions: [
        IconButton(
            tooltip: 'Editar curso',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final v = await editFields(context, 'Editar curso', {
                'titulo': course['titulo'],
                'descripcion': course['descripcion'] ?? ''
              }, long: {
                'descripcion'
              }, optional: {
                'descripcion'
              });
              if (v != null) await update({...course, ...v});
            })
      ]),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(padding: const EdgeInsets.all(22), children: [
                const Text('APRENDE · PRACTICA · RECUERDA',
                    style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 11)),
                const SizedBox(height: 12),
                Text(course['titulo'],
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 10),
                Text(course['descripcion'] ?? ''),
                const SizedBox(height: 24),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  FilledButton.icon(
                      onPressed: () => study('tarjetas'),
                      icon: const Icon(Icons.style_outlined),
                      label: Text('Tarjetas (${items('tarjetas').length})')),
                  FilledButton.tonalIcon(
                      onPressed: () => study('preguntas'),
                      icon: const Icon(Icons.quiz_outlined),
                      label: Text('Practicar (${items('preguntas').length})')),
                  OutlinedButton.icon(
                      onPressed: () => study('preguntas', mistakes: true),
                      icon: const Icon(Icons.replay),
                      label: const Text('Mis errores')),
                  OutlinedButton.icon(
                      onPressed: () => study('tarjetas', favorites: true),
                      icon: const Icon(Icons.star_outline),
                      label: const Text('Tarjetas favoritas')),
                  OutlinedButton.icon(
                      onPressed: () => study('preguntas', favorites: true),
                      icon: const Icon(Icons.bookmark_outline),
                      label: const Text('Preguntas favoritas'))
                ]),
                const SizedBox(height: 30),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tu ruta de estudio',
                          style: Theme.of(context).textTheme.headlineSmall),
                      IconButton(
                          tooltip: 'Añadir tema',
                          onPressed: addTopic,
                          icon: const Icon(Icons.add_circle_outline))
                    ]),
                const SizedBox(height: 12),
                if ((course['temas'] as List).isEmpty)
                  const Empty(
                      icon: Icons.edit_note,
                      title: 'Empieza con un tema',
                      text: 'Pulsa + y escribe tus primeros apuntes.'),
                ...rows(course['temas']).asMap().entries.map((entry) => Panel(
                    child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                            backgroundColor: mint,
                            child: Text('${entry.key + 1}'.padLeft(2, '0'),
                                style: const TextStyle(
                                    color: Color(0xFF245A48),
                                    fontWeight: FontWeight.bold))),
                        title: Text(entry.value['titulo'],
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${(entry.value['tarjetas'] as List).length} tarjetas · ${(entry.value['preguntas'] as List).length} preguntas'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => TopicPage(
                                      store: widget.store,
                                      courseId: widget.id,
                                      topicId: entry.value['id'],
                                      save: widget.save)));
                          if (mounted) setState(() {});
                        }))),
                const SizedBox(height: 20),
                TextButton.icon(
                    onPressed: () async {
                      if (await confirm(context, 'Eliminar curso',
                          'Se eliminarán este curso y sus avances. Esta acción no se puede deshacer.')) {
                        await widget.save(() {
                          widget.store.data['courses'] = widget.store.courses
                              .where((c) => c['id'] != widget.id)
                              .toList();
                          widget.store.progress.removeWhere(
                              (k, v) => k.startsWith('${widget.id}/'));
                        });
                        if (context.mounted &&
                            !widget.store.courses
                                .any((c) => c['id'] == widget.id))
                          Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar curso')),
              ]))));
}

class TopicPage extends StatefulWidget {
  final Store store;
  final String courseId, topicId;
  final Future<bool> Function(VoidCallback) save;
  const TopicPage(
      {super.key,
      required this.store,
      required this.courseId,
      required this.topicId,
      required this.save});
  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  int selected = 0;
  J get course =>
      widget.store.courses.firstWhere((c) => c['id'] == widget.courseId);
  J get topic =>
      rows(course['temas']).firstWhere((t) => t['id'] == widget.topicId);
  Future<void> change(void Function(J) mutate) async {
    await widget.save(() {
      final courses = widget.store.courses;
      final ci = courses.indexWhere((c) => c['id'] == widget.courseId);
      final topics = rows(courses[ci]['temas']);
      final ti = topics.indexWhere((t) => t['id'] == widget.topicId);
      mutate(topics[ti]);
      courses[ci]['temas'] = topics;
      validateCourse(courses[ci]);
      widget.store.data['courses'] = courses;
    });
    if (mounted) setState(() {});
  }

  Future<void> editItem(String kind, {J? item, int? index}) async {
    Map<String, String> fields;
    if (kind == 'conceptos') {
      fields = {
        'termino': item?['termino'] ?? '',
        'definicion': item?['definicion'] ?? ''
      };
    } else if (kind == 'tarjetas') {
      fields = {
        'pregunta': item?['pregunta'] ?? '',
        'respuesta': item?['respuesta'] ?? '',
        'fuente': item?['fuente'] ?? ''
      };
    } else {
      fields = {
        'enunciado': item?['enunciado'] ?? '',
        for (var i = 0; i < 4; i++)
          'opcion ${i + 1}': item == null ? '' : item['opciones'][i],
        'correcta (1 a 4)':
            item == null ? '1' : '${item['indiceCorrecto'] + 1}',
        'explicacion': item?['explicacion'] ?? '',
        'fuente': item?['fuente'] ?? ''
      };
    }
    final v = await editFields(
        context, item == null ? 'Añadir $kind' : 'Editar $kind', fields, long: {
      'definicion',
      'pregunta',
      'respuesta',
      'enunciado',
      'explicacion'
    }, optional: {
      'fuente'
    });
    if (v == null) return;
    J out = {...v};
    if (kind != 'conceptos') out['id'] = item?['id'] ?? uid();
    if (kind == 'preguntas') {
      out = {
        'id': out['id'],
        'enunciado': v['enunciado'],
        'opciones': [for (var i = 1; i <= 4; i++) v['opcion $i']],
        'indiceCorrecto': int.parse(v['correcta (1 a 4)']!) - 1,
        'explicacion': v['explicacion'],
        'fuente': v['fuente'],
        'dificultad': item?['dificultad'] ?? 'intermedio'
      };
    }
    await change((t) {
      final list = rows(t[kind]);
      if (index == null) {
        list.add(out);
      } else {
        list[index] = out;
      }
      t[kind] = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = topic;
    final kind = ['resumen', 'conceptos', 'tarjetas', 'preguntas'][selected];
    return Scaffold(
        appBar: AppBar(title: const Text('Tema'), actions: [
          IconButton(
              tooltip: 'Editar tema',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final v = await editFields(context, 'Editar tema', {
                  'titulo': t['titulo'],
                  'resumen': t['resumen'],
                  'objetivos': (t['objetivos'] as List).join('\n')
                }, long: {
                  'resumen',
                  'objetivos'
                }, optional: {
                  'resumen',
                  'objetivos'
                });
                if (v != null)
                  await change((t) {
                    t.addAll(v);
                    t['objetivos'] = v['objetivos']!
                        .split('\n')
                        .where((v) => v.trim().isNotEmpty)
                        .toList();
                  });
              })
        ]),
        floatingActionButton: selected == 0
            ? null
            : FloatingActionButton.extended(
                onPressed: () => editItem(kind),
                icon: const Icon(Icons.add),
                label: const Text('Añadir')),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 100),
                    children: [
                      Text(t['titulo'],
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 20),
                      Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                              4,
                              (i) => ChoiceChip(
                                  label: Text([
                                    'Apuntes',
                                    'Conceptos',
                                    'Tarjetas',
                                    'Preguntas'
                                  ][i]),
                                  selected: selected == i,
                                  onSelected: (_) =>
                                      setState(() => selected = i)))),
                      const SizedBox(height: 22),
                      if (selected == 0) ...[
                        if ((t['objetivos'] as List).isNotEmpty)
                          Panel(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Lo que aprenderás',
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 10),
                                ...(t['objetivos'] as List).map((v) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text('• $v')))
                              ])),
                        Panel(
                            child: SelectableText(
                                t['resumen'].toString().isEmpty
                                    ? 'Añade tus apuntes con el lápiz de arriba.'
                                    : t['resumen'],
                                style: Theme.of(context).textTheme.bodyLarge))
                      ] else ...[
                        if (kind != 'conceptos' && (t[kind] as List).isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: FilledButton.icon(
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => StudyPage(
                                              store: widget.store,
                                              courseId: widget.courseId,
                                              kind: kind,
                                              items: rows(t[kind]),
                                              save: widget.save))),
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Estudiar este tema'))),
                        if ((t[kind] as List).isEmpty)
                          const Empty(
                              icon: Icons.note_add_outlined,
                              title: 'Aquí empieza tu material',
                              text:
                                  'Pulsa Añadir para crear el primer elemento.'),
                        ...rows(t[kind]).asMap().entries.map((e) => Panel(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                      e.value[kind == 'conceptos'
                                          ? 'termino'
                                          : kind == 'tarjetas'
                                              ? 'pregunta'
                                              : 'enunciado'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 10),
                                  Text(kind == 'conceptos'
                                      ? e.value['definicion']
                                      : kind == 'tarjetas'
                                          ? e.value['respuesta']
                                          : e.value['explicacion']),
                                  if ((e.value['fuente'] ?? '').isNotEmpty)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Text(
                                            'Fuente: ${e.value['fuente']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall)),
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                            tooltip: 'Editar',
                                            onPressed: () => editItem(kind,
                                                item: e.value, index: e.key),
                                            icon: const Icon(
                                                Icons.edit_outlined)),
                                        IconButton(
                                            tooltip: 'Eliminar',
                                            onPressed: () async {
                                              if (await confirm(
                                                  context,
                                                  'Eliminar elemento',
                                                  'Se eliminará este elemento.'))
                                                await change((t) {
                                                  (t[kind] as List)
                                                      .removeAt(e.key);
                                                  if (e.value['id'] != null)
                                                    widget.store.progress.remove(
                                                        '${widget.courseId}/$kind/${e.value['id']}');
                                                });
                                            },
                                            icon: const Icon(
                                                Icons.delete_outline))
                                      ])
                                ]))),
                      ]
                    ]))));
  }
}

class StudyPage extends StatefulWidget {
  final Store store;
  final String courseId, kind;
  final List<J> items;
  final Future<bool> Function(VoidCallback) save;
  const StudyPage(
      {super.key,
      required this.store,
      required this.courseId,
      required this.kind,
      required this.items,
      required this.save});
  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  late List<J> list;
  int index = 0, score = 0;
  bool revealed = false, answered = false, working = false;
  int? choice;
  bool get cards => widget.kind == 'tarjetas';
  String get keyName =>
      '${widget.courseId}/${widget.kind}/${list[index]['id']}';
  @override
  void initState() {
    super.initState();
    list = widget.items.map(clone).toList()..shuffle(Random());
    if (!cards) {
      for (final q in list) {
        final opts = List<String>.from(q['opciones']);
        final order = List.generate(4, (i) => i)..shuffle(Random());
        q['opciones'] = order.map((i) => opts[i]).toList();
        q['indiceCorrecto'] = order.indexOf(q['indiceCorrecto'] as int);
      }
    }
  }

  Future<void> record(bool value) async {
    if (working || answered) return;
    setState(() => working = true);
    final saved = await widget.save(() {
      final p = widget.store.state(keyName);
      if (cards) {
        p['known'] = value;
      } else {
        p['attempts'] = (p['attempts'] as int) + 1;
        p['correct'] = (p['correct'] as int) + (value ? 1 : 0);
        p['last'] = value;
      }
      widget.store.progress[keyName] = p;
    });
    if (!mounted) return;
    if (!saved) {
      setState(() => working = false);
      return;
    }
    setState(() {
      working = false;
      answered = true;
      if (value) score++;
    });
    if (cards) next();
  }

  void next() => setState(() {
        index++;
        revealed = false;
        answered = false;
        choice = null;
      });
  @override
  Widget build(BuildContext context) {
    if (index >= list.length)
      return Scaffold(
          appBar: AppBar(title: const Text('Sesión terminada')),
          body: Center(
              child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 70, color: ink),
                    const SizedBox(height: 24),
                    Text('Un paso más cerca.',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 14),
                    Text(
                        cards
                            ? 'Recordaste $score de ${list.length} tarjetas.'
                            : 'Acertaste $score de ${list.length} preguntas.',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    const Text('Tus avances se guardan en este dispositivo.'),
                    const SizedBox(height: 28),
                    FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Volver al material'))
                  ]))));
    final q = list[index];
    final p = widget.store.state(keyName);
    return Scaffold(
        appBar: AppBar(
            title: Text(cards ? 'Tarjetas de estudio' : 'Práctica'),
            actions: [
              IconButton(
                  tooltip: 'Marcar favorito',
                  onPressed: working
                      ? null
                      : () async {
                          setState(() => working = true);
                          await widget.save(() {
                            final p = widget.store.state(keyName);
                            p['favorite'] = p['favorite'] != true;
                            widget.store.progress[keyName] = p;
                          });
                          if (mounted) setState(() => working = false);
                        },
                  icon: Icon(
                      p['favorite'] == true
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: ink))
            ]),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(padding: const EdgeInsets.all(24), children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${index + 1} DE ${list.length}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ink,
                                letterSpacing: 1)),
                        Text(cards
                            ? 'Recupera lo que sabes'
                            : 'Sin prisa. Piensa tu respuesta.')
                      ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                          value: index / list.length, minHeight: 7)),
                  const SizedBox(height: 30),
                  Panel(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Icon(
                            cards
                                ? Icons.style_outlined
                                : Icons.psychology_outlined,
                            color: ink,
                            size: 32),
                        const SizedBox(height: 20),
                        Text(q[cards ? 'pregunta' : 'enunciado'],
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 24),
                        if (cards) ...[
                          if (!revealed)
                            FilledButton.tonal(
                                onPressed: () =>
                                    setState(() => revealed = true),
                                child: const Text('Mostrar respuesta')),
                          if (revealed) ...[
                            const Divider(),
                            const SizedBox(height: 12),
                            SelectableText(q['respuesta'],
                                style: Theme.of(context).textTheme.bodyLarge),
                            const SizedBox(height: 14),
                            Text('Fuente: ${q['fuente'] ?? 'Material propio'}',
                                style: Theme.of(context).textTheme.bodySmall)
                          ],
                        ] else
                          ...List.generate(4, (i) {
                            final correct = i == q['indiceCorrecto'];
                            return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.all(17),
                                        backgroundColor: answered && correct
                                            ? mint
                                            : choice == i
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .secondaryContainer
                                                : null,
                                        foregroundColor: answered && correct
                                            ? const Color(0xFF174E3D)
                                            : null,
                                        side: BorderSide(
                                            color: choice == i
                                                ? ink
                                                : Theme.of(context)
                                                    .dividerColor),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16))),
                                    onPressed: answered || working
                                        ? null
                                        : () => setState(() => choice = i),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '${String.fromCharCode(65 + i)}.  ',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Expanded(
                                              child: Text(q['opciones'][i],
                                                  style: TextStyle(
                                                      color: answered && correct
                                                          ? const Color(
                                                              0xFF174E3D)
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .onSurface)))
                                        ])));
                          }),
                      ])),
                  if (cards && revealed)
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      OutlinedButton(
                          onPressed: working ? null : () => record(false),
                          child: const Text('Necesito repasar')),
                      FilledButton(
                          onPressed: working ? null : () => record(true),
                          child: const Text('La recuerdo'))
                    ]),
                  if (!cards && !answered)
                    FilledButton(
                        onPressed: choice == null || working
                            ? null
                            : () => record(choice == q['indiceCorrecto']),
                        child: const Text('Comprobar respuesta')),
                  if (!cards && answered) ...[
                    Panel(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              choice == q['indiceCorrecto']
                                  ? '¡Bien hecho!'
                                  : 'Una oportunidad para aprender',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 10),
                          Text(
                              'Respuesta correcta: ${q['opciones'][q['indiceCorrecto']]}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(q['explicacion']),
                          const SizedBox(height: 10),
                          Text('Fuente: ${q['fuente'] ?? 'Material propio'}',
                              style: Theme.of(context).textTheme.bodySmall)
                        ])),
                    FilledButton(
                        onPressed: next,
                        child: Text(index == list.length - 1
                            ? 'Ver resultado'
                            : 'Siguiente'))
                  ],
                ]))));
  }
}

class Panel extends StatelessWidget {
  final Widget child;
  const Panel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border:
              Border.all(color: Theme.of(context).dividerColor.withAlpha(22))),
      child: child);
}

class Empty extends StatelessWidget {
  final IconData icon;
  final String title, text;
  const Empty(
      {super.key, required this.icon, required this.title, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
      child: Column(children: [
        Icon(icon, size: 54, color: ink),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center)
      ]));
}

Future<bool> confirm(
        BuildContext context, String title, String message) async =>
    await showDialog<bool>(
        context: context,
        builder: (ctx) =>
            AlertDialog(title: Text(title), content: Text(message), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirmar'))
            ])) ??
    false;
Future<Map<String, String>?> editFields(
    BuildContext context, String title, Map<String, String> fields,
    {Set<String> long = const {}, Set<String> optional = const {}}) async {
  return Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
          builder: (_) => Editor(
              title: title, fields: fields, long: long, optional: optional)));
}

class Editor extends StatefulWidget {
  final String title;
  final Map<String, String> fields;
  final Set<String> long, optional;
  const Editor(
      {super.key,
      required this.title,
      required this.fields,
      required this.long,
      required this.optional});
  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final form = GlobalKey<FormState>();
  late Map<String, TextEditingController> controllers;
  @override
  void initState() {
    super.initState();
    controllers = widget.fields
        .map((k, v) => MapEntry(k, TextEditingController(text: v)));
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                  key: form,
                  child: ListView(padding: const EdgeInsets.all(24), children: [
                    ...controllers.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: TextFormField(
                            controller: e.value,
                            minLines: widget.long.contains(e.key) ? 4 : 1,
                            maxLines: widget.long.contains(e.key) ? 12 : 1,
                            decoration: InputDecoration(
                                labelText: e.key,
                                helperText: e.key == 'objetivos'
                                    ? 'Un objetivo por línea'
                                    : widget.optional.contains(e.key)
                                        ? 'Opcional'
                                        : null),
                            validator: (v) {
                              if (!widget.optional.contains(e.key) &&
                                  (v ?? '').trim().isEmpty)
                                return 'Completa este campo';
                              if (e.key == 'correcta (1 a 4)' &&
                                  !['1', '2', '3', '4'].contains(v?.trim()))
                                return 'Escribe 1, 2, 3 o 4';
                              return null;
                            }))),
                    FilledButton.icon(
                        onPressed: () {
                          if (form.currentState!.validate())
                            Navigator.pop(
                                context,
                                controllers
                                    .map((k, v) => MapEntry(k, v.text.trim())));
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Guardar')),
                    const SizedBox(height: 30)
                  ])))));
}
