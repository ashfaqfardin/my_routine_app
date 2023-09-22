import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;


class MyRoutineApp extends StatefulWidget {
  const MyRoutineApp({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyRoutineApp> createState() => _MyRoutineAppState();
}

class _MyRoutineAppState extends State<MyRoutineApp> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    const settingsAndroid = AndroidInitializationSettings('app_icon');
    const settingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: settingsAndroid, iOS: settingsIOS);
    flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _showNotification(Task task) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      importance: Importance.max,
      priority: Priority.high,
      channelShowBadge: false, // Add this line to control badge behavior
    );

    const iosPlatformChannelSpecifics = DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );
    final scheduledDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      task.time.hour,
      task.time.minute,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      task.hashCode,
      'Upcoming Task: ${task.taskName}',
      task.description,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _scheduleNotificationForTasks() async {
    final now = DateTime.now();
    for (final task in tasks) {
      final taskTime = DateTime(
        now.year,
        now.month,
        now.day,
        task.time.hour,
        task.time.minute,
      );
      if (taskTime.isAfter(now)) {
        await _showNotification(task);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          widget.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFF3E0),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text(task.taskName),
            subtitle: Text('Time: ${task.time.format(context)}'),
            onTap: () {
              _editTask(task);
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete_rounded),
              onPressed: () {
                _deleteTask(index);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addTask();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addTask() async {
    final newTask = await showDialog<Task>(
      context: context,
      builder: (BuildContext context) {
        return const TaskDialog();
      },
    );
    if (newTask != null) {
      setState(() {
        tasks.add(newTask);
        _scheduleNotificationForTasks();
      });
    }
  }

  void _editTask(Task task) async {
    final editedTask = await showDialog<Task>(
      context: context,
      builder: (BuildContext context) {
        return TaskDialog(
          initialTask: task,
        );
      },
    );
    if (editedTask != null) {
      setState(() {
        final index = tasks.indexWhere((element) => element.hashCode == task.hashCode);
        tasks[index] = editedTask;
        _scheduleNotificationForTasks();
      });
    }
  }

  void _deleteTask(int index) {
    setState(() {
      final task = tasks[index];
      tasks.removeAt(index);
      flutterLocalNotificationsPlugin.cancel(task.hashCode);
    });
  }
}

class Task {
  final String taskName;
  final TimeOfDay time;
  final String description;

  Task({
    required this.taskName,
    required this.time,
    required this.description,
  });
}

class TaskDialog extends StatefulWidget {
  final Task? initialTask;

  const TaskDialog({Key? key, this.initialTask}) : super(key: key);

  @override
  _TaskDialogState createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _taskNameController;
  late TimeOfDay _selectedTime;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _taskNameController = TextEditingController(text: widget.initialTask?.taskName ?? '');
    _selectedTime = widget.initialTask?.time ?? TimeOfDay.now();
    _descriptionController = TextEditingController(text: widget.initialTask?.description ?? '');
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTask == null ? 'Add Task' : 'Edit Task'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _taskNameController,
                decoration: const InputDecoration(labelText: 'Task Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              const Text('Task Time'),
              const SizedBox(height: 8.0),
              InkWell(
                onTap: () async {
                  final selectedTime = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (selectedTime != null) {
                    setState(() {
                      _selectedTime = selectedTime;
                    });
                  }
                },
                child: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(fontSize: 16.0),
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newTask = Task(
                taskName: _taskNameController.text,
                time: _selectedTime,
                description: _descriptionController.text,
              );
              Navigator.of(context).pop(newTask);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

extension TimeOfDayExtension on TimeOfDay {
  String format(BuildContext context) {
    return MaterialLocalizations.of(context).formatTimeOfDay(this);
  }
}


void main() => runApp(
  const MaterialApp(
    home: MyRoutineApp(title: 'My Routine'),
  ),
);

