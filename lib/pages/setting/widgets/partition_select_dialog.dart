import 'dart:convert';

import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class PartitionSelectDialog extends StatefulWidget {
  final String jsonPath;
  final String storageKey;
  final bool saveAsNames;

  const PartitionSelectDialog({
    super.key,
    this.jsonPath = 'assets/json/video_zone.json',
    this.storageKey = SettingBoxKey.whitePartitionIds,
    this.saveAsNames = false,
  });

  @override
  State<PartitionSelectDialog> createState() => _PartitionSelectDialogState();
}

class _PartitionSelectDialogState extends State<PartitionSelectDialog> {
  Map<String, dynamic> _videoZone = {};
  final List<String> _selectedIds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final String jsonStr = await rootBundle.loadString(widget.jsonPath);
    _videoZone = json.decode(jsonStr);
    _selectedIds.addAll(
      List<String>.from(GStorage.setting.get(widget.storageKey) ?? []),
    );
    setState(() {
      _loading = false;
    });
  }

  void _onSave() {
    GStorage.setting.put(widget.storageKey, _selectedIds);
    Get.back(result: _selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择白名单分区'),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _videoZone.keys.length,
                itemBuilder: (context, index) {
                  final String key = _videoZone.keys.elementAt(index);
                  final List<dynamic> items = _videoZone[key];
                  return _buildBigPartitionItem(key, items);
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: Text(
            '取消',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        TextButton(
          onPressed: _onSave,
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildBigPartitionItem(String title, List<dynamic> items) {
    // Check status of big partition
    bool allSelected = true;
    bool anySelected = false;

    for (var item in items) {
      final String id = widget.saveAsNames ? item['name'] : item['tid'];
      if (_selectedIds.contains(id)) {
        anySelected = true;
      } else {
        allSelected = false;
      }
    }

    return ExpansionTile(
      title: Text(title),
      leading: Checkbox(
        value: allSelected ? true : (anySelected ? null : false),
        tristate: true,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              // Select all
              for (var item in items) {
                final String id =
                    widget.saveAsNames ? item['name'] : item['tid'];
                if (!_selectedIds.contains(id)) {
                  _selectedIds.add(id);
                }
              }
            } else {
              // Deselect all
              for (var item in items) {
                final String id =
                    widget.saveAsNames ? item['name'] : item['tid'];
                _selectedIds.remove(id);
              }
            }
          });
        },
      ),
      children: items.map((item) {
        final String id = widget.saveAsNames ? item['name'] : item['tid'];
        final bool isSelected = _selectedIds.contains(id);
        return CheckboxListTile(
          title: Text(item['name']),
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedIds.add(id);
              } else {
                _selectedIds.remove(id);
              }
            });
          },
        );
      }).toList(),
    );
  }
}
