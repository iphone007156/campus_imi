import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

import '../models/lesson.dart';

class RoomShape {
  final String number;
  final Path path;
  RoomShape(this.number, this.path);
  Offset get center => path.getBounds().center;
}

class MapLabel {
  final String text;
  final Offset pos;
  final double rotation;
  MapLabel(this.text, this.pos, this.rotation);
}

class FloorPlan {
  final Size size;
  final List<RoomShape> rooms;
  final List<MapLabel> labels;
  final String svg;
  FloorPlan(this.size, this.rooms, this.labels, this.svg);

  RoomShape? roomAt(Offset p) {
    for (final r in rooms) {
      if (r.path.contains(p)) return r;
    }
    return null;
  }

  RoomShape? byNumber(String n) {
    for (final r in rooms) {
      if (r.number == n) return r;
    }
    return null;
  }
}

class RoomInfo {
  final String title;
  final String description;
  final String department;
  RoomInfo({required this.title, this.description = '', this.department = ''});
}

class Suggestion {
  final String label;
  final String subtitle;
  final String room;
  final bool isTeacher;
  Suggestion(this.label, this.subtitle, this.room, {this.isTeacher = false});
}

Future<FloorPlan> loadFloorPlan(String asset) async {
  final raw = await rootBundle.loadString(asset);
  final doc = XmlDocument.parse(raw);
  final svg = doc.rootElement;

  double minX = 0, minY = 0, w = 1000, h = 1000;
  final vb = svg.getAttribute('viewBox');
  if (vb != null) {
    final v = vb.trim().split(RegExp(r'[ ,]+')).map(double.parse).toList();
    if (v.length == 4) {
      minX = v[0];
      minY = v[1];
      w = v[2];
      h = v[3];
    }
  } else {
    w = double.tryParse(svg.getAttribute('width') ?? '') ?? w;
    h = double.tryParse(svg.getAttribute('height') ?? '') ?? h;
  }

  final rooms = <RoomShape>[];
  for (final el in doc.descendants.whereType<XmlElement>()) {
    final id = el.getAttribute('id');
    if (id == null || !id.startsWith('room-')) continue;

    Path? p;
    switch (el.name.local) {
      case 'path':
        p = parseSvgPathData(el.getAttribute('d') ?? '');
        break;
      case 'rect':
        final x = double.tryParse(el.getAttribute('x') ?? '0') ?? 0;
        final y = double.tryParse(el.getAttribute('y') ?? '0') ?? 0;
        final rw = double.tryParse(el.getAttribute('width') ?? '0') ?? 0;
        final rh = double.tryParse(el.getAttribute('height') ?? '0') ?? 0;
        p = Path()..addRect(Rect.fromLTWH(x, y, rw, rh));
        break;
      case 'polygon':
        final pts = (el.getAttribute('points') ?? '')
            .trim()
            .split(RegExp(r'[ ,]+'))
            .map(double.parse)
            .toList();
        p = Path();
        for (var i = 0; i + 1 < pts.length; i += 2) {
          i == 0 ? p.moveTo(pts[i], pts[i + 1]) : p.lineTo(pts[i], pts[i + 1]);
        }
        p.close();
        break;
    }
    if (p != null) {
      rooms.add(RoomShape(id.substring(5), p.shift(Offset(-minX, -minY))));
    }
  }

  final labels = <MapLabel>[];
  final lg = doc.descendants
      .whereType<XmlElement>()
      .where((e) => e.name.local == 'g' && e.getAttribute('id') == 'labels')
      .toList();
  for (final g in lg) {
    for (final t in g.findElements('text')) {
      final x = double.tryParse(t.getAttribute('x') ?? '') ?? 0;
      final y = double.tryParse(t.getAttribute('y') ?? '') ?? 0;
      var rot = 0.0;
      final tr = t.getAttribute('transform');
      if (tr != null) {
        final m = RegExp(r'rotate\(\s*(-?[\d.]+)').firstMatch(tr);
        if (m != null) rot = double.parse(m.group(1)!) * 3.1415926535 / 180;
      }
      labels.add(MapLabel(t.innerText.trim(), Offset(x - minX, y - minY), rot));
    }
    g.parent!.children.remove(g);
  }
  return FloorPlan(Size(w, h), rooms, labels, doc.toXmlString());
}

class NavGraph {
  final Map<String, Offset> nodes = {};
  final Map<String, List<MapEntry<String, double>>> _adj = {};

  NavGraph._();

  static Future<NavGraph?> load(String asset) async {
    try {
      final j = jsonDecode(await rootBundle.loadString(asset));
      final g = NavGraph._();
      (j['nodes'] as Map<String, dynamic>).forEach((k, v) {
        g.nodes[k] = Offset((v[0] as num).toDouble(), (v[1] as num).toDouble());
      });
      for (final e in j['edges'] as List) {
        final a = e[0] as String, b = e[1] as String;
        final d = (g.nodes[a]! - g.nodes[b]!).distance;
        g._adj.putIfAbsent(a, () => []).add(MapEntry(b, d));
        g._adj.putIfAbsent(b, () => []).add(MapEntry(a, d));
      }
      return g;
    } catch (_) {
      return null;
    }
  }

  bool has(String id) => nodes.containsKey(id);

  (Map<String, double>, Map<String, String>) _dijkstra(String src) {
    final dist = <String, double>{for (final k in nodes.keys) k: double.infinity};
    final prev = <String, String>{};
    final todo = nodes.keys.toSet();
    dist[src] = 0;
    while (todo.isNotEmpty) {
      String? u;
      for (final k in todo) {
        if (u == null || dist[k]! < dist[u]!) u = k;
      }
      if (u == null || dist[u]! == double.infinity) break;
      todo.remove(u);
      for (final e in _adj[u] ?? const <MapEntry<String, double>>[]) {
        final nd = dist[u]! + e.value;
        if (nd < dist[e.key]!) {
          dist[e.key] = nd;
          prev[e.key] = u;
        }
      }
    }
    return (dist, prev);
  }

  List<Offset>? route(String from, String to) {
    if (!has(from) || !has(to)) return null;
    final (dist, prev) = _dijkstra(from);
    if (dist[to]! == double.infinity) return null;
    return _build(prev, from, to);
  }

  List<Offset>? routeFromNearestStairs(String to) {
    if (!has(to)) return null;
    final (dist, prev) = _dijkstra(to);
    String? best;
    for (final k in nodes.keys) {
      if (k.startsWith('stairs-') && dist[k]! < double.infinity) {
        if (best == null || dist[k]! < dist[best]!) best = k;
      }
    }
    if (best == null) return null;
    return _build(prev, to, best).reversed.toList();
  }

  List<Offset> _build(Map<String, String> prev, String from, String to) {
    final out = <Offset>[];
    String? cur = to;
    while (cur != null) {
      out.add(nodes[cur]!);
      if (cur == from) break;
      cur = prev[cur];
    }
    return out.reversed.toList();
  }
}

String? normRoom(String raw) {
  final m = RegExp(r'(\d{2,3})\s*([а-яА-Яa-zA-Z]?)').firstMatch(raw);
  if (m == null) return null;
  var suffix = (m.group(2) ?? '').toLowerCase();
  if (suffix == 'а') suffix = 'a';
  return '${m.group(1)}$suffix';
}

int? floorOfRoom(String room) => int.tryParse(room.isEmpty ? '' : room[0]);
const _dayNames = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота'];

class IndoorMapScreen extends StatefulWidget {
  final String buildingId;
  final String buildingName;
  final List<int> floors;
  final String? initialRoom;

  const IndoorMapScreen({
    super.key,
    this.buildingId = 'ammosov',
    this.buildingName = 'Учебный корпус СВФУ',
    this.floors = const [1, 2, 3, 4, 5, 6, 7],
    this.initialRoom,
  });

  static void openForRoom(BuildContext context, String rawRoom) {
    final room = normRoom(rawRoom);
    if (room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось определить номер кабинета')));
      return;
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => IndoorMapScreen(initialRoom: room)));
  }

  @override
  State<IndoorMapScreen> createState() => _IndoorMapScreenState();
}

class _IndoorMapScreenState extends State<IndoorMapScreen> {
  final _transform = TransformationController();
  final Map<int, FloorPlan> _plans = {};
  final Map<int, NavGraph?> _graphs = {};
  List<Lesson> _lessons = [];

  int _floor = 4;
  FloorPlan? _plan;
  RoomShape? _selected;
  RoomInfo? _info;
  List<Offset>? _route;
  String? _routeStart;
  Size _viewport = Size.zero;
  double _fitScale = 0.5;
  bool _loading = true;
  String? _error;

  String _asset(int f) => 'assets/maps/${widget.buildingId}_f$f.svg';
  String _navAsset(int f) => 'assets/maps/${widget.buildingId}_f${f}_nav.json';

  @override
  void initState() {
    super.initState();
    _floor = widget.floors.first;
    _init();
  }

  Future<void> _init() async {
    _loadLessons();
    await _setFloor(_floor);
    for (final f in widget.floors) {
      await _getPlan(f);
    }
    if (widget.initialRoom != null) {
      await _findRoom(widget.initialRoom!);
    }
  }

  Future<void> _loadLessons() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('lessons').get();
      if (!mounted) return;
      setState(() {
        _lessons = snap.docs.map((d) => Lesson.fromMap(d.id, d.data())).toList();
      });
    } catch (_) {}
  }

  Future<FloorPlan?> _getPlan(int f) async {
    if (_plans.containsKey(f)) return _plans[f];
    try {
      return _plans[f] = await loadFloorPlan(_asset(f));
    } catch (_) {
      return null;
    }
  }

  Future<NavGraph?> _getGraph(int f) async {
    if (_graphs.containsKey(f)) return _graphs[f];
    return _graphs[f] = await NavGraph.load(_navAsset(f));
  }

  Future<void> _setFloor(int f) async {
    setState(() => _loading = true);
    final plan = await _getPlan(f);
    if (!mounted) return;
    setState(() {
      _floor = f;
      _plan = plan;
      _error = plan == null ? 'План $f этажа пока не загружен' : null;
      _selected = null;
      _info = null;
      _route = null;
      _routeStart = null;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitToScreen());
  }

  void _fitToScreen() {
    if (_plan == null || _viewport == Size.zero) return;
    final s = (_viewport.width / _plan!.size.width)
        .clamp(0.0, _viewport.height / _plan!.size.height);
    _fitScale = s;
    final dx = (_viewport.width - _plan!.size.width * s) / 2;
    final dy = (_viewport.height - _plan!.size.height * s) / 2;
    _transform.value = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(s);
  }

  void _centerOn(Offset c, {double? scale}) {
    final s = scale ?? (_fitScale * 3.2);
    _transform.value = Matrix4.identity()
      ..translate(_viewport.width / 2, _viewport.height / 2)
      ..scale(s)
      ..translate(-c.dx, -c.dy);
  }

  void _fitBounds(Rect r) {
    const pad = 80.0;
    final s = ((_viewport.width) / (r.width + pad * 2))
        .clamp(0.0, (_viewport.height * 0.6) / (r.height + pad * 2))
        .clamp(_fitScale, 4.0);
    _centerOn(r.center, scale: s);
  }

  Future<void> _onTapRoom(RoomShape? r) async {
    if (_routeStart != null && r != null && r.number != _routeStart) {
      await _buildRoute(_routeStart!, r.number);
      return;
    }
    await _select(r);
  }

  Future<void> _select(RoomShape? r) async {
    setState(() {
      _selected = r;
      _info = null;
      if (r != null) _route = null;
    });
    if (r == null) return;
    try {
      final d = await FirebaseFirestore.instance
          .collection('buildings')
          .doc(widget.buildingId)
          .collection('rooms')
          .doc(r.number)
          .get();
      if (!mounted || _selected != r) return;
      final m = d.data();
      setState(() => _info = RoomInfo(
        title: m?['title'] ?? 'Аудитория ${r.number}',
        description: m?['description'] ?? '',
        department: m?['department'] ?? '',
      ));
    } catch (_) {
      if (mounted) setState(() => _info = RoomInfo(title: 'Аудитория ${r.number}'));
    }
  }

  Future<void> _findRoom(String raw) async {
    final number = normRoom(raw) ?? raw.trim();
    if (number.isEmpty) return;
    final guess = floorOfRoom(number);
    final order = <int>{
      if (guess != null && widget.floors.contains(guess)) guess,
      _floor,
      ...widget.floors,
    };
    for (final f in order) {
      final plan = await _getPlan(f);
      final room = plan?.byNumber(number);
      if (room != null) {
        if (f != _floor) await _setFloor(f);
        await _select(room);
        _centerOn(room.center);
        return;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Кабинет $number не найден')));
    }
  }

  Future<void> _buildRoute(String from, String to) async {
    final g = await _getGraph(_floor);
    final plan = _plan;
    if (g == null || plan == null) return _toast('Для этого этажа ещё нет графа маршрутов');
    final path = g.route(from, to);
    if (path == null) return _toast('Маршрут между $from и $to пока недоступен');
    _applyRoute([
      if (plan.byNumber(from) != null) plan.byNumber(from)!.center,
      ...path,
      if (plan.byNumber(to) != null) plan.byNumber(to)!.center,
    ]);
    final target = plan.byNumber(to);
    setState(() {
      _routeStart = null;
      _selected = target;
    });
  }

  Future<void> _routeFromStairs() async {
    final r = _selected;
    if (r == null) return;
    final g = await _getGraph(_floor);
    if (g == null) return _toast('Для этого этажа ещё нет графа маршрутов');
    final path = g.routeFromNearestStairs(r.number);
    if (path == null) return _toast('Для кабинета ${r.number} маршрут пока недоступен');
    _applyRoute([...path, r.center]);
  }

  void _applyRoute(List<Offset> pts) {
    setState(() => _route = pts);
    var rect = Rect.fromPoints(pts.first, pts.first);
    for (final p in pts) {
      rect = rect.expandToInclude(Rect.fromPoints(p, p));
    }
    _fitBounds(rect);
  }

  void _toast(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  List<Suggestion> _suggest(String q) {
    q = q.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final out = <Suggestion>[];
    for (final e in _plans.entries) {
      for (final r in e.value.rooms) {
        if (r.number.toLowerCase().startsWith(q)) {
          out.add(Suggestion(r.number, 'Этаж ${e.key}', r.number));
        }
      }
    }
    final seen = <String>{};
    for (final l in _lessons) {
      final room = normRoom(l.room);
      if (room == null || l.teacher.isEmpty) continue;
      if (l.teacher.toLowerCase().contains(q) && seen.add('${l.teacher}|$room')) {
        out.add(Suggestion(l.teacher, 'ауд. $room', room, isTeacher: true));
      }
    }
    out.sort((a, b) => a.isTeacher == b.isTeacher ? a.label.compareTo(b.label) : (a.isTeacher ? 1 : -1));
    return out.take(6).toList();
  }

  List<Lesson> _upcoming(String room) {
    final today = DateTime.now().weekday - 1;
    final list = _lessons.where((l) => normRoom(l.room) == room).toList();
    list.sort((a, b) {
      final da = (a.dayIndex - today) % 7, db = (b.dayIndex - today) % 7;
      return da != db ? da.compareTo(db) : a.time.compareTo(b.time);
    });
    return list.take(5).toList();
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ Динамический фон
      appBar: AppBar(
        title: Text(widget.buildingName),
      ),
      body: Stack(
        children: [
          _buildMap(),
          _buildSearch(),
          _buildFloorSwitcher(),
          if (_routeStart != null) _buildPickBanner(),
          if (_selected != null) _buildSheet(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return LayoutBuilder(builder: (context, c) {
      _viewport = Size(c.maxWidth, c.maxHeight);
      if (_loading) return const Center(child: CircularProgressIndicator());
      final plan = _plan;
      if (plan == null) return Center(child: Text(_error ?? 'Нет плана'));
      return InteractiveViewer(
        transformationController: _transform,
        constrained: false,
        minScale: 0.1,
        maxScale: 8,
        boundaryMargin: const EdgeInsets.all(2000),
        child: GestureDetector(
          onTapUp: (d) => _onTapRoom(plan.roomAt(d.localPosition)),
          child: SizedBox(
            width: plan.size.width,
            height: plan.size.height,
            child: Stack(children: [
              SvgPicture.string(plan.svg,
                  width: plan.size.width, height: plan.size.height, fit: BoxFit.fill),
              CustomPaint(size: plan.size, painter: _HighlightPainter(_selected?.path)),
              if (_route != null)
                CustomPaint(size: plan.size, painter: _RoutePainter(_route!)),
              AnimatedBuilder(
                animation: _transform,
                builder: (_, __) {
                  final scale = _transform.value.getMaxScaleOnAxis();
                  if (scale < _fitScale * 1.6) return const SizedBox.shrink();
                  return CustomPaint(
                      size: plan.size, painter: _LabelPainter(plan.labels, scale));
                },
              ),
            ]),
          ),
        ),
      );
    });
  }

  Widget _buildSearch() {
    return Positioned(
      top: 12,
      left: 12,
      right: 80,
      child: Autocomplete<Suggestion>(
        optionsBuilder: (v) => _suggest(v.text),
        displayStringForOption: (s) => s.label,
        onSelected: (s) => _findRoom(s.room),
        fieldViewBuilder: (ctx, ctrl, focus, onSubmit) => Material(
          elevation: 3,
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor, // ✅ Динамический цвет
          child: TextField(
            controller: ctrl,
            focusNode: focus,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) {
              final s = _suggest(v);
              _findRoom(s.isNotEmpty ? s.first.room : v);
            },
            decoration: InputDecoration(
              hintText: 'Кабинет или преподаватель',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ctrl.text.isEmpty
                  ? null
                  : IconButton(icon: const Icon(Icons.close), onPressed: ctrl.clear),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        optionsViewBuilder: (ctx, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor, // ✅ Динамический цвет
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: _viewport.width - 92, maxHeight: 300),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final s in options)
                    ListTile(
                      dense: true,
                      leading: Icon(s.isTeacher ? Icons.person_outline : Icons.meeting_room_outlined),
                      title: Text(s.label),
                      subtitle: Text(s.subtitle),
                      onTap: () => onSelected(s),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloorSwitcher() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      right: 12,
      top: 12,
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent, // Убираем стандартный фон
        child: Column(children: [
          for (final f in widget.floors.reversed)
            InkWell(
              onTap: () => _setFloor(f),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: f == _floor
                      ? (isDark ? Colors.grey[700] : const Color(0xFFE9ECF1)) // ✅ Динамический цвет
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$f',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: f == _floor ? FontWeight.w800 : FontWeight.w400,
                      color: f == _floor
                          ? (isDark ? Colors.white : const Color(0xFF111827))
                          : Theme.of(context).textTheme.bodySmall?.color,
                    )),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildPickBanner() {
    return Positioned(
      top: 70,
      left: 12,
      right: 80,
      child: Material(
        color: const Color(0xFF2F7FEB),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Expanded(
              child: Text('Старт: ауд. $_routeStart. Нажми на кабинет назначения',
                  style: const TextStyle(color: Colors.white)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() => _routeStart = null),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildSheet() {
    final r = _selected!;
    final lessons = _upcoming(r.number);
    final teachers = {
      for (final l in _lessons.where((l) => normRoom(l.room) == r.number))
        if (l.teacher.isNotEmpty) l.teacher
    }.toList();

    return DraggableScrollableSheet(
      key: ValueKey(r.number),
      initialChildSize: 0.26,
      minChildSize: 0.12,
      maxChildSize: 0.65,
      builder: (ctx, scroll) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, // ✅ Динамический фон
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: const [BoxShadow(blurRadius: 12, color: Color(0x33000000))],
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(children: [
              Expanded(
                child: Text(_info?.title ?? 'Аудитория ${r.number}',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selected = null;
                  _route = null;
                  _routeStart = null;
                }),
              ),
            ]),
            Text('Этаж $_floor · кабинет ${r.number}',
                style: Theme.of(context).textTheme.bodySmall),
            if ((_info?.department ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Кафедра: ${_info!.department}', style: Theme.of(context).textTheme.bodyMedium),
            ],
            if ((_info?.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(_info!.description, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.stairs_outlined),
                  label: const Text('От лестницы'),
                  onPressed: _routeFromStairs,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.alt_route),
                  label: const Text('Отсюда'),
                  onPressed: () => setState(() {
                    _routeStart = r.number;
                    _route = null;
                  }),
                ),
              ),
            ]),
            if (teachers.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Преподаватели', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              for (final t in teachers) Text(t, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (lessons.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Ближайшие пары', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              for (final l in lessons)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.subject, style: Theme.of(context).textTheme.bodyMedium),
                  subtitle: Text(
                      '${_dayNames[l.dayIndex.clamp(0, 5)]}, ${l.time} · ${l.group}',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  final Path? path;
  _HighlightPainter(this.path);

  @override
  void paint(Canvas canvas, Size size) {
    if (path == null) return;
    canvas.drawPath(path!, Paint()..color = const Color(0xCCFFE66D));
    canvas.drawPath(
        path!,
        Paint()
          ..color = const Color(0xFFF2B600)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(_HighlightPainter old) => old.path != path;
}

class _RoutePainter extends CustomPainter {
  final List<Offset> pts;
  _RoutePainter(this.pts);

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final paint = Paint()
      ..color = const Color(0xFF2F7FEB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 14), paint);
        d += 26;
      }
    }
    canvas.drawCircle(pts.first, 9, Paint()..color = const Color(0xFF22A06B));
    canvas.drawCircle(pts.last, 9, Paint()..color = const Color(0xFFE5484D));
    canvas.drawCircle(pts.first, 9, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);
    canvas.drawCircle(pts.last, 9, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.pts != pts;
}

class _LabelPainter extends CustomPainter {
  final List<MapLabel> labels;
  final double scale;
  _LabelPainter(this.labels, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final fs = (13 / scale).clamp(6.0, 20.0);
    for (final l in labels) {
      final tp = TextPainter(
        text: TextSpan(
            text: l.text,
            style: TextStyle(
                fontSize: fs, color: const Color(0xFF4A5A72), fontWeight: FontWeight.w500)),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(l.pos.dx, l.pos.dy);
      canvas.rotate(l.rotation);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_LabelPainter old) => old.scale != scale || old.labels != labels;
}