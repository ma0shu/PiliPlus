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

  static Set<String> whitePartitionIds = Pref.whitePartitionIds.toSet();
  static Set<String> whitePartitionV2Names = Pref.whitePartitionV2Names.toSet();

  static bool isWhitelisted(String title, String? tname, String? tid) {
    // 1. Title Regex
    if (enableWhiteFilter && whiteRcmdRegExp.hasMatch(title)) return true;
    
    // 2. Zone Regex
    if (tname != null && enableZoneWhiteFilter && zoneWhiteRegExp.hasMatch(tname)) return true;

    // 3. Zone V1 IDs
    if (tid != null && whitePartitionIds.contains(tid)) return true;

    // 4. Zone V2 Names
    if (tname != null && whitePartitionV2Names.contains(tname)) return true;

    return false;
  }

  static bool isBlacklisted(String title, String? tname) {
    if (enableFilter && rcmdRegExp.hasMatch(title)) {
      debugPrint('Blacklist matched title: $title');
      return true;
    }
    if (tname != null && enableZoneFilter && zoneRegExp.hasMatch(tname)) {
      debugPrint('Blacklist matched zone: $tname');
      return true;
    }
    return false;
  }

  static bool shouldFilter(String title, String? tname, String? tid) {
     bool whitelistActive = enableWhiteFilter || enableZoneWhiteFilter || whitePartitionIds.isNotEmpty || whitePartitionV2Names.isNotEmpty;
     
     if (whitelistActive) {
       if (!isWhitelisted(title, tname, tid)) {
         // debugPrint('Whitelist MISMATCH: "$title" | Zone: $tname');
         return true; // Strict mode: not whitelisted -> filter
       }
       // debugPrint('Whitelist MATCH: "$title" | Zone: $tname');
     }

     if (isBlacklisted(title, tname)) {
       return true;
     }

     return false;
  }

  static bool filterTitle(String title) {
    // Legacy method, redirect to shouldFilter with null zone
    return shouldFilter(title, null, null);
  }

  static bool filterZone(String? tname, {String? tid}) {
    // Legacy method, redirect to shouldFilter with empty title (might be risky if title whitelist is active)
    // Ideally we shouldn't use this anymore, but for safety:
    return shouldFilter('', tname, tid);
  }

  static bool filterAll(BaseVideoItemModel videoItem) {
    return (videoItem.duration > 0 &&
            videoItem.duration < minDurationForRcmd) ||
        filterLikeRatio(videoItem.stat.like, videoItem.stat.view) ||
        filterTitle(videoItem.title);
  }
}
