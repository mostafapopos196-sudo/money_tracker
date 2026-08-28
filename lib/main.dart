import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdvancedMoneyTracker());
}

class AdvancedMoneyTracker extends StatelessWidget {
  const AdvancedMoneyTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class ExpenseItem {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isIncome;

  ExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.isIncome,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'isIncome': isIncome,
      };

  factory ExpenseItem.fromMap(Map<String, dynamic> map) => ExpenseItem(
        id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: map['title'],
        amount: (map['amount'] as num).toDouble(),
        category: map['category'],
        date: DateTime.parse(map['date']),
        isIncome: map['isIncome'],
      );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  double _totalBudget = 1000.0;
  List<ExpenseItem> _expenses = [];
  String _selectedCategory = 'أكل وشرب';
  String _filterCategory = 'الكل';

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  final List<String> _categories = [
    'أكل وشرب',
    'مواصلات',
    'ألعاب وترفيه',
    'دراسة ودروس',
    'أخرى'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalBudget = prefs.getDouble('total_budget') ?? 1000.0;
      final String? expensesString = prefs.getString('expenses_list');
      if (expensesString != null) {
        _expenses = (jsonDecode(expensesString) as List)
            .map((item) => ExpenseItem.fromMap(item))
            .toList();
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('total_budget', _totalBudget);
    await prefs.setString(
      'expenses_list',
      jsonEncode(_expenses.map((e) => e.toMap()).toList()),
    );
  }

  void _processTransaction({required bool isIncome}) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final title = _titleController.text.trim();

    if (title.isEmpty || amount <= 0) return;
    if (!isIncome && amount > _totalBudget) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المبلغ أضخم من الميزانية المتاحة!')),
      );
      return;
    }

    setState(() {
      if (isIncome) {
        _totalBudget += amount;
      } else {
        _totalBudget -= amount;
      }

      _expenses.insert(
        0,
        ExpenseItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: isIncome ? 'إيداع: $title' : title,
          amount: amount,
          category: isIncome ? 'إيداع' : _selectedCategory,
          date: DateTime.now(),
          isIncome: isIncome,
        ),
      );
    });

    _saveData();
    _titleController.clear();
    _amountController.clear();
    FocusScope.of(context).unfocus();
  }

  void _deleteTransaction(int index) {
    final item = _expenses[index];
    setState(() {
      if (item.isIncome) {
        _totalBudget -= item.amount;
      } else {
        _totalBudget += item.amount;
      }
      _expenses.removeAt(index);
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterCategory == 'الكل'
        ? _expenses
        : _expenses.where((e) => e.category == _filterCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('مُنظّم المال الذكي'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.web),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const LocalWebScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('رصيد الميزانية الحالية',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text(
                      '${_totalBudget.toStringAsFixed(2)} ج.م',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'البيان أو الاسم',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _processTransaction(isIncome: false),
                    icon: const Icon(Icons.remove),
                    label: const Text('صرف'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _processTransaction(isIncome: true),
                    icon: const Icon(Icons.add),
                    label: const Text('إيداع'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('تصفية الفئات:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _filterCategory,
                  items: ['الكل', 'إيداع', ..._categories]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _filterCategory = v!),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('لا توجد معاملات مسجلة'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) =>
                              _deleteTransaction(_expenses.indexOf(item)),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(item.title),
                              subtitle: Text(
                                '${item.category} • ${item.date.day}/${item.date.month}',
                              ),
                              trailing: Text(
                                '${item.isIncome ? "+" : "-"}${item.amount.toStringAsFixed(2)} ج.م',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: item.isIncome
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ),
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

// شاشة عرض كود HTML / CSS / JavaScript
class LocalWebScreen extends StatefulWidget {
  const LocalWebScreen({super.key});

  @override
  State<LocalWebScreen> createState() => _LocalWebScreenState();
}

class _LocalWebScreenState extends State<LocalWebScreen> {
  late final WebViewController _controller;

  final String htmlContent = '''
    <!DOCTYPE html>
    <html lang="ar">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body {
          font-family: sans-serif;
          background-color: #f4f4f9;
          text-align: center;
          padding: 20px;
        }
        h1 { color: #00796b; }
        button {
          background-color: #00796b;
          color: white;
          border: none;
          padding: 10px 20px;
          border-radius: 5px;
          font-size: 16px;
          cursor: pointer;
        }
      </style>
    </head>
    <body>
      <h1>صفحة HTML / CSS / JS</h1>
      <p id="text">اضغط على الزر لتشغيل JavaScript</p>
      <button onclick="changeText()">اضغط هنا</button>

      <script>
        function changeText() {
          document.getElementById('text').innerText = 'تم تشغيل كود JavaScript بنجاح!';
        }
      </script>
    </body>
    </html>
  ''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معاينة الـ Web')),
      body: WebViewWidget(controller: _controller),
    );
  }
}