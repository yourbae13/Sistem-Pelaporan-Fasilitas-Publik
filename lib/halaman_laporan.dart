import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'models/laporan.dart';

class HalamanLaporan extends StatefulWidget {
  const HalamanLaporan({super.key});

  @override
  State<HalamanLaporan> createState() => _HalamanLaporanState();
}

class _HalamanLaporanState extends State<HalamanLaporan> {
  final _db = DatabaseHelper.instance;
  final _searchCtrl = TextEditingController();
  List<Laporan> _data = [];
  StatLaporan _stat = const StatLaporan(0, 0, 0);
  String _filter = 'Semua';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await _db.getLaporan(
      search: _searchCtrl.text.trim(),
      status: _filter,
    );
    final stat = await _db.getStatistik();
    if (!mounted) return;
    setState(() {
      _data = data;
      _stat = stat;
      _loading = false;
    });
  }

  String? _nextStatus(String s) {
    final i = statusList.indexOf(s);
    return i >= 0 && i < statusList.length - 1 ? statusList[i + 1] : null;
  }

  Future<void> _ubahStatus(Laporan l) async {
    final next = _nextStatus(l.status);
    if (next == null || l.id == null) return;
    await _db.updateStatus(l.id!, next);
    await _load();
  }

  Future<void> _hapus(Laporan l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Laporan'),
        content: Text('Hapus "${l.judul}" secara permanen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true && l.id != null) {
      await _db.hapus(l.id!);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Laporan dihapus')));
    }
  }

  Future<void> _edit(Laporan l) async {
    final key = GlobalKey<FormState>();
    final judulCtrl = TextEditingController(text: l.judul);
    final lokasiCtrl = TextEditingController(text: l.lokasi);
    String kategori = l.kategori;
    int urgensi = l.urgensi;
    DateTime tanggal = DateTime.tryParse(l.tanggal) ?? DateTime.now();

    final hasil = await showDialog<Laporan>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Edit Laporan'),
          content: SingleChildScrollView(
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: judulCtrl,
                    decoration: const InputDecoration(labelText: 'Judul'),
                    validator: (v) => (v == null || v.trim().length < 5)
                        ? 'Minimal 5 karakter'
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: kategori,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: kategoriList
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
                    onChanged: (v) => kategori = v ?? kategori,
                  ),
                  TextFormField(
                    controller: lokasiCtrl,
                    decoration: const InputDecoration(labelText: 'Lokasi'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Lokasi wajib diisi'
                        : null,
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: urgensi,
                    decoration: const InputDecoration(labelText: 'Urgensi'),
                    items: urgensiLabel.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => urgensi = v ?? urgensi,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Tanggal: ${formatTanggal(tanggal)}'),
                      ),
                      TextButton(
                        onPressed: () async {
                          final p = await showDatePicker(
                            context: ctx,
                            initialDate: tanggal,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(DateTime.now().year + 1),
                          );
                          if (p != null) setD(() => tanggal = p);
                        },
                        child: const Text('Pilih'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (!key.currentState!.validate()) return;
                Navigator.pop(
                  ctx,
                  Laporan(
                    id: l.id,
                    judul: judulCtrl.text.trim(),
                    kategori: kategori,
                    lokasi: lokasiCtrl.text.trim(),
                    urgensi: urgensi,
                    tanggal: formatTanggal(tanggal),
                    status: l.status,
                  ),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (hasil != null) {
      await _db.update(hasil);
      await _load();
    }
  }

  Widget _statCard(String label, int value, Color color) {
    return Expanded(
      child: Card(
        color: color.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Widget _item(Laporan l) {
    final selesai = l.status == 'Selesai';
    final urgColor = l.urgensi == 3
        ? Colors.red
        : (l.urgensi == 2 ? Colors.orange : Colors.blueGrey);
    final next = _nextStatus(l.status);

    return Opacity(
      opacity: selesai ? 0.6 : 1,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: l.urgensi == 3 && !selesai ? Colors.red : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.judul,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: selesai ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l.kategori} • ${l.lokasi}\n${l.tanggal}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        _badge(urgensiLabel[l.urgensi] ?? '-', urgColor),
                        _badge(
                          l.status,
                          selesai
                              ? Colors.green
                              : (l.status == 'Diproses'
                                    ? Colors.blue
                                    : Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (next != null)
                IconButton(
                  tooltip: 'Ubah ke $next',
                  icon: const Icon(Icons.arrow_circle_right_outlined),
                  onPressed: () => _ubahStatus(l),
                ),
              PopupMenuButton<String>(
                onSelected: (v) => v == 'edit' ? _edit(l) : _hapus(l),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monitoring Laporan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                _statCard('Total Laporan', _stat.total, Colors.teal),
                _statCard('Laporan Aktif', _stat.aktif, Colors.orange),
                _statCard('Laporan Selesai', _stat.selesai, Colors.green),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _load(),
              decoration: const InputDecoration(
                hintText: 'Cari judul atau lokasi',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: ['Semua', ...statusList]
                  .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s),
                        selected: _filter == s,
                        onSelected: (_) {
                          setState(() => _filter = s);
                          _load();
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _data.isEmpty
                ? const Center(child: Text('Belum ada laporan'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _data.length,
                    itemBuilder: (_, i) => _item(_data[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
