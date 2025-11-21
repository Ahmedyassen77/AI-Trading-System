"""
Simple Test Strategy - للتأكد أن كل شيء يعمل
منطق بسيط: إذا الشمعة خضراء → BUY، إذا حمراء → SELL
"""

import pandas as pd


class SimpleStrategy:
    """استراتيجية بسيطة للاختبار"""
    
    def __init__(self, config: dict):
        self.symbol = config.get('symbol', 'EURUSD')
        self.sl_points = config.get('sl_points', 150)
        self.tp_points = config.get('tp_points', 300)
        self.risk = config.get('risk_pct', 1.0)
        
    def generate_signals(self, df: pd.DataFrame) -> list:
        """
        يولد الإشارات من DataFrame
        
        Args:
            df: DataFrame يحتوي على ['time', 'open', 'close', 'high', 'low']
            
        Returns:
            قائمة من الإشارات بتنسيق dict
        """
        signals = []
        
        for i in range(1, len(df)):
            row = df.iloc[i]
            
            # الشمعة الحالية
            close = float(row['close'])
            open_price = float(row['open'])
            timestamp = row['time']
            
            # منطق بسيط: شمعة خضراء = BUY، شمعة حمراء = SELL
            if close > open_price:
                action = 'BUY'
                entry_price = close
                sl = entry_price - (self.sl_points * 0.00001)
                tp = entry_price + (self.tp_points * 0.00001)
                comment = 'green_candle_buy'
            else:
                action = 'SELL'
                entry_price = close
                sl = entry_price + (self.sl_points * 0.00001)
                tp = entry_price - (self.tp_points * 0.00001)
                comment = 'red_candle_sell'
            
            signal = {
                'timestamp': timestamp.strftime('%Y-%m-%dT%H:%M:%SZ'),
                'symbol': self.symbol,
                'action': action,
                'price': round(entry_price, 5),
                'sl': round(sl, 5),
                'tp': round(tp, 5),
                'risk': self.risk,
                'comment': comment
            }
            
            signals.append(signal)
            
        return signals
