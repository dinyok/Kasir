import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'cart_notifier.dart';
import 'cart_item.dart';
import 'package:collection/collection.dart';


class CashierScreen extends StatefulWidget {
  @override
  _CashierScreenState createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  void _addToCart(DocumentSnapshot product, CartNotifier cartNotifier) {
    int currentStock = product['stock'];
    CartItem? existingCartItem = cartNotifier.cart.firstWhereOrNull((item) => item.product.id == product.id);


    if (existingCartItem != null) {
      if (existingCartItem.quantity < currentStock) {
        // Product is already in the cart, increase the quantity by 1
        cartNotifier.increaseQuantity(existingCartItem!);
      } else {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('${product['productName']} is out of stock'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      // Product is not in the cart, add it with a quantity of 1
      cartNotifier.addToCart(CartItem(product: product, quantity: 1));

      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('${product['productName']} added to cart'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    cartNotifier.notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    final cartNotifier = Provider.of<CartNotifier>(context, listen: false);

    return Scaffold(
      key: _scaffoldMessengerKey,
      body: Column(
        children: [
          Expanded(
            child: ChangeNotifierProvider(
              create: (_) => CartNotifier(),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('products').snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final products = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];

                      return InkWell(
                        onTap: () {
                          _addToCart(product, cartNotifier);
                        },
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: product['photoUrl'] != null
                                      ? Image.network(
                                    product['photoUrl']!,
                                    width: 75,
                                    height: 75,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(8.0),
                                        child: Image.asset(
                                          'assets/placeholder.jpg',
                                          width: 75,
                                          height: 75,
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    },
                                  )
                                      : ClipRRect(
                                        borderRadius: BorderRadius.circular(8.0),
                                        child: Image.asset(
                                          'assets/placeholder.jpg',
                                          width: 75,
                                          height: 75,
                                          fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['productName'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text('Stock: ${product['stock']}'),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Rp ${product['sellingPrice'].toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          CartSummary(),
        ],
      ),
    );
  }
}

class CartSummary extends StatelessWidget {
  const CartSummary({Key? key}) : super(key: key);

  void _showOrderDetails(BuildContext context, CartNotifier cartNotifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Add this line
      //backgroundColor: Colors.transparent, // Add this line
      builder: (BuildContext context) {
        return OrderDetails(cartNotifier: cartNotifier);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartNotifier = Provider.of<CartNotifier>(context, listen: false);

    return ValueListenableBuilder<int>(
      valueListenable: cartNotifier.cartLengthNotifier,
      builder: (context, cartLength, child) {
        return ValueListenableBuilder<double>(
          valueListenable: cartNotifier.subtotal,
          builder: (context, subtotalValue, child) {
            if (cartLength == 0) {
              return SizedBox.shrink();
            }
            return GestureDetector(
              onTap: () {
                _showOrderDetails(context, cartNotifier);
              },
              child: Material(
                color: Colors.transparent, // Set the color of the Material to transparent
                elevation: 0, // Set the elevation to 0 to remove shadow effect
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  margin: EdgeInsets.all(8),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$cartLength items in cart',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Rp ${subtotalValue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class OrderDetails extends StatelessWidget {
  final CartNotifier cartNotifier;

  OrderDetails({Key? key, required this.cartNotifier}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Container(
        height: MediaQuery
            .of(context)
            .size
            .height * 0.8,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 250),
                        child: SingleChildScrollView(
                          child: Column(
                            children: cartNotifier.cart.map((product) {
                              return ValueListenableBuilder<int>(
                                valueListenable: product.quantityNotifier,
                                builder: (context, quantityValue, child) {
                                  return Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment
                                            .center,
                                        children: [
                                          Text('${product
                                              .product['productName']}'),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.remove),
                                                onPressed: () {
                                                  cartNotifier.decreaseQuantity(
                                                      product);
                                                },
                                              ),
                                              Text('${quantityValue}'),
                                              IconButton(
                                                icon: Icon(Icons.add),
                                                onPressed: () {
                                                  cartNotifier.increaseQuantity(
                                                      product);
                                                },
                                              ),
                                            ],
                                          ),
                                          Text('Rp ${(product.product['sellingPrice'] * quantityValue).toStringAsFixed(2)}'),
                                        ],
                                      ),
                                      Divider(),
                                    ],
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      ValueListenableBuilder<double>(
                        valueListenable: cartNotifier.subtotal,
                        builder: (context, subtotalValue, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal:'),
                              Text('Rp ${subtotalValue.toStringAsFixed(2)}'),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            cartNotifier.clearCart();
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Cancel Order',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: TextButton.styleFrom(backgroundColor: Colors
                              .red),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: cartNotifier.total,
              builder: (context, totalValue, child) {
                return Container(
                  color: Colors.grey[200],
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:'),
                      Text('Rp ${totalValue.toStringAsFixed(2)}'),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle the payment process here
                  },
                  child: Text('Pay'),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
