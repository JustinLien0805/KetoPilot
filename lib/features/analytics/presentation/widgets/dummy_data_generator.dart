import 'dart:math';

import '../../domain/models/glucose_insulin_model.dart';

/// 生成 Dummy Data 的工具類
class DummyDataGenerator {
  static final Random _random = Random();

  /// 生成實測數據（模擬 CGM 數據）
  /// 添加一些隨機噪聲以模擬真實測量
  static List<GlucoseDataPoint> generateMeasuredData({
    required double startTime,
    required double endTime,
    required double interval, // 採樣間隔（分鐘）
    required double basalGlucose,
    MealData? meal,
  }) {
    final List<GlucoseDataPoint> points = [];
    double currentGlucose = basalGlucose;

    for (double t = startTime; t <= endTime; t += interval) {
      // 基礎血糖波動（小幅隨機變化）
      final noise = (_random.nextDouble() - 0.5) * 5.0; // ±2.5 mg/dL

      // 如果有進食，模擬餐後血糖上升
      if (meal != null && t >= meal.time) {
        final timeSinceMeal = t - meal.time;
        if (timeSinceMeal <= 120) {
          // 餐後 2 小時內血糖上升
          final peakTime = 60.0; // 峰值在餐後 60 分鐘
          final peakGlucose =
              basalGlucose + (meal.carbsG * 2.0); // 每克碳水約上升 2 mg/dL
          final glucoseIncrease =
              peakGlucose *
              exp(-pow((timeSinceMeal - peakTime) / 40.0, 2)); // 高斯分佈
          currentGlucose = basalGlucose + glucoseIncrease;
        } else {
          // 2 小時後逐漸回到基礎值
          final decay = exp(-(timeSinceMeal - 120) / 60.0);
          currentGlucose =
              basalGlucose + (currentGlucose - basalGlucose) * decay;
        }
      }

      // 添加測量噪聲
      currentGlucose += noise;
      currentGlucose = currentGlucose.clamp(40.0, 400.0);

      points.add(
        GlucoseDataPoint(
          time: t,
          glucose: currentGlucose,
          insulin: 10.0 + _random.nextDouble() * 5.0, // 模擬胰島素值
          insulinEffect: 0.0,
        ),
      );
    }

    return points;
  }

  /// 生成預測數據（使用模型模擬）
  static List<GlucoseDataPoint> generatePredictedData({
    required double startTime,
    required double endTime,
    required double timeStep,
    required ModelParameters parameters,
    MealData? meal,
  }) {
    final model = GlucoseInsulinModel(parameters: parameters);
    return model.simulate(
      startTime: startTime,
      endTime: endTime,
      timeStep: timeStep,
      meal: meal,
    );
  }

  /// 生成完整的圖表數據（實測 + 預測）
  static ChartData generateChartData({
    double startTime = -30.0, // 餐前 30 分鐘
    double endTime = 180.0, // 餐後 180 分鐘
    double mealTime = 0.0, // 進食時間（設為 0，即模擬開始後立即進食）
    double mealCarbs = 50.0, // 50 克碳水化合物
    ModelParameters? parameters,
  }) {
    final params = parameters ?? ModelParameters();
    final meal = MealData(time: mealTime, carbsG: mealCarbs);

    // 生成實測數據（每 5 分鐘一個點，模擬 CGM）
    final measuredData = generateMeasuredData(
      startTime: startTime,
      endTime: endTime,
      interval: 5.0,
      basalGlucose: params.G_b,
      meal: meal,
    );

    // 生成預測數據（使用模型模擬，每 1 分鐘計算一次）
    final predictedData = generatePredictedData(
      startTime: startTime,
      endTime: endTime,
      timeStep: 1.0,
      parameters: params,
      meal: meal,
    );

    return ChartData(
      measuredData: measuredData,
      predictedData: predictedData,
      mealTime: mealTime,
    );
  }
}

/// 圖表數據容器
class ChartData {
  final List<GlucoseDataPoint> measuredData;
  final List<GlucoseDataPoint> predictedData;
  final double? mealTime;

  ChartData({
    required this.measuredData,
    required this.predictedData,
    this.mealTime,
  });
}
