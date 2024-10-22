import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shop_app/business%20logic/models/product_model.dart';

class ProductsPage extends StatelessWidget {
  final List<Product> products;
  final String categoryName;

  ProductsPage({Key? key, required this.products, required this.categoryName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(products[index].name),
            subtitle: Text(products[index].productDescription),
            leading: products[index].images.isNotEmpty
                ? Image.network(products[index].images[0], width: 50, height: 50, fit: BoxFit.cover)
                : Icon(Icons.image_not_supported),
            onTap: () {
              // Navigate to product detail page
            },
          );
        },
      ),
    );
  }
}