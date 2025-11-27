"""
Smart Money Concepts (SMC) Strategy
استراتيجية كاملة تطبق كل مفاهيم SMC مع التظليل والرسم
"""

import pandas as pd
import numpy as np
from datetime import datetime, timezone
from typing import List, Dict, Tuple, Optional


class SMCStrategy:
    """
    استراتيجية SMC كاملة مع:
    - HTF Bias
    - Liquidity Zones (External/Internal)
    - Sweep Detection
    - CHoCH & BOS
    - Order Blocks (OB)
    - Fair Value Gaps (FVG)
    - Asian Session Filter
    """
    
    def __init__(self, config: dict):
        self.symbol = config.get('symbol', 'EURUSD')
        self.htf = config.get('htf_timeframe', 'H4')
        self.mtf = config.get('mtf_timeframe', 'M15')
        self.ltf = config.get('ltf_timeframe', 'M5')
        
        # Swing Detection Parameters
        self.swing_lookback = config.get('swing_lookback', 3)
        self.sweep_threshold = config.get('sweep_threshold', 0.0001)
        
        # Risk Management
        self.risk_pct = config.get('risk_pct', 1.0)
        self.min_rr = config.get('min_rr', 2.0)
        
        # Session Times (UTC)
        self.asian_start = 23
        self.asian_end = 7
        self.london_start = 7
        
        # Drawing Colors
        self.colors = {
            'bullish_bias': 'green_light',
            'bearish_bias': 'red_light',
            'bullish_ob': 'green',
            'bearish_ob': 'red',
            'fvg': 'yellow',
            'liquidity_high': 'orange',
            'liquidity_low': 'blue',
            'sweep': 'purple',
            'choch': 'cyan',
            'bos': 'magenta'
        }
        
        # State
        self.htf_bias = None  # 'bullish' or 'bearish'
        self.swing_highs = []
        self.swing_lows = []
        
    # ==========================================
    # 1. HTF BIAS DETECTION
    # ==========================================
    
    def detect_swing_points(self, df: pd.DataFrame) -> Tuple[List, List]:
        """كشف القمم والقيعان الهيكلية"""
        highs = []
        lows = []
        
        for i in range(self.swing_lookback, len(df) - self.swing_lookback):
            # Swing High
            is_high = True
            for j in range(1, self.swing_lookback + 1):
                if df.iloc[i]['high'] <= df.iloc[i-j]['high'] or \
                   df.iloc[i]['high'] <= df.iloc[i+j]['high']:
                    is_high = False
                    break
            
            if is_high:
                highs.append({
                    'index': i,
                    'time': df.iloc[i]['time'],
                    'price': df.iloc[i]['high'],
                    'type': 'swing_high'
                })
            
            # Swing Low
            is_low = True
            for j in range(1, self.swing_lookback + 1):
                if df.iloc[i]['low'] >= df.iloc[i-j]['low'] or \
                   df.iloc[i]['low'] >= df.iloc[i+j]['low']:
                    is_low = False
                    break
            
            if is_low:
                lows.append({
                    'index': i,
                    'time': df.iloc[i]['time'],
                    'price': df.iloc[i]['low'],
                    'type': 'swing_low'
                })
        
        return highs, lows
    
    def detect_bos_choch(self, df: pd.DataFrame, highs: List, lows: List) -> List:
        """كشف BOS و CHoCH"""
        events = []
        
        if len(highs) < 2 or len(lows) < 2:
            return events
        
        # تتبع آخر قمة/قاع مكسور
        last_broken_high = None
        last_broken_low = None
        current_bias = None
        
        for i in range(len(df)):
            current_high = df.iloc[i]['high']
            current_low = df.iloc[i]['low']
            current_close = df.iloc[i]['close']
            
            # فحص كسر القمم
            for sh in highs:
                if sh['index'] < i and current_close > sh['price']:
                    if last_broken_high is None or sh['price'] > last_broken_high:
                        # تحديد إذا كان BOS أو CHoCH
                        if current_bias == 'bearish':
                            event_type = 'choch_bullish'
                            current_bias = 'bullish'
                        else:
                            event_type = 'bos_bullish'
                            current_bias = 'bullish'
                        
                        events.append({
                            'index': i,
                            'time': df.iloc[i]['time'],
                            'type': event_type,
                            'price': sh['price'],
                            'direction': 'bullish'
                        })
                        last_broken_high = sh['price']
            
            # فحص كسر القيعان
            for sl in lows:
                if sl['index'] < i and current_close < sl['price']:
                    if last_broken_low is None or sl['price'] < last_broken_low:
                        # تحديد إذا كان BOS أو CHoCH
                        if current_bias == 'bullish':
                            event_type = 'choch_bearish'
                            current_bias = 'bearish'
                        else:
                            event_type = 'bos_bearish'
                            current_bias = 'bearish'
                        
                        events.append({
                            'index': i,
                            'time': df.iloc[i]['time'],
                            'type': event_type,
                            'price': sl['price'],
                            'direction': 'bearish'
                        })
                        last_broken_low = sl['price']
        
        return events
    
    def determine_htf_bias(self, df: pd.DataFrame) -> str:
        """تحديد الاتجاه العام على HTF"""
        highs, lows = self.detect_swing_points(df)
        events = self.detect_bos_choch(df, highs, lows)
        
        if not events:
            return 'neutral'
        
        # آخر حدث يحدد الـ Bias
        last_event = events[-1]
        
        if 'bullish' in last_event['type']:
            return 'bullish'
        elif 'bearish' in last_event['type']:
            return 'bearish'
        
        return 'neutral'
    
    # ==========================================
    # 2. LIQUIDITY ZONES
    # ==========================================
    
    def detect_liquidity_zones(self, df: pd.DataFrame, highs: List, lows: List) -> Dict:
        """كشف مناطق السيولة External و Internal"""
        liquidity = {
            'external_highs': [],
            'external_lows': [],
            'internal_highs': [],
            'internal_lows': []
        }
        
        # External Liquidity - Double Tops
        for i in range(len(highs) - 1):
            h1 = highs[i]
            h2 = highs[i + 1]
            price_diff = abs(h1['price'] - h2['price']) / h1['price']
            
            if price_diff < 0.003:  # 0.3% threshold
                liquidity['external_highs'].append({
                    'time': h2['time'],
                    'price': max(h1['price'], h2['price']),
                    'type': 'double_top'
                })
        
        # External Liquidity - Double Bottoms
        for i in range(len(lows) - 1):
            l1 = lows[i]
            l2 = lows[i + 1]
            price_diff = abs(l1['price'] - l2['price']) / l1['price']
            
            if price_diff < 0.003:
                liquidity['external_lows'].append({
                    'time': l2['time'],
                    'price': min(l1['price'], l2['price']),
                    'type': 'double_bottom'
                })
        
        # بارز Highs/Lows كـ External Liquidity
        if highs:
            liquidity['external_highs'].append({
                'time': highs[-1]['time'],
                'price': highs[-1]['price'],
                'type': 'swing_high'
            })
        
        if lows:
            liquidity['external_lows'].append({
                'time': lows[-1]['time'],
                'price': lows[-1]['price'],
                'type': 'swing_low'
            })
        
        return liquidity
    
    # ==========================================
    # 3. SWEEP DETECTION
    # ==========================================
    
    def detect_sweeps(self, df: pd.DataFrame, liquidity: Dict) -> List:
        """كشف Sweep للسيولة"""
        sweeps = []
        
        # Sweep External Highs
        for liq in liquidity['external_highs']:
            for i in range(len(df)):
                if df.iloc[i]['time'] > liq['time']:
                    # اخترق القمة
                    if df.iloc[i]['high'] > liq['price']:
                        # ثم أغلق أسفلها
                        if df.iloc[i]['close'] < liq['price']:
                            sweeps.append({
                                'index': i,
                                'time': df.iloc[i]['time'],
                                'type': 'sweep_high',
                                'price': liq['price'],
                                'direction': 'bearish'
                            })
                            break
        
        # Sweep External Lows
        for liq in liquidity['external_lows']:
            for i in range(len(df)):
                if df.iloc[i]['time'] > liq['time']:
                    # اخترق القاع
                    if df.iloc[i]['low'] < liq['price']:
                        # ثم أغلق فوقه
                        if df.iloc[i]['close'] > liq['price']:
                            sweeps.append({
                                'index': i,
                                'time': df.iloc[i]['time'],
                                'type': 'sweep_low',
                                'price': liq['price'],
                                'direction': 'bullish'
                            })
                            break
        
        return sweeps
    
    # ==========================================
    # 4. ORDER BLOCKS (OB)
    # ==========================================
    
    def is_asian_session(self, timestamp) -> bool:
        """فحص إذا كانت الشمعة في الجلسة الآسيوية"""
        hour = timestamp.hour
        if self.asian_start > self.asian_end:
            return hour >= self.asian_start or hour < self.asian_end
        else:
            return self.asian_start <= hour < self.asian_end
    
    def detect_order_blocks(self, df: pd.DataFrame, events: List) -> List:
        """كشف Order Blocks بعد BOS/CHoCH"""
        order_blocks = []
        
        for event in events:
            if 'choch' not in event['type'] and 'bos' not in event['type']:
                continue
            
            event_idx = event['index']
            direction = event['direction']
            
            # ابحث عن آخر شمعة معاكسة قبل الحركة
            for i in range(event_idx - 1, max(0, event_idx - 10), -1):
                candle = df.iloc[i]
                
                # تجاهل الجلسة الآسيوية
                if self.is_asian_session(candle['time']):
                    continue
                
                is_bullish_candle = candle['close'] > candle['open']
                is_bearish_candle = candle['close'] < candle['open']
                
                # Bullish OB: آخر شمعة هابطة قبل حركة صاعدة
                if direction == 'bullish' and is_bearish_candle:
                    order_blocks.append({
                        'time': candle['time'],
                        'type': 'bullish_ob',
                        'high': candle['high'],
                        'low': candle['low'],
                        'open': candle['open'],
                        'close': candle['close'],
                        'direction': 'bullish'
                    })
                    break
                
                # Bearish OB: آخر شمعة صاعدة قبل حركة هابطة
                if direction == 'bearish' and is_bullish_candle:
                    order_blocks.append({
                        'time': candle['time'],
                        'type': 'bearish_ob',
                        'high': candle['high'],
                        'low': candle['low'],
                        'open': candle['open'],
                        'close': candle['close'],
                        'direction': 'bearish'
                    })
                    break
        
        return order_blocks
    
    # ==========================================
    # 5. FAIR VALUE GAPS (FVG)
    # ==========================================
    
    def detect_fvg(self, df: pd.DataFrame) -> List:
        """كشف Fair Value Gaps"""
        fvgs = []
        
        for i in range(2, len(df)):
            candle_1 = df.iloc[i - 2]
            candle_2 = df.iloc[i - 1]
            candle_3 = df.iloc[i]
            
            # Bullish FVG
            if candle_3['low'] > candle_1['high']:
                fvgs.append({
                    'time': candle_3['time'],
                    'type': 'bullish_fvg',
                    'top': candle_3['low'],
                    'bottom': candle_1['high'],
                    'direction': 'bullish'
                })
            
            # Bearish FVG
            if candle_3['high'] < candle_1['low']:
                fvgs.append({
                    'time': candle_3['time'],
                    'type': 'bearish_fvg',
                    'top': candle_1['low'],
                    'bottom': candle_3['high'],
                    'direction': 'bearish'
                })
        
        return fvgs
    
    # ==========================================
    # 6. ENTRY LOGIC
    # ==========================================
    
    def check_confirmation_candle(self, df: pd.DataFrame, idx: int) -> Optional[str]:
        """فحص شمعة التأكيد (Engulfing أو Inside Bar)"""
        if idx < 1:
            return None
        
        current = df.iloc[idx]
        previous = df.iloc[idx - 1]
        
        current_body = abs(current['close'] - current['open'])
        previous_body = abs(previous['close'] - previous['open'])
        
        # Bullish Engulfing
        if (current['close'] > current['open'] and 
            previous['close'] < previous['open'] and
            current['open'] <= previous['close'] and
            current['close'] >= previous['open']):
            return 'bullish_engulfing'
        
        # Bearish Engulfing
        if (current['close'] < current['open'] and 
            previous['close'] > previous['open'] and
            current['open'] >= previous['close'] and
            current['close'] <= previous['open']):
            return 'bearish_engulfing'
        
        # Inside Bar
        if (current['high'] <= previous['high'] and 
            current['low'] >= previous['low']):
            return 'inside_bar'
        
        return None
    
    def generate_signals(self, df: pd.DataFrame) -> Dict:
        """
        توليد إشارات التداول مع معلومات الرسم
        
        Returns:
            Dict يحتوي على:
            - signals: قائمة الإشارات للتداول
            - drawings: قائمة الرسومات للشارت
        """
        
        # تحديد HTF Bias
        self.htf_bias = self.determine_htf_bias(df)
        
        # كشف Swing Points
        highs, lows = self.detect_swing_points(df)
        self.swing_highs = highs
        self.swing_lows = lows
        
        # كشف BOS/CHoCH
        events = self.detect_bos_choch(df, highs, lows)
        
        # كشف Liquidity
        liquidity = self.detect_liquidity_zones(df, highs, lows)
        
        # كشف Sweeps
        sweeps = self.detect_sweeps(df, liquidity)
        
        # كشف Order Blocks
        order_blocks = self.detect_order_blocks(df, events)
        
        # كشف FVGs
        fvgs = self.detect_fvg(df)
        
        # إعداد الرسومات
        drawings = self._prepare_drawings(
            df, highs, lows, events, liquidity, 
            sweeps, order_blocks, fvgs
        )
        
        # توليد إشارات التداول
        signals = self._generate_trade_signals(
            df, sweeps, events, order_blocks, fvgs
        )
        
        return {
            'signals': signals,
            'drawings': drawings,
            'htf_bias': self.htf_bias,
            'stats': {
                'swing_highs': len(highs),
                'swing_lows': len(lows),
                'bos_choch_events': len(events),
                'sweeps': len(sweeps),
                'order_blocks': len(order_blocks),
                'fvgs': len(fvgs),
                'signals': len(signals)
            }
        }
    
    def _prepare_drawings(self, df, highs, lows, events, liquidity, 
                         sweeps, order_blocks, fvgs) -> List:
        """تجهيز معلومات الرسم للشارت"""
        drawings = []
        
        # 1. HTF Bias Background
        if self.htf_bias:
            drawings.append({
                'type': 'background',
                'object': 'htf_bias',
                'color': self.colors[f'{self.htf_bias}_bias'],
                'label': f'HTF Bias: {self.htf_bias.upper()}'
            })
        
        # 2. Swing Highs/Lows
        for sh in highs[-5:]:  # آخر 5 قمم
            drawings.append({
                'type': 'line',
                'object': 'swing_high',
                'time': sh['time'],
                'price': sh['price'],
                'color': 'orange',
                'label': 'SH'
            })
        
        for sl in lows[-5:]:  # آخر 5 قيعان
            drawings.append({
                'type': 'line',
                'object': 'swing_low',
                'time': sl['time'],
                'price': sl['price'],
                'color': 'blue',
                'label': 'SL'
            })
        
        # 3. BOS/CHoCH Events
        for event in events[-10:]:
            drawings.append({
                'type': 'arrow',
                'object': event['type'],
                'time': event['time'],
                'price': event['price'],
                'color': self.colors['bos'] if 'bos' in event['type'] else self.colors['choch'],
                'label': event['type'].upper(),
                'direction': event['direction']
            })
        
        # 4. Liquidity Zones
        for liq in liquidity['external_highs'][-3:]:
            drawings.append({
                'type': 'rectangle',
                'object': 'liquidity_high',
                'time': liq['time'],
                'price': liq['price'],
                'height': 0.0010,  # 10 pips
                'color': self.colors['liquidity_high'],
                'label': 'External Liq HIGH'
            })
        
        for liq in liquidity['external_lows'][-3:]:
            drawings.append({
                'type': 'rectangle',
                'object': 'liquidity_low',
                'time': liq['time'],
                'price': liq['price'],
                'height': 0.0010,
                'color': self.colors['liquidity_low'],
                'label': 'External Liq LOW'
            })
        
        # 5. Sweeps
        for sweep in sweeps[-5:]:
            drawings.append({
                'type': 'marker',
                'object': 'sweep',
                'time': sweep['time'],
                'price': sweep['price'],
                'color': self.colors['sweep'],
                'label': f"SWEEP {sweep['type'].split('_')[1].upper()}",
                'marker': 'X'
            })
        
        # 6. Order Blocks
        for ob in order_blocks[-5:]:
            drawings.append({
                'type': 'rectangle',
                'object': ob['type'],
                'time': ob['time'],
                'price_high': ob['high'],
                'price_low': ob['low'],
                'color': self.colors[ob['type']],
                'label': ob['type'].upper().replace('_', ' '),
                'extend': True
            })
        
        # 7. Fair Value Gaps
        for fvg in fvgs[-5:]:
            drawings.append({
                'type': 'rectangle',
                'object': fvg['type'],
                'time': fvg['time'],
                'price_high': fvg['top'],
                'price_low': fvg['bottom'],
                'color': self.colors['fvg'],
                'label': 'FVG',
                'extend': True
            })
        
        return drawings
    
    def _generate_trade_signals(self, df, sweeps, events, order_blocks, fvgs) -> List:
        """توليد إشارات التداول الفعلية"""
        signals = []
        
        # منطق الدخول:
        # 1. Sweep حدث
        # 2. CHoCH تأكيدي بعده
        # 3. دخول السعر لـ OB أو FVG
        # 4. شمعة تأكيد
        
        for sweep_idx, sweep in enumerate(sweeps):
            # ابحث عن CHoCH بعد Sweep
            choch_after_sweep = None
            for event in events:
                if (event['time'] > sweep['time'] and 
                    'choch' in event['type'] and
                    event['direction'] == sweep['direction']):
                    choch_after_sweep = event
                    break
            
            if not choch_after_sweep:
                continue
            
            # ابحث عن OB أو FVG بعد CHoCH
            entry_zone = None
            for ob in order_blocks:
                if (ob['time'] > choch_after_sweep['time'] and
                    ob['direction'] == sweep['direction']):
                    entry_zone = ob
                    break
            
            if not entry_zone:
                for fvg in fvgs:
                    if (fvg['time'] > choch_after_sweep['time'] and
                        fvg['direction'] == sweep['direction']):
                        entry_zone = fvg
                        break
            
            if not entry_zone:
                continue
            
            # ابحث عن لمسة السعر للـ entry zone وشمعة تأكيد
            for i in range(len(df)):
                candle = df.iloc[i]
                if candle['time'] <= entry_zone['time']:
                    continue
                
                # فحص لمسة OB/FVG
                in_zone = False
                if 'ob' in entry_zone.get('type', ''):
                    in_zone = (candle['low'] <= entry_zone['high'] and 
                              candle['high'] >= entry_zone['low'])
                elif 'fvg' in entry_zone.get('type', ''):
                    in_zone = (candle['low'] <= entry_zone['top'] and 
                              candle['high'] >= entry_zone['bottom'])
                
                if not in_zone:
                    continue
                
                # فحص شمعة تأكيد
                confirmation = self.check_confirmation_candle(df, i)
                if not confirmation:
                    continue
                
                # حساب SL و TP
                if sweep['direction'] == 'bullish':
                    entry_price = candle['close']
                    sl = entry_zone.get('low', candle['low']) - 0.0005
                    tp = entry_price + (entry_price - sl) * self.min_rr
                    action = 'BUY'
                else:
                    entry_price = candle['close']
                    sl = entry_zone.get('high', candle['high']) + 0.0005
                    tp = entry_price - (sl - entry_price) * self.min_rr
                    action = 'SELL'
                
                # تأكد من R:R
                risk = abs(entry_price - sl)
                reward = abs(tp - entry_price)
                if reward / risk < self.min_rr:
                    continue
                
                # إنشاء الإشارة
                signals.append({
                    'timestamp': candle['time'].strftime('%Y-%m-%dT%H:%M:%SZ'),
                    'symbol': self.symbol,
                    'action': action,
                    'price': round(entry_price, 5),
                    'sl': round(sl, 5),
                    'tp': round(tp, 5),
                    'risk': self.risk_pct,
                    'comment': f"SMC_{sweep['type']}_{confirmation}",
                    'context': {
                        'sweep_type': sweep['type'],
                        'choch': True,
                        'entry_zone': entry_zone.get('type', 'unknown'),
                        'confirmation': confirmation,
                        'htf_bias': self.htf_bias
                    }
                })
                
                break  # إشارة واحدة لكل setup
        
        return signals
