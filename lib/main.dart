import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo App',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 72, 45, 36),
        scaffoldBackgroundColor: Colors.yellow[50],
      ),
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

  // SAVE
  void saveData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> data = todos.map((e) => jsonEncode(e)).toList();
    prefs.setStringList('todos', data);
  }

  // LOAD
  void loadData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? data = prefs.getStringList('todos');

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

  // SORT
  void sortTodos() {
    todos.sort((a, b) {
      if (a["dueDate"] == null) return 1;
      if (b["dueDate"] == null) return -1;

      DateTime da = DateTime.parse(a["dueDate"]);
      DateTime db = DateTime.parse(b["dueDate"]);
      return da.compareTo(db);
    });
  }

  // TOGGLE
  void toggleTodo(int index) {
    setState(() {
      todos[index]["isDone"] = !todos[index]["isDone"];
    });
    saveData();
  }

  // DELETE
  void deleteTodo(int index) {
    setState(() {
      todos.removeAt(index);
    });
    saveData();
  }

  // EDIT
  void editTodo(int index) {
    TextEditingController editTitle = TextEditingController(
      text: todos[index]["title"],
    );
    TextEditingController editDesc = TextEditingController(
      text: todos[index]["description"],
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("แก้ไขงาน"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: editTitle),
            const SizedBox(height: 10),
            TextField(controller: editDesc),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                todos[index]["title"] = editTitle.text;
                todos[index]["description"] = editDesc.text;
              });
              saveData();
              Navigator.pop(context);
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  // ITEM UI
  Widget buildItem(Map<String, dynamic> todo, int index) {
    return Card(
      color: Colors.yellow[100],
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Checkbox(
          value: todo["isDone"],
          activeColor: const Color.fromARGB(255, 72, 45, 36),
          onChanged: (_) => toggleTodo(index),
        ),
        title: Text(
          todo["title"] ?? "",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: todo["isDone"] ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((todo["description"] ?? "").isNotEmpty)
              Text(todo["description"]),
            if (todo["dueDate"] != null &&
                todo["dueDate"].toString().isNotEmpty)
              Text(
                " ${todo["dueDate"].toString().split(' ')[0]}",
                style: const TextStyle(color: Color.fromARGB(255, 72, 45, 36)),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => editTodo(index),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Color.fromARGB(255, 90, 0, 0),
              ),
              onPressed: () => deleteTodo(index),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    sortTodos();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "📋 To-Do List",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 72, 45, 36),
        centerTitle: true,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 72, 45, 36),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final newTodo = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTodoPage()),
          );

          if (newTodo != null) {
            setState(() {
              todos.add(newTodo);
            });
            saveData();
          }
        },
      ),

      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              "⏳ งานที่ยังไม่เสร็จ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          ...todos.where((t) => !t["isDone"]).map((todo) {
            int index = todos.indexOf(todo);
            return buildItem(todo, index);
          }),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              "✅ งานที่เสร็จแล้ว",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          ...todos.where((t) => t["isDone"]).map((todo) {
            int index = todos.indexOf(todo);
            return buildItem(todo, index);
          }),
        ],
      ),
    );
  }
}

// หน้าเพิ่มงาน
class AddTodoPage extends StatefulWidget {
  const AddTodoPage({super.key});

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descController = TextEditingController();
  DateTime? selectedDate;

  void pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void save() {
    if (titleController.text.isEmpty) return;

    Navigator.pop(context, {
      "title": titleController.text,
      "description": descController.text,
      "isDone": false,
      "dueDate": selectedDate?.toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เพิ่มงาน", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 72, 45, 36),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "ชื่องาน",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: "รายละเอียด",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate == null
                      ? "ยังไม่ได้เลือกวัน"
                      : "${selectedDate!.toString().split(' ')[0]}",
                ),
                ElevatedButton(
                  onPressed: pickDate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 72, 45, 36),
                  ),
                  child: const Text(
                    "เลือกวัน",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 72, 45, 36),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "บันทึก",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
