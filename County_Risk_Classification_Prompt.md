# County Risk Classification

## Input Structure
You will receive: "Analyze county with these characteristics: Total damage: $[AMOUNT], Event frequency: [NUMBER], Recent activity: [NUMBER] reports, Volatility: [CATEGORY]."

## Extract These Values
- Total damage: Look for dollar amount after "Total damage: $"
- Event frequency: Number after "Event frequency:"
- Recent activity: Number before "reports"
- Volatility: Category after "Volatility:" (HIGH_VOLATILITY/MODERATE_VOLATILITY/LOW_VOLATILITY)

## Pattern Recognition

### DAMAGE PATTERNS
- 10+ digits (billions): EXTREME damage level
- 9 digits (hundreds of millions): HIGH damage level  
- 8 digits (tens of millions): MEDIUM damage level
- 7 digits or less: LOW damage level

### FREQUENCY PATTERNS
- 1000+ events: EXTREME frequency
- 500-999: HIGH frequency
- 100-499: MEDIUM frequency
- <100: LOW frequency

### ACTIVITY PATTERNS
- 20+ reports: Very active
- 10-19 reports: Active
- 1-9 reports: Quiet
- 0 reports: Dormant

## Generate Required Output

### risk_score (0-100):
Base score from damage:
- Billions = 85
- Hundreds of millions = 65
- Tens of millions = 45
- Millions or less = 25

Adjustments:
- Add 10 if frequency >1000
- Add 10 if HIGH_VOLATILITY
- Add 5 if recent activity >10
- Subtract 5 if 0 recent activity

### risk_tier:
- EXTREME: risk_score 80-100
- HIGH: risk_score 60-79
- MEDIUM: risk_score 40-59
- LOW: risk_score 0-39

### confidence_level (0.0-1.0):
- 0.9: Damage and frequency both EXTREME or both LOW
- 0.7: Damage and frequency one level apart
- 0.5: Conflicting signals (EXTREME damage + LOW frequency)

### primary_hazard:
Match patterns:
- 1000+ events + any damage: "HAIL"
- <100 events + billion damage: "HURRICANE"
- 500+ events + HIGH_VOLATILITY: "SEVERE_STORM"
- Moderate frequency + consistent damage: "FLOOD"
- Mixed indicators: "MIXED_PERILS"

### premium_factor (0.5-5.0):
Based on risk_tier:
- EXTREME: 3.0-5.0
- HIGH: 2.0-3.0
- MEDIUM: 1.2-2.0
- LOW: 0.5-1.2

Volatility adjustment:
- HIGH_VOLATILITY: Use upper half of range
- LOW_VOLATILITY: Use lower half of range

## Output Format
risk_score: [number]
risk_tier: [LOW/MEDIUM/HIGH/EXTREME]
confidence_level: [0.0-1.0]
primary_hazard: [hazard type]
premium_factor: [0.5-5.0]