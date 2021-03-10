import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test00001020/providers/store_provider.dart';
import 'package:test00001020/widget/products/product_list.dart';

class ProductListScreen extends StatelessWidget {
  static const String id = 'product-list-screen';
  @override
  Widget build(BuildContext context) {
    var _storeProvider = Provider.of<StoreProvider>(context);

    return Scaffold(
        body: NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          SliverAppBar(
            title: Text(
              _storeProvider.selectedProductCategory,
              style: TextStyle(color: Colors.white),
            ),
            iconTheme: IconThemeData(
              color: Colors.white,
            ),
          ),
        ];
      },
      body: ProductListWidget(),
    ));
  }
}
