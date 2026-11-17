const kategoriList = [
  'Penerangan',
  'Jalan',
  'Drainase',
  'Sampah',
  'Lalu Lintas',
];
const urgensiLabel = {1: 'Normal', 2: 'Mendesak', 3: 'Darurat'};
const statusList = ['Baru', 'Diproses', 'Selesai'];

String formatTanggal(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class Laporan {
  final int? id;
  final String judul;
  final String kategori;
  final String lokasi;
  final int urgensi;
  final String tanggal;
  final String status;

  const Laporan({
    this.id,
    required this.judul,
    required this.kategori,
    required this.lokasi,
    required this.urgensi,
    required this.tanggal,
    this.status = 'Baru',
  });

  factory Laporan.fromMap(Map<String, Object?> map) => Laporan(
    id: map['id'] as int?,
    judul: map['judul'] as String,
    kategori: map['kategori'] as String,
    lokasi: map['lokasi'] as String,
    urgensi: map['urgensi'] as int,
    tanggal: map['tanggal'] as String,
    status: map['status'] as String,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'judul': judul,
    'kategori': kategori,
    'lokasi': lokasi,
    'urgensi': urgensi,
    'tanggal': tanggal,
    'status': status,
  };
}
