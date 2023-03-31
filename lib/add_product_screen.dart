import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _photoUrl;
  String? _productName;
  String? _productCategory;
  double? _sellingPrice;
  double? _capitalPrice;
  String? _sku;
  int? _stock;
  String? _location;
  String? _description;

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) {
      return null;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    final String fileName = '${user!.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

    final UploadTask uploadTask = storageRef.putFile(_imageFile!);

    final TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }

  // Add a function to submit the form data and save the product
  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        User? user = FirebaseAuth.instance.currentUser;
        _photoUrl = await _uploadImage();
        await FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('products').add({
          'photoUrl': _photoUrl,
          'productName': _productName,
          'productCategory': _productCategory,
          'sellingPrice': _sellingPrice,
          'capitalPrice': _capitalPrice,
          'sku': _sku,
          'stock': _stock,
          'location': _location,
          'description': _description,
        });
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> categories = ['Electronics', 'Fashion', 'Home Appliances'];
    List<String> businessLocations = ['New York', 'Los Angeles', 'Chicago'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Product'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    color: Colors.grey[200],
                    child: _imageFile != null
                        ? Image.file(
                      _imageFile!,
                      fit: BoxFit.cover,
                    )
                        : Center(child: Text('Upload Photo')),
                  ),
                ),

                TextFormField(
                  decoration: InputDecoration(labelText: 'Product Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a product name' : null,
                  onSaved: (value) => _productName = value,
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Product Category'),
                  items: categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _productCategory = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a product category';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Selling Price'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a selling price' : null,
                  onSaved: (value) => _sellingPrice = double.tryParse(value!),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Capital Price'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a capital price' : null,
                  onSaved: (value) => _capitalPrice = double.tryParse(value!),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'SKU'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a SKU' : null,
                  onSaved: (value) => _sku = value,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter the stock amount' : null,
                  onSaved: (value) => _stock = int.tryParse(value!),
                ),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Location'),
                  items: businessLocations.map((String location) {
                    return DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _location = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a location';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
                  onSaved: (value) => _description = value,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveProduct,
        child: Icon(Icons.save),
        tooltip: 'Save Product',
      ),
    );
  }
}
