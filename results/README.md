# Results Directory

هذا المجلد يحتوي على نتائج الباكتيستات

## Structure

```
results/
├── backtest_report.html        # تقرير MT5 الكامل
├── test_001_report.html        # تقرير اختبار محدد
├── test_001_summary.json       # ملخص النتائج بصيغة JSON
└── analysis/                   # تحليلات إضافية
```

## JSON Summary Format

```json
{
  "test_id": "test_001",
  "strategy": "simple_strategy",
  "symbol": "EURUSD",
  "timeframe": "M15",
  "period": {
    "from": "2024-01-01",
    "to": "2024-12-31"
  },
  "results": {
    "initial_deposit": 10000,
    "final_balance": 10500,
    "profit": 500,
    "profit_percent": 5.0,
    "total_trades": 100,
    "winning_trades": 60,
    "losing_trades": 40,
    "win_rate": 60.0,
    "max_drawdown": 250,
    "max_drawdown_percent": 2.5,
    "profit_factor": 1.5,
    "sharpe_ratio": 1.2
  },
  "generated_at": "2024-11-21T12:00:00Z"
}
```
