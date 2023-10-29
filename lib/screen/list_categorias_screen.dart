 import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListCategoriasScreen extends StatefulWidget {
  @override
  _ListCategoriasScreenState createState() => _ListCategoriasScreenState();
}

class _ListCategoriasScreenState extends State<ListCategoriasScreen> {
  TextEditingController _searchController = TextEditingController();
  TextEditingController _categoriaController = TextEditingController();
  late Stream<QuerySnapshot> _categoriasStream;
  String? _selectedCategoriaId;

  @override
  void initState() {
    super.initState();
    _categoriasStream = FirebaseFirestore.instance.collection('categorias').snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _searchCategorias(String query) {
    return FirebaseFirestore.instance
        .collection('categorias')
        .where('nombre', isGreaterThanOrEqualTo: query)
        .where('nombre', isLessThan: query + 'z')
        .snapshots();
  }

  Stream<QuerySnapshot> _getProductos(String categoriaId) {
    return FirebaseFirestore.instance
        .collection('productos')
        .where('categoriaId', isEqualTo: categoriaId)
        .snapshots();
  }

  Future<void> _agregarCategoria({String? docId, String? nombreCategoria}) {
    _categoriaController.text = nombreCategoria ?? '';
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? 'Agregar Categoría' : 'Editar Categoría'),
          content: TextField(
            controller: _categoriaController,
            decoration: InputDecoration(labelText: 'Nombre de la Categoría'),
          ),
          actions: [
            ElevatedButton(
              child: Text('Guardar'),
              onPressed: () async {
                if (docId == null) {
                  await FirebaseFirestore.instance.collection('categorias').add({
                    'nombre': _categoriaController.text,
                  });
                } else {
                  await FirebaseFirestore.instance.collection('categorias').doc(docId).update({
                    'nombre': _categoriaController.text,
                  });
                }
                Navigator.of(context).pop();
                _categoriaController.clear();
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

  Future<void> _eliminarCategoria(String docId) async {
    await FirebaseFirestore.instance.collection('categorias').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar categoría',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _categoriasStream = _searchCategorias(value);
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _categoriasStream,
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data?.docs.length ?? 0,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> categoria = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      String docId = snapshot.data!.docs[index].id;

                      return ListTile(
                        title: Text(categoria['nombre']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _agregarCategoria(docId: docId, nombreCategoria: categoria['nombre']),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _eliminarCategoria(docId),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedCategoriaId = docId;
                          });
                        },
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Ocurrió un error al cargar las categorías'));
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          if (_selectedCategoriaId != null)
            Expanded(
              child: StreamBuilder(
                stream: _getProductos(_selectedCategoriaId!),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      itemCount: snapshot.data?.docs.length ?? 0,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> producto = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                        return ListTile(
                          title: Text(producto['nombre']),
                          subtitle: Text('Precio: \$${producto['precio']}'),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Ocurrió un error al cargar los productos'));
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _agregarCategoria(),
      ),
    );
  }
}