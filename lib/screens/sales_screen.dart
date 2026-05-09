import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import '../models/sale.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../theme/app_theme.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<Sale>     _all    = [];
  List<Sale>     _shown  = [];
  List<Product>  _prods  = [];
  List<Customer> _customers = [];
  bool _loading = true;
  final _search  = TextEditingController();
  String _status = '';
  final _eur = NumberFormat.currency(locale: 'es_ES', symbol: '€');

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.getSales(),
        ApiService.getProducts(),
        ApiService.getCustomers(),
      ]);
      _all       = results[0] as List<Sale>;
      _prods     = results[1] as List<Product>;
      _customers = results[2] as List<Customer>;
      _filter();
    } catch (e) {
      if (mounted) _snack('$e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _shown = _all.where((s) {
        if (q.isNotEmpty &&
            !(s.customerName ?? '').toLowerCase().contains(q) &&
            !(s.invoiceNumber ?? '').toLowerCase().contains(q)) return false;
        if (_status.isNotEmpty && s.paymentStatus != _status) return false;
        return true;
      }).toList();
    });
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppTheme.danger : AppTheme.success,
      ));

  Future<void> _cycleStatus(Sale sale) async {
    try {
      await ApiService.updatePaymentStatus(sale.id, sale.nextStatus);
      _load();
    } catch (e) { _snack('$e', error: true); }
  }

  Future<void> _downloadPdf(Sale sale) async {
    try {
      final bytes = await ApiService.getInvoicePdf(sale.id);
      await Printing.sharePdf(
          bytes: bytes,
          filename: 'Factura_${sale.invoiceNumber ?? sale.id}.pdf');
    } catch (e) { _snack('Error al descargar PDF: $e', error: true); }
  }

  Future<void> _delete(Sale sale) async {
    final ok = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar venta'),
          content: Text('¿Eliminar la venta ${sale.invoiceNumber ?? "#${sale.id}"}?\nSe restaurará el stock.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                child: const Text('Eliminar')),
          ],
        ));
    if (ok != true) return;
    try { await ApiService.deleteSale(sale.id); _snack('Venta eliminada'); _load(); }
    catch (e) { _snack('$e', error: true); }
  }

  Future<void> _showNewSaleForm() async {
    await Navigator.push(context, MaterialPageRoute(
        builder: (_) => _NewSaleScreen(products: _prods, customers: _customers)));
    _load();
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pagada':  return AppTheme.success;
      case 'vencida': return AppTheme.danger;
      default:        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ventas'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(children: [
              TextField(
                controller: _search, onChanged: (_) => _filter(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar cliente o factura...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search, color: Colors.white60),
                  filled: true, fillColor: Colors.white24,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: _status.isEmpty ? null : _status,
                  decoration: InputDecoration(
                    hintText: 'Todos los estados',
                    filled: true, fillColor: Colors.white24,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  dropdownColor: Colors.white,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...['pendiente', 'pagada', 'vencida'].map((s) =>
                        DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))),
                  ],
                  onChanged: (v) { _status = v ?? ''; _filter(); },
                )),
                if (_status.isNotEmpty || _search.text.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () { _search.clear(); _status = ''; _filter(); },
                  ),
                ],
              ]),
            ]),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _shown.isEmpty
              ? Center(child: Text(_all.isEmpty ? 'No hay ventas. Pulsa + para registrar.' : 'Sin resultados.',
                  style: const TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _shown.length,
                    itemBuilder: (_, i) {
                      final s = _shown[i];
                      final sc = _statusColor(s.paymentStatus);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(s.invoiceNumber ?? 'Sin número',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                              GestureDetector(
                                onTap: () => _cycleStatus(s),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: sc.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Text(s.statusLabel,
                                      style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            Text(s.customerName ?? '-', style: const TextStyle(color: Colors.grey)),
                            Text(DateFormat('dd/MM/yyyy').format(s.saleDate),
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Text(_eur.format(s.total),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primary),
                                tooltip: 'Descargar PDF',
                                onPressed: () => _downloadPdf(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                                tooltip: 'Eliminar',
                                onPressed: () => _delete(s),
                              ),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewSaleForm,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Venta'),
      ),
    );
  }
}

// ── Formulario de nueva venta ─────────────────────────────────────────────────
class _NewSaleScreen extends StatefulWidget {
  final List<Product>  products;
  final List<Customer> customers;
  const _NewSaleScreen({required this.products, required this.customers});

  @override
  State<_NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<_NewSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  Customer? _selectedCustomer;
  final _nameC    = TextEditingController();
  final _nifC     = TextEditingController();
  final _addrC    = TextEditingController();
  final _cityC    = TextEditingController();
  final _postalC  = TextEditingController();
  final _emailC   = TextEditingController();
  double _ivaRate      = 21;
  double _discountRate = 0;
  bool   _submitting   = false;

  final List<_ItemRow> _items = [];

  @override
  void initState() { super.initState(); _addItem(); }

  void _addItem() => setState(() => _items.add(_ItemRow(products: widget.products)));

  double get _subtotal => _items.fold(0, (s, r) => s + r.subtotal);
  double get _discountAmount => _subtotal * (_discountRate / 100);
  double get _taxableBase    => _subtotal - _discountAmount;
  double get _ivaAmount      => _taxableBase * (_ivaRate / 100);
  double get _total          => _taxableBase + _ivaAmount;

  void _fillCustomer(Customer c) {
    _nameC.text   = c.name;
    _nifC.text    = c.nif ?? '';
    _addrC.text   = c.address ?? '';
    _cityC.text   = c.city ?? '';
    _postalC.text = c.postalCode ?? '';
    _emailC.text  = c.email ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final itemsData = _items
        .where((r) => r.productId != null && r.quantity > 0)
        .map((r) => {'product_id': r.productId, 'quantity': r.quantity})
        .toList();
    if (itemsData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Añade al menos un artículo'), backgroundColor: AppTheme.danger));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ApiService.createSale({
        'items':               itemsData,
        'iva_rate':            _ivaRate,
        'discount_rate':       _discountRate,
        'customer_id':         _selectedCustomer?.id,
        'customer_name':       _nameC.text,
        'customer_nif':        _nifC.text,
        'customer_address':    _addrC.text,
        'customer_city':       _cityC.text,
        'customer_postal_code':_postalC.text,
        'customer_email':      _emailC.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Venta registrada'), backgroundColor: AppTheme.success));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.danger));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eur = NumberFormat.currency(locale: 'es_ES', symbol: '€');

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Venta')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // ── Cliente ──────────────────────────────────────────
          _section('Datos del Cliente'),
          if (widget.customers.isNotEmpty)
            DropdownButtonFormField<Customer>(
              decoration: const InputDecoration(labelText: 'Cliente guardado'),
              value: _selectedCustomer,
              items: [
                const DropdownMenuItem(value: null, child: Text('— Seleccionar —')),
                ...widget.customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))),
              ],
              onChanged: (c) { setState(() => _selectedCustomer = c); if (c != null) _fillCustomer(c); },
            ),
          const SizedBox(height: 10),
          TextFormField(controller: _nameC,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: (v) => v!.isEmpty ? 'Requerido' : null),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextFormField(controller: _nifC, decoration: const InputDecoration(labelText: 'NIF/CIF'))),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _emailC,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress)),
          ]),
          const SizedBox(height: 10),
          TextFormField(controller: _addrC, decoration: const InputDecoration(labelText: 'Dirección')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextFormField(controller: _cityC, decoration: const InputDecoration(labelText: 'Ciudad'))),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _postalC, decoration: const InputDecoration(labelText: 'C.P.'))),
          ]),
          const SizedBox(height: 20),

          // ── Artículos ────────────────────────────────────────
          Row(children: [
            _section('Artículos'),
            const Spacer(),
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Añadir'),
            ),
          ]),
          ..._items.asMap().entries.map((e) => _itemWidget(e.key, e.value)),
          const SizedBox(height: 20),

          // ── Totales ──────────────────────────────────────────
          _section('Precios'),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              _totalRow('Subtotal:', eur.format(_subtotal)),
              Row(children: [
                const Text('Descuento:', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                SizedBox(width: 70, child: TextFormField(
                  initialValue: '0',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(suffixText: '%', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) => setState(() => _discountRate = double.tryParse(v) ?? 0),
                )),
                const Spacer(),
                Text('-${eur.format(_discountAmount)}', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Text('IVA:', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                SizedBox(width: 70, child: TextFormField(
                  initialValue: '21',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(suffixText: '%', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  onChanged: (v) => setState(() => _ivaRate = double.tryParse(v) ?? 0),
                )),
                const Spacer(),
                Text(eur.format(_ivaAmount), style: const TextStyle(color: Colors.grey)),
              ]),
              const Divider(height: 16),
              Row(children: [
                const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                Text(eur.format(_total),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primary)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Registrar Venta', style: TextStyle(fontSize: 16)),
          ),
        ]),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary)),
  );

  Widget _totalRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      const Spacer(),
      Text(value),
    ]),
  );

  Widget _itemWidget(int idx, _ItemRow row) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Row(children: [
        Expanded(child: DropdownButtonFormField<int>(
          value: row.productId,
          decoration: const InputDecoration(labelText: 'Producto', isDense: true),
          items: [
            const DropdownMenuItem(value: null, child: Text('— Seleccionar —')),
            ...widget.products.map((p) =>
                DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.stock})'))),
          ],
          onChanged: (v) => setState(() { row.productId = v; row.unitPrice = widget.products.firstWhere((p) => p.id == v, orElse: () => Product(id: 0, name: '', price: 0, stock: 0)).price; }),
        )),
        const SizedBox(width: 8),
        SizedBox(width: 70, child: TextFormField(
          initialValue: '1',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Cant.', isDense: true),
          onChanged: (v) => setState(() => row.quantity = int.tryParse(v) ?? 1),
        )),
        const SizedBox(width: 8),
        if (_items.length > 1) IconButton(
          icon: const Icon(Icons.close, color: AppTheme.danger, size: 20),
          onPressed: () => setState(() => _items.removeAt(idx)),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
        ),
      ]),
    ),
  );
}

class _ItemRow {
  final List<Product> products;
  int?   productId;
  int    quantity  = 1;
  double unitPrice = 0;

  _ItemRow({required this.products});

  double get subtotal => unitPrice * quantity;
}
