import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/**
 * FOUNGNIGUE SOULEYMANE HASSAN COULIBALY
 * CSC 6360
 * GEORGIA STATE UNIVERSITY
 * SPRING 2025
 * GRADUATE STUDENT
 */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// Main App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TaskListScreen(),
    );
  }
}

// Task Model
class Task {
  String id;
  String name;
  bool isCompleted;
  String priority;

  Task({
    this.id = '',
    required this.name,
    this.isCompleted = false,
    required this.priority,
  });

  // Create Task from Firestore data
  factory Task.fromFirestore(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      name: data['name'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      priority: data['priority'] ?? 'Low',
    );
  }

  // Convert Task to Firestore data
  Map<String, dynamic> toFirestore(String userId) {
    return {
      'name': name,
      'isCompleted': isCompleted,
      'priority': priority,
      'userId': userId,
    };
  }
}

// Task Screen
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _taskController = TextEditingController();
  String _selectedPriority = "Low";
  final Map<String, int> _priorityOrder = {"High": 1, "Medium": 2, "Low": 3};

  @override
  void initState() {
    super.initState();
    _signInAnonymously();
  }

  // Firebase Anonymous Auth
  Future<void> _signInAnonymously() async {
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      print("Signed in anonymously as: ${userCredential.user?.uid}");
    } catch (e) {
      print("Anonymous sign-in failed: $e");
    }
  }

  // Add Task to Firebase
  void _addTask() {
    if (_taskController.text.isEmpty) return;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    Task newTask = Task(
      name: _taskController.text.trim(),
      priority: _selectedPriority,
    );

    FirebaseFirestore.instance
        .collection('tasks')
        .add(newTask.toFirestore(userId));

    _taskController.clear();
  }

  // Update task completion
  void _toggleTaskCompletion(Task task) {
    FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
      'isCompleted': !task.isCompleted,
    });
  }

  // Delete task
  void _deleteTask(Task task) {
    FirebaseFirestore.instance.collection('tasks').doc(task.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Task Management App"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const Text(
              "Task Management Application designed by Hassan",
              style: TextStyle(color: Colors.cyan, fontSize: 24.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _taskController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter Task',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _selectedPriority,
                  items:
                      ["Low", "Medium", "High"]
                          .map(
                            (priority) => DropdownMenuItem(
                              value: priority,
                              child: Text(priority),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value!;
                    });
                  },
                ),
                ElevatedButton.icon(
                  style: const ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(
                      Colors.orange,
                    ),
                  ),
                  onPressed: _addTask,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Task"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child:
                  userId == null
                      ? const Center(child: CircularProgressIndicator())
                      : StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('tasks')
                                .where('userId', isEqualTo: userId)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(child: Text("No tasks found."));
                          }

                          List<Task> tasks =
                              snapshot.data!.docs
                                  .map(
                                    (doc) => Task.fromFirestore(
                                      doc.id,
                                      doc.data() as Map<String, dynamic>,
                                    ),
                                  )
                                  .toList();

                          // Optional sorting by priority
                          tasks.sort(
                            (a, b) => _priorityOrder[a.priority]!.compareTo(
                              _priorityOrder[b.priority]!,
                            ),
                          );

                          return ListView.builder(
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return Card(
                                child: ListTile(
                                  leading: Checkbox(
                                    value: task.isCompleted,
                                    onChanged:
                                        (_) => _toggleTaskCompletion(task),
                                  ),
                                  title: Text(task.name),
                                  subtitle: Text("Priority: ${task.priority}"),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteTask(task),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
