# auto_refresh_list_view

功能完善的列表刷新组件,使用MVP设计模式.


## 开始

### 安装

在pubspec.yaml中加入

```
dependencies:
  auto_refresh_list_view: <latest version>
```



### 介绍

采用MVP设计模式,将AutoRefreshListView最大限度进行解耦.由3个Presenter组成,将数据处理、item的展示、状态视图展示分别由不同Presenter提供实现.

```dart
new AutoRefreshListView(
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

### 效果图

<img src="https://upload-images.jianshu.io/upload_images/3537150-ddc9f449b5052a76.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="420" width="240">
<img src="https://upload-images.jianshu.io/upload_images/3537150-db6f72a6699f3372.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="420" width="240">
<img src="https://upload-images.jianshu.io/upload_images/3537150-f15473dd624b000a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="420" width="240">
<img src="https://upload-images.jianshu.io/upload_images/3537150-d8fddcaa1a1cd4a8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="420" width="240">
<img src="https://upload-images.jianshu.io/upload_images/3537150-a5c4566cb203bca4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="420" width="240">
<img src="https://upload-images.jianshu.io/upload_images/3537150-632e6adc8d9e796e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="420" width="240">
<img src="https://upload-images.jianshu.io/upload_images/3537150-2f5bdb0f5c052128.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240" height="420" width="240">

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
    /// mocked data
    return Future.delayed(Duration(seconds: 2)).then((_) {
      List titles = [];
      var count = Random().nextBool() ? pageSize : (pageSize - 1);
      for (int i = 0; i < count; i++) {
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

