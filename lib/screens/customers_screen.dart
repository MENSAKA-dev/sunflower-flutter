import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/customer.dart';
import '../theme/app_theme.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<Customer> _all   = [];
  List<Customer> _shown = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _all = await ApiService.getCustomers();
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
      _shown = _all.where((c) =>
        c.name.toLowerCase().contains(q) ||
        (c.email ?? '').toLowerCase().contains(q) ||
        (c.nif ?? '').toLowerCase().contains(q)
      ).toList();
    });
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppTheme.danger : AppTheme.success,
      ));

  Future<void> _showForm({Customer? c}) async {
    final nameC   = TextEditingController(text: c?.name ?? '');
    final nifC    = TextEditingController(text: c?.nif ?? '');
    final addrC   = TextEditingController(text: c?.address ?? '');
    final cityC   = TextEditingController(text: c?.city ?? '');
    final postalC = TextEditingController(text: c?.postalCode ?? '');
    final phoneC  = TextEditingController(text: c?.phone ?? '');
    final emailC  = TextEditingController(text: c?.email ?? '');
    final notesC  = TextEditingController(text: c?.notes ?? '');
    final key     = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(c == null ? 'Nuevo Cliente' : 'Editar Cliente'),
        content: SingleChildScrollView(
          child: Form(key: key, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: nameC, decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 10),
            TextFormField(controller: nifC, decoration: const InputDecoration(labelText: 'NIF/CIF')),
            const SizedBox(height: 10),
            TextFormField(controller: addrC, decoration: const InputDecoration(labelText: 'Dirección')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextFormField(controller: cityC, decoration: const InputDecoration(labelText: 'Ciudad'))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: postalC, decoration: const InputDecoration(labelText: 'C.P.'))),
            ]),
            const SizedBox(height: 10),
            TextFormField(controller: phoneC, decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            TextFormField(controller: emailC, decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            TextFormField(controller: notesC, decoration: const InputDecoration(labelText: 'Notas'),
                maxLines: 2),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () {
            if (key.currentState!.validate()) Navigator.pop(ctx, true);
          }, child: const Text('Guardar')),
        ],
      ),
    );

    if (ok != true) return;
    final data = {
      'name': nameC.text, 'nif': nifC.text, 'address': addrC.text,
      'city': cityC.text, 'postal_code': postalC.text,
      'phone': phoneC.text, 'email': emailC.text, 'notes': notesC.text,
    };
    try {
      if (c == null) { await ApiService.createCustomer(data); _snack('Cliente creado'); }
      else { await ApiService.updateCustomer(c.id, data); _snack('Cliente actualizado'); }
      _load();
    } catch (e) { _snack('$e', error: true); }
  }

  Future<void> _delete(Customer c) async {
    final ok = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar cliente'),
          content: Text('¿Eliminar "${c.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                child: const Text('Eliminar')),
          ],
        ));
    if (ok != true) return;
    try { await ApiService.deleteCustomer(c.id); _snack('Cliente eliminado'); _load(); }
    catch (e) { _snack('$e', error: true); }
  }

  Future<void> _showHistory(Customer c) async {
    List<Map<String, dynamic>> sales = [];
    try { sales = await ApiService.getCustomerSales(c.id); }
    catch (_) {}
    if (!mounted) return;

    final eur = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
        builder: (ctx, ctrl) => Column(children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.all(16),
              child: Text('Historial: ${c.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          if (sales.isEmpty)
            const Expanded(child: Center(child: Text('Sin compras registradas.',
                style: TextStyle(color: Colors.grey)))),
          if (sales.isNotEmpty) Expanded(
            child: ListView.builder(
              controller: ctrl,
              itemCount: sales.length,
              itemBuilder: (_, i) {
                final s = sales[i];
                final status = s['payment_status'] ?? 'pendiente';
                final statusColor = status == 'pagada' ? AppTheme.success
                    : status == 'vencida' ? AppTheme.danger : AppTheme.warning;
                return ListTile(
                  leading: const Icon(Icons.receipt, color: AppTheme.primary),
                  title: Text(s['invoice_number'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(
                      DateTime.tryParse(s['sale_date']?.toString() ?? '') ?? DateTime.now())),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(eur.format(double.tryParse(s['total']?.toString() ?? '0') ?? 0),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _search, onChanged: (_) => _filter(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white60),
                filled: true, fillColor: Colors.white24,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _shown.isEmpty
              ? Center(child: Text(_all.isEmpty ? 'No hay clientes. Pulsa + para añadir.' : 'Sin resultados.',
                  style: const TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _shown.length,
                    itemBuilder: (_, i) {
                      final c = _shown[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryLight,
                            child: Text(c.name[0].toUpperCase(),
                                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            [c.city, c.email].where((s) => s != null && s.isNotEmpty).join('  ·  '),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.history, size: 20, color: AppTheme.primary),
                                onPressed: () => _showHistory(c)),
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showForm(c: c)),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                                onPressed: () => _delete(c)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
