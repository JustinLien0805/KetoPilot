import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/themes/app_theme.dart';
import '../../domain/models/glucose_insulin_model.dart';

/// 葡萄糖-胰島素動態模型圖表 Widget
class GlucoseInsulinChartWidget extends StatelessWidget {
  /// 實測數據點（來自 CGM）
  final List<GlucoseDataPoint> measuredData;

  /// 預測數據點（來自模型模擬）
  final List<GlucoseDataPoint> predictedData;

  /// 進食時間點（分鐘）
  final double? mealTime;

  const GlucoseInsulinChartWidget({
    super.key,
    required this.measuredData,
    required this.predictedData,
    this.mealTime,
  });

  @override
  Widget build(BuildContext context) {
    if (measuredData.isEmpty && predictedData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // 計算時間範圍
    final allTimes = [
      ...measuredData.map((e) => e.time),
      ...predictedData.map((e) => e.time),
    ];
    final minTime = allTimes.isEmpty
        ? 0.0
        : allTimes.reduce((a, b) => a < b ? a : b);
    final maxTime = allTimes.isEmpty
        ? 240.0
        : allTimes.reduce((a, b) => a > b ? a : b);

    // 計算血糖範圍
    final allGlucose = [
      ...measuredData.map((e) => e.glucose),
      ...predictedData.map((e) => e.glucose),
    ];
    final minGlucose = allGlucose.isEmpty
        ? 40.0
        : allGlucose.reduce((a, b) => a < b ? a : b);
    final maxGlucose = allGlucose.isEmpty
        ? 400.0
        : allGlucose.reduce((a, b) => a > b ? a : b);

    // 添加邊距
    final glucoseRange = maxGlucose - minGlucose;
    final glucoseMin = (minGlucose - glucoseRange * 0.1).clamp(40.0, 400.0);
    final glucoseMax = (maxGlucose + glucoseRange * 0.1).clamp(40.0, 400.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Text(
              'Glucose-Insulin Dynamics (Actual vs. Predicted)',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // 圖例
            _buildLegend(context),
            const SizedBox(height: 16),
            // 圖表
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (glucoseMax - glucoseMin) / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.dividerColor.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (maxTime - minTime) / 6,
                        getTitlesWidget: (value, meta) {
                          // 轉換為小時顯示
                          final hours = (value / 60).toStringAsFixed(1);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '$hours h',
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                      axisNameWidget: const Text(
                        'Time',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: (glucoseMax - glucoseMin) / 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                      axisNameWidget: const Text(
                        'Glucose (mg/dL)',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: AppTheme.dividerColor, width: 1),
                  ),
                  minX: minTime,
                  maxX: maxTime,
                  minY: glucoseMin,
                  maxY: glucoseMax,
                  lineBarsData: [
                    // 實測數據（實線，藍色）
                    if (measuredData.isNotEmpty)
                      LineChartBarData(
                        spots: measuredData
                            .map((point) => FlSpot(point.time, point.glucose))
                            .toList(),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.blue,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(show: false),
                      ),
                    // 預測數據（虛線，橙色）
                    if (predictedData.isNotEmpty)
                      LineChartBarData(
                        spots: predictedData
                            .map((point) => FlSpot(point.time, point.glucose))
                            .toList(),
                        isCurved: true,
                        color: Colors.orange,
                        barWidth: 2,
                        dashArray: [5, 5], // 虛線
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                  ],
                  // 進食時間標記
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          return LineTooltipItem(
                            '${touchedSpot.y.toInt()} mg/dL\n${(touchedSpot.x / 60).toStringAsFixed(1)} h',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  // 進食時間垂直線
                  extraLinesData: mealTime != null
                      ? ExtraLinesData(
                          verticalLines: [
                            VerticalLine(
                              x: mealTime!,
                              color: Colors.red.withValues(alpha: 0.5),
                              strokeWidth: 2,
                              dashArray: [5, 5],
                              label: VerticalLineLabel(
                                show: true,
                                alignment: Alignment.topRight,
                                padding: const EdgeInsets.only(right: 4),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (measuredData.isNotEmpty) _buildLegendItem('Actual', Colors.blue),
        if (measuredData.isNotEmpty && predictedData.isNotEmpty)
          const SizedBox(width: 16),
        if (predictedData.isNotEmpty)
          _buildLegendItem('Predicted', Colors.orange),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
