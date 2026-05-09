import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _all     = [];
  List<Product> _shown   = [];
  bool _loading          = true;
  final _search          = TextEditingController();
  final _eur             = NumberFormat.currency(locale: 'es_ES', symbol: '€');

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _all = await ApiService.getProducts();
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
      _shown = _all.where((p) =>
        p.name.toLowerCase().contains(q) ||
        (p.category ?? '').toLowerCase().contains(q)
      ).toList();
    });
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.danger : AppTheme.success,
    ));
  }

  Future<void> _showForm({Product? p}) async {
    final nameC  = TextEditingController(text: p?.name ?? '');
    final descC  = TextEditingController(text: p?.description ?? '');
    final priceC = TextEditingController(text: p?.price.toString() ?? '');
    final stockC = TextEditingController(text: p?.stock.toString() ?? '');
    final catC   = TextEditingController(text: p?.category ?? '');
    final key    = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p == null ? 'Nuevo Producto' : 'Editar Producto'),
        content: SingleChildScrollView(
          child: Form(key: key, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: nameC, decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null),
            const SizedBox(height: 10),
            TextFormField(controller: descC, decoration: const InputDecoration(labelText: 'Descripción')),
            const SizedBox(height: 10),
            TextFormField(controller: priceC, decoration: const InputDecoration(labelText: 'Precio (€) *'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => double.tryParse(v ?? '') == null ? 'Número válido' : null),
            const SizedBox(height: 10),
            TextFormField(controller: stockC, decoration: const InputDecoration(labelText: 'Stock *'),
                keyboardType: TextInputType.number,
                validator: (v) => int.tryParse(v ?? '') == null ? 'Número entero' : null),
            const SizedBox(height: 10),
            TextFormField(controller: catC, decoration: const InputDecoration(labelText: 'Categoría')),
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
      'name': nameC.text, 'description': descC.text,
      'price': double.parse(priceC.text), 'stock': int.parse(stockC.text), 'category': catC.text,
    };
    try {
      if (p == null) {
        await ApiService.createProduct(data);
        _snack('Producto creado');
      } else {
        await ApiService.updateProduct(p.id, data);
        _snack('Producto actualizado');
      }
      _load();
    } catch (e) { _snack('$e', error: true); }
  }

  Future<void> _delete(Product p) async {
    final ok = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar producto'),
          content: Text('¿Eliminar "${p.name}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                child: const Text('Eliminar')),
          ],
        ));
    if (ok != true) return;
    try {
      await ApiService.deleteProduct(p.id);
      _snack('Producto eliminado');
      _load();
    } catch (e) { _snack('$e', error: true); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => _filter(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white60),
                filled: true,
                fillColor: Colors.white24,
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
              ? Center(child: Text(_all.isEmpty ? 'No hay productos. Pulsa + para añadir.' : 'Sin resultados.',
                  style: const TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _shown.length,
                    itemBuilder: (_, i) {
                      final p = _shown[i];
                      final lowStock = p.stock <= 10;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: lowStock
                                ? AppTheme.danger.withOpacity(0.1)
                                : AppTheme.primaryLight,
                            child: Icon(Icons.inventory_2_outlined,
                                color: lowStock ? AppTheme.danger : AppTheme.primary, size: 20),
                          ),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${p.category ?? "Sin categoría"}  ·  Stock: ${p.stock}',
                            style: TextStyle(color: lowStock ? AppTheme.danger : Colors.grey),
                          ),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(_eur.format(p.price),
                                style: const TextStyle(fontWeight: FontWeight.bold,
                                    color: AppTheme.primary, fontSize: 15)),
                            const SizedBox(width: 4),
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _showForm(p: p)),
                            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.danger),
                                onPressed: () => _delete(p)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
