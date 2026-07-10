import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
      ),
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

  ExpenseItem({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.isIncome,
  });

  // تحويل البيانات لنصوص ليتم حفظها في الجهاز
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'isIncome': isIncome,
    };
  }

  // استرجاع البيانات وتحويلها لكائنات مجدداً عند فتح البرنامج
  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      title: map['title'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      isIncome: map['isIncome'],
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  double _totalBudget = 1000.0;
  List<ExpenseItem> _expenses = []; 

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _budgetController = TextEditingController();
  String _selectedCategory = 'أكل وشرب';

  final List<String> _categories = ['أكل وشرب', 'مواصلات', 'ألعاب وترفيه', 'دراسة ودروس', 'أخرى'];

  @override
  void initState() {
    super.initState();
    _loadData(); // قراءة العمليات القديمة أول ما البرنامج يفتح
  }

  // دالة تحميل البيانات من ذاكرة التخزين
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalBudget = prefs.getDouble('total_budget') ?? 1000.0;
      final String? expensesString = prefs.getString('expenses_list');
      if (expensesString != null) {
        final List<dynamic> decodedList = jsonDecode(expensesString);
        _expenses = decodedList.map((item) => ExpenseItem.fromMap(item)).toList();
      }
    });
  }

  // دالة الحفظ التلقائي في ذاكرة التخزين
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('total_budget', _totalBudget);
    final List<Map<String, dynamic>> encodedList = _expenses.map((item) => item.toMap()).toList();
    await prefs.setString('expenses_list', jsonEncode(encodedList));
  }

  // دالة تسجيل المصاريف (خصم)
  void _addExpense() {
    final enteredTitle = _titleController.text;
    final enteredAmount = double.tryParse(_amountController.text) ?? 0.0;

    if (enteredTitle.isEmpty || enteredAmount <= 0 || enteredAmount > _totalBudget) {
      return; 
    }

    setState(() {
      _totalBudget -= enteredAmount;
      _expenses.insert(
        0,
        ExpenseItem(
          title: enteredTitle,
          amount: enteredAmount,
          category: _selectedCategory,
          date: DateTime.now(),
          isIncome: false,
        ),
      );
    });

    _titleController.clear();
    _amountController.clear();
    _saveData(); // حفظ البيانات فوراً بعد الخصم
  }

  // دالة التحكم في الميزانية وزيادتها (إيداع)
  void _updateBudget() {
    final enteredBudget = double.tryParse(_budgetController.text) ?? 0.0;
    if (enteredBudget <= 0) return;

    setState(() {
      _totalBudget += enteredBudget; 
      _expenses.insert(
        0,
        ExpenseItem(
          title: 'إيداع / زيادة ميزانية',
          amount: enteredBudget,
          category: 'دخل إضافي',
          date: DateTime.now(),
          isIncome: true,
        ),
      );
    });
    _budgetController.clear();
    _saveData(); // حفظ البيانات فوراً بعد الإيداع
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مُنظّم المال الذكي - تحكم كامل'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // كارت الميزانية
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.teal, Colors.teal.shade700]),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text('الميزانية الحالية المتبقية', style: TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 10),
                    Text('${_totalBudget.toStringAsFixed(2)} ج.م', 
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            
            // إضافة ميزانية جديدة
            Card(
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'شحن أو إضافة ميزانية جديدة',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _updateBudget,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('إضافة للميزانية'),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            
            // خانات إضافة مصروف
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'اسم المصروف (صرفت في إيه؟)'),
                    ),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'المبلغ بالضبط'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('تصنيف المصروف:'),
                        DropdownButton<String>(
                          value: _selectedCategory,
                          items: _categories.map((String cat) {
                            return DropdownMenuItem<String>(value: cat, child: Text(cat));
                          }).toList(),
                          onChanged: (val) {
                            setState(() { _selectedCategory = val!; });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _addExpense,
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('إخصم المصروف بدقة'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            
            const Align(
              alignment: Alignment.centerRight,
              child: Text('سجل العمليات التاريخي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
            ),
            const SizedBox(height: 5),
            
            // قائمة عرض العمليات
            Expanded(
              child: _expenses.isEmpty
                  ? const Center(child: Text('لم يتم تسجيل أي عمليات حتى الآن.'))
                  : ListView.builder(
                      itemCount: _expenses.length,
                      itemBuilder: (ctx, index) {
                        final item = _expenses[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: item.isIncome ? Colors.green.shade100 : Colors.red.shade100,
                              child: Text(
                                '${item.isIncome ? '+' : '-'}${item.amount.toInt()}', 
                                style: TextStyle(color: item.isIncome ? Colors.green.shade900 : Colors.red.shade900, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${item.category} • ${DateFormat('yyyy-MM-dd kk:mm').format(item.date)}'),
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