import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/models/event.dart';
import '../../../core/models/couple.dart';
import '../../../core/models/user.dart';
import '../../../core/services/events_api_service.dart';
import '../../../core/services/couple_api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/snackbar_utils.dart';

import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/points_chip.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Event> _events = [];
  bool _isLoading = true;
  User? _currentUser;
  Couple? _coupleInfo;

  @override
  void initState() {
    print('EventsScreen - initState 开始');
    super.initState();
    // 延迟到下一帧执行，避免在build过程中调用ScaffoldMessenger
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('EventsScreen - PostFrameCallback 执行，准备调用 _loadData');
      _loadData();
    });
    print('EventsScreen - initState 结束');
  }

  Future<void> _loadData() async {
    print('EventsScreen - _loadData 开始执行');
    setState(() {
      _isLoading = true;
    });
    print('EventsScreen - 设置 _isLoading = true');

    try {
      // 获取当前用户信息
      print('EventsScreen - 开始获取当前用户信息');
      final userInfo = StorageService.getUserInfo();
      print('EventsScreen - StorageService.getUserInfo() 返回: $userInfo');

      if (userInfo != null) {
        print('EventsScreen - 开始解析用户信息');
        _currentUser = User.fromJson(userInfo);
        print('EventsScreen - 成功解析用户信息: ${_currentUser?.username}');
      } else {
        print('EventsScreen - 没有找到用户信息');
      }

      // 获取情侣信息
      print('EventsScreen - 开始获取情侣信息...');
      try {
        final coupleResponse = await CoupleApiService.getCouple();
        print('EventsScreen - 情侣API响应: $coupleResponse');

        if (coupleResponse['couple'] != null) {
          print('EventsScreen - 开始解析情侣数据: ${coupleResponse['couple']}');
          _coupleInfo = Couple.fromJson(coupleResponse['couple']);
          print('EventsScreen - 成功解析情侣信息: ${_coupleInfo?.partner.username}');
        } else {
          print('EventsScreen - 响应中没有couple数据');
          _coupleInfo = null;
        }
      } catch (e, stackTrace) {
        print('EventsScreen - 获取情侣信息失败: $e');
        print('EventsScreen - 错误类型: ${e.runtimeType}');
        print('EventsScreen - 堆栈跟踪: $stackTrace');

        if (e is DioException) {
          print('EventsScreen - DioException状态码: ${e.response?.statusCode}');
          print('EventsScreen - DioException响应数据: ${e.response?.data}');
        }

        // 如果是404错误（没有情侣关系），这是正常的
        if (e.toString().contains('暂无情侣关系')) {
          print('EventsScreen - 确认没有情侣关系 (404)');
          _coupleInfo = null;
        } else {
          // 其他错误，可能是网络问题等，不改变当前状态
          print('EventsScreen - 其他错误，保持当前状态');
          // 不设置 _coupleInfo = null，保持之前的状态
        }
      }

      print('EventsScreen - 最终情侣信息状态: ${_coupleInfo != null ? "有情侣" : "无情侣"}');

      // 只有在有情侣关系的情况下才获取事件列表
      if (_coupleInfo != null) {
        // 获取事件列表
        print('开始获取事件列表...');
        final eventsResponse = await EventsApiService.getEvents();
        print('事件API响应: $eventsResponse');

      final eventsData = eventsResponse['events'] as List<dynamic>? ?? [];
      print('事件数据数量: ${eventsData.length}');

      // 逐个解析事件，捕获具体的解析错误
      final List<Event> parsedEvents = [];
      for (int i = 0; i < eventsData.length; i++) {
        try {
          print('解析第${i + 1}个事件: ${eventsData[i]}');
          final event = Event.fromJson(eventsData[i]);
          parsedEvents.add(event);
          print('成功解析事件: ${event.name}');
        } catch (e, stackTrace) {
          print('解析第${i + 1}个事件失败: $e');
          print('事件数据: ${eventsData[i]}');
          print('堆栈跟踪: $stackTrace');
          // 继续处理其他事件，不让一个错误影响整个列表
        }
      }

        setState(() {
          _events = parsedEvents;
        });
      } else {
        print('没有情侣关系，跳过获取事件列表');
        setState(() {
          _events = [];
        });
      }
    } catch (e, stackTrace) {
      print('EventsScreen - _loadData 捕获到异常: $e');
      print('EventsScreen - 异常类型: ${e.runtimeType}');
      print('EventsScreen - 堆栈跟踪: $stackTrace');

      if (mounted) {
        SnackbarUtils.showError(context, '加载数据失败: ${_getErrorMessage(e)}');
      }
    } finally {
      print('EventsScreen - _loadData finally块执行，设置 _isLoading = false');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      return error.response?.data?['error'] ?? error.message ?? '网络错误';
    }
    return error.toString();
  }

  Future<void> _showCreateEventDialog() async {
    if (_coupleInfo == null) {
      SnackbarUtils.showError(context, '需要先添加情侣才能使用事件功能');
      return;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final pointsController = TextEditingController();
    int targetId = _currentUser?.id ?? 0;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('创建事件'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('目标用户:', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<int>(
                      title: const Text('我自己'),
                      value: _currentUser?.id ?? 0,
                      groupValue: targetId,
                      onChanged: (value) {
                        setDialogState(() {
                          targetId = value!;
                        });
                      },
                    ),
                    RadioListTile<int>(
                      title: Text(_coupleInfo?.partner.username ?? '情侣'),
                      value: _coupleInfo?.partner.id ?? 0,
                      groupValue: targetId,
                      onChanged: (value) {
                        setDialogState(() {
                          targetId = value!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '事件名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '事件描述',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  decoration: const InputDecoration(
                    labelText: '积分变化（正数为奖励，负数为惩罚）',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _createEvent(
        targetId,
        nameController.text.trim(),
        descriptionController.text.trim(),
        pointsController.text.trim(),
      );
    }
  }

  Future<void> _createEvent(int targetId, String name, String description, String pointsStr) async {
    if (name.isEmpty || pointsStr.isEmpty || targetId == 0) {
      SnackbarUtils.showError(context, '请填写完整信息');
      return;
    }

    final points = int.tryParse(pointsStr);
    if (points == null) {
      SnackbarUtils.showError(context, '请输入有效的积分值');
      return;
    }

    try {
      await EventsApiService.createEvent(
        targetId: targetId,
        name: name,
        description: description,
        points: points,
      );

      if (mounted) {
        SnackbarUtils.showSuccess(context, '事件创建成功！');
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, '创建事件失败: ${_getErrorMessage(e)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('EventsScreen - build 方法执行');
    print('EventsScreen - _isLoading: $_isLoading');
    print('EventsScreen - _coupleInfo: ${_coupleInfo != null ? "不为null" : "为null"}');
    print('EventsScreen - _events.length: ${_events.length}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('事件记录'),
      ),
      body: _isLoading
          ? const LoadingWidget(message: '加载中...')
          : _coupleInfo == null
              ? const EmptyStateWidget(
                  icon: Icons.favorite_outline,
                  title: '需要先添加情侣',
                  subtitle: '才能使用事件功能',
                  iconColor: Colors.pink,
                )
              : _events.isEmpty
                  ? EmptyStateWidget(
                      icon: Icons.event_outlined,
                      title: '还没有事件',
                      subtitle: '创建一些积分事件吧！',
                      action: ElevatedButton.icon(
                        onPressed: _showCreateEventDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('创建事件'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          return _buildEventCard(event);
                        },
                      ),
                    ),
      floatingActionButton: _coupleInfo != null
          ? FloatingActionButton(
              onPressed: _showCreateEventDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    event.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PointsChip(points: event.points),
              ],
            ),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${event.creatorName} → ${event.targetName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  event.formatDate(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
