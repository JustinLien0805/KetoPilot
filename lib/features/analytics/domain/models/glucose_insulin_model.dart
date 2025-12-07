/// 葡萄糖-胰島素動態模型
/// 實現簡化的 Bergman Minimal Model
class GlucoseInsulinModel {
  /// 個人化參數
  final ModelParameters parameters;

  GlucoseInsulinModel({required this.parameters});

  /// 計算飲食輸入函數 R_a(t)
  /// 簡化模型：進食後 30 分鐘內 R_a 為常數，之後歸零
  // ignore: non_constant_identifier_names
  double calculateRa(double t, MealData? meal) {
    if (meal == null) return 0.0;

    final timeSinceMeal = t - meal.time;
    if (timeSinceMeal < 0 || timeSinceMeal > 30) {
      return 0.0;
    }

    // 簡化模型：R_a = (f * D * Abs) / V
    // f: 吸收係數, D: 碳水化合物克數, Abs: 吸收率, V: 分佈體積
    const f = 0.8; // 80% 吸收率
    const abs = 0.9; // 90% 可用
    const v = 1.5; // 分佈體積 (L/kg，假設 70kg 約 105L，簡化為 1.5 dL/kg)

    // 轉換：碳水化合物 (g) -> 葡萄糖 (mg/dL/min)
    // 1g 碳水化合物 ≈ 4 kcal，假設全部轉為葡萄糖
    // 簡化計算：每克碳水化合物產生約 0.4 mg/dL/min 的葡萄糖出現率
    return (f * meal.carbsG * abs) / (v * 30.0); // 30分鐘內平均分佈
  }

  /// 計算內源性胰島素分泌函數 phi(G - G_b)
  double calculateInsulinSecretion(double glucose, double basalGlucose) {
    if (glucose <= basalGlucose) return 0.0;

    // 線性反應模型
    // phi = gamma * (G - G_b)
    const gamma = 0.01; // 分泌係數 (μU/mL per mg/dL)
    return gamma * (glucose - basalGlucose);
  }

  /// 使用 Euler 方法求解微分方程系統
  /// 返回預測的血糖曲線數據點
  List<GlucoseDataPoint> simulate({
    required double startTime,
    required double endTime,
    required double timeStep,
    MealData? meal,
  }) {
    // 初始化狀態變數
    double G = parameters.G_b; // 初始血糖 = 基礎值
    double I = parameters.I_b; // 初始胰島素 = 基礎值
    double X = 0.0; // 初始胰島素效應 = 0

    final List<GlucoseDataPoint> points = [];

    // 模擬迴圈
    for (double t = startTime; t <= endTime; t += timeStep) {
      // 計算當下的 R_a (飲食影響)
      // ignore: non_constant_identifier_names
      final Ra = calculateRa(t, meal);

      // 計算內源性胰島素分泌
      final insulinSecretion = calculateInsulinSecretion(G, parameters.G_b);

      // 計算變化率 (Derivatives)
      // dG/dt = -S_I * X * (G - G_b) + R_a - E_G * (G - G_b)
      final dG =
          -parameters.S_I * X * (G - parameters.G_b) +
          Ra -
          parameters.E_G * (G - parameters.G_b);

      // dX/dt = -p_2 * X + p_3 * (I - I_b)
      final dX = -parameters.p_2 * X + parameters.p_3 * (I - parameters.I_b);

      // dI/dt = -n * (I - I_b) + phi(G - G_b)
      final dI = -parameters.n * (I - parameters.I_b) + insulinSecretion;

      // 更新狀態 (Euler Integration)
      G = G + dG * timeStep;
      X = X + dX * timeStep;
      I = I + dI * timeStep;

      // 確保數值在合理範圍內
      G = G.clamp(40.0, 400.0);
      I = I.clamp(0.0, 100.0);
      X = X.clamp(-10.0, 10.0);

      // 每 5 分鐘存一個點（減少數據量，提高圖表效能）
      if ((t - startTime) % 5.0 < timeStep) {
        points.add(
          GlucoseDataPoint(time: t, glucose: G, insulin: I, insulinEffect: X),
        );
      }
    }

    return points;
  }
}

/// 模型參數類
class ModelParameters {
  /// 基礎血糖值 (mg/dL)
  // ignore: non_constant_identifier_names
  final double G_b;

  /// 基礎胰島素值 (μU/mL)
  // ignore: non_constant_identifier_names
  final double I_b;

  /// 胰島素敏感度 (min^-1 per μU/mL)
  // ignore: non_constant_identifier_names
  final double S_I;

  /// 葡萄糖效能 (min^-1)
  // ignore: non_constant_identifier_names
  final double E_G;

  /// 胰島素遠端效應衰減率 (min^-1)
  final double p_2;

  /// 胰島素遠端效應增益 (min^-1 per μU/mL)
  final double p_3;

  /// 胰島素清除率 (min^-1)
  final double n;

  /// 標準人體參數（預設值）
  ModelParameters({
    this.G_b = 90.0, // 正常空腹血糖
    this.I_b = 10.0, // 正常基礎胰島素
    this.S_I = 0.00005, // 胰島素敏感度
    this.E_G = 0.01, // 葡萄糖效能
    this.p_2 = 0.025, // 遠端效應衰減
    this.p_3 = 0.000013, // 遠端效應增益
    this.n = 0.3, // 胰島素清除率
  });
}

/// 飲食數據
class MealData {
  /// 進食時間（分鐘，相對於模擬開始時間）
  final double time;

  /// 碳水化合物克數
  final double carbsG;

  MealData({required this.time, required this.carbsG});
}

/// 血糖數據點
class GlucoseDataPoint {
  /// 時間（分鐘）
  final double time;

  /// 血糖濃度 (mg/dL)
  final double glucose;

  /// 胰島素濃度 (μU/mL)
  final double insulin;

  /// 胰島素效應
  final double insulinEffect;

  GlucoseDataPoint({
    required this.time,
    required this.glucose,
    required this.insulin,
    required this.insulinEffect,
  });
}
