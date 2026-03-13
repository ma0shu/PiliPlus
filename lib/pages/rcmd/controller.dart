import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/utils/storage_pref.dart';

class RcmdController
    extends CommonListController<
      RcmdPageResult<BaseRecVideoItemModel>,
      BaseRecVideoItemModel
    > {
  late bool enableSaveLastData = Pref.enableSaveLastData;
  final bool appRcmd = Pref.appRcmd;
  int _freshIdx = 0;

  int? lastRefreshAt;
  late bool savedRcmdTip = Pref.savedRcmdTip;

  @override
  void onInit() {
    super.onInit();
    page = 0;
    _freshIdx = 0;
    queryData();
  }

  @override
  Future<LoadingState<RcmdPageResult<BaseRecVideoItemModel>>> customGetData() {
    return appRcmd
        ? VideoHttp.rcmdVideoListApp(freshIdx: _freshIdx)
        : VideoHttp.rcmdVideoList(freshIdx: _freshIdx, ps: 20);
  }

  @override
  List<BaseRecVideoItemModel>? getDataList(
    RcmdPageResult<BaseRecVideoItemModel> response,
  ) {
    return response.items;
  }

  @override
  bool customHandleResponse(
    bool isRefresh,
    Success<RcmdPageResult<BaseRecVideoItemModel>> response,
  ) {
    _freshIdx = response.response.nextFreshIdx;
    return false;
  }

  @override
  void handleListResponse(List<BaseRecVideoItemModel> dataList) {
    if (enableSaveLastData && page == 0) {
      if (loadingState.value case Success(:final response)) {
        if (response != null && response.isNotEmpty) {
          if (savedRcmdTip) {
            lastRefreshAt = dataList.length;
          }
          if (response.length > 200) {
            dataList.addAll(response.take(50));
          } else {
            dataList.addAll(response);
          }
        }
      }
    }
  }

  @override
  Future<void> onRefresh() {
    page = 0;
    _freshIdx = 0;
    isEnd = false;
    return queryData();
  }
}
