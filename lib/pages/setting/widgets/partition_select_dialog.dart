import 'dart:convert';

import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class PartitionSelectDialog extends StatefulWidget {
  const PartitionSelectDialog({super.key});

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
    final String jsonStr =
        await rootBundle.loadString('assets/json/video_zone.json');
    _videoZone = json.decode(jsonStr);
    _selectedIds.addAll(Pref.whitePartitionIds);
    setState(() {
      _loading = false;
    });
  }

  void _onSave() {
    GStorage.setting.put(SettingBoxKey.whitePartitionIds, _selectedIds);
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
      if (_selectedIds.contains(item['tid'])) {
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
                if (!_selectedIds.contains(item['tid'])) {
                  _selectedIds.add(item['tid']);
                }
              }
            } else {
              // Deselect all
              for (var item in items) {
                _selectedIds.remove(item['tid']);
              }
            }
          });
        },
      ),
      children: items.map((item) {
        final bool isSelected = _selectedIds.contains(item['tid']);
        return CheckboxListTile(
          title: Text(item['name']),
          value: isSelected,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedIds.add(item['tid']);
              } else {
                _selectedIds.remove(item['tid']);
              }
            });
          },
        );
      }).toList(),
    );
  }
}
