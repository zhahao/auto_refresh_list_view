import 'package:flutter/material.dart';
import 'dart:async';
import 'package:list_view_item_builder/list_view_item_builder.dart';
import 'data_presenter.dart';
import 'item_presenter.dart';
import 'state_view_presenter.dart';

class AutoRefreshListViewController {
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

  /// listView的控制器
  ScrollController get scrollController => _scrollController;

  VoidCallback _beginRefreshCallback;
  VoidCallback _reloadDataCallback;
  ScrollController _scrollController;
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

  /// [RefreshIndicator.color]属性
  final Color refreshIndicatorColor;

  /// [RefreshIndicator.backgroundColor]属性
  final Color refreshIndicatorBackgroundColor;

  AutoRefreshListView({
    Key key,
    @required this.itemPresenter,
    @required this.dataPresenter,
    @required this.stateViewPresenter,
    this.controller,
    this.refreshIndicatorColor,
    this.refreshIndicatorBackgroundColor,
    bool canPullDown,
    bool canPullUp,
    bool immediateRefresh,
    EdgeInsetsGeometry padding,
  })  : assert(itemPresenter != null &&
            dataPresenter != null &&
            stateViewPresenter != null),
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
  bool _loadingMoreFlag = false;
  ListViewItemBuilder _itemBuilder;
  GlobalKey<RefreshIndicatorState> _globalKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _initItemBuilder();
    _initState();
    _initController();
    _addListener();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == null) {
      return Container(
        height: 0,
      );
    }
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

  _initState() {
    if (widget.immediateRefresh == true) {
      _state = _AutoRefreshListViewState.loadingFirstPage;
      _loadData(true);
    }
  }

  _initController() {
    if (!mounted) return;
    if (widget.controller != null) {
      widget.controller._beginRefreshCallback = () {
        if (_globalKey?.currentState == null) {
          setState(() {
            _state = _AutoRefreshListViewState.loadingFirstPage;
          });
          _loadData(true);
        } else {
          _globalKey.currentState.show();
        }
      };
      widget.controller._reloadDataCallback = () => setState(() {});
      widget.controller._scrollController = _listScrollController;
    }
  }

  _initItemBuilder() {
    _itemBuilder = ListViewItemBuilder(
      sectionCountBuilder: widget.itemPresenter.sectionCount,
      rowCountBuilder: widget.itemPresenter.rowCount,
      itemsBuilder: widget.itemPresenter.items,
      sectionHeaderBuilder: widget.itemPresenter.sectionHeader,
      sectionFooterBuilder: widget.itemPresenter.sectionFooter,
      itemOnTap: widget.itemPresenter.itemOnTap,
      itemShouldTap: widget.itemPresenter.itemShouldTap,
      headerWidgetBuilder: widget.itemPresenter.headerWidget,
      footerWidgetBuilder: widget.itemPresenter.footerWidget,
      loadMoreWidgetBuilder: _buildListFooterView,
    );
  }

  _addListener() {
    _listScrollController.addListener(() {
      if (widget.canPullUp != true) return;

      var maxScroll = _listScrollController.position.maxScrollExtent;
      var pixel = _listScrollController.position.pixels;

      if (maxScroll == pixel &&
          (_state == _AutoRefreshListViewState.loadCompletedHasMoreData ||
              _state == _AutoRefreshListViewState.errorOnLoadMoreData) &&
          !_loadingMoreFlag) {
        setState(() {
          _state = _AutoRefreshListViewState.loadingMoreData;
        });
        _loadData(false);
      }
    });
  }

  Future<void> _loadData(bool firstLoad) async {
    if (_loadingMoreFlag) return;

    _loadingMoreFlag = true;

    if (firstLoad) {
      widget.dataPresenter.resetPage();
    } else {
      widget.dataPresenter.nextPage();
    }

    RefreshListItemDataEntity data =
        await widget.dataPresenter.fetchDataEntity();
    _loadingMoreFlag = false;

    if (!mounted) return;

    setState(() {
      if (data.success == true) {
        if (firstLoad) {
          widget.dataPresenter.clear();
        }

        if (widget.dataPresenter.isEmptyData(data)) {
          if (firstLoad) {
            _state = _AutoRefreshListViewState.emptyOnLoadFirstPage;
          } else {
            _state = _AutoRefreshListViewState.loadCompletedNoMoreData;
          }
        } else if (widget.dataPresenter.isNoMoreData(data)) {
          widget.dataPresenter.addAll(data);
          _state = _AutoRefreshListViewState.loadCompletedNoMoreData;
        } else {
          widget.dataPresenter.addAll(data);
          _state = _AutoRefreshListViewState.loadCompletedHasMoreData;
        }
      } else {
        if (firstLoad) {
          _state = _AutoRefreshListViewState.errorOnLoadFirstPage;
        } else {
          widget.dataPresenter.previousPage();
          _state = _AutoRefreshListViewState.errorOnLoadMoreData;
        }
      }
    });
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
            child: widget.canPullDown == true
                ? RefreshIndicator(
                    key: _globalKey,
                    child: listView,
                    onRefresh: _onRefresh,
                    color: widget.refreshIndicatorColor,
                    backgroundColor: widget.refreshIndicatorBackgroundColor,
                  )
                : listView)
      ],
    );
  }

  Widget _buildLoadedErrorView() {
    return widget.stateViewPresenter.errorOnLoadView(() {
      setState(() {
        _state = _AutoRefreshListViewState.loadingFirstPage;
      });
      _loadData(true);
    });
  }

  Widget _buildListFooterView(BuildContext ctx) {
    switch (_state) {
      case _AutoRefreshListViewState.loadCompletedNoMoreData:
        return widget.stateViewPresenter.noMoreCanLoadView();
      case _AutoRefreshListViewState.loadCompletedHasMoreData:
        return widget.stateViewPresenter.pullUpLoadMoreView(() {
          setState(() {
            _state = _AutoRefreshListViewState.loadingMoreData;
          });
          _loadData(false);
        });
      case _AutoRefreshListViewState.loadingMoreData:
        return widget.stateViewPresenter.loadingMoreView();
      case _AutoRefreshListViewState.errorOnLoadFirstPage:
        return widget.stateViewPresenter.errorOnLoadView(() => _loadData(true));
      case _AutoRefreshListViewState.errorOnLoadMoreData:
        return widget.stateViewPresenter.errorOnMoreView(() {
          setState(() {
            _state = _AutoRefreshListViewState.loadingMoreData;
          });
          _loadData(false);
        });
      default:
        return Container(height: 0);
    }
  }

  Future<void> _onRefresh() async => _loadData(true);

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

  /// 没有更多数据
  loadCompletedNoMoreData,

  /// 有更多数据
  loadCompletedHasMoreData,

  /// 加载更多时失败
  errorOnLoadMoreData,

  /// 正在加载更多
  loadingMoreData,
}
