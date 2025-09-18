import 'package:flutter/material.dart';

class PersonalBudgetScreen extends StatefulWidget {
  const PersonalBudgetScreen({super.key});

  @override
  State<PersonalBudgetScreen> createState() => _PersonalBudgetScreenState();
}

class _PersonalBudgetScreenState extends State<PersonalBudgetScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Budget'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Personal Budget Screen Content'),
      ),
    );
  }
}