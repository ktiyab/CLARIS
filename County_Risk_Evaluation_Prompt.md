# County Territorial Risk Assessment

## Read the Semantic Profile
Extract ALL these values:
- Total events: [number] 
- Total damages: $[amount]
- Worst single event: $[amount]
- Recent 5-year damage: $[amount]
- Risk classification: [ZONE]
- Trend: [DIRECTION]

## Pattern Recognition Rules

### For TOTAL DAMAGE:
- 10 digits ($X,XXX,XXX,XXX) = Billions = EXTREME territory
- 9 digits ($XXX,XXX,XXX) = Hundreds of millions = HIGH territory
- 8 digits or less = MODERATE/LOW territory

### For WORST EVENT vs TOTAL:
- If worst event is also 10 digits (billions) = Requires catastrophe modeling
- If worst event is half of total damage = High reinsurance attachment needed
- If worst event is small fraction of total = Standard reinsurance adequate

### For RECENT TREND:
- If recent damage is millions but total is billions = Territory improving
- If recent damage is large portion of total = Territory deteriorating
- Check Trend field: STABLE_OR_DECREASING vs INCREASING_RISK

### For EVENT FREQUENCY:
- 1000+ events = High frequency territory
- 500-999 = Moderate frequency territory
- Under 500 = Low frequency territory

## Generate County Insurance Output:

### Territory Classification: [STATE the RISK_ZONE from input]

### Key Territory Factors:
1. Loss concentration: [State worst event amount and proportion]
2. Frequency profile: [State total events and classification]
3. Trend analysis: [State if improving/deteriorating with recent vs total]

### Territory Rating Decision:
- EXTREME territory (billions, 1000+ events): Apply 1.35x factor
- If IMPROVING (recent tiny vs total): Reduce to 1.30x factor
- HIGH territory: Apply 1.20-1.25x factor
- MODERATE territory: Apply 1.00-1.10x factor
- LOW territory: Apply 0.85-0.95x factor

### Portfolio Management Strategy:
**Total Insured Value (TIV) Limit**: 
- EXTREME: Cap county at $500M aggregate exposure
- HIGH: Monitor at $1B threshold
- MODERATE/LOW: Standard concentration limits

**Reinsurance Attachment**:
- If worst event >$1B: Low attachment point required
- If worst event $100M-$1B: Standard attachment
- If worst event <$100M: Higher retention acceptable

**Market Appetite**:
- EXTREME + deteriorating: RESTRICT new business
- EXTREME + improving: SELECTIVE underwriting only
- HIGH: MONITOR with enhanced guidelines
- MODERATE/LOW: STANDARD to GROWTH appetite

***
- RISK PATTERN: Notable risk patterns that warrant further investigation
- RISK FACTORS: Potential risk factors not captured in traditional models
- AREAS FOR ANALYSIS: Suggested areas for detailed actuarial analysis
- OBSERVATION: Data quality observations or anomalies to verify
- RISK SCORE: Risk score (0-100)
- COVERAFE LIMITS: Recommended coverage limits
- PREMIUM: Suggested premium adjustment factor