import 'package:flutter/material.dart';

class CostStatisticsScreen extends StatelessWidget {
  const CostStatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê chi phí'),
      ),
      body: const Center(
        child: Text(
          'Trang thống kê chi phí (Cost Statistics)',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
