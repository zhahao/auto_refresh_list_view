import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:list_view_item_builder/list_view_item_builder.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'data_presenter.dart';
import 'item_presenter.dart';
import 'state_view_presenter.dart';

class AutoRefreshListViewController with ChangeNotifier {
  /// 开始重新加载数据并刷新列表
  void beginRefresh() {
    if (_beginRefreshCallback != null) {
      _beginRefreshCallback();
    }
  }

  /// 不重新获取数据,只刷新当前数据的列表
  void reloadData() {
    if (_reloadDataCallback != null) {
      _reloadDataCallback();
    }
  }

  /// header刷新完成
  VoidCallback headerRefreshCompleted;

  /// listView的控制器
  ScrollController get scrollController => _scrollController;

  /// listViewItemBuilder,可以使用它的jumpTo和animateTo功能
  ListViewItemBuilder get listViewItemBuilder => _listViewItemBuilder;

  VoidCallback _beginRefreshCallback;
  VoidCallback _reloadDataCallback;
  ScrollController _scrollController;
  ListViewItemBuilder _listViewItemBuilder;
}

class AutoRefreshListView extends StatefulWidget {
  /// item的Presenter,默认null
  /// 负责ListView的item构建.
  final RefreshListViewItemIPresenter itemPresenter;

  /// 数据Presenter,主要负责获取数据,以及数据的逻辑处理,默认null.
  /// 负责提供数据和处理数据.
  /// 简单列表用[RefreshListViewDataPresenter]即可
  final RefreshListViewDataIPresenter dataPresenter;

  /// 各种状态的View的Presenter,默认由[RefreshListStateViewPresenter]实现
  /// 负责提供加载中、加载失败、空页面、加载更多等view.
  final RefreshListStateViewIPresenter stateViewPresenter;

  /// 是否提供下拉加载操作,默认true.
  final bool canPullDown;

  /// 是否提供上拉加载操作,默认true.
  final bool canPullUp;

  /// 初始化完成是否立即刷新,默认true
  final bool immediateRefresh;

  /// listView的padding,默认zero
  final EdgeInsetsGeometry padding;

  /// 控制器,用来操作内部listView
  final AutoRefreshListViewController controller;

  /// 刷新头,默认[MaterialClassicHeader]
  final Widget refreshHeader;

  AutoRefreshListView({
    Key key,
    @required this.itemPresenter,
    @required this.dataPresenter,
    @required this.stateViewPresenter,
    this.controller,
    Widget refreshHeader,
    bool canPullDown,
    bool canPullUp,
    bool immediateRefresh,
    EdgeInsetsGeometry padding,
  })  : assert(
            itemPresenter != null &&
                dataPresenter != null &&
                stateViewPresenter != null,
            "presenter 必须存在"),
        refreshHeader = refreshHeader ?? MaterialClassicHeader(),
        canPullDown = canPullDown ?? true,
        canPullUp = canPullUp ?? true,
        immediateRefresh = immediateRefresh ?? true,
        padding = padding ?? EdgeInsets.zero,
        super(key: key);

  @override
  _AutoRefreshListView createState() => _AutoRefreshListView();
}

class _AutoRefreshListView extends State<AutoRefreshListView> {
  _AutoRefreshListViewState _state;
  ScrollController _listScrollController = ScrollController();
  ListViewItemBuilder _itemBuilder;
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    _initItemBuilder();
    _initLoadState();
    _initController();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == null) {
      return Container(
        height: 0,
      );
    }
    widget.stateViewPresenter.context = context;
    switch (_state) {
      case _AutoRefreshListViewState.loadingFirstPage:
        return widget.stateViewPresenter.loadingView();
      case _AutoRefreshListViewState.errorOnLoadFirstPage:
        return _buildLoadedErrorView();
      case _AutoRefreshListViewState.emptyOnLoadFirstPage:
        return widget.stateViewPresenter.emptyOnLoadView();
      default:
        return _buildListView();
    }
  }

  _initLoadState() {
    if (widget.immediateRefresh == true) {
      _state = _AutoRefreshListViewState.loadingFirstPage;
      _loadData(firstPageLoad: true, isHeader: true);
    }
  }

  _initController() {
    if (!mounted) return;
    if (widget.controller != null) {
      widget.controller._beginRefreshCallback = () {
        if (_state == _AutoRefreshListViewState.loadListViewData) {
          _refreshController.requestRefresh();
        } else {
          setState(() {});
          _state = _AutoRefreshListViewState.loadingFirstPage;
          _loadData(firstPageLoad: true, isHeader: true);
        }
      };
      widget.controller._reloadDataCallback = () => setState(() {});
      widget.controller._scrollController = _listScrollController;
      widget.controller._listViewItemBuilder = _itemBuilder;
    }
  }

  _initItemBuilder() {
    _itemBuilder = ListViewItemBuilder(
      scrollController: _listScrollController,
      sectionCountBuilder: widget.itemPresenter.sectionCount,
      rowCountBuilder: widget.itemPresenter.rowCount,
      itemsBuilder: widget.itemPresenter.items,
      sectionHeaderBuilder: widget.itemPresenter.sectionHeader,
      sectionFooterBuilder: widget.itemPresenter.sectionFooter,
      itemOnTap: widget.itemPresenter.itemOnTap,
      itemShouldTap: widget.itemPresenter.itemShouldTap,
      headerWidgetBuilder: widget.itemPresenter.headerWidget,
      footerWidgetBuilder: widget.itemPresenter.footerWidget,
    );
  }

  Future<void> _loadData({bool firstPageLoad, bool isHeader = true}) async {
    if (firstPageLoad) {
      widget.dataPresenter.resetPage();
    } else {
      widget.dataPresenter.nextPage();
    }

    RefreshListItemDataEntity data =
        await widget.dataPresenter.fetchDataEntity();

    if (!mounted) return;

    setState(() {});

    if (data.success == true) {
      if (firstPageLoad || isHeader) {
        widget.dataPresenter.clear();
      }

      if (widget.dataPresenter.isEmptyData(data)) {
        if (firstPageLoad) {
          _state = _AutoRefreshListViewState.emptyOnLoadFirstPage;
          _refreshController.loadNoData();
        } else {
          _refreshCompleted();
          _refreshController.loadNoData();
        }
      } else if (widget.dataPresenter.isNoMoreData(data)) {
        widget.dataPresenter.addAll(data);
        if (firstPageLoad) {
          _state = _AutoRefreshListViewState.loadListViewData;
        } else {
          if (isHeader) {
            _refreshCompleted();
          }
        }
        _refreshController.loadNoData();
      } else {
        widget.dataPresenter.addAll(data);

        if (firstPageLoad) {
          _state = _AutoRefreshListViewState.loadListViewData;
          _refreshCompleted();
        } else {
          if (isHeader) {
            _refreshCompleted();
          }
        }
        _refreshController.loadComplete();
      }
    } else {
      if (firstPageLoad || isHeader) {
        _state = _AutoRefreshListViewState.errorOnLoadFirstPage;
        _refreshController.loadNoData();
        _refreshCompleted();
      } else {
        widget.dataPresenter.previousPage();
        if (isHeader) {
          _refreshCompleted();
        } else {
          _refreshController.loadFailed();
        }
      }
    }
  }

  _refreshCompleted() {
    _refreshController.refreshCompleted();
    if (widget.controller?.headerRefreshCompleted != null) {
      widget.controller.headerRefreshCompleted();
    }
  }

  Widget _buildListView() {
    var listView = ListView.builder(
      itemBuilder: _itemBuilder.itemBuilder,
      itemCount: _itemBuilder.itemCount,
      controller: _listScrollController,
      shrinkWrap: true,
      padding: widget.padding,
      physics: const AlwaysScrollableScrollPhysics(),
    );
    return Column(
      children: <Widget>[
        Expanded(
            child: SmartRefresher(
          controller: _refreshController,
          enablePullUp: widget.canPullUp,
          enablePullDown: widget.canPullDown,
          child: listView,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          scrollController: _listScrollController,
          header: widget.refreshHeader,
          footer: CustomFooter(
            builder: (BuildContext context, LoadStatus mode) {
              if (mode == LoadStatus.idle) {
                return Container();
              } else if (mode == LoadStatus.loading) {
                return widget.stateViewPresenter.loadingMoreView();
              } else if (mode == LoadStatus.failed) {
                return widget.stateViewPresenter.errorOnMoreView(() {
                  _refreshController.requestLoading();
                });
              } else if (mode == LoadStatus.canLoading) {
                return widget.stateViewPresenter.pullUpLoadMoreView(null);
              } else {
                return widget.stateViewPresenter.noMoreCanLoadView();
              }
            },
          ),
        )),
      ],
    );
  }

  Future<void> _onRefresh() async =>
      _loadData(firstPageLoad: false, isHeader: true);

  Future<void> _onLoading() async =>
      _loadData(firstPageLoad: false, isHeader: false);

  Widget _buildLoadedErrorView() {
    return widget.stateViewPresenter.errorOnLoadView(() {
      setState(() {
        _state = _AutoRefreshListViewState.loadingFirstPage;
      });
      _loadData(firstPageLoad: true, isHeader: true);
    });
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }
}

enum _AutoRefreshListViewState {
  /// 第一次进入的时候正在加载数据
  loadingFirstPage,

  /// 第一次进入加载数据失败
  errorOnLoadFirstPage,

  /// 第一次进入加载数据为空
  emptyOnLoadFirstPage,

  /// list加载
  loadListViewData,
}
