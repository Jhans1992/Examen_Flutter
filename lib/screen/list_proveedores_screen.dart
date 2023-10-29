// Importaciones necesarias
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({Key? key}) : super(key: key);

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  // Controlador para el campo de búsqueda
  late TextEditingController _searchController;
  // Stream para obtener todos los proveedores
  late Stream<QuerySnapshot> _proveedoresStream;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _proveedoresStream = FirebaseFirestore.instance.collection('proveedores').snapshots();
    print('Inicialización completa');
  }

  // Función para realizar la búsqueda de proveedores
  Stream<QuerySnapshot> _searchProveedores(String query) {
    String queryLower = query.toLowerCase();
    print('Realizando búsqueda: $queryLower');
    return FirebaseFirestore.instance
        .collection('proveedores')
        .where('nombre_lower', isGreaterThanOrEqualTo: queryLower)
        .where('nombre_lower', isLessThan: queryLower + '\uf8ff')
        .snapshots();
  }

  // Función para mostrar la información de un proveedor en un diálogo
  Future<void> _verProveedor(Map<String, dynamic> proveedor) async {
    print('Mostrando información del proveedor: ${proveedor['nombre']}');
    return _showDialog(
      title: proveedor['nombre'] ?? 'Desconocido',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Correo: ${proveedor['correo']}'),
          Text('Dirección: ${proveedor['direccion']}'),
          // Agrega más campos si es necesario
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
  }

  // Función para editar o añadir un proveedor
  Future<void> _editarProveedor({String? docId, String? nombreInit, String? correoInit, String? direccionInit}) async {
    String nombre = nombreInit ?? '';
    String correo = correoInit ?? '';
    String direccion = direccionInit ?? '';

    print('Editando proveedor: ${docId ?? 'Nuevo proveedor'}');

    return _showDialog(
      title: docId == null ? 'Agregar Proveedor' : 'Editar Proveedor',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            onChanged: (value) {
              nombre = value;
            },
            decoration: InputDecoration(labelText: 'Nombre'),
            controller: TextEditingController(text: nombreInit),
          ),
          TextField(
            onChanged: (value) {
              correo = value;
            },
            decoration: InputDecoration(labelText: 'Correo'),
            controller: TextEditingController(text: correoInit),
          ),
          TextField(
            onChanged: (value) {
              direccion = value;
            },
            decoration: InputDecoration(labelText: 'Dirección'),
            controller: TextEditingController(text: direccionInit),
          ),
          // Agrega más campos si es necesario
        ],
      ),
      actions: [
        ElevatedButton(
          child: Text('Guardar'),
          onPressed: () async {
            if (docId == null) {
              await FirebaseFirestore.instance.collection('proveedores').add({
                'nombre': nombre,
                'nombre_lower': nombre.toLowerCase(),
                'correo': correo,
                'direccion': direccion,
              });
              print('Proveedor añadido: $nombre');
            } else {
              await FirebaseFirestore.instance.collection('proveedores').doc(docId).update({
                'nombre': nombre,
                'nombre_lower': nombre.toLowerCase(),
                'correo': correo,
                'direccion': direccion,
              });
              print('Proveedor editado: $nombre');
            }
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: Text('Cancelar'),
          onPressed: () {
            print('Edición cancelada');
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  // Función para eliminar un proveedor
  Future<void> _eliminarProveedor(String docId) async {
    print('Eliminando proveedor: $docId');
    await FirebaseFirestore.instance.collection('proveedores').doc(docId).delete();
  }

  // Función para mostrar diálogos reutilizable
  Future<void> _showDialog({required String title, required Widget content, required List<Widget> actions}) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: content,
          actions: actions,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('Construyendo interfaz de usuario');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre',
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    print('Limpiando búsqueda');
                    _searchController.clear();
                    setState(() {}); 
                    // Añadido para reiniciar la vista cuando se limpia la búsqueda
                    
                  },
                ),
              ),
              onChanged: (value) {
                print('Búsqueda cambiada: $value');
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _searchController.text.isNotEmpty
                  ? _searchProveedores(_searchController.text)
                  : _proveedoresStream,
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.docs.isEmpty) {
                    print('No se encontraron resultados');
                    return const Center(child: Text('No se encontraron resultados'));
                  }
                  print('Mostrando resultados');
                  return ListView.builder(
                    itemCount: snapshot.data?.docs.length ?? 0,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data?.docs[index];
                      var proveedor = doc?.data() as Map<String, dynamic>;

                      return ListTile(
                        title: Text('Nombre: ${proveedor['nombre'] ?? 'Desconocido'}'),
                        subtitle: Text('Correo: ${proveedor['correo']}\nDirección: ${proveedor['direccion']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _editarProveedor(
                                  docId: doc?.id,
                                  nombreInit: proveedor['nombre'],
                                  correoInit: proveedor['correo'],
                                  direccionInit: proveedor['direccion'],
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _eliminarProveedor(doc!.id);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          _verProveedor(proveedor);
                        },
                      );
                    },
                  );
                }
                if (snapshot.hasError) {
                  print('Error al cargar los proveedores: ${snapshot.error}');
                  return const Center(child: Text('Error al cargar los proveedores'));
                }
                print('Cargando proveedores');
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _editarProveedor();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
