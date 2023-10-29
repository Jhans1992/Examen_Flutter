import 'package:crud_firebase/home.dart';
import 'package:crud_firebase/login/login_screen.dart';
import 'package:crud_firebase/login/register_user_screen.dart';
import 'package:crud_firebase/screen/error_screen.dart';
import 'package:flutter/material.dart';
import 'package:crud_firebase/screen/screen.dart';

class AppRoutes {
  static const initialRoute = 'login';
  static Map<String, Widget Function(BuildContext)> routes = {


  
  'login': (context) => const LoginScreen(),
  'add_user': (BuildContext context) => const RegisterUserScreen(),
  'home': (BuildContext context) => const HomeScreen(),
  'list_categorias': (context) => ListCategoriasScreen(),
  'list_productos': (context) => const ProductosPage(),
  'list_proveedores': (context) => const ProveedoresScreen(),
  
    
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => ErrorScreen(),
    );
  }
}
