import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/pages/setting/models/recommend_settings.dart';
import 'package:flutter/material.dart' hide ListTile;

class RecommendSetting extends StatefulWidget {
  const RecommendSetting({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<RecommendSetting> createState() => _RecommendSettingState();
}

class _RecommendSettingState extends State<RecommendSetting> {
  final list = recommendSettings;
  late final List<SettingsModel> part;

  @override
  void initState() {
    super.initState();
    part = list.sublist(0, 4);
    list.removeRange(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: widget.showAppBar == false
          ? null
            ),
          ),
        ],
      ),
    );
  }
}
