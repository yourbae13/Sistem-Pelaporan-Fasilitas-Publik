import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'database_helper.dart';
import 'halaman_laporan.dart';
import 'models/laporan.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart City',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HalamanInput(),
    );
  }
}

class HalamanInput extends StatefulWidget {
  const HalamanInput({super.key});

  @override
  State<HalamanInput> createState() => _HalamanInputState();
}

class _HalamanInputState extends State<HalamanInput> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _lokasiCtrl = TextEditingController();
  final _tanggalCtrl = TextEditingController();
  String? _kategori;
  int? _urgensi;
  DateTime? _tanggal;
  bool _saving = false;
  int _resetCount = 0;

  @override
  void dispose() {
    _judulCtrl.dispose();
    _lokasiCtrl.dispose();
    _tanggalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _tanggal = picked;
        _tanggalCtrl.text = formatTanggal(picked);
      });
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await DatabaseHelper.instance.tambah(
        Laporan(
          judul: _judulCtrl.text.trim(),
          kategori: _kategori!,
          lokasi: _lokasiCtrl.text.trim(),
          urgensi: _urgensi!,
          tanggal: formatTanggal(_tanggal!),
        ),
      );
      if (!mounted) return;
      _judulCtrl.clear();
      _lokasiCtrl.clear();
      _tanggalCtrl.clear();
      setState(() {
        _kategori = null;
        _urgensi = null;
        _tanggal = null;
        _resetCount++;
      });
      _formKey.currentState!.reset();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Laporan berhasil dikirim')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lapor Fasilitas Publik')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _judulCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Judul Masalah',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Judul wajib diisi';
                      if (t.length < 5) return 'Minimal 5 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey('kat$_resetCount'),
                    initialValue: _kategori,
                    decoration: const InputDecoration(
                      labelText: 'Kategori Fasilitas',
                      border: OutlineInputBorder(),
                    ),
                    items: kategoriList
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
                    onChanged: (v) => _kategori = v,
                    validator: (v) =>
                        v == null ? 'Kategori wajib dipilih' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lokasiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Lokasi / Kecamatan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Lokasi wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    key: ValueKey('urg$_resetCount'),
                    initialValue: _urgensi,
                    decoration: const InputDecoration(
                      labelText: 'Tingkat Urgensi',
                      border: OutlineInputBorder(),
                    ),
                    items: urgensiLabel.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => _urgensi = v,
                    validator: (v) =>
                        v == null ? 'Urgensi wajib dipilih' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tanggalCtrl,
                    readOnly: true,
                    onTap: _pilihTanggal,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Kejadian',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Tanggal wajib dipilih'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _simpan,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Kirim Laporan'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HalamanLaporan()),
                    ),
                    child: const Text('Pantau Laporan Kota'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
