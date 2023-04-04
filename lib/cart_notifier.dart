import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'cart_item.dart';

class CartNotifier extends ChangeNotifier {
  List<CartItem> _cart = [];
  final ValueNotifier<double> subtotal;
  final ValueNotifier<double> total;
  final ValueNotifier<double> priceDetail;
  final ValueNotifier<int> cartLengthNotifier;

  CartNotifier()
      : subtotal = ValueNotifier<double>(0),
        total = ValueNotifier<double>(0),
        priceDetail = ValueNotifier<double>(0),
        cartLengthNotifier = ValueNotifier<int>(0);

  List<CartItem> get cart => _cart;
  double get subtotalValue => subtotal.value;

  void addToCart(CartItem cartItem) {
    if (cartItem.product['stock'] <= 0) {
      return;
    }

    _cart.add(cartItem);
    subtotal.value += cartItem.product['sellingPrice'];
    total.value = subtotal.value;
    cartLengthNotifier.value += cartItem.quantity;
    notifyListeners();
  }

  void increaseQuantity(CartItem cartItem) {
    int index = _cart.indexWhere((item) => item.product.id == cartItem.product.id);
    if (index >= 0) {
      if (_cart[index].product['stock'] > _cart[index].quantity) {
        _cart[index].quantity++;
        subtotal.value += _cart[index].product['sellingPrice'];
        total.value = subtotal.value;
        cartLengthNotifier.value++;
      }
    }
  }

  void decreaseQuantity(CartItem cartItem) {
    int index = _cart.indexWhere((item) => item.product.id == cartItem.product.id);

    if (index >= 0) {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
        subtotal.value -= _cart[index].product['sellingPrice'];
        total.value = subtotal.value;
        cartLengthNotifier.value--;
      }
    }
  }

  void clearCart() {
    _cart.clear();
    total.value = 0;
    subtotal.value = 0;
    cartLengthNotifier.value = 0;
    notifyListeners();
  }
}
