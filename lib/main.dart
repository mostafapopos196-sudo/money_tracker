import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AdvancedMoneyTracker());
}

class AdvancedMoneyTracker extends StatelessWidget {
  const AdvancedMoneyTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const MainScreen(),
    );
  }
}

class ExpenseItem {
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isIncome;

  ExpenseItem({required this.title, required this.amount, required this.category, required this.date, required this.isIncome});

  Map<String, dynamic> toMap() => {'title': title, 'amount': amount, 'category': category, 'date': date.toIso8601String(), 'isIncome': isIncome};

  factory ExpenseItem.fromMap(Map<String, dynamic> map) => ExpenseItem(
      title: map['title'], amount: map['amount'], category: map['category'], date: DateTime.parse(map['date']), isIncome: map['isIncome']);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  double _totalBudget = 1000.0;
  List<ExpenseItem> _expenses = [];
  String _selectedCategory = 'أكل وشرب'; // تم تعريف المتغير هنا
  String _filterCategory = 'الكل';

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final List<String> _categories = ['أكل وشرب', 'مواصلات', 'ألعاب وترفيه', 'دراسة ودروس', 'أخرى'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalBudget = prefs.getDouble('total_budget') ?? 1000.0;
      final String? expensesString = prefs.getString('expenses_list');
      if (expensesString != null) {
        _expenses = (jsonDecode(expensesString) as List).map((item) => ExpenseItem.fromMap(item)).toList();
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('total_budget', _totalBudget);
    await prefs.setString('expenses_list', jsonEncode(_expenses.map((e) => e.toMap()).toList()));
  }

  void _addExpense() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (_titleController.text.isEmpty || amount <= 0 || amount > _totalBudget) return;
    setState(() {
      _totalBudget -= amount;
      _expenses.insert(0, ExpenseItem(title: _titleController.text, amount: amount, category: _selectedCategory, date: DateTime.now(), isIncome: false));
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterCategory == 'الكل' ? _expenses : _expenses.where((e) => e.category == _filterCategory).toList();
    
    return Scaffold(
      appBar: AppBar(title: const Text('مُنظّم المال الذكي')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('الميزانية: ${_totalBudget.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24)),
            // مكان الإضافة
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'الاسم')),
            TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'المبلغ'), keyboardType: TextInputType.number),
            DropdownButton<String>(
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            ElevatedButton(onPressed: _addExpense, child: const Text('إضافة')),
            const Divider(),
            // الفلتر
            DropdownButton<String>(
              value: _filterCategory,
              items: ['الكل', ..._categories].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _filterCategory = v!),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => ListTile(title: Text(filtered[i].title), subtitle: Text(filtered[i].category)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}