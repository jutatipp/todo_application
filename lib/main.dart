import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

//  COLOR SYSTEM
const primary = Color(0xFF0058BE);
const primaryLight = Color(0xFF2170E4);
const surface = Color(0xFFF9F9FF);
const surfaceLow = Color(0xFFF2F3FD);
const textPrimary = Color(0xFF191B23);
const success = Color(0xFF006947);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo App',
      theme: ThemeData(scaffoldBackgroundColor: surface, fontFamily: 'Inter'),
      home: const TodoPage(),
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  List<Map<String, dynamic>> todos = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('todos', todos.map((e) => jsonEncode(e)).toList());
  }

  void loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('todos');

    if (data != null) {
      setState(() {
        todos = data.map((e) {
          final item = Map<String, dynamic>.from(jsonDecode(e));
          return {
            "title": item["title"] ?? "",
            "description": item["description"] ?? "",
            "isDone": item["isDone"] ?? false,
            "dueDate": item["dueDate"],
          };
        }).toList();
      });
    }
  }

  void toggleTodo(int index) {
    setState(() {
      todos[index]["isDone"] = !todos[index]["isDone"];
    });
    saveData();
  }

  void deleteTodo(int index) {
    setState(() {
      todos.removeAt(index);
    });
    saveData();
  }

  void editTodo(int index) {
    TextEditingController t = TextEditingController(
      text: todos[index]["title"],
    );
    TextEditingController d = TextEditingController(
      text: todos[index]["description"],
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surfaceLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("แก้ไขงาน"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: t),
            const SizedBox(height: 10),
            TextField(controller: d),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                todos[index]["title"] = t.text;
                todos[index]["description"] = d.text;
              });
              saveData();
              Navigator.pop(context);
            },
            child: const Text("บันทึก", style: TextStyle(color: primary)),
          ),
        ],
      ),
    );
  }

  Widget buildCard(Map todo, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Checkbox(
            value: todo["isDone"],
            activeColor: success,
            onChanged: (_) => toggleTodo(index),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo["title"],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    decoration: todo["isDone"]
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if ((todo["description"] ?? "").isNotEmpty)
                  Text(todo["description"]),
                if (todo["dueDate"] != null)
                  Text(
                    " ${todo["dueDate"].toString().split(' ')[0]}",
                    style: const TextStyle(color: primary),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: primary),
            onPressed: () => editTodo(index),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => deleteTodo(index),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = todos.where((t) => !t["isDone"]).toList();
    final done = todos.where((t) => t["isDone"]).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surface,
        title: const Text(
          "To-Do List",
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton: GestureDetector(
        onTap: () async {
          final newTodo = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTodoPage()),
          );

          if (newTodo != null) {
            setState(() => todos.add(newTodo));
            saveData();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primary, primaryLight]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),

      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              " งานที่ยังไม่เสร็จ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...pending.map((e) => buildCard(e, todos.indexOf(e))),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              " งานที่เสร็จแล้ว",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...done.map((e) => buildCard(e, todos.indexOf(e))),
        ],
      ),
    );
  }
}

// ADD PAGE
class AddTodoPage extends StatefulWidget {
  const AddTodoPage({super.key});

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  TextEditingController title = TextEditingController();
  TextEditingController desc = TextEditingController();
  DateTime? date;

  void save() {
    if (title.text.isEmpty) return;
    Navigator.pop(context, {
      "title": title.text,
      "description": desc.text,
      "isDone": false,
      "dueDate": date?.toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: const Text("เพิ่มงาน", style: TextStyle(color: textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: "ชื่องาน"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: desc,
              decoration: const InputDecoration(labelText: "รายละเอียด"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                setState(() {});
              },
              child: const Text("เลือกวัน"),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primary, primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text("บันทึก", style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
