import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/foundation.dart';

class RecommendFilter {
  static int minDurationForRcmd = Pref.minDurationForRcmd;
  static int minPlayForRcmd = Pref.minPlayForRcmd;
  static int minLikeRatioForRecommend = Pref.minLikeRatioForRecommend;
  static bool exemptFilterForFollowed = Pref.exemptFilterForFollowed;
  static bool applyFilterToRelatedVideos = Pref.applyFilterToRelatedVideos;
  static RegExp rcmdRegExp = RegExp(
    Pref.banWordForRecommend,
    caseSensitive: false,
  );
  static bool enableFilter = rcmdRegExp.pattern.isNotEmpty;
  static RegExp whiteRcmdRegExp = RegExp(
    Pref.whiteWordForRecommend,
    caseSensitive: false,
  );
  static bool enableWhiteFilter = whiteRcmdRegExp.pattern.isNotEmpty;

  static RegExp zoneRegExp = RegExp(Pref.banWordForZone, caseSensitive: false);
  static bool enableZoneFilter = zoneRegExp.pattern.isNotEmpty;
  static RegExp zoneWhiteRegExp = RegExp(
    Pref.whiteWordForZone,
    caseSensitive: false,
  );
  static bool enableZoneWhiteFilter = zoneWhiteRegExp.pattern.isNotEmpty;

  static bool filter(BaseVideoItemModel videoItem) {
    //由于相关视频中没有已关注标签，只能视为非关注视频
    if (videoItem.isFollowed && exemptFilterForFollowed) {
      return false;
    }
    return filterAll(videoItem);
  }

  static bool filterLikeRatio(int? like, int? view) {
    if (view != null) {
      return (view > -1 && view < minPlayForRcmd) ||
          (like != null &&
              like > -1 &&
              like * 100 < minLikeRatioForRecommend * view);
    }
    return false;
  }

  static bool filterTitle(String title) {
    if (enableWhiteFilter && whiteRcmdRegExp.hasMatch(title)) {
      debugPrint('Whitelist matched title: $title');
      return false;
    }
    if (enableFilter && rcmdRegExp.hasMatch(title)) {
      debugPrint('Blacklist matched title: $title');
      return true;
    }
    return false;
  }

  static bool filterZone(String? tname) {
    if (tname == null) return false;
    if (enableZoneFilter && zoneRegExp.hasMatch(tname)) {
      if (enableZoneWhiteFilter && zoneWhiteRegExp.hasMatch(tname)) {
        debugPrint('Whitelist matched zone: $tname');
        return false;
      }
      debugPrint('Blacklist matched zone: $tname');
      return true;
    }
    return false;
  }

  static bool filterAll(BaseVideoItemModel videoItem) {
    return (videoItem.duration > 0 &&
            videoItem.duration < minDurationForRcmd) ||
        filterLikeRatio(videoItem.stat.like, videoItem.stat.view) ||
        filterTitle(videoItem.title);
  }
}
