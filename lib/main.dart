import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final bool isIncome; // لتحديد هل هي إضافة فلوس ولا صرف

  ExpenseItem({
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.isIncome,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  double _totalBudget = 1000.0; // الميزانية الابتدائية
  final List<ExpenseItem> _expenses = []; 

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _budgetController = TextEditingController(); // كنترولر للتحكم في الميزانية
  String _selectedCategory = 'أكل وشرب';

  final List<String> _categories = ['أكل وشرب', 'مواصلات', 'ألعاب وترفيه', 'دراسة ودروس', 'أخرى'];

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
  }

  // دالة التحكم في الميزانية وزيادتها
  void _updateBudget() {
    final enteredBudget = double.tryParse(_budgetController.text) ?? 0.0;
    if (enteredBudget <= 0) return;

    setState(() {
      _totalBudget += enteredBudget; // هيزود المبلغ اللي كتبته على ميزانيتك الحالية
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
            
            // القسم الجديد: التحكم في الميزانية وزيادتها
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
            
            // قائمة العمليات (عرض المصاريف باللون الأحمر، والإيداع باللون الأخضر دقة عالية)
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