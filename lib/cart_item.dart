import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CartItem {
  final DocumentSnapshot product;
  final ValueNotifier<int> quantityNotifier; // Add a ValueNotifier for quantity

  CartItem({
    required this.product,
    required int quantity,
  }) : quantityNotifier = ValueNotifier<int>(quantity);

  int get quantity => quantityNotifier.value;

  set quantity(int newQuantity) {
    quantityNotifier.value = newQuantity;
  }
}
