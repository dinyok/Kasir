import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kasir/login_screen.dart';
import 'package:kasir/welcome_page.dart'; // Import WelcomePage
import 'package:kasir/profile_screen.dart';
import 'package:kasir/product_management_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kasir/cashier_screen.dart';
import 'cart_notifier.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartNotifier(),
      child: MyApp(),
    ),
  );
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return null;
    }
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Management and Cashier App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.hasData) {
          // User is signed in, show the main screen
          return MyHomePage(title: 'Stock Management and Cashier App');
        } else {
          // User is not signed in, show the login screen
          return WelcomePage();
        }
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static List<Widget> _screens = [
    CashierScreen(),
    TransactionHistoryScreen(),
    ReportScreen(),
    ProductManagementScreen(),
    StoreManagementScreen(),
  ];

  static List<String> _titles = [
    'Cashier',
    'Transaction History',
    'Report',
    'Product Management',
    'Store Management',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
          title: Text(_titles[_selectedIndex]),
      ),
      body: _screens[_selectedIndex],
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                    builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return DrawerHeader(
                          decoration: BoxDecoration(color: Theme.of(context).primaryColor),
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return DrawerHeader(
                          decoration: BoxDecoration(color: Theme.of(context).primaryColor),
                          child: CircularProgressIndicator(),
                        );
                      }

                      var userData = snapshot.data!;
                      String businessName = userData['businessName'] ?? 'N/A';
                      String email = userData['email'] ?? 'N/A';
                      String location = userData['location'] ?? 'N/A';

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProfileScreen()),
                          );
                        },
                        child: UserAccountsDrawerHeader(
                          decoration: BoxDecoration(color: Theme.of(context).primaryColor),
                          accountName: Text('$businessName'' (''$location'')'),
                          accountEmail: Text(email),
                          currentAccountPicture: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 48.0,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.point_of_sale),
                    title: Text('Cashier'),
                    onTap: () => _onItemTapped(0),
                  ),
                  ListTile(
                    leading: Icon(Icons.history),
                    title: Text('Transaction History'),
                    onTap: () => _onItemTapped(1),
                  ),
                  ListTile(
                    leading: Icon(Icons.description),
                    title: Text('Report'),
                    onTap: () => _onItemTapped(2),
                  ),
                  ListTile(
                    leading: Icon(Icons.inventory_2),
                    title: Text('Product Management'),
                    onTap: () => _onItemTapped(3),
                  ),
                  ListTile(
                    leading: Icon(Icons.store),
                    title: Text('Store Management'),
                    onTap: () => _onItemTapped(4),
                  ),
                ],
              ),
            ),
            Container(
              alignment: Alignment.bottomCenter,
              padding: EdgeInsets.all(16.0),
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  // Navigate to the login page after logout
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WelcomePage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Close the stream
    FirebaseAuth.instance.authStateChanges().listen((event) {}).cancel();
    super.dispose();
  }
}

class TransactionHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Transaction History Screen',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class ReportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Report Screen',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}



class StoreManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Store Management Screen',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
