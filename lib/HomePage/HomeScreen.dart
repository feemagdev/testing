import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test00001020/Screen/top_picker_stroe.dart';
import 'package:test00001020/providers/auth_provider.dart';
import 'package:test00001020/widget/appBar.dart';
import 'package:test00001020/widget/image_slider.dart';

class HomeScreen extends StatefulWidget {
  static const String id = 'home-screen';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [MyAppBar()];
        },
        body: ListView(
          children: [
            ImageSlider(),

            Container(height: 200, child: TopPickerStore()),
            //  Padding(
            ////    padding: const EdgeInsets.only(top: 8.0),
            ////    child: NearByStores(),
            //),
          ],
        ),
      ),
    );
  }
}
