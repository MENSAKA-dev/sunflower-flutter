import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats     = {};
  List<Map<String, dynamic>> _monthly   = [];
  List<Map<String, dynamic>> _topProds  = [];
  List<Product> _lowStock = [];
  final _eur = NumberFormat.currency(locale: 'es_ES', symbol: '€');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getSalesStats(),
        ApiService.getMonthlyStats(),
        ApiService.getTopProducts(),
        ApiService.getProducts(),
      ]);
      setState(() {
        _stats    = results[0] as Map<String, dynamic>;
        _monthly  = results[1] as List<Map<String, dynamic>>;
        _topProds = results[2] as List<Map<String, dynamic>>;
        final all = results[3] as List<Product>;
        _lowStock = all.where((p) => p.stock <= 10).toList();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _statsGrid(),
                  const SizedBox(height: 16),
                  if (_lowStock.isNotEmpty) ...[_alertsCard(), const SizedBox(height: 16)],
                  _monthlyChart(),
                  const SizedBox(height: 16),
                  _topProductsChart(),
                ]),
              ),
            ),
    );
  }

  Widget _statsGrid() {
    final total     = double.tryParse(_stats['total_revenue']?.toString() ?? '0') ?? 0;
    final pending   = double.tryParse(_stats['pending_revenue']?.toString() ?? '0') ?? 0;
    final sales     = _stats['total_sales']?.toString() ?? '0';
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _statCard('Ventas', sales, Icons.receipt_long, AppTheme.primary),
        _statCard('Ingresos', _eur.format(total), Icons.euro, Colors.green.shade700),
        _statCard('Pendiente', _eur.format(pending), Icons.hourglass_top, AppTheme.warning),
        _statCard('Stock bajo', '${_lowStock.length}', Icons.warning_amber, AppTheme.danger),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        ]),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ]),
    ),
  );

  Widget _alertsCard() => Card(
    color: const Color(0xFFFEF2F2),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
          const SizedBox(width: 8),
          Text('Stock bajo (${_lowStock.length} productos)',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: _lowStock.map((p) => Chip(
          label: Text('${p.name}: ${p.stock == 0 ? "Sin stock" : "${p.stock} uds"}',
              style: const TextStyle(fontSize: 12)),
          backgroundColor: p.stock == 0 ? const Color(0xFFDC2626) : const Color(0xFFFEE2E2),
          labelStyle: TextStyle(color: p.stock == 0 ? Colors.white : AppTheme.danger),
          padding: EdgeInsets.zero,
        )).toList()),
      ]),
    ),
  );

  Widget _monthlyChart() {
    final now = DateTime.now();
    final labels = <String>[];
    final spots  = <FlSpot>[];
    for (int i = 11; i >= 0; i--) {
      final d   = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('yyyy-MM').format(d);
      final row = _monthly.firstWhere((r) => r['month'] == key, orElse: () => {});
      labels.add(DateFormat('MMM yy', 'es').format(d));
      spots.add(FlSpot((11 - i).toDouble(),
          double.tryParse(row['revenue']?.toString() ?? '0') ?? 0));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ingresos mensuales (12 meses)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28, interval: 2,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= labels.length || i % 2 != 0) return const SizedBox();
                    return Text(labels[i], style: const TextStyle(fontSize: 9, color: Colors.grey));
                  },
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 44,
                  getTitlesWidget: (v, _) =>
                      Text('${v.toInt()}€', style: const TextStyle(fontSize: 9, color: Colors.grey)),
                )),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppTheme.primary,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                    radius: 3, color: Colors.white, strokeWidth: 2, strokeColor: AppTheme.primary)),
                belowBarData: BarAreaData(
                    show: true, color: AppTheme.primary.withOpacity(0.08)),
              )],
            )),
          ),
        ]),
      ),
    );
  }

  Widget _topProductsChart() {
    if (_topProds.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(24),
          child: Center(child: Text('Sin ventas registradas aún', style: TextStyle(color: Colors.grey)))));
    }
    const palette = [AppTheme.primary, Color(0xFF7C3AED), Color(0xFF2563EB),
                     Color(0xFF0891B2), Color(0xFF059669), AppTheme.warning];
    final maxY = _topProds
        .map((r) => double.tryParse(r['total_revenue']?.toString() ?? '0') ?? 0)
        .fold(0.0, (a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Productos más vendidos', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(BarChartData(
              maxY: maxY * 1.25,
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 32,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= _topProds.length) return const SizedBox();
                    final name = (_topProds[i]['product_name'] ?? '').toString();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(name.length > 8 ? '${name.substring(0, 7)}…' : name,
                          style: const TextStyle(fontSize: 9, color: Colors.grey)),
                    );
                  },
                )),
              ),
              barGroups: _topProds.asMap().entries.map((e) => BarChartGroupData(
                x: e.key,
                barRods: [BarChartRodData(
                  toY: double.tryParse(e.value['total_revenue']?.toString() ?? '0') ?? 0,
                  color: palette[e.key % palette.length],
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                )],
              )).toList(),
            )),
          ),
        ]),
      ),
    );
  }
}
