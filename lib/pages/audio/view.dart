import 'dart:math' show min;

import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/progress_bar/audio_video_progress_bar.dart';
import 'package:PiliPlus/grpc/bilibili/app/listener/v1.pb.dart';
import 'package:PiliPlus/models/common/image_preview_type.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/pages/audio/controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/widgets/action_item.dart';
import 'package:PiliPlus/pages/video/related/view.dart';
import 'package:PiliPlus/pages/video/reply/view.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/num_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart' hide DraggableScrollableSheet;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/utils/id_utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class AudioPage extends StatefulWidget {
  const AudioPage({super.key});

  @override
  State<AudioPage> createState() => _AudioPageState();

  static void toAudioPage({
    int? id,
    required int oid,
    List<int>? subId,
    required int itemType,
    required PlaylistSource from,
    String? heroTag,
    Duration? start,
    String? audioUrl,
    int? extraId,
  }) => Get.toNamed(
    '/audio',
    preventDuplicates: false,
    arguments: {
      'id': id,
      'oid': oid,
      'subId': subId,
      'from': from,
      'itemType': itemType,
      'heroTag': heroTag,
      'start': start,
      'audioUrl': audioUrl,
      'extraId': extraId,
    },
  );
}

extension _ListOrderExt on ListOrder {
  String get title => const ['无序', '正序', '倒序', '随机'][value];
}

class _AudioPageState extends State<AudioPage> {
  final _controller = Get.put(
    AudioController(),
    tag: Utils.generateRandomString(8),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.didChangeDependencies(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPortrait = context.mediaQuery.orientation == Orientation.portrait;
    return Scaffold(
      appBar: AppBar(
        title: const Text('音频播放'),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) {
              return PopupMenuButton<ListOrder>(
                tooltip: '排序',
                icon: const Icon(Icons.sort),
                initialValue: _controller.order,
                onSelected: (value) {
                  _controller.onChangeOrder(value);
                  (context as Element).markNeedsBuild();
                },
                itemBuilder: (context) => ListOrder.values
                    .map((e) => PopupMenuItem(value: e, child: Text(e.title)))
                    .toList(),
              );
            },
          ),
          if (_controller.isVideo) ...[
            TextButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.videocam_outlined, size: 20),
              label: const Text('看视频'),
            ),
            IconButton(
              onPressed: _showMore,
              icon: const Icon(Icons.more_vert),
            ),
          ],
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: _buildInfo(colorScheme, isPortrait),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
                    child: Text(
                      '相关推荐',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                RelatedVideoPanel(
                  heroTag: _controller.heroTag,
                  onVideoTap: (item) {
                    _controller.player?.pause();
                    int oid = item.aid ?? 0;
                    if (oid == 0 && item.bvid != null) {
                      oid = IdUtils.bv2av(item.bvid!);
                    }
                    if (oid == 0) {
                      SmartDialog.showToast('无法获取视频ID');
                      return;
                    }
                    AudioPage.toAudioPage(
                      oid: oid,
                      itemType: 1, // 1 for video
                      from: PlaylistSource.DEFAULT,
                    );
                  },
                ),
              ],
              body: VideoReplyPanel(
                heroTag: _controller.heroTag,
                isNested: true,
              ),
            ),
          ),
          _buildProgressBar(colorScheme),
          _buildDuration(colorScheme),
          _buildControls(),
          SizedBox(height: context.mediaQueryPadding.bottom + 12),
        ],
      ),
    );
  }

  void _showPlaylist() {
    if (_controller.playlist case final playlist?) {
      final initialScrollOffset = 45.0 * _controller.index!;
      final scrollController = ScrollController(
        initialScrollOffset: initialScrollOffset,
      );
      showModalBottomSheet(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        constraints: BoxConstraints(
          maxWidth: min(640, context.mediaQueryShortestSide),
        ),
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          return FractionallySizedBox(
            heightFactor: Utils.isMobile && !context.mediaQuerySize.isPortrait
                ? 1.0
                : 0.7,
            alignment: Alignment.bottomCenter,
            child: Column(
              children: [
                InkWell(
                  onTap: Get.back,
                  borderRadius: StyleString.bottomSheetRadius,
                  child: SizedBox(
                    height: 35,
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 3,
                        decoration: BoxDecoration(
                          color: colorScheme.outline,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Theme(
                      data: theme.copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: refreshIndicator(
                        onRefresh: () => _controller.loadPrev(context),
                        child: CustomScrollView(
                          controller: scrollController,
                          physics: _controller.reachStart
                              ? const ClampingScrollPhysics()
                              : const AlwaysScrollableScrollPhysics(
                                  parent: ClampingScrollPhysics(),
                                ),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.paddingOf(context).bottom + 100,
                              ),
                              sliver: SliverList.builder(
                                itemCount: playlist.length,
                                itemBuilder: (_, index) {
                                  if (index == playlist.length - 1) {
                                    _controller.loadNext(context);
                                  }
                                  final isCurr = index == _controller.index;
                                  final item = playlist[index];
                                  if (item.parts.length > 1) {
                                    final subId = _controller.subId.firstOrNull;
                                    return ExpansionTile(
                                      dense: true,
                                      minTileHeight: 45,
                                      initiallyExpanded: isCurr,
                                      collapsedIconColor: isCurr
                                          ? colorScheme.primary
                                          : null,
                                      iconColor: isCurr
                                          ? null
                                          : colorScheme.onSurfaceVariant,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      title: Text(
                                        item.arc.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: isCurr
                                            ? TextStyle(
                                                fontSize: 14,
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              )
                                            : const TextStyle(fontSize: 14),
                                      ),
                                      trailing: isCurr
                                          ? null
                                          : iconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                if (index <
                                                    _controller.index!) {
                                                  _controller.index -= 1;
                                                }
                                                _controller.playlist!.removeAt(
                                                  index,
                                                );
                                                (context as Element)
                                                    .markNeedsBuild();
                                              },
                                              iconColor: colorScheme.outline,
                                              size: 28,
                                              iconSize: 18,
                                            ),
                                      children: item.parts.map((e) {
                                        final isCurr = e.subId == subId;
                                        return ListTile(
                                          dense: true,
                                          minTileHeight: 45,
                                          contentPadding:
                                              const EdgeInsetsDirectional.only(
                                                start: 56.0,
                                                end: 24.0,
                                              ),
                                          onTap: () {
                                            Get.back();
                                            if (!isCurr) {
                                              _controller.playIndex(
                                                index,
                                                subId: [e.subId],
                                              );
                                            }
                                          },
                                          title: Text.rich(
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: isCurr
                                                ? TextStyle(
                                                    fontSize: 14,
                                                    color: colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  )
                                                : TextStyle(
                                                    fontSize: 14,
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            TextSpan(
                                              children: [
                                                if (isCurr) ...[
                                                  WidgetSpan(
                                                    alignment:
                                                        PlaceholderAlignment
                                                            .bottom,
                                                    child: Image.asset(
                                                      'assets/images/live.gif',
                                                      width: 16,
                                                      height: 16,
                                                      color:
                                                          colorScheme.primary,
                                                    ),
                                                  ),
                                                  const TextSpan(text: '  '),
                                                ],
                                                TextSpan(text: e.title),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  }
                                  return ListTile(
                                    dense: true,
                                    minTileHeight: 45,
                                    onTap: () {
                                      Get.back();
                                      if (!isCurr) {
                                        _controller.playIndex(index);
                                      }
                                    },
                                    title: Text.rich(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: isCurr
                                          ? TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            )
                                          : const TextStyle(fontSize: 14),
                                      TextSpan(
                                        children: [
                                          if (isCurr) ...[
                                            WidgetSpan(
                                              alignment:
                                                  PlaceholderAlignment.bottom,
                                              child: Image.asset(
                                                'assets/images/live.gif',
                                                width: 16,
                                                height: 16,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                            const TextSpan(text: '  '),
                                          ],
                                          TextSpan(
                                            text: item.arc.title,
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: isCurr
                                        ? null
                                        : iconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              if (index < _controller.index!) {
                                                _controller.index -= 1;
                                              }
                                              _controller.playlist!.removeAt(
                                                index,
                                              );
                                              (context as Element)
                                                  .markNeedsBuild();
                                            },
                                            iconColor: colorScheme.outline,
                                            size: 28,
                                            iconSize: 18,
                                          ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewPaddingOf(context).bottom,
                  ),
                  child: InkWell(
                    onTap: Get.back,
                    child: SizedBox(
                      height: 45,
                      child: Center(
                        child: Text(
                          '关闭',
                          style: TextStyle(color: colorScheme.outline),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ).whenComplete(scrollController.dispose);
    }
  }

  void _showPlaySettings() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: min(640, context.mediaQueryShortestSide),
      ),
      builder: (context) {
        final colorScheme = ColorScheme.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: Get.back,
              borderRadius: StyleString.bottomSheetRadius,
              child: SizedBox(
                height: 35,
                child: Center(
                  child: Container(
                    width: 32,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colorScheme.outline,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: 12,
                left: 20,
                right: 20,
                bottom: MediaQuery.viewPaddingOf(context).bottom + 20,
              ),
              child: Column(
                spacing: 12,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) => Column(
                      spacing: 12,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('播放倍速(${_controller.speed})'),
                        Slider(
                          padding: EdgeInsets.zero,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          value: _controller.speed,
                          onChanged: (value) {
                            _controller.speed = value.toPrecision(1);
                            (context as Element).markNeedsBuild();
                          },
                          onChangeEnd: (_) =>
                              _controller.setSpeed(_controller.speed),
                        ),
                      ],
                    ),
                  ),
                  const Text('播放模式'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: PlayRepeat.values
                        .sublist(0, 4)
                        .map(
                          (e) => _playModeWidget(
                            colorScheme: colorScheme,
                            playMode: e,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _playModeWidget({
    required ColorScheme colorScheme,
    required PlayRepeat playMode,
  }) {
    final isCurr = playMode == _controller.playMode.value;
    final color = isCurr ? colorScheme.primary : colorScheme.outline;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Get.back();
        if (!isCurr) {
          _controller.playMode.value = playMode;
          GStorage.setting.put(SettingBoxKey.audioPlayMode, playMode.index);
        }
      },
      child: Column(
        spacing: 6,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurr
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : colorScheme.onInverseSurface.withValues(alpha: 0.8),
            ),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                size: 26,
                playMode.icon,
                color: color,
              ),
            ),
          ),
          Text(
            playMode.desc,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }

  void _showMore() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxWidth: min(640, context.mediaQueryShortestSide),
      ),
      builder: (context) {
        final colorScheme = ColorScheme.of(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewPaddingOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: Get.back,
                borderRadius: StyleString.bottomSheetRadius,
                child: SizedBox(
                  height: 35,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: colorScheme.outline,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // ListTile(
              //   dense: true,
              //   title: const Text(
              //     '定时关闭',
              //     style: TextStyle(fontSize: 14),
              //   ),
              //   onTap: () {
              //     Get.back();
              //     _controller.showTimerDialog();
              //   },
              // ),
              ListTile(
                dense: true,
                title: const Text(
                  '举报',
                  style: TextStyle(fontSize: 14),
                ),
                onTap: () {
                  Get.back();
                  PageUtils.reportVideo(_controller.oid.toInt());
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActions(DetailItem audioItem) {
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => ActionItem(
              animation: _controller.tripleAnimation,
              icon: const Icon(FontAwesomeIcons.thumbsUp),
              selectIcon: const Icon(
                FontAwesomeIcons.solidThumbsUp,
              ),
              selectStatus: _controller.hasLike.value,
              semanticsLabel: '点赞',
              text: NumUtils.numFormat(audioItem.stat.like),
              onStartTriple: _controller.onStartTriple,
              onCancelTriple: _controller.onCancelTriple,
            ),
          ),
          Obx(
            () => ActionItem(
              animation: _controller.tripleAnimation,
              icon: const Icon(FontAwesomeIcons.b),
              selectIcon: const Icon(FontAwesomeIcons.b),
              onTap: _controller.actionCoinVideo,
              selectStatus: _controller.hasCoin,
              semanticsLabel: '投币',
              text: NumUtils.numFormat(
                audioItem.stat.coin,
              ),
            ),
          ),
          Obx(
            () => ActionItem(
              animation: _controller.tripleAnimation,
              icon: const Icon(FontAwesomeIcons.star),
              selectIcon: const Icon(
                FontAwesomeIcons.solidStar,
              ),
              onTap: () => _controller.showFavBottomSheet(context),
              onLongPress: () => _controller.showFavBottomSheet(
                context,
                isLongPress: true,
              ),
              selectStatus: _controller.hasFav.value,
              semanticsLabel: '收藏',
              text: NumUtils.numFormat(
                audioItem.stat.favourite,
              ),
            ),
          ),
          ActionItem(
            icon: const Icon(FontAwesomeIcons.comment),
            onTap: _controller.showReply,
            semanticsLabel: '评论',
            text: NumUtils.numFormat(
              audioItem.stat.reply,
            ),
          ),
          ActionItem(
            icon: const Icon(
              FontAwesomeIcons.shareFromSquare,
            ),
            onTap: () => _controller.actionShareVideo(context),
            selectStatus: false,
            semanticsLabel: '分享',
            text: NumUtils.numFormat(
              audioItem.stat.share,
            ),
          ),
          if (audioItem.associatedItem.hasOid() &&
              audioItem.associatedItem.subId.isNotEmpty)
            ActionItem(
              icon: const Icon(FontAwesomeIcons.circlePlay),
              onTap: () {
                _controller.player?.pause();
                PageUtils.toVideoPage(
                  cid: audioItem.associatedItem.subId.first.toInt(),
                  aid: audioItem.associatedItem.oid.toInt(),
                );
              },
              selectStatus: false,
              semanticsLabel: '看MV',
              text: '看MV',
            ),
        ],
      ),
    );
  }

  void _onDragStart(ThumbDragDetails details) {
    // do nothing
  }

  void _onDragUpdate(ThumbDragDetails details) {
    _controller
      ..isDragging = true
      ..position.value = details.timeStamp;
  }

  void _onSeek(Duration value) {
    _controller
      ..player?.platform?.seek(value)
      ..isDragging = false;
  }

  Widget _buildProgressBar(ColorScheme colorScheme) {
    final primary = colorScheme.primary;
    final thumbGlowColor = primary.withAlpha(80);
    final bufferedBarColor = primary.withValues(alpha: 0.4);
    final baseBarColor = colorScheme.brightness.isDark
        ? const Color(0x33FFFFFF)
        : const Color(0x33999999);
    final child = Obx(
      () => ProgressBar(
        progress: _controller.position.value,
        total: _controller.duration.value,
        baseBarColor: baseBarColor,
        progressBarColor: primary,
        bufferedBarColor: bufferedBarColor,
        thumbColor: primary,
        thumbGlowColor: thumbGlowColor,
        thumbGlowRadius: 0,
        thumbRadius: 6,
        onDragStart: _onDragStart,
        onDragUpdate: _onDragUpdate,
        onSeek: _onSeek,
      ),
    );
    if (Utils.isDesktop) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: child,
      );
    }
    return child;
  }

  Widget _buildDuration(ColorScheme colorScheme) {
    return SizedBox(
      height: 30,
      child: DefaultTextStyle(
        style: TextStyle(fontSize: 13, color: colorScheme.outline),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() {
              final position = _controller.position.value;
              if (_controller.player != null) {
                return Text(
                  DurationUtils.formatDuration(position.inSeconds),
                );
              }
              return const SizedBox.shrink();
            }),
            Obx(() {
              final duration = _controller.duration.value;
              if (_controller.player != null) {
                return Text(
                  DurationUtils.formatDuration(duration.inSeconds),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Obx(
          () => IconButton(
            onPressed: _showPlaySettings,
            icon: Icon(
              size: 26,
              _controller.playMode.value.icon,
            ),
          ),
        ),
        IconButton(
          onPressed: _controller.playPrev,
          icon: const Icon(
            size: 40,
            Icons.skip_previous_rounded,
          ),
        ),
        IconButton(
          onPressed: _controller.playOrPause,
          icon: AnimatedIcon(
            size: 40,
            icon: AnimatedIcons.play_pause,
            progress: _controller.animController,
          ),
        ),
        IconButton(
          onPressed: _controller.playNext,
          icon: const Icon(
            size: 40,
            Icons.skip_next_rounded,
          ),
        ),
        IconButton(
          onPressed: _showPlaylist,
          icon: const Icon(
            size: 26,
            Icons.menu_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(ColorScheme colorScheme, bool isPortrait) {
    return Obx(() {
      final audioItem = _controller.audioItem.value;
      if (audioItem != null) {
        final cover = audioItem.arc.cover.http2https;
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => PageUtils.imageView(
                      imgList: [SourceModel(url: cover)],
                    ),
                    child: Hero(
                      tag: cover,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: NetworkImgLayer(
                          src: cover,
                          width: 100,
                          height: 100,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          audioItem.arc.title,
                          style: const TextStyle(
                            height: 1.4,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 8),
                        if (audioItem.owner.hasName())
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _controller.player?.pause();
                              Get.toNamed('/member?mid=${audioItem.owner.mid}');
                            },
                            child: Row(
                              spacing: 6,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (audioItem.owner.hasAvatar())
                                  NetworkImgLayer(
                                    src: audioItem.owner.avatar,
                                    width: 20,
                                    height: 20,
                                    type: ImageType.avatar,
                                  ),
                                Text(
                                  audioItem.owner.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              size: 12,
                              Icons.headphones_outlined,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${NumUtils.numFormat(audioItem.stat.view)}  '
                              '${DateFormatUtils.dateFormat(audioItem.arc.publish.toInt(), long: DateFormatUtils.longFormatD)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (audioItem.arc.hasDesc()) ...[
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      '简介',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    children: [
                      SelectableText(
                        audioItem.arc.desc,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildActions(audioItem),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }
}

extension _PlayReatExt on PlayRepeat {
  IconData get icon => switch (this) {
    PlayRepeat.pause => Icons.pause_rounded,
    PlayRepeat.listOrder => Icons.keyboard_double_arrow_right_rounded,
    PlayRepeat.singleCycle => Icons.play_circle_outline_rounded,
    PlayRepeat.listCycle => Icons.sync_rounded,
    PlayRepeat.autoPlayRelated => throw UnimplementedError(),
  };
}
