import 'package:flutter/material.dart';
import 'package:auto_refresh_list_view/auto_refresh_list_view.dart';
import 'dart:async';
import 'dart:math';
import 'package:english_words/english_words.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'example_auto_refresh_list_view',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'example_auto_refresh_list_view'),
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
  AutoRefreshListViewController _listViewController = AutoRefreshListViewController();

  @override
  void initState() {
    super.initState();
    _itemPresenter = RefreshListViewHomeItemPresenter(_dataPresenter);
  }

  Widget _buildListView() {
    return AutoRefreshListView(
      itemPresenter: _itemPresenter,
      dataPresenter: _dataPresenter,
      stateViewPresenter: _stateViewPresenter,
      controller: _listViewController,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                _listViewController.beginRefresh();
              })
        ],
      ),
      body: _buildListView(),
    );
  }
}

class RefreshListViewHomeDataPresenter extends RefreshListViewDataPresenter {
  @override
  int pageSize = 10;

  @override
  Future<RefreshListItemDataEntity> fetchDataEntity() {
    /// mocked data
    return Future.delayed(Duration(seconds: 2)).then((_) {
      List titles = [];
      var count = Random().nextBool() ? pageSize : (pageSize - 1);
      for (int i = 0; i < count; i++) {
        titles.add(WordPair.random().asPascalCase);
      }
      return titles;
    }).then((_) {
      /// 随机模拟数据
      return RefreshListItemDataEntity()
        ..success = Random().nextBool()
        ..entityList = _;
    });
  }
}

class RefreshListViewHomeItemPresenter extends RefreshListViewItemIPresenter {
  final RefreshListViewHomeDataPresenter dataPresenter;

  RefreshListViewHomeItemPresenter(this.dataPresenter);

  @override
  Widget items(BuildContext context, int section, int index) {
    return Container(
      alignment: Alignment.center,
      child: Text(dataPresenter.entityList[index]),
      height: 50,
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
}
