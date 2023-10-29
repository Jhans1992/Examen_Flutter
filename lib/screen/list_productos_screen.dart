import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({Key? key}) : super(key: key);

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  TextEditingController _searchController = TextEditingController();
  late Stream<QuerySnapshot> _productosStream;

  // Controladores de texto para el diálogo de agregar/editar producto
  TextEditingController _nombreController = TextEditingController();
  TextEditingController _descripcionController = TextEditingController();
  TextEditingController _precioController = TextEditingController();
  TextEditingController _categoriaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _productosStream =
        FirebaseFirestore.instance.collection('productos').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _searchProducts(String query) {
    String lowerCaseQuery = query.toLowerCase();
    return FirebaseFirestore.instance
        .collection('productos')
        .where('nombreBusqueda', isGreaterThanOrEqualTo: lowerCaseQuery)
        .where('nombreBusqueda', isLessThan: lowerCaseQuery + '\uf8ff')
        .snapshots();
  }

  Future _agregarProducto(
      {String? docId,
      String? nombreInit,
      String? descripcionInit,
      String? precioInit,
      String? categoriaInit}) {
    _nombreController.text = nombreInit ?? '';
    _descripcionController.text = descripcionInit ?? '';
    _precioController.text = precioInit ?? '';
    _categoriaController.text = categoriaInit ?? '';

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? 'Agregar Producto' : 'Editar Producto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                decoration: InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: _descripcionController,
                decoration: InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: _precioController,
                decoration: InputDecoration(labelText: 'Precio'),
              ),
              TextField(
                controller: _categoriaController,
                decoration: InputDecoration(labelText: 'Categoría'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              child: Text('Guardar'),
              onPressed: () async {
                try {
                  String nombre = _nombreController.text;
                  String descripcion = _descripcionController.text;
                  String precio = _precioController.text;
                  String categoria = _categoriaController.text;
                  String nombreBusqueda = nombre.toLowerCase();

                  if (docId == null) {
                    await FirebaseFirestore.instance
                        .collection('productos')
                        .add({
                      'nombre': nombre,
                      'descripcion': descripcion,
                      'precio': precio,
                      'categoria': categoria,
                      'nombreBusqueda': nombreBusqueda,
                    });
                  } else {
                    await FirebaseFirestore.instance
                        .collection('productos')
                        .doc(docId)
                        .update({
                      'nombre': nombre,
                      'descripcion': descripcion,
                      'precio': precio,
                      'categoria': categoria,
                      'nombreBusqueda': nombreBusqueda,
                    });
                  }
                  Navigator.of(context).pop();
                } catch (e) {
                  print('Error al guardar producto: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al guardar producto'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            ElevatedButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future _verProducto(Map<String, dynamic> producto) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(producto['nombre'] ?? 'Desconocido'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Descripción: ${producto['descripcion']}'),
              Text('Precio: ${producto['precio']}'),
              Text('Categoría: ${producto['categoria']}'),
            ],
          ),
          actions: [
            ElevatedButton(
              child: Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future _eliminarProducto(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('productos')
          .doc(docId)
          .delete();
    } catch (e) {
      print('Error al eliminar producto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al eliminar producto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Aquí comienza la sección mejorada de visualización de productos
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar producto por nombre',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  if (value.isEmpty) {
                    _productosStream = FirebaseFirestore.instance
                        .collection('productos')
                        .snapshots();
                  } else {
                    _productosStream = _searchProducts(value);
                  }
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _productosStream,
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  return ListView.separated(
                    itemCount: snapshot.data?.docs.length ?? 0,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      var doc = snapshot.data?.docs[index];
                      var producto = doc?.data() as Map<String, dynamic>?;
                      if (producto != null) {
                        return ListTile(
                          title: Text(producto['nombre'] ?? 'Desconocido'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Descripción: ${producto['descripcion']}'),
                              Text('Precio: ${producto['precio']}'),
                              Text('Categoría: ${producto['categoria']}'),
                            ],
                          ),
                          trailing: _buildActions(doc?.id, producto),
                          onTap: () => _verProducto(producto),
                        );
                      } else {
                        return const ListTile(
                          title: Text('Producto desconocido'),
                        );
                      }
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _agregarProducto(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActions(String? docId, Map<String, dynamic> producto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            _agregarProducto(
              docId: docId,
              nombreInit: producto['nombre'],
              descripcionInit: producto['descripcion'],
              precioInit: producto['precio'],
              categoriaInit: producto['categoria'],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            if (docId != null) _eliminarProducto(docId);
          },
        ),
      ],
    );
  }
}
