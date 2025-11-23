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
    if (enableWhiteFilter || enableFilter) {
       debugPrint('FilterTitle: "$title" | White: $enableWhiteFilter ("${whiteRcmdRegExp.pattern}") | Black: $enableFilter ("${rcmdRegExp.pattern}") | PrefBlack: "${Pref.banWordForRecommend}"');
    }

    // 1. Whitelist Check (Strict Mode)
    if (enableWhiteFilter) {
      if (!whiteRcmdRegExp.hasMatch(title)) {
        debugPrint('Whitelist MISMATCH title: $title');
        return true; // Filtered because it didn't match whitelist
      }
      debugPrint('Whitelist matched title: $title');
    }

    // 2. Blacklist Check
    if (enableFilter && rcmdRegExp.hasMatch(title)) {
      debugPrint('Blacklist matched title: $title');
      return true; // Filtered
    }
    return false;
  }

  static Set<String> whitePartitionIds = Pref.whitePartitionIds.toSet();

  static bool filterZone(String? tname, {String? tid}) {
    if (tname == null) return false;
    debugPrint('FilterZone: "$tname" | White: $enableZoneWhiteFilter ("${zoneWhiteRegExp.pattern}") | Black: $enableZoneFilter ("${zoneRegExp.pattern}") | PrefBlack: "${Pref.banWordForZone}"');
    
    // 1. Whitelist Check (Strict Mode)
    // Check regex OR partition ID list
    bool matchedWhitelist = false;
    if (enableZoneWhiteFilter && zoneWhiteRegExp.hasMatch(tname)) {
      matchedWhitelist = true;
    }
    if (!matchedWhitelist && tid != null && whitePartitionIds.contains(tid)) {
      matchedWhitelist = true;
    }

    // If whitelist is active (either regex or IDs has content), we must match one of them
    bool whitelistActive = enableZoneWhiteFilter || whitePartitionIds.isNotEmpty;

    if (whitelistActive) {
      if (!matchedWhitelist) {
        debugPrint('Whitelist MISMATCH zone: $tname (tid: $tid)');
        return true; // Filtered because it didn't match whitelist
      }
      debugPrint('Whitelist matched zone: $tname (tid: $tid)');
    }

    // 2. Blacklist Check
    if (enableZoneFilter && zoneRegExp.hasMatch(tname)) {
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
