import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/themes/app_theme.dart';
import '../widgets/glucose_insulin_chart_widget.dart';
import '../widgets/dummy_data_generator.dart';

@RoutePage()
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  late ChartData _chartData;

  @override
  void initState() {
    super.initState();
    // 生成 dummy data
    _chartData = DummyDataGenerator.generateChartData(
      startTime: -30.0, // 餐前 30 分鐘
      endTime: 180.0, // 餐後 180 分鐘
      mealTime: 0.0, // 進食時間（模擬開始時）
      mealCarbs: 50.0, // 50 克碳水化合物
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          Text(
            'Analytics & Reports',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'View trends and insights from your health data',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          // 葡萄糖-胰島素動態模型圖表
          GlucoseInsulinChartWidget(
            measuredData: _chartData.measuredData,
            predictedData: _chartData.predictedData,
            mealTime: _chartData.mealTime,
          ),
          const SizedBox(height: 24),
          // 預留給其他兩個圖表的空間
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Charts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Two more graphs will be displayed here.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
