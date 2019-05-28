import 'package:flutter/material.dart';
import 'dart:async';
import 'package:list_view_item_builder/list_view_item_builder.dart';
import 'data_presenter.dart';
import 'item_presenter.dart';
import 'state_view_presenter.dart';

class AutoRefreshListViewController {
  /// 开始重新刷新列表
  void beginRefresh() {
    if (_beginRefreshCallback != null) {
      _beginRefreshCallback();
    }
  }

  /// listView的控制器
  ScrollController get scrollController => _scrollController;

  VoidCallback _beginRefreshCallback;

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

  /// 构建完成是否立即刷新,默认true
  final bool immediateRefresh;

  /// listView的padding,默认zero
  final EdgeInsetsGeometry padding;

  /// 控制器,用来操作内部listView
  final AutoRefreshListViewController controller;

  AutoRefreshListView(
      {Key key,
      @required this.itemPresenter,
      @required this.dataPresenter,
      this.controller,
      bool canPullDown,
      bool canPullUp,
      bool immediateRefresh,
      RefreshListStateViewIPresenter stateViewPresenter,
      EdgeInsetsGeometry padding})
      : assert(itemPresenter != null && dataPresenter != null),
        canPullDown = canPullDown ?? true,
        canPullUp = canPullUp ?? true,
        stateViewPresenter =
            stateViewPresenter ?? RefreshListStateViewPresenter(),
        immediateRefresh = immediateRefresh ?? true,
        padding = padding ?? EdgeInsets.zero,
        super(key: key);

  @override
  _AutoRefreshListView createState() => _AutoRefreshListView();
}

class _AutoRefreshListView extends State<AutoRefreshListView> {
  _RefreshListState _state;
  ScrollController _listScrollController = ScrollController();
  bool _loadingMoreFlag = false;
  ListViewItemBuilder _itemBuilder;

  @override
  void initState() {
    super.initState();
    _initItemBuilder();

    if (widget.immediateRefresh == true) {
      _state = _RefreshListState.loadingFirstPage;
      _loadData(true);
    }
    _addListener();

    if (mounted) {
      if (widget.controller != null) {
        widget.controller._beginRefreshCallback = _refreshList;
        widget.controller._scrollController = _listScrollController;
      }
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

  @override
  Widget build(BuildContext context) {
    if (_state == null) {
      return Container(
        height: 0,
      );
    }
    switch (_state) {
      case _RefreshListState.loadingFirstPage:
        return widget.stateViewPresenter.loadingView();
      case _RefreshListState.errorOnLoadFirstPage:
        return _buildLoadedErrorView();
      case _RefreshListState.emptyOnLoadFirstPage:
        return widget.stateViewPresenter.emptyOnLoadView();
      default:
        return _buildListView();
    }
  }

  /// 重新从第一页数据开始加载,然后刷新列表到结束
  Future<void> _refreshList() async => await _loadData(true);

  _addListener() {
    _listScrollController.addListener(() {
      if (widget.canPullUp != true) return;

      var maxScroll = _listScrollController.position.maxScrollExtent;
      var pixel = _listScrollController.position.pixels;

      if (maxScroll == pixel &&
          (_state == _RefreshListState.loadCompletedHasMoreData || _state == _RefreshListState.errorOnLoadMoreData) &&
          !_loadingMoreFlag) {
        setState(() {
          _state = _RefreshListState.loadingMoreData;
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

    setState(() {
      if (data.success) {
        if (firstLoad) {
          widget.dataPresenter.clear();
        }

        if (widget.dataPresenter.isEmptyData(data)) {
          if (firstLoad) {
            _state = _RefreshListState.emptyOnLoadFirstPage;
          } else {
            _state = _RefreshListState.loadCompletedNoMoreData;
          }
        } else if (widget.dataPresenter.isNoMoreData(data)) {
          widget.dataPresenter.addAll(data);
          _state = _RefreshListState.loadCompletedNoMoreData;
        }

        /// 还有数据
        else {
          widget.dataPresenter.addAll(data);
          _state = _RefreshListState.loadCompletedHasMoreData;
        }
      } else {
        if (firstLoad) {
          _state = _RefreshListState.errorOnLoadFirstPage;
        } else {
          widget.dataPresenter.previousPage();
          _state = _RefreshListState.errorOnLoadMoreData;
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
    );
    return widget.canPullDown == true
        ? RefreshIndicator(child: listView, onRefresh: _onRefresh)
        : listView;
  }

  Widget _buildLoadedErrorView() {
    return widget.stateViewPresenter.errorOnLoadView(() {
      setState(() {
        _state = _RefreshListState.loadingFirstPage;
      });
      _loadData(true);
    });
  }

  Widget _buildListFooterView(BuildContext ctx) {
    Widget footerWidget;
    switch (_state) {
      case _RefreshListState.loadCompletedNoMoreData:
        footerWidget = widget.stateViewPresenter.noMoreCanLoadView();
        break;
      case _RefreshListState.loadCompletedHasMoreData:
        footerWidget = widget.stateViewPresenter.pullUpLoadMoreView(() {
          setState(() {
            _state = _RefreshListState.loadingMoreData;
          });
          _loadData(false);
        });
        break;
      case _RefreshListState.loadingMoreData:
        footerWidget = widget.stateViewPresenter.loadingMoreView();
        break;
      case _RefreshListState.errorOnLoadFirstPage:
        footerWidget = widget.stateViewPresenter.errorOnLoadView(() => _loadData(true));
        break;
      case _RefreshListState.errorOnLoadMoreData:
        footerWidget = widget.stateViewPresenter.errorOnMoreView(() {
          setState(() {
            _state = _RefreshListState.loadingMoreData;
          });
          _loadData(false);
        });
        break;
      default:
        footerWidget = Container(
          height: 0,
        );
        break;
    }
    return footerWidget;
  }

  Future<void> _onRefresh() async => _loadData(true);

  @override
  void dispose() {
    super.dispose();
    _listScrollController.dispose();
  }
}

enum _RefreshListState {
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
