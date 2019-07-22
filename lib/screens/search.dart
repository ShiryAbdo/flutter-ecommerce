import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_pagewise/flutter_pagewise.dart';
import 'package:http/http.dart' as http;
import 'package:ofypets_mobile_app/models/option_type.dart';
import 'package:ofypets_mobile_app/models/option_value.dart';
import 'package:ofypets_mobile_app/models/product.dart';
import 'package:ofypets_mobile_app/models/searchProduct.dart';
import 'package:ofypets_mobile_app/screens/product_detail.dart';
import 'package:ofypets_mobile_app/utils/constants.dart';
import 'package:ofypets_mobile_app/utils/headers.dart';

class ProductSearch extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ProductSearchState();
  }
}

class _ProductSearchState extends State<ProductSearch> {
  String slug = '';
  TextEditingController _controller;
  List<SearchProduct> searchProducts = [];
  bool _isLoading = false;
  Product tappedProduct = Product();
  final int perPage = TWENTY;
  int currentPage = ONE;
  int subCatId = ZERO;
  bool isSearched = false;
  static const int PAGE_SIZE = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Colors.green,
                ),
                // margin: EdgeInsets.all(10),
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 50,
                decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5)),
                margin: EdgeInsets.all(10),
              ),
              Container(
                padding: EdgeInsets.only(left: 15),
                child: TextField(
                  controller: _controller,
                  onChanged: (value) {
                    setState(() {
                      slug = value;
                    });
                  },
                  autofocus: true,
                  decoration: InputDecoration(
                      labelText: 'Find the best for your pet...',
                      border: InputBorder.none,
                      labelStyle:
                          TextStyle(fontWeight: FontWeight.w300, fontSize: 18)),
                ),
              ),
              Container(
                height: 50,
                margin: EdgeInsets.all(10),
                width: MediaQuery.of(context).size.width,
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    FocusScope.of(context).requestFocus(new FocusNode());
                    print('SEARCH');
                    print(slug);
                    setState(() {
                      isSearched = true;
                    });
                    // searchProduct();
                  },
                ),
              )
            ],
          ),
          preferredSize: Size.fromHeight(20),
        ),
      ),
      body: isSearched
          ? Theme(
              data: ThemeData(primarySwatch: Colors.green),
              child: PagewiseListView(
                pageSize: PAGE_SIZE,
                itemBuilder: favoriteCard,
                pageFuture: (pageIndex) => searchProduct(),
              ))
          : Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.green,
              ),
            ),
    );
  }

  Widget favoriteCard(BuildContext context, SearchProduct product, int index) {
    return GestureDetector(
        onTap: () {
          getProductDetail(index);
        },
        child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            margin: EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                Row(children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    height: 150,
                    width: 150,
                    color: Colors.white,
                    child: product.image != null
                        ? FadeInImage(
                            image: NetworkImage(product.image),
                            placeholder: AssetImage(
                                'images/placeholders/no-product-image.png'),
                          )
                        : Image.asset(
                            'images/placeholders/no-product-image.png'),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          child: Text(
                            product.name,
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          child: Text(
                            product.currencySymbol + product.price,
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 15, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  )
                ])
              ],
            )));
  }

  getProductDetail(int index) async {
    Map<String, String> headers = await getHeaders();
    Map<String, dynamic> responseBody = Map();
    print('GETTING DETAILS');
    setState(() {
      _isLoading = true;
      searchProducts.clear();
    });
    http.Response response =
        await http.get(Settings.SERVER_URL + 'api/v1/products/7?data_set=large',
            // 'api/v1/products/${searchProducts[index].slug}?data_set=large',

            headers: headers);

    responseBody = json.decode(response.body);
    print('------------IMAGE URL RECEIVED----------');
    print(responseBody['data']['included']['master']['data']['included']
        ['images'][0]['data']['attributes']['product_url']);
    List<Product> variants = [];
    List<OptionValue> optionValues = [];
    List<OptionType> optionTypes = [];

    int review_product_id = responseBody['data']['attributes']["id"];
    variants = [];
    if (responseBody['data']['attributes']['has_variants']) {
      responseBody['data']['included']['variants'].forEach((variant) {
        optionValues = [];
        optionTypes = [];
        variant['data']['included']['option_values'].forEach((option) {
          setState(() {
            optionValues.add(OptionValue(
              id: option['data']['attributes']['id'],
              name: option['data']['attributes']['name'],
              optionTypeId: option['data']['attributes']['option_type_id'],
              optionTypeName: option['data']['attributes']['option_type_name'],
              optionTypePresentation: option['data']['attributes']
                  ['option_type_presentation'],
            ));
          });
        });
        setState(() {
          variants.add(Product(
              id: variant['data']['attributes']['id'],
              name: variant['data']['attributes']['name'],
              description: variant['data']['attributes']['description'],
              optionValues: optionValues,
              displayPrice: variant['data']['attributes']['display_price'],
              image: variant['data']['included']['images'][0]['data']
                  ['attributes']['product_url'],
              isOrderable: variant['data']['attributes']['is_orderable'],
              avgRating: double.parse(
                  responseBody['data']['attributes']['avg_rating']),
              reviewsCount: responseBody['data']['attributes']['reviews_count']
                  .toString(),
              reviewProductId: review_product_id));
        });
      });
      responseBody['data']['included']['option_types'].forEach((optionType) {
        setState(() {
          optionTypes.add(OptionType(
              id: optionType['data']['attributes']['id'],
              name: optionType['data']['attributes']['name'],
              position: optionType['data']['attributes']['position'],
              presentation: optionType['data']['attributes']['presentation']));
        });
      });
      setState(() {
        tappedProduct = Product(
            name: responseBody['data']['attributes']['name'],
            displayPrice: responseBody['data']['attributes']['display_price'],
            avgRating:
                double.parse(responseBody['data']['attributes']['avg_rating']),
            reviewsCount:
                responseBody['data']['attributes']['reviews_count'].toString(),
            image: responseBody['data']['included']['master']['data']
                ['included']['images'][0]['data']['attributes']['product_url'],
            variants: variants,
            reviewProductId: review_product_id,
            hasVariants: responseBody['data']['attributes']['has_variants'],
            optionTypes: optionTypes);
      });
    } else {
      setState(() {
        tappedProduct = Product(
          id: responseBody['data']['included']['id'],
          name: responseBody['data']['attributes']['name'],
          displayPrice: responseBody['data']['attributes']['display_price'],
          avgRating:
              double.parse(responseBody['data']['attributes']['avg_rating']),
          reviewsCount:
              responseBody['data']['attributes']['reviews_count'].toString(),
          image: responseBody['data']['included']['master']['data']['included']
              ['images'][0]['data']['attributes']['product_url'],
          hasVariants: responseBody['data']['attributes']['has_variants'],
          isOrderable: responseBody['data']['included']['master']['data']
              ['attributes']['is_orderable'],
          reviewProductId: review_product_id,
          description: responseBody['data']['attributes']['description'],
        );
      });
    }
    setState(() {
      _isLoading = false;
    });
    print('PRODUCT IS');
    print(tappedProduct);
    MaterialPageRoute route = MaterialPageRoute(
        builder: (context) => ProductDetailScreen(tappedProduct));
    Navigator.push(context, route);
  }

  Future<List<SearchProduct>> searchProduct() async {
    Map<String, String> headers = await getHeaders();
    Map<String, dynamic> responseBody = Map();
    print('SENDING REQUEST');
    searchProducts = [];
    http.Response response = await http.get(
        Settings.SERVER_URL +
            'api/v1/products?q[name_cont_all]=$slug&page=$currentPage&per_page=$perPage&data_set=small',
        headers: headers);
    currentPage++;
    responseBody = json.decode(response.body);
    print('------------SEARCH RESPONSE----------');
    print(responseBody);
    responseBody['data'].forEach((favoriteObj) {
      print(favoriteObj['attributes']['slug']);

      setState(() {
        searchProducts.add(SearchProduct(
            name: favoriteObj['attributes']['name'],
            image: favoriteObj['attributes']['product_url'],
            price: favoriteObj['attributes']['price'],
            currencySymbol: favoriteObj['attributes']['currency_symbol'],
            slug: favoriteObj['attributes']['slug']));
      });
    });
    return searchProducts;
  }
}