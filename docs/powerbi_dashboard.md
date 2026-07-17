# Power BI 看板说明

## 页面结构

### 1. 经营概览

- 核心指标：总行为数、活跃用户数、交易金额估算、用户购买转化率。
- 趋势指标：每日行为数、每日交易金额估算。
- 转化指标：用户级宽松浏览、加购和购买漏斗。

### 2. 转化与品类

- 对比用户级宽松、会话级宽松和会话级严格浏览至购买转化率。
- 展示交易金额估算 TOP10 与有效购买事件 TOP10 品类。
- 识别高流量但低于整体加权转化基准的品类，并展示转化缺口。

### 3. RFM 用户价值

- 展示购买用户数、重要价值用户占比、金额贡献和挽留用户占比。
- 对比八类 RFM 人群的用户规模与金额贡献。
- 使用气泡散点图同时表达平均最近购买间隔、人均消费金额和用户规模。

## 数据来源

看板使用 SQL 脚本生成的日粒度、漏斗、品类与 RFM 汇总结果。原始明细数据不直接加载到看板，避免将约 2,000 万行行为日志全部导入 Power BI。

主要输入包括：

- `ecommerce_daily_metrics`：由 `sql/05_daily_metrics.sql` 生成。
- `results/core_metrics.csv`
- `results/funnel_summary.csv`
- `results/category_amount_top10.csv`
- `results/category_purchase_top10.csv`
- `results/high_traffic_low_conversion_categories.csv`
- `results/rfm_segment_summary.csv`

## 关键 DAX

### 用户级宽松浏览至购买转化率

```DAX
用户级宽松转化率 =
CALCULATE(
    DIVIDE(
        MAX(funnel_summary[view_to_purchase_pct]),
        100
    ),
    funnel_summary[funnel_type] = "user_loose"
)
```

### RFM 重要价值用户金额贡献

```DAX
重要价值用户金额贡献 =
CALCULATE(
    DIVIDE(
        MAX(rfm_segment_summary[monetary_share_pct]),
        100
    ),
    rfm_segment_summary[customer_segment] = "重要价值用户"
)
```

### RFM 挽留用户占比

```DAX
挽留用户占比 =
DIVIDE(
    CALCULATE(
        SUM(rfm_segment_summary[user_count]),
        rfm_segment_summary[customer_segment]
            IN {
                "重要挽留用户",
                "一般挽留用户"
            }
    ),
    SUM(rfm_segment_summary[user_count])
)
```

### 动态分群金额贡献率

```DAX
分群金额贡献率 =
DIVIDE(
    SUM(rfm_segment_summary[total_monetary_value]),
    CALCULATE(
        SUM(rfm_segment_summary[total_monetary_value]),
        ALL(rfm_segment_summary[customer_segment])
    )
)
```

## 口径提醒

- 交易金额为有效购买事件 `price` 之和，不是严格 GMV。
- 购买事件不是订单，平均购买事件金额不是客单价。
- 用户级宽松漏斗允许跨会话，不检查行为顺序。
- 会话级严格漏斗使用首次 `view < cart < purchase` 的时间条件。
- RFM 的 F 使用去重购买会话数作为订单频次代理。

完整指标定义见 [metric_dictionary.md](metric_dictionary.md)，业务结论见 [findings.md](findings.md)。
