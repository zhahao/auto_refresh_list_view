import 'package:flutter/material.dart';
import 'package:auto_refresh_list_view/auto_refresh_list_view.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'example_auto_refresh_list_view',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: '\n\nexample_auto_refresh_list_view'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  RefreshListViewHomeItemPresenter _itemPresenter;
  RefreshListViewHomeDataPresenter _dataPresenter =
      RefreshListViewHomeDataPresenter();
  RefreshListHomeStateViewPresenter _stateViewPresenter =
      RefreshListHomeStateViewPresenter();
  AutoRefreshListViewController _listViewController =
      AutoRefreshListViewController();
  double _sliderTop = 0;
  final _imageHeight = 200.0;
  final _sliderHeight = 50.0;
  bool _isTop = false;

  @override
  void initState() {
    super.initState();

    // _sliderTop = _imageHeight - _sliderHeight;
    // final maxSliderTop = _imageHeight - _sliderHeight;
    // _itemPresenter = RefreshListViewHomeItemPresenter(_dataPresenter);
    // Future.delayed(Duration(seconds: 1), () {
    //   _listViewController.scrollController.addListener(() {
    //     final offset = _listViewController.scrollController.offset;
    //     if (offset > _imageHeight - _sliderHeight) {
    //       _sliderTop = 0;
    //     } else {
    //       _sliderTop = _imageHeight - _sliderHeight - offset;
    //     }
    //     _sliderTop = min(_sliderTop, maxSliderTop);
    //     _isTop = _sliderTop == 0;
    //     setState(() {});
    //   });
    // });
  }

  Widget _buildListView() {
    /// 如果列表比较简单,可以把所有的presenter设置为this,然后实现对应方法即可
    return AutoRefreshListView(
      itemPresenter: _itemPresenter,
      dataPresenter: _dataPresenter,
      stateViewPresenter: _stateViewPresenter,
      controller: _listViewController,
    );
  }

  _buildAppBar() {
    return AppBar(
      title: Text('listView'),
      actions: <Widget>[
        GestureDetector(
          child: Text('data'),
          onTap: (){
            _listViewController.beginRefresh();
          },
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          _buildAppBar(),
          Flexible(child: _buildListView()),
        ],
      ),
    );
  }
}

class RefreshListViewHomeDataPresenter extends RefreshListViewDataPresenter<String> {
  @override
  int pageSize = 20;

  @override
  Future<RefreshListItemDataEntity> fetchDataEntity() {
    /// mocked data
    return Future.delayed(Duration(seconds: 2)).then((_) {
      List titles = <String>[];
      var random = Random().nextInt(2);

      /// 模拟数据足够、数据不足、无数据,概率各1/3
      // var count = random == 1 ? pageSize : (random == 2 ? pageSize - 1 : 0);
      var count = 110;

      for (int i = 0; i < count; i++) {
        titles.add(i.toString());
      }
      print('${titles[122].toString()}');
      return titles;
    }).then((_) {
      /// 随机模拟数据
      return RefreshListItemDataEntity()
        ..success = true
        ..entityList = _;
    });
  }
}

class RefreshListViewHomeItemPresenter extends RefreshListViewItemIPresenter {
  final RefreshListViewHomeDataPresenter dataPresenter;

  RefreshListViewHomeItemPresenter(this.dataPresenter);

  @override
  Widget items(BuildContext context, int section, int index) {
    return RefreshItem(
      text: dataPresenter.entityList[index],
    );
  }

  @override
  int rowCount(int section) => dataPresenter.entityList?.length ?? 0;

  @override
  void itemOnTap(BuildContext context, int section, int index) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(dataPresenter.entityList[index]),
            ));
  }

  @override
  Widget headerWidget(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.transparent,
    );
  }
}

class RefreshListHomeStateViewPresenter extends RefreshListStateViewPresenter {
  @override
  Color themeColor = Colors.cyan;

  @override
  String emptyOnLoadText = '没有数据了~';

  @override
  Widget emptyImageWidget = Image.asset(
    'assets/load_empty.png',
    width: 215,
    height: 120,
  );

  @override
  Widget loadErrorImageWidget = Image.asset(
    'assets/load_error.png',
    width: 160,
    height: 160,
  );

  @override
  Widget customListView() {
    // TODO: implement customListView
    return Container(
      child: Text("2222"),
    );
  }
}

class RefreshItem extends StatefulWidget {
  final String text;

  RefreshItem({this.text});

  @override
  _RefreshItemState createState() => _RefreshItemState();
}

class _RefreshItemState extends State<RefreshItem> {
  @override
  Widget build(BuildContext context) {
    print("build");
    return Container(
      alignment: Alignment.center,
      child: Text(widget.text),
      height: 50,
      color: Colors.white,
    );
  }
}
