import 'package:flutter/material.dart';

import 'smc_models.dart';

const _g = Color(0xFF22C55E);
const _r = Color(0xFFEF4444);
const _b = Color(0xFF60A5FA);
const _o = Color(0xFFF59E0B);
const _p = Color(0xFFA78BFA);
const _c = Color(0xFF22D3EE);

List<SmcTopic> get smcTopics => _topics;

SmcTopic? smcTopicById(String id) {
  for (final t in _topics) {
    if (t.id == id) return t;
  }
  return null;
}

List<String> smcGroups() {
  final seen = <String>{};
  return [
    for (final t in _topics)
      if (seen.add(t.group)) t.group,
  ];
}

final _topics = <SmcTopic>[
  SmcTopic(
    id: 'structure',
    code: 'MSS',
    title: 'Market Structure',
    subtitle: 'BOS, CHoCH, swing highs and lows',
    group: 'Foundations',
    what:
        'Structure is the map. A Break of Structure (BOS) continues the current trend when price closes beyond a swing. A Change of Character (CHoCH) is the first close against that trend — a warning that delivery may have flipped. ICT reads this on the timeframe you will trade, then confirms it on one higher timeframe.',
    spot:
        'Mark swing highs and swing lows. In a rally: higher highs and higher lows. BOS = close above the last swing high. CHoCH = close below the last higher-low that was holding the uptrend. Do not count wicks alone — ICT delivery is about candle bodies / closes.',
    use:
        'Trade in the direction of the latest BOS after a CHoCH on the lower timeframe. The CHoCH tells you the old move is done; the next BOS confirms the new side. This is context, not an entry by itself.',
    mistake:
        'Calling every wick a CHoCH. A wick through a level is often a liquidity grab. Wait for a close and a follow-through displacement.',
    us100:
        'On US100, M15 swings during London/NY overlap are cleaner than Asian chop. A CHoCH on M15 after NY takes Asia’s high is a classic day-trade flip.',
    chart: _chartStructure,
  ),
  SmcTopic(
    id: 'liquidity',
    code: 'LIQ',
    title: 'Liquidity',
    subtitle: 'BSL, SSL, equal highs and lows',
    group: 'Foundations',
    what:
        'Stops rest above old highs (Buy-Side Liquidity, BSL) and below old lows (Sell-Side Liquidity, SSL). Smart money often runs that pool first, then delivers the real move the other way. Equal highs / equal lows are the most obvious magnets.',
    spot:
        'Look for two or more highs at the same price (EQH) or lows (EQL). Also: previous day high/low, session high/low, and the high/low of a consolidation. The “obvious” breakout is usually the liquidity.',
    use:
        'Wait for the sweep, then look for displacement away from the pool. Entry is not the sweep itself — it is the shift after the pool is taken.',
    mistake:
        'Fading every high. If higher-timeframe premium is still being sought, BSL can be taken and price can keep going. Liquidity is a magnet, not a guaranteed reversal.',
    us100:
        'US100 often sweeps the previous day’s high in the NY AM session, then sells toward the NY open or previous day’s low. Mark PDH/PDL on the chart every morning.',
    chart: _chartLiquidity,
  ),
  SmcTopic(
    id: 'displacement',
    code: 'DISP',
    title: 'Displacement',
    subtitle: 'Strong delivery that leaves imbalance',
    group: 'Foundations',
    what:
        'Displacement is a fast, energetic run of candles that breaks structure and usually leaves a Fair Value Gap. It is how the algorithm shows intent. Without displacement, most “patterns” are just noise.',
    spot:
        'Several large-bodied candles in one direction, little overlap, a gap (FVG) in the middle, and a BOS on the close. Volume is not required — the candle range and imbalance are the tell on US100 CFDs.',
    use:
        'After displacement, wait for price to return into the FVG or the order block that started the run. That retrace is the entry area. Do not chase the expanding candles.',
    mistake:
        'Entering mid-displacement. You are buying the expensive side of the move. Let it return to the imbalance.',
    us100:
        'US100 displacements cluster at 9:30–10:00 NY (cash open) and during 10:00–11:00 Silver Bullet. One M5 displacement is often enough for a day-trade draw.',
    chart: _chartDisplacement,
  ),
  SmcTopic(
    id: 'premium-discount',
    code: 'PD',
    title: 'Premium & Discount',
    subtitle: 'Dealing range, 50% and OTE',
    group: 'Foundations',
    what:
        'A dealing range is the swing low to swing high of the move you care about. Below equilibrium (50%) is discount; above is premium. ICT Optimal Trade Entry (OTE) is the 0.62–0.79 Fibonacci retracement of that range — buy discounts in a bullish draw, sell premiums in a bearish draw.',
    spot:
        'Anchor fib from the dealing-range low to high (or high to low). Equilibrium is 0.5. OTE sits in the 0.62–0.79 pocket. Confluence: an FVG or order block sitting in that pocket.',
    use:
        'If daily bias is up, ignore cheap-looking shorts in premium until the discount array is visited — or wait for a lower-timeframe CHoCH. Bias first, then the cheap side of the range.',
    mistake:
        'Buying every discount without a draw on liquidity above. Discount only matters if price still wants a higher pool.',
    us100:
        'On US100 H1, the overnight range often becomes the dealing range. NY open trades frequently fade back into OTE of that range before the real continuation.',
    chart: _chartPremium,
  ),
  SmcTopic(
    id: 'fvg',
    code: 'FVG',
    title: 'Fair Value Gap',
    subtitle: '3-candle imbalance',
    group: 'Imbalances',
    what:
        'A Fair Value Gap is a 3-candle pattern: the wick of candle 1 and the wick of candle 3 do not overlap. The space between them is inefficiency. Price often returns to “rebalance” that gap later. Bullish FVG forms in an up displacement; bearish FVG in a down displacement.',
    spot:
        'Candle 1, impulsive candle 2, candle 3. If candle 1 high < candle 3 low → bullish FVG. If candle 1 low > candle 3 high → bearish FVG. The gap is the box you draw. A “CE” (consequent encroachment) is the 50% of that gap — a refined entry.',
    use:
        'Trade when price trades back into the FVG in the direction of the displacement. Stops go beyond the displacement extreme (or the order block). Partial at the next liquidity pool.',
    mistake:
        'Every tiny gap is not a setup. Prefer FVGs created by a BOS/CHoCH displacement, in premium or discount that matches bias.',
    us100:
        'On US100 M5/M15, the cleanest FVGs print after the NY cash open impulse. A 4–12 point M5 FVG is a typical day-trade imbalance on this index.',
    chart: _chartFvg,
  ),
  SmcTopic(
    id: 'ifvg',
    code: 'IFVG',
    title: 'Inverse Fair Value Gap',
    subtitle: 'When an FVG flips role',
    group: 'Imbalances',
    what:
        'An Inverse FVG (IFVG) is an FVG that price fully trades through and closes beyond. The old imbalance is “inverted”: a bullish gap that fails becomes a bearish IFVG (resistance), and vice versa. It is a failed efficiency that now supports the new direction.',
    spot:
        'Find an FVG. Watch for a close through the far side of the gap (not just a wick). After that close, the same box is the IFVG. A return into it from the other side is the inverse test.',
    use:
        'After a CHoCH, the FVG that price punched through often becomes the IFVG entry. It pairs well with a breaker block at the same price.',
    mistake:
        'Calling it inverted on a wick. ICT inversion is a close through the gap, then a retest.',
    us100:
        'US100 often inverts the London FVG during the NY AM reversal. The same green box that held in London becomes the red IFVG shorts fade into.',
    chart: _chartIfvg,
  ),
  SmcTopic(
    id: 'bpr',
    code: 'BPR',
    title: 'Balanced Price Range',
    subtitle: 'Overlapping bullish and bearish FVGs',
    group: 'Imbalances',
    what:
        'A Balanced Price Range is where a bullish FVG and a bearish FVG overlap. Price delivered both ways through the same pocket, so that pocket is “balanced.” Later revisits of a BPR are high-reaction zones — the algorithm has already shown it cares about that price.',
    spot:
        'Draw both FVGs. The overlap rectangle is the BPR. It often sits at the origin of a larger displacement or inside a breaker.',
    use:
        'Fade or continue from the BPR in the direction of the higher-timeframe draw. Stops beyond the BPR plus a buffer. It is a refinement tool, not a standalone model.',
    mistake:
        'Forcing a BPR on two gaps that barely touch. If the overlap is sloppy, treat them as two separate FVGs.',
    us100:
        'US100 H1 BPRs around the New York open level are common: London dumps, NY rips back through the same prices, then the overlap becomes the afternoon magnet.',
    chart: _chartBpr,
  ),
  SmcTopic(
    id: 'volume-imbalance',
    code: 'VI',
    title: 'Volume Imbalance',
    subtitle: 'Body gap between two candles',
    group: 'Imbalances',
    what:
        'A volume imbalance is a small gap between consecutive candle bodies (not necessarily wicks). It is a finer inefficiency than a 3-candle FVG. Price often “prints” through it later to rebalance the bodies.',
    spot:
        'Two candles in the same direction where the second body does not overlap the first body. Draw the thin strip between bodies. It is smaller than an FVG and often sits inside one.',
    use:
        'Use VI as a scalping refinement inside an FVG or order block. Limit entries at the VI when the higher-timeframe story is already set.',
    mistake:
        'Treating every body gap as a day-trade level. Most VIs are noise unless they sit inside a PD array you already trust.',
    us100:
        'On US100 M1/M3, VIs inside the M15 FVG are how many ICT scalpers refine a Silver Bullet fill.',
    chart: _chartVi,
  ),
  SmcTopic(
    id: 'order-block',
    code: 'OB',
    title: 'Order Block',
    subtitle: 'Last opposing candle before displacement',
    group: 'Blocks',
    what:
        'An order block is the last down-close candle before a bullish displacement (bullish OB) or the last up-close candle before a bearish displacement (bearish OB). It represents the origin of the move — where orders were resting before price was delivered the other way.',
    spot:
        'Find the impulsive run that broke structure. Walk back to the last opposite-color candle. That body (sometimes including the wick) is the OB. Valid OBs usually leave an FVG right after them.',
    use:
        'Wait for price to return into the OB. Conservative entry: close inside the body. Aggressive: wick into the OB. Stop beyond the OB extreme. Target the liquidity the displacement was aiming for.',
    mistake:
        'Marking every red candle as a bullish OB. If there was no displacement and no BOS, it is just a candle.',
    us100:
        'US100 M15 bullish OBs printed just before the 9:30 NY impulse are the ones day-traders keep on the chart all morning.',
    chart: _chartOb,
  ),
  SmcTopic(
    id: 'breaker-block',
    code: 'BB',
    title: 'Breaker Block',
    subtitle: 'Failed order block that flips',
    group: 'Blocks',
    what:
        'A breaker is an order block that fails: price trades through it, takes the liquidity beyond, then displaces the other way. The failed block is now a breaker — it changes role (support becomes resistance, or the reverse). Unicorn setups often use a breaker plus an FVG.',
    spot:
        'Bullish OB gets traded through to the downside (stops under it taken), then price rips up and closes back above. That old OB is now a bullish breaker when price retests it from above. Mirror for bearish.',
    use:
        'Enter on the retest of the breaker in the new direction. It is stronger when an FVG sits on top of the breaker (Unicorn). Stop goes beyond the swing that created the failure.',
    mistake:
        'Labeling a simple BOS candle as a breaker. A breaker needs the failed-block story: through, liquidity taken, then reverse.',
    us100:
        'US100 often builds a London bullish OB, dumps it in the NY Judas swing, then uses that same block as a breaker for the real NY long.',
    chart: _chartBreaker,
  ),
  SmcTopic(
    id: 'rejection-block',
    code: 'RB',
    title: 'Rejection Block',
    subtitle: 'Wick rejection at a PD array',
    group: 'Blocks',
    what:
        'A rejection block is the wick (opening or closing) that rejects a level — usually a swing, FVG, or session high/low — showing that price probed liquidity and was refused. The wick range becomes the block. It is more “wick-based” than a classic body order block.',
    spot:
        'A candle with a long wick through BSL/SSL or into a PD array, then a close back inside the range. The wick’s mid (consequent encroachment of the wick) is a refined reaction point.',
    use:
        'When price returns to the wick extreme or the 50% of the wick, look for a lower-timeframe entry in the rejection direction. Pair it with SMT or a CHoCH.',
    mistake:
        'Every pin bar is not a rejection block. It needs context: a pool taken, then a close back, then a later retest.',
    us100:
        'US100 weekly wicks above prior week highs are classic rejection blocks. Intraday, the 10:00 NY news wick often becomes the afternoon rejection block.',
    chart: _chartRejection,
  ),
  SmcTopic(
    id: 'smt',
    code: 'SMT',
    title: 'SMT Divergence',
    subtitle: 'Correlated markets disagree',
    group: 'Bias & timing',
    what:
        'SMT (Smart Money Technique) is divergence between correlated assets. If US100 makes a new low but US500 (or YM) does not — or DXY fails to confirm — the weak market is often the one about to reverse. SMT is a timing tool at liquidity, not an entry by itself.',
    spot:
        'At a session low: compare US100 vs US500 vs DXY. SMT = one makes a lower low, the other makes a higher low. At highs: one higher high, the other lower high. Also: NQ vs ES is the cleanest equity-index SMT.',
    use:
        'When SSL is taken on US100 but ES holds, look for a US100 CHoCH and FVG long. SMT says “this sweep is likely engineered.” Still wait for displacement.',
    mistake:
        'Forcing SMT on random swings. It matters at obvious liquidity and at killzone times.',
    us100:
        'Keep a small ES/US500 or YM window next to US100. The NY 9:45–10:15 SMT at PDH/PDL is one of the highest-quality tells on this index.',
    chart: _chartSmt,
  ),
  SmcTopic(
    id: 'daily-bias',
    code: 'BIAS',
    title: 'Daily Bias',
    subtitle: 'HTF draw, opens, and the day\'s side',
    group: 'Bias & timing',
    what:
        'Daily bias is the side you expect the day to deliver: toward buy-side or sell-side liquidity. It is built from the daily/4H dealing range, midnight opening price, true day open, previous day’s high/low, and where price sits in premium/discount. Bias is a filter — it does not mean “buy every candle.”',
    spot:
        'If daily is discount and PDH is still untaken, bias is often up (draw on BSL). If daily is premium and PDL is untaken, bias is often down. The first hour can Judas against that bias, then deliver it.',
    use:
        'Only take lower-timeframe setups that aim at the daily draw. Skip textbook FVGs that point the wrong way. Re-evaluate after a true CHoCH on H1.',
    mistake:
        'Changing bias after two M1 candles. Bias lives on H1/H4/Daily. Intraday noise is the Judas.',
    us100:
        'US100 daily bias often respects the 00:00 NY midnight open. Price above midnight open, seeking PDH, is a common bullish day profile — after any morning dump.',
    chart: _chartBias,
  ),
  SmcTopic(
    id: 'killzones',
    code: 'KZ',
    title: 'Killzones',
    subtitle: 'London, NY AM, NY PM, Silver windows',
    group: 'Bias & timing',
    what:
        'Killzones are the windows when ICT expects algorithmic delivery: London Open (≈2:00–5:00 NY), New York AM (≈7:00–10:00 NY, cash open inside), NY lunch, and NY PM. Most of the day’s range is born here. Outside them, US100 often chops.',
    spot:
        'Mark session boxes. Note London high/low, then NY open. The AM killzone frequently raids London’s high or low, then runs the other way. Silver Bullet is a 60-minute subset (see that lesson).',
    use:
        'Plan: which pool will NY take? Wait for the raid inside the killzone, then the displacement. Do not force entries at 12:30 NY unless you are trading the lunch model on purpose.',
    mistake:
        'Trading every hour as if it were 9:30. Dead time is a feature — sit on hands.',
    us100:
        'US100 cash open (9:30 NY) is the sharpest killzone candle of the day. Spreads widen for a moment; wait for the first impulse to finish before using the FVG.',
    chart: _chartKillzones,
  ),
  SmcTopic(
    id: 'silver-bullet',
    code: 'SB',
    title: 'Silver Bullet',
    subtitle: 'Timed FVG after liquidity',
    group: 'Models',
    what:
        'Silver Bullet is a time-based model: during a specific 60-minute window, wait for liquidity to be taken, then trade the first FVG in the direction of the remaining draw. Classic NY windows: 3:00–4:00 NY, 10:00–11:00 NY, and 2:00–3:00 NY (check current ICT notes — the clock is the model).',
    spot:
        'Inside the window: sweep of a nearby high or low, displacement, FVG. Entry is the FVG. Invalidation is a close back through the FVG against you. Target: next session high/low or PDH/PDL.',
    use:
        'One setup per window. If the FVG never forms, there is no Silver Bullet — skip. This model is about patience and the clock, not predicting the whole day.',
    mistake:
        'Entering at 10:00 just because the window started. No raid + no FVG = no trade.',
    us100:
        'US100 10:00–11:00 NY Silver Bullet after the 9:30 impulse is the most practiced version on this index. Use M1/M5 FVGs, M15 for bias.',
    chart: _chartSilver,
  ),
  SmcTopic(
    id: 'unicorn',
    code: 'UNI',
    title: 'Unicorn Model',
    subtitle: 'Breaker + FVG stacked',
    group: 'Models',
    what:
        'The Unicorn is confluence: a breaker block and a Fair Value Gap occupying the same price. The failed order block and the imbalance agree. That overlap is the unicorn entry zone — one of ICT’s refined PD arrays.',
    spot:
        'Identify a breaker (failed OB after a liquidity run). See if a new FVG sits on that breaker. The overlap box is the unicorn. Both bullish and bearish versions exist.',
    use:
        'Limit into the overlap. Stop beyond the breaker extreme. Target the liquidity the displacement was built to reach. Fewer trades, cleaner R-multiples.',
    mistake:
        'Calling any FVG-on-a-candle a unicorn. The breaker story (failure then flip) must be there.',
    us100:
        'US100 M5 unicorns after a NY sweep of London high are textbook: London OB fails, M5 FVG prints on the breaker, then the afternoon continuation.',
    chart: _chartUnicorn,
  ),
  SmcTopic(
    id: 'mmxm',
    code: 'MMXM',
    title: 'Market Maker Model',
    subtitle: 'MMXM buy and sell models',
    group: 'Models',
    what:
        'The Market Maker Buy/Sell Model (MMXM) is the full story of a dealing range: original consolidation, sell-side or buy-side of the curve, smart money reversal (SMR), then reversal-confirmation and the run to the opposite liquidity. You are locating where you sit on that curve — not predicting every wiggle.',
    spot:
        'Find the original consolidation. Price leaves it (often with a Judas), runs one side (the “smart money reversal” low/high), then returns through the consolidation toward the other side. IRL/IBF (institutional order flow) shows as BOS in the new direction.',
    use:
        'Do not buy the sell-side of the curve just because it looks cheap. Wait for the SMR (sweep + CHoCH) then use FVG/OB on the reversal-confirmation leg toward original consolidation and beyond.',
    mistake:
        'Shorting the entire way down the buy model. The left side is distribution; the right side after SMR is the move you actually want.',
    us100:
        'US100 often prints a full M15 MMXM between London and NY close: Asia box, London raid, NY reversal, then a grind back through the box into the opposite session extreme.',
    chart: _chartMmxm,
  ),
  SmcTopic(
    id: 'turtle-soup',
    code: 'TS',
    title: 'Turtle Soup',
    subtitle: 'False breakout of equal highs/lows',
    group: 'Models',
    what:
        'Turtle Soup is a false-breakout model: price pokes beyond a well-defined high or low (where “turtles” / breakout traders are), then snaps back. You are trading the stop-run, not the breakout. It is liquidity + rejection, named after the old Turtle trend-following rules.',
    spot:
        'Equal highs or a clean range high. A candle closes or wicks through, then a strong close back inside the range. Lower-timeframe CHoCH confirms. The soup is the trap; the meal is the move back to the other side of the range.',
    use:
        'Stops above/below the soup wick. Target: opposite range liquidity or the 50% of the range first. Works best at HTF PD arrays and in killzones.',
    mistake:
        'Fading a real displacement breakout that leaves a huge FVG and never comes back. Turtle Soup needs the snap-back. If price runs 80 points and holds, that was not soup — that was the trend.',
    us100:
        'US100 equal highs from yesterday’s London session get souped at 9:35–9:50 NY constantly. If the M5 closes back below those highs, the soup short toward NY open is a staple drill.',
    chart: _chartTurtle,
  ),
  SmcTopic(
    id: 'po3',
    code: 'PO3',
    title: 'Power of Three',
    subtitle: 'Accumulation, manipulation, distribution',
    group: 'Models',
    what:
        'Power of Three is the candle anatomy of a session or a day: Accumulation (sideways, the open), Manipulation (the Judas swing against the real intent, taking stops), Distribution (the real move toward the day’s liquidity). One daily candle often contains all three.',
    spot:
        'Mark the session open. The first push away is often manipulation. The reversal through the open and the rest of the range is distribution. On a bullish day: dump first, then rally. Bearish day: rally first, then sell.',
    use:
        'Do not trade the manipulation as if it were the trend. Wait for the reversal through the opening price, then use FVG/OB in the distribution phase.',
    mistake:
        'FOMO on the first 15 minutes. That is often the Judas, not the day.',
    us100:
        'A bullish US100 day frequently dumps 40–80 points after 9:30, takes SSL, then distributes up into PDH into the afternoon. That dump is PO3 manipulation.',
    chart: _chartPo3,
  ),
  SmcTopic(
    id: 'judas',
    code: 'JUDAS',
    title: 'Judas Swing',
    subtitle: 'False move after the open',
    group: 'Models',
    what:
        'The Judas swing is the fake move right after a key open (midnight, London, NY). It runs stops of traders who were early, then reverses into the real delivery. It is the “manipulation” leg of Power of Three.',
    spot:
        'Right after 9:30 NY (or London open), a sharp push that takes a nearby high or low, then a reversal that takes out the open the other way. The Judas is the first swing; the real move is what follows.',
    use:
        'Let Judas print. After the reversal and a CHoCH, enter using the FVG left by the true displacement. Stops beyond the Judas extreme.',
    mistake:
        'Marrying the first tick after the open. The open is where liquidity is engineered.',
    us100:
        'US100 Judas at 9:30 is famous: a 20–50 point spike to raid Asia/London, then a full retrace. Demo this with tiny size until you can sit through it without clicking.',
    chart: _chartJudas,
  ),
  SmcTopic(
    id: 'inducement',
    code: 'IDM',
    title: 'Inducement',
    subtitle: 'The trap before the real discount',
    group: 'Models',
    what:
        'Inducement is a small, obvious PD array (tiny FVG or short-term low) placed before the real order block or discount. It induces traders to enter early. Smart money runs that inducement, then delivers from the deeper array.',
    spot:
        'In a bullish expansion, a shallow higher-low or a 1-candle gap sits above the true bullish OB. Price dips through the shallow level (inducement), then reacts at the deeper OB/FVG.',
    use:
        'If your long is sitting on the first tiny gap, assume it may be inducement. Prefer the deeper array that started the displacement. Let inducement get taken, then enter.',
    mistake:
        'Moving stops to the inducement low. That is where the raid goes. Stops belong beyond the true origin.',
    us100:
        'US100 M5 often leaves a baby FVG on the way down to the M15 order block. That baby gap is inducement — it will be traded through before the real bounce.',
    chart: _chartInducement,
  ),
  SmcTopic(
    id: 'cisd',
    code: 'CISD',
    title: 'Change in State of Delivery',
    subtitle: 'Shift from sell to buy delivery (and reverse)',
    group: 'Models',
    what:
        'CISD is the moment delivery flips: a sequence of down-close candles is broken by a strong up-close (or the reverse). It is a precise, candle-state way to call the shift — related to CHoCH but focused on the run of delivery candles themselves.',
    spot:
        'In a sell-off, note the last series of down-closes. A bullish CISD is when price closes back above the open/high of that delivery sequence. Then a new series of up-closes begins. Timeframes: M1–M5 for scalps, M15 for day trades.',
    use:
        'Use CISD as the trigger after liquidity is taken. Then enter the first FVG of the new delivery state. It keeps you from guessing at the exact tick of a CHoCH.',
    mistake:
        'One random opposite candle is not CISD. You need a break of the delivery sequence and follow-through.',
    us100:
        'On US100 M1 during Silver Bullet, CISD after a 10:02 liquidity poke is a common trigger into the M1 FVG long or short.',
    chart: _chartCisd,
  ),
];

final _chartStructure = SmcChart(
  timeframe: 'M15',
  caption: 'US100 M15: higher highs, then a CHoCH under the last higher-low, then a new BOS.',
  ohlc: [
    [22, 28, 20, 26],
    [26, 32, 25, 31],
    [31, 34, 29, 30],
    [30, 38, 29, 37],
    [37, 42, 35, 41],
    [41, 44, 38, 39],
    [39, 46, 38, 45],
    [45, 48, 36, 37],
    [37, 39, 28, 30],
    [30, 32, 24, 26],
    [26, 29, 23, 28],
    [28, 36, 27, 35],
    [35, 40, 34, 39],
    [39, 48, 38, 47],
    [47, 52, 45, 50],
    [50, 56, 49, 55],
  ],
  marks: const [
    SmcMark.tag(i0: 6, price: 48, label: 'HH', color: _b),
    SmcMark.tag(i0: 5, price: 36, label: 'HL', color: _b),
    SmcMark.tag(i0: 9, price: 22, label: 'CHoCH', color: _o),
    SmcMark.tag(i0: 13, price: 50, label: 'BOS', color: _g),
    SmcMark.line(price: 38, label: 'broken HL', color: _o, i0: 5, i1: 10),
  ],
);

final _chartLiquidity = SmcChart(
  timeframe: 'M15',
  caption: 'Equal highs = BSL. Price raids them, then sells toward SSL.',
  ohlc: [
    [40, 55, 38, 52],
    [52, 58, 50, 54],
    [54, 58, 48, 50],
    [50, 57, 47, 53],
    [53, 58, 51, 56],
    [56, 64, 54, 50],
    [50, 52, 42, 44],
    [44, 46, 36, 38],
    [38, 40, 30, 32],
    [32, 34, 22, 24],
    [24, 28, 20, 26],
    [26, 38, 25, 36],
    [36, 42, 34, 40],
    [40, 48, 38, 46],
    [46, 50, 44, 48],
    [48, 52, 46, 51],
  ],
  marks: const [
    SmcMark.line(price: 58, label: 'BSL · EQH', color: _r, i0: 1, i1: 5),
    SmcMark.line(price: 20, label: 'SSL', color: _g, i0: 9, i1: 11),
    SmcMark.tag(i0: 5, price: 66, label: 'sweep', color: _o),
  ],
);

final _chartDisplacement = SmcChart(
  timeframe: 'M5',
  caption: 'A run of large bodies breaks structure and leaves an FVG — that is displacement.',
  ohlc: [
    [30, 34, 28, 32],
    [32, 35, 30, 33],
    [33, 36, 31, 34],
    [34, 37, 32, 31],
    [31, 33, 29, 30],
    [30, 32, 28, 29],
    [29, 58, 29, 55],
    [55, 62, 53, 60],
    [60, 66, 58, 64],
    [64, 68, 60, 62],
    [62, 64, 58, 59],
    [59, 61, 54, 56],
    [56, 58, 52, 54],
    [54, 63, 53, 61],
    [61, 70, 60, 68],
    [68, 74, 66, 72],
  ],
  marks: const [
    SmcMark.box(i0: 5, i1: 8, low: 37, high: 53, label: 'FVG', color: _g),
    SmcMark.tag(i0: 8, price: 68, label: 'displacement', color: _c),
  ],
);

final _chartPremium = SmcChart(
  timeframe: 'H1',
  caption: 'Dealing range: premium above 50%, discount below. OTE is the 62–79% pocket.',
  ohlc: [
    [18, 22, 16, 20],
    [20, 28, 19, 27],
    [27, 40, 26, 38],
    [38, 55, 37, 53],
    [53, 72, 52, 70],
    [70, 78, 68, 76],
    [76, 80, 70, 72],
    [72, 74, 60, 62],
    [62, 64, 50, 52],
    [52, 54, 42, 44],
    [44, 48, 40, 46],
    [46, 58, 45, 56],
    [56, 64, 54, 62],
    [62, 70, 60, 68],
    [68, 76, 66, 74],
    [74, 82, 72, 80],
  ],
  marks: const [
    SmcMark.line(price: 80, label: 'range high', color: _r, i0: 5, i1: 15),
    SmcMark.line(price: 50, label: 'EQ 50%', color: _o, i0: 0, i1: 15),
    SmcMark.box(i0: 8, i1: 11, low: 38, high: 48, label: 'OTE / discount', color: _g),
    SmcMark.line(price: 18, label: 'range low', color: _g, i0: 0, i1: 4),
  ],
);

final _chartFvg = SmcChart(
  timeframe: 'M5',
  caption: 'Bullish FVG: candle 1 high does not touch candle 3 low. Price later returns into the gap.',
  ohlc: [
    [24, 28, 22, 26],
    [26, 30, 24, 29],
    [29, 32, 27, 28],
    [28, 31, 26, 27],
    [27, 29, 25, 26],
    [26, 52, 26, 50],
    [50, 58, 48, 56],
    [56, 62, 54, 60],
    [60, 64, 52, 54],
    [54, 56, 46, 48],
    [48, 50, 42, 44],
    [44, 52, 43, 50],
    [50, 58, 49, 56],
    [56, 64, 55, 62],
    [62, 70, 60, 68],
    [68, 74, 66, 72],
  ],
  marks: const [
    SmcMark.box(i0: 4, i1: 7, low: 32, high: 48, label: 'Bullish FVG', color: _g),
    SmcMark.tag(i0: 10, price: 40, label: 'rebalance', color: _c),
  ],
);

final _chartIfvg = SmcChart(
  timeframe: 'M15',
  caption: 'The bullish FVG is closed through. On the retest it acts as IFVG resistance.',
  ohlc: [
    [30, 34, 28, 32],
    [32, 48, 32, 46],
    [46, 54, 44, 52],
    [52, 58, 50, 56],
    [56, 60, 48, 50],
    [50, 52, 40, 42],
    [42, 44, 30, 32],
    [32, 34, 24, 26],
    [26, 28, 22, 24],
    [24, 36, 23, 34],
    [34, 44, 33, 42],
    [42, 50, 40, 44],
    [44, 46, 36, 38],
    [38, 40, 28, 30],
    [30, 32, 22, 24],
    [24, 26, 18, 20],
  ],
  marks: const [
    SmcMark.box(i0: 0, i1: 3, low: 34, high: 44, label: 'FVG → IFVG', color: _r),
    SmcMark.tag(i0: 6, price: 28, label: 'close through', color: _o),
    SmcMark.tag(i0: 11, price: 50, label: 'retest short', color: _r),
  ],
);

final _chartBpr = SmcChart(
  timeframe: 'M15',
  caption: 'Bearish FVG then a bullish FVG overlap — the overlap is the BPR.',
  ohlc: [
    [70, 74, 66, 68],
    [68, 70, 50, 52],
    [52, 54, 46, 48],
    [48, 50, 42, 44],
    [44, 46, 40, 42],
    [42, 44, 38, 40],
    [40, 62, 40, 60],
    [60, 68, 58, 66],
    [66, 72, 64, 70],
    [70, 74, 62, 64],
    [64, 66, 56, 58],
    [58, 64, 57, 62],
    [62, 70, 61, 68],
    [68, 76, 66, 74],
    [74, 80, 72, 78],
    [78, 84, 76, 82],
  ],
  marks: const [
    SmcMark.box(i0: 0, i1: 3, low: 54, high: 66, label: 'Bear FVG', color: _r),
    SmcMark.box(i0: 5, i1: 8, low: 50, high: 58, label: 'Bull FVG', color: _g),
    SmcMark.box(i0: 2, i1: 7, low: 54, high: 58, label: 'BPR', color: _p),
  ],
);

final _chartVi = SmcChart(
  timeframe: 'M1',
  caption: 'Thin gap between two candle bodies — volume imbalance inside a larger FVG.',
  ohlc: [
    [28, 32, 26, 30],
    [30, 34, 28, 33],
    [33, 36, 31, 32],
    [32, 34, 30, 31],
    [31, 42, 31, 41],
    [42, 50, 41, 49],
    [49, 56, 48, 55],
    [55, 60, 52, 53],
    [53, 55, 46, 48],
    [48, 50, 44, 46],
    [46, 52, 45, 51],
    [51, 58, 50, 56],
    [56, 62, 54, 60],
    [60, 66, 58, 64],
    [64, 70, 62, 68],
    [68, 74, 66, 72],
  ],
  marks: const [
    SmcMark.box(i0: 3, i1: 6, low: 36, high: 41, label: 'VI', color: _c),
    SmcMark.box(i0: 3, i1: 7, low: 36, high: 48, label: 'FVG', color: _g),
  ],
);

final _chartOb = SmcChart(
  timeframe: 'M15',
  caption: 'Last down-close before the rally is the bullish order block. Price returns into it later.',
  ohlc: [
    [48, 52, 46, 50],
    [50, 54, 44, 46],
    [46, 48, 40, 42],
    [42, 44, 36, 38],
    [38, 40, 34, 36],
    [36, 58, 36, 56],
    [56, 64, 54, 62],
    [62, 70, 60, 68],
    [68, 74, 58, 60],
    [60, 62, 50, 52],
    [52, 54, 40, 42],
    [42, 48, 38, 46],
    [46, 58, 45, 56],
    [56, 66, 54, 64],
    [64, 72, 62, 70],
    [70, 78, 68, 76],
  ],
  marks: const [
    SmcMark.box(i0: 3, i1: 4, low: 34, high: 44, label: 'Bullish OB', color: _g),
    SmcMark.tag(i0: 7, price: 72, label: 'displacement', color: _c),
    SmcMark.tag(i0: 10, price: 36, label: 'mitigation', color: _o),
  ],
);

final _chartBreaker = SmcChart(
  timeframe: 'M15',
  caption: 'OB fails (liquidity under it taken), then price reclaims it — that box is now a breaker.',
  ohlc: [
    [50, 54, 42, 44],
    [44, 46, 38, 40],
    [40, 62, 40, 60],
    [60, 68, 58, 66],
    [66, 70, 52, 54],
    [54, 56, 36, 38],
    [38, 40, 24, 26],
    [26, 28, 20, 22],
    [22, 48, 22, 46],
    [46, 58, 44, 56],
    [56, 64, 50, 52],
    [52, 54, 44, 46],
    [46, 50, 42, 48],
    [48, 60, 47, 58],
    [58, 68, 56, 66],
    [66, 76, 64, 74],
  ],
  marks: const [
    SmcMark.box(i0: 0, i1: 1, low: 38, high: 54, label: 'Breaker', color: _p),
    SmcMark.tag(i0: 7, price: 18, label: 'SSL raid', color: _o),
    SmcMark.tag(i0: 12, price: 40, label: 'retest', color: _g),
  ],
);

final _chartRejection = SmcChart(
  timeframe: 'M15',
  caption: 'Long wick through BSL, close back inside. The wick is the rejection block.',
  ohlc: [
    [40, 48, 38, 46],
    [46, 52, 44, 50],
    [50, 56, 48, 54],
    [54, 58, 50, 52],
    [52, 56, 50, 54],
    [54, 78, 52, 58],
    [58, 62, 48, 50],
    [50, 52, 40, 42],
    [42, 44, 34, 36],
    [36, 40, 32, 38],
    [38, 46, 36, 44],
    [44, 50, 42, 48],
    [48, 54, 46, 52],
    [52, 58, 50, 56],
    [56, 60, 48, 50],
    [50, 52, 42, 44],
  ],
  marks: const [
    SmcMark.line(price: 58, label: 'old high', color: _o, i0: 2, i1: 6),
    SmcMark.box(i0: 5, i1: 5, low: 58, high: 78, label: 'Rejection wick', color: _r),
    SmcMark.tag(i0: 8, price: 32, label: 'away', color: _c),
  ],
);

final _chartSmt = SmcChart(
  timeframe: 'M15',
  caption: 'US100 makes a lower low; a correlated index (ES) holds. That SMT + CHoCH is the tell.',
  ohlc: [
    [48, 54, 46, 52],
    [52, 56, 44, 46],
    [46, 48, 36, 38],
    [38, 42, 34, 40],
    [40, 48, 38, 46],
    [46, 50, 36, 38],
    [38, 40, 24, 26],
    [26, 30, 22, 28],
    [28, 40, 27, 38],
    [38, 50, 36, 48],
    [48, 56, 46, 54],
    [54, 62, 52, 60],
    [60, 66, 58, 64],
    [64, 70, 62, 68],
    [68, 74, 66, 72],
    [72, 78, 70, 76],
  ],
  marks: const [
    SmcMark.tag(i0: 2, price: 34, label: 'ES holds', color: _b),
    SmcMark.tag(i0: 6, price: 20, label: 'US100 LL · SMT', color: _o),
    SmcMark.tag(i0: 9, price: 52, label: 'CHoCH up', color: _g),
  ],
);

final _chartBias = SmcChart(
  timeframe: 'H1',
  caption: 'Midnight open as a compass: below it into discount, then the day draws on PDH.',
  ohlc: [
    [50, 54, 48, 52],
    [52, 56, 50, 54],
    [54, 58, 46, 48],
    [48, 50, 40, 42],
    [42, 44, 34, 36],
    [36, 38, 30, 32],
    [32, 40, 30, 38],
    [38, 48, 37, 46],
    [46, 54, 44, 52],
    [52, 58, 50, 56],
    [56, 62, 54, 60],
    [60, 68, 58, 66],
    [66, 74, 64, 72],
    [72, 80, 70, 78],
    [78, 84, 76, 82],
    [82, 88, 80, 86],
  ],
  marks: const [
    SmcMark.line(price: 52, label: '00:00 NY open', color: _c, i0: 0, i1: 15),
    SmcMark.tag(i0: 5, price: 28, label: 'Judas / discount', color: _o),
    SmcMark.tag(i0: 14, price: 86, label: 'draw on PDH', color: _g),
  ],
);

final _chartKillzones = SmcChart(
  timeframe: 'M15',
  caption: 'London range first, then NY AM raid and delivery. Most of the US100 day lives in these boxes.',
  ohlc: [
    [40, 44, 38, 42],
    [42, 50, 40, 48],
    [48, 54, 46, 52],
    [52, 56, 44, 46],
    [46, 48, 40, 42],
    [42, 44, 36, 38],
    [38, 40, 34, 36],
    [36, 62, 36, 60],
    [60, 68, 58, 66],
    [66, 72, 54, 56],
    [56, 58, 44, 46],
    [46, 48, 38, 40],
    [40, 52, 39, 50],
    [50, 60, 48, 58],
    [58, 66, 56, 64],
    [64, 70, 62, 68],
  ],
  marks: const [
    SmcMark.box(i0: 0, i1: 6, low: 34, high: 56, label: 'London KZ', color: _b),
    SmcMark.box(i0: 7, i1: 12, low: 36, high: 72, label: 'NY AM KZ', color: _o),
  ],
);

final _chartSilver = SmcChart(
  timeframe: 'M1',
  caption: '10:00–11:00 NY: raid a nearby low, first FVG up — that is the Silver Bullet.',
  ohlc: [
    [48, 54, 46, 52],
    [52, 56, 50, 54],
    [54, 58, 44, 46],
    [46, 48, 36, 38],
    [38, 40, 32, 34],
    [34, 36, 28, 30],
    [30, 48, 30, 46],
    [46, 54, 44, 52],
    [52, 58, 50, 56],
    [56, 60, 48, 50],
    [50, 52, 44, 46],
    [46, 54, 45, 52],
    [52, 60, 50, 58],
    [58, 66, 56, 64],
    [64, 72, 62, 70],
    [70, 76, 68, 74],
  ],
  marks: const [
    SmcMark.box(i0: 2, i1: 15, low: 26, high: 78, label: '10:00–11:00 NY', color: _o),
    SmcMark.box(i0: 5, i1: 8, low: 40, high: 44, label: 'SB FVG', color: _g),
    SmcMark.tag(i0: 5, price: 26, label: 'SSL raid', color: _c),
  ],
);

final _chartUnicorn = SmcChart(
  timeframe: 'M5',
  caption: 'Breaker and FVG occupy the same prices — the overlap is the Unicorn.',
  ohlc: [
    [55, 60, 44, 46],
    [46, 48, 40, 42],
    [42, 64, 42, 62],
    [62, 70, 60, 68],
    [68, 72, 50, 52],
    [52, 54, 30, 32],
    [32, 34, 24, 26],
    [26, 50, 26, 48],
    [48, 58, 46, 56],
    [56, 62, 48, 50],
    [50, 52, 42, 44],
    [44, 50, 41, 48],
    [48, 58, 47, 56],
    [56, 66, 54, 64],
    [64, 74, 62, 72],
    [72, 80, 70, 78],
  ],
  marks: const [
    SmcMark.box(i0: 0, i1: 1, low: 40, high: 60, label: 'Breaker', color: _p),
    SmcMark.box(i0: 6, i1: 9, low: 42, high: 46, label: 'FVG', color: _g),
    SmcMark.tag(i0: 11, price: 40, label: 'Unicorn', color: _c),
  ],
);

final _chartMmxm = SmcChart(
  timeframe: 'M15',
  caption: 'Original consolidation → sell-side of curve → SMR low → buy-side run back through the box.',
  ohlc: [
    [50, 56, 48, 54],
    [54, 58, 50, 52],
    [52, 56, 48, 50],
    [50, 54, 46, 52],
    [52, 48, 36, 38],
    [38, 40, 28, 30],
    [30, 32, 22, 24],
    [24, 26, 16, 18],
    [18, 22, 14, 20],
    [20, 36, 19, 34],
    [34, 48, 32, 46],
    [46, 54, 44, 52],
    [52, 60, 50, 58],
    [58, 68, 56, 66],
    [66, 76, 64, 74],
    [74, 84, 72, 82],
  ],
  marks: const [
    SmcMark.box(i0: 0, i1: 3, low: 46, high: 58, label: 'Original cons.', color: _b),
    SmcMark.tag(i0: 8, price: 12, label: 'SMR', color: _o),
    SmcMark.tag(i0: 14, price: 80, label: 'buy model target', color: _g),
  ],
);

final _chartTurtle = SmcChart(
  timeframe: 'M15',
  caption: 'Equal highs get poked, then price snaps back inside — Turtle Soup, not a breakout.',
  ohlc: [
    [36, 50, 34, 48],
    [48, 54, 46, 52],
    [52, 56, 44, 46],
    [46, 48, 40, 42],
    [42, 54, 40, 52],
    [52, 56, 48, 54],
    [54, 68, 52, 56],
    [56, 58, 44, 46],
    [46, 48, 36, 38],
    [38, 40, 30, 32],
    [32, 34, 24, 26],
    [26, 28, 20, 22],
    [22, 30, 18, 28],
    [28, 36, 26, 34],
    [34, 40, 32, 38],
    [38, 44, 36, 42],
  ],
  marks: const [
    SmcMark.line(price: 56, label: 'EQH', color: _o, i0: 1, i1: 6),
    SmcMark.tag(i0: 6, price: 70, label: 'false break', color: _r),
    SmcMark.tag(i0: 11, price: 18, label: 'soup target', color: _g),
  ],
);

final _chartPo3 = SmcChart(
  timeframe: 'M15',
  caption: 'Accumulate at the open, manipulate (dump), distribute up through the open — one US100 day.',
  ohlc: [
    [50, 54, 48, 52],
    [52, 56, 50, 54],
    [54, 58, 52, 55],
    [55, 57, 50, 52],
    [52, 54, 40, 42],
    [42, 44, 32, 34],
    [34, 36, 26, 28],
    [28, 40, 26, 38],
    [38, 50, 36, 48],
    [48, 58, 46, 56],
    [56, 64, 54, 62],
    [62, 70, 60, 68],
    [68, 76, 66, 74],
    [74, 80, 72, 78],
    [78, 84, 76, 82],
    [82, 88, 80, 86],
  ],
  marks: const [
    SmcMark.box(i0: 0, i1: 3, low: 48, high: 58, label: 'Accumulate', color: _b),
    SmcMark.tag(i0: 6, price: 24, label: 'Manipulate', color: _o),
    SmcMark.box(i0: 8, i1: 15, low: 46, high: 88, label: 'Distribute', color: _g),
  ],
);

final _chartJudas = SmcChart(
  timeframe: 'M5',
  caption: '9:30 spike takes Asia high, then the real move is the drop. That spike is the Judas.',
  ohlc: [
    [40, 44, 38, 42],
    [42, 46, 40, 44],
    [44, 48, 42, 46],
    [46, 70, 45, 66],
    [66, 72, 50, 52],
    [52, 54, 40, 42],
    [42, 44, 32, 34],
    [34, 36, 26, 28],
    [28, 30, 20, 22],
    [22, 26, 18, 24],
    [24, 32, 22, 30],
    [30, 36, 28, 34],
    [34, 40, 32, 38],
    [38, 44, 36, 42],
    [42, 46, 34, 36],
    [36, 38, 28, 30],
  ],
  marks: const [
    SmcMark.line(price: 46, label: 'Asia high', color: _o, i0: 0, i1: 4),
    SmcMark.tag(i0: 3, price: 74, label: 'Judas', color: _r),
    SmcMark.tag(i0: 8, price: 18, label: 'true delivery', color: _g),
  ],
);

final _chartInducement = SmcChart(
  timeframe: 'M5',
  caption: 'Shallow FVG gets raided. The real bounce is the deeper order block.',
  ohlc: [
    [70, 74, 52, 54],
    [54, 56, 48, 50],
    [50, 52, 44, 46],
    [46, 68, 46, 66],
    [66, 74, 64, 72],
    [72, 78, 60, 62],
    [62, 64, 54, 56],
    [56, 58, 50, 52],
    [52, 54, 40, 42],
    [42, 48, 38, 46],
    [46, 58, 45, 56],
    [56, 66, 54, 64],
    [64, 72, 62, 70],
    [70, 78, 68, 76],
    [76, 82, 74, 80],
    [80, 86, 78, 84],
  ],
  marks: const [
    SmcMark.box(i0: 5, i1: 7, low: 56, high: 60, label: 'Inducement', color: _o),
    SmcMark.box(i0: 1, i1: 2, low: 44, high: 56, label: 'True OB', color: _g),
    SmcMark.tag(i0: 8, price: 38, label: 'raid', color: _r),
  ],
);

final _chartCisd = SmcChart(
  timeframe: 'M1',
  caption: 'A run of down-closes is broken by a strong up-close — CISD — then a new FVG.',
  ohlc: [
    [70, 74, 66, 68],
    [68, 70, 60, 62],
    [62, 64, 54, 56],
    [56, 58, 48, 50],
    [50, 52, 42, 44],
    [44, 46, 36, 38],
    [38, 58, 38, 56],
    [56, 64, 54, 62],
    [62, 70, 60, 68],
    [68, 72, 58, 60],
    [60, 62, 54, 56],
    [56, 66, 55, 64],
    [64, 72, 62, 70],
    [70, 78, 68, 76],
    [76, 82, 74, 80],
    [80, 86, 78, 84],
  ],
  marks: const [
    SmcMark.box(i0: 0, i1: 5, low: 36, high: 74, label: 'sell delivery', color: _r),
    SmcMark.tag(i0: 6, price: 58, label: 'CISD', color: _g),
    SmcMark.box(i0: 5, i1: 8, low: 46, high: 54, label: 'new FVG', color: _g),
  ],
);
