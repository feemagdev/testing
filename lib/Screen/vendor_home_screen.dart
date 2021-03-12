import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:provider/provider.dart';
import 'package:test00001020/providers/store_provider.dart';
import 'package:test00001020/services/product_services.dart';
import 'package:url_launcher/url_launcher.dart';

const categoryHeight = 50.0;
const productHeight = 120.0;

class VendorHomeScreen extends StatefulWidget {
  final String vendorID;
  static const String id = 'vendor-screen';

  const VendorHomeScreen({Key key, @required this.vendorID}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<VendorHomeScreen>
    with SingleTickerProviderStateMixin {
  List<String> _catList = [];
  List<Map<int, QueryDocumentSnapshot>> _prodList = [];
  bool isLoading = true;
  List<CategoryWiseProducts> pd = [];
  List<TabCategory> tabs = [];

  double top = 0.0;
  double position = 150;
  double left = 0;
  double right = 0;
  ScrollController _scrollController = ScrollController();
  TabController _tabController;
  bool selected = true;
  bool _listen = true;

  @override
  void initState() {
    ProductServices _services = ProductServices();

    _services.category
        .get()
        .then((value) => {
              value.docs.forEach((QueryDocumentSnapshot element) {
                print(element.data());
                if (element.data()['subCat'] != null) {
                  print(element.data()['subCat'].length);
                  for (int i = 0; i < element.data()['subCat'].length; i++) {
                    _catList.add(element.data()['subCat'][i]['name']);
                  }
                }
              })
            })
        .whenComplete(() async {
      print(_catList);
      await Future.forEach(_catList, (String catName) async {
        await FirebaseFirestore.instance
            .collection('products')
            .where('seller.sellerUid', isEqualTo: widget.vendorID)
            .where('category.subCategory', isEqualTo: catName)
            .where('published', isEqualTo: true)
            .get()
            .then((value) {
          _prodList.add(value.docs.asMap());
        });
      }).whenComplete(() {
        for (int i = 0; i < _catList.length; i++) {
          if (_prodList[i].isNotEmpty) {
            pd.add(CategoryWiseProducts(category: _catList[i], products: null));
            print(_prodList[i].length);
            _prodList[i].forEach((key, value) {
              pd.add(
                  CategoryWiseProducts(category: null, products: value.data()));
            });
          }
        }

        double offsetFrom = 0.0;
        double offsetTo = 0.0;

        for (int i = 0; i < _catList.length; i++) {
          if (_prodList[i].isNotEmpty) {
            if (i > 0) {
              offsetFrom += _prodList[i - 1].length * productHeight + 120;
            }
            if (i == _catList.length - 1) {
              offsetFrom += productHeight * _prodList[i].length;
            }

            if (i < _catList.length - 1) {
              offsetTo = offsetFrom + _prodList[i].length * productHeight + 120;
            } else {
              offsetTo = double.infinity;
            }
            print(" leangth is" + _prodList[i].length.toString());

            tabs.add(TabCategory(
                offsetFrom: categoryHeight * i + offsetFrom,
                offsetTo: offsetTo,
                name: _catList[i],
                selected: (i == 0)));
          }
        }
        _tabController = TabController(length: tabs.length, vsync: this);
        setState(() {
          isLoading = false;
        });
      });
    });

    _scrollController.addListener(_onScrollListerner);
    super.initState();
  }

  void _onScrollListerner() {
    if (_listen) {
      for (int i = 0; i < tabs.length; i++) {
        final tab = tabs[i];
        if (_scrollController.offset >= tab.offsetFrom &&
            _scrollController.offset <= tab.offsetTo &&
            !tab.selected) {
          onCategorySelected(i, animationRequired: false);
          _tabController.animateTo(i);
        }
      }
    }
  }

  void onCategorySelected(int index, {bool animationRequired = true}) async {
    final selected = tabs[index];
    for (int i = 0; i < tabs.length; i++) {
      tabs[i] = tabs[i].copyWith(selected.name == tabs[i].name);
    }
    setState(() {});
    if (animationRequired) {
      _listen = false;
      await _scrollController.animateTo(selected.offsetFrom,
          duration: Duration(milliseconds: 200), curve: Curves.linear);
      _listen = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    double topheight = MediaQuery.of(context).padding.top;

    var _store = Provider.of<StoreProvider>(context);

    mapLauncher() async {
      GeoPoint location = _store.storedetails['loaction'];
      final availableMaps = await MapLauncher.installedMaps;

      await availableMaps.first.showMarker(
        coords: Coords(location.latitude, location.longitude),
        title: '${_store.storedetails['shopName']} is here',
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.grey[100],
                      expandedHeight: MediaQuery.of(context).size.height * 0.35,
                      centerTitle: true,
                      automaticallyImplyLeading: false,
                      toolbarHeight: 80,
                      floating: false,
                      pinned: true,
                      title: Opacity(
                        opacity: top < 82 + topheight ? 1.0 : 0.0,
                        child: Text(
                          _store.storedetails['shopName'],
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      leading: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black,
                        ),
                      ),
                      actions: [
                        IconButton(
                            icon: Icon(
                              Icons.favorite,
                              color: Colors.black,
                            ),
                            onPressed: () {}),
                        IconButton(
                            icon: Icon(
                              Icons.search,
                              color: Colors.black,
                            ),
                            onPressed: () {})
                      ],
                      flexibleSpace: LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                          // print('constraints=' + constraints.toString());
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              top = constraints.biggest.height;
                              position = constraints.biggest.height;
                              if (top < 82 + topheight) {
                                position = 80 + topheight;
                              }
                            });
                          });
                          return FlexibleSpaceBar(
                            background: Container(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    top: topheight + 80, right: 10, left: 10),
                                child: ListView(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  children: [
                                    Text(
                                      _store.storedetails['shopName'],
                                      textScaleFactor: 1.5,
                                    ),
                                    Text(
                                      _store.storedetails['dialog'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      _store.storedetails['address'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      _store.storedetails['email'],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Distance : ${_store.distanc}km',
                                      style: TextStyle(),
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                        ),
                                        Icon(
                                          Icons.star,
                                        ),
                                        Icon(
                                          Icons.star,
                                        ),
                                        Icon(
                                          Icons.star_half,
                                        ),
                                        Icon(
                                          Icons.star_outline,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          '(3.5)',
                                        )
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        CircleAvatar(
                                            backgroundColor: Colors.white,
                                            child: IconButton(
                                              icon: Icon(Icons.phone,
                                                  color: Colors.amber),
                                              onPressed: () {
                                                launch(
                                                    'tel: ${_store.storedetails['moblie']}');
                                              },
                                            )),
                                        SizedBox(width: 3),
                                        CircleAvatar(
                                            backgroundColor: Colors.white,
                                            child: IconButton(
                                              icon: Icon(Icons.map,
                                                  color: Colors.amber),
                                              onPressed: () {
                                                mapLauncher();
                                              },
                                            )),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.only(
                        top: 100,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = pd[index];
                            if (item.isCategory) {
                              return Container(
                                width: MediaQuery.of(context).size.width,
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(
                                      height: 10,
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    _RappiTabCategoryItem(item.category),
                                  ],
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: _RappiTabProductItem(item.products),
                              );
                            }
                          },
                          childCount: pd.length,
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: position,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        )),
                    child: Padding(
                        padding: EdgeInsets.only(
                            top: 20.0, right: 10.0, bottom: 10.0, left: 10.0),
                        child: TabBar(
                          onTap: onCategorySelected,
                          controller: _tabController,
                          isScrollable: true,
                          indicator: BubbleTabIndicator(
                            indicatorHeight: 40.0,
                            indicatorColor: Colors.grey[500],
                            tabBarIndicatorSize: TabBarIndicatorSize.tab,
                            // Other flags
                            // indicatorRadius: 1,
                            // insets: EdgeInsets.all(1),
                            // padding: EdgeInsets.all(10)
                          ),
                          indicatorPadding: EdgeInsets.only(left: 5, right: 5),
                          tabs: tabs.map((e) => _RapidTabWidget(e)).toList(),
                        )),
                  ),
                ),
              ],
            ),
    );
  }
}

class _RapidTabWidget extends StatelessWidget {
  final TabCategory category;
  _RapidTabWidget(this.category);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: category.selected ? 1 : 0.5,
      child: Container(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            category.name,
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class _RappiTabCategoryItem extends StatelessWidget {
  final String category;

  const _RappiTabCategoryItem(this.category);
  @override
  Widget build(BuildContext context) {
    return Container(
      height: categoryHeight,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          category,
          textScaleFactor: 1.5,
        ),
      ),
    );
  }
}

class RappiTabCategory {
  final String name;

  RappiTabCategory({@required this.name});
}

class _RappiTabProductItem extends StatelessWidget {
  final Map<String, dynamic> product;

  const _RappiTabProductItem(this.product);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 1,
            offset: Offset(0, 1), // changes position of shadow
          ),
        ],
      ),
      height: productHeight,
      child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * .65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['productName'],
                      textScaleFactor: 1.1,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      product['description'],
                      textScaleFactor: 1.1,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      '\$' + product['price'].toString(),
                      textScaleFactor: 1.1,
                    ),
                  ],
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.2,
                height: MediaQuery.of(context).size.width * 0.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      image: NetworkImage(product['productImage']),
                      fit: BoxFit.fill),
                ),
              ),
            ],
          )),
    );
  }
}

class RappiTabProduct {
  final String name;
  final double price;

  RappiTabProduct({@required this.name, @required this.price});
}

class TabCategory {
  final String name;
  final bool selected;
  final double offsetFrom;
  final double offsetTo;

  TabCategory(
      {@required this.offsetFrom,
      @required this.offsetTo,
      @required this.name,
      @required this.selected});

  TabCategory copyWith(bool selected) => TabCategory(
      name: name,
      selected: selected,
      offsetFrom: offsetFrom,
      offsetTo: offsetTo);
}

class Item {
  final RappiTabCategory category;
  final RappiTabProduct product;
  Item({@required this.category, @required this.product});

  bool get isCategory => category != null;
}

class CategoryWiseProducts {
  final String category;
  final Map<String, dynamic> products;

  CategoryWiseProducts({this.category, this.products});

  bool get isCategory => category != null;
}

/*headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            VendorAppBar(),
          ];
        },
        body: ListView(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          children: [
            VendorBanner(),
            VendorCategories(),
            SizedBox(height: 120.0),
            FeatureProducts(),
          ],
        ),*/
