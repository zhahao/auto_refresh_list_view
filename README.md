# refresh_list_view

功能完善的列表刷新组件,使用MVP设计模式.


## 开始

### 安装

在pubspec.yaml中加入

```
dependencies:
  auto_refresh_list_view: <latest version>
```



### 介绍

采用MVP设计模式,将RefreshListView最大限度进行解耦,由3个Presenter组成,将数据处理、item的展示、状态视图展示分别由不同Presenter提供.

```dart
new QRefreshListView(
      itemPresenter: _itemPresenter,
      dataPresenter: _dataPresenter,
      stateViewPresenter: _stateViewPresenter,
    )
```



#### dataPresenter

负责提供数据和处理数据.比如拉取网络数据,然后将数据加入list或者其他操作.

#### stateViewPresenter

负责提供加载中、加载失败、空页面、加载更多等view.支持自定义.

#### itemPresenter

负责创建ListView的item、header、footer、sectionHeader、sectionFooter等.一般情况下会持有dataPresenter,因为视图的展示基本上都需要由数据来驱动.


<img src="https://upload-images.jianshu.io/upload_images/3537150-8d7b9f810364f4d9.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="420" width="240">
<img src="https://upload-images.jianshu.io/upload_images/3537150-fc15703bd57ca975.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="420" width="240">
<img src="https://upload-images.jianshu.io/upload_images/3537150-341d4a32473bb4c7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="420" width="240">
<img src="https://upload-images.jianshu.io/upload_images/3537150-d9f1064b7413868f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="420" width="240">
<img src="https://upload-images.jianshu.io/upload_images/3537150-c5d7bc017671d351.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="420" width="240">
<img src="https://upload-images.jianshu.io/upload_images/3537150-660c4767b79919ec.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="420" width="240">



### 使用

####  _MyHomePageState

```dart
class _MyHomePageState extends State<MyHomePage> {
  RefreshListViewHomeItemPresenter _itemPresenter;
  RefreshListViewHomeDataPresenter _dataPresenter =
      RefreshListViewHomeDataPresenter();
  RefreshListHomeStateViewPresenter _stateViewPresenter =
      RefreshListHomeStateViewPresenter();
  QRefreshListViewController _listViewController = QRefreshListViewController();

  @override
  void initState() {
    super.initState();
    _itemPresenter = RefreshListViewHomeItemPresenter(_dataPresenter);
  }


  Widget _buildListView() {
    return QRefreshListView(
      itemPresenter: _itemPresenter,
      dataPresenter: _dataPresenter,
      stateViewPresenter: _stateViewPresenter,
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
```



#### RefreshListViewDataPresenter

```dart
class RefreshListViewHomeDataPresenter extends RefreshListViewDataPresenter {
  @override
  int pageSize = 10;

  @override
  Future<RefreshListItemDataEntity> fetchDataEntity() {
    /// mock data
    return Future.delayed(Duration(seconds: 2)).then((_) {
      List titles = [];
      for (int i = 0; i < 0; i++) {
        titles.add(WordPair.random().asPascalCase);
      }
      return titles;
    }).then((_) {
      return RefreshListItemDataEntity()
        ..success = Random().nextBool()
        ..entityList = _;
    });
  }
}
```



#### RefreshListViewItemIPresenter

```dart
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
```



#### RefreshListStateViewPresenter



```dart
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
```

