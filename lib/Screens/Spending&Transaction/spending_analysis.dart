import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend_vesta/Screens/Spending&Transaction/transactions.dart';

class SpendingAnalysis extends StatefulWidget {
  const SpendingAnalysis({super.key});

  @override
  State<SpendingAnalysis> createState() => _SpendingAnalysisPageState();
}

class _SpendingAnalysisPageState extends State<SpendingAnalysis> {
  int _selectedTab = 0;
  String _selectedType = "Expense";

  final List<String> _tabs = ["Day", "Week", "Month", "Year"];

  final List<Map<String, dynamic>> _spending = [
    {
      "label": "Food And Drinks",
      "amount": -150.0,
      "color": Colors.blue,
      "icon": Icons.restaurant,
    },
    {
      "label": "Groceries",
      "amount": -150.0,
      "color": Colors.amber,
      "icon": Icons.shopping_bag,
    },
    {
      "label": "Entertainment",
      "amount": -150.0,
      "color": Colors.orange,
      "icon": Icons.movie,
    },
    {
      "label": "Others",
      "amount": -200.0,
      "color": Colors.black87,
      "icon": Icons.more_horiz,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Spending Analysis"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Toggle Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                _tabs.length,
                (index) => ChoiceChip(
                  label: Text(_tabs[index]),
                  selected: _selectedTab == index,
                  checkmarkColor: Colors.white,
                  onSelected: (_) => setState(() => _selectedTab = index),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: _selectedTab == index ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chart + Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedType,
                  items: ["Expense", "Income"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedType = val!),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Donut Chart
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _spending.map((s) {
                    return PieChartSectionData(
                      color: s["color"],
                      value: s["amount"].abs(),
                      title: "${((s["amount"].abs() / 650) * 100).round()}%",
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      radius: 60,
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                ),
              ),
            ),

            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text(
                    "Top Spendings",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Transactions(),
                        ),
                      );
                    },
                    child: Text(
                      "All Transactions",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // List of categories
            Expanded(
              child: ListView.builder(
                itemCount: _spending.length,
                itemBuilder: (context, index) {
                  final item = _spending[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item["color"].withOpacity(0.2),
                        child: Icon(item["icon"], color: item["color"]),
                      ),
                      title: Text(item["label"]),
                      subtitle: const Text("Jan 12, 2022"), // sample date
                      trailing: Text(
                        "${item["amount"] < 0 ? "-" : "+"} JOD ${item["amount"].abs().toStringAsFixed(2)}",
                        style: TextStyle(
                          color: item["amount"] < 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
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
