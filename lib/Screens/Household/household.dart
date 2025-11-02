import 'package:flutter/material.dart';

class HouseholdPage extends StatefulWidget {
  const HouseholdPage({super.key});

  @override
  State<HouseholdPage> createState() => _HouseholdPageState();
}

class _HouseholdPageState extends State<HouseholdPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HouseholdPage Analysis'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('HouseholdPage Analysis Screen Content'),
      ),
    );
  }
}