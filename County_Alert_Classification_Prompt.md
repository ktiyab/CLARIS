# County Alert Evaluation - Pattern Matching

## Input Recognition

### Pattern A: Activity Anomaly
"County [NAME] has [CURRENT] recent reports with [THREATS] severe threats. Historical average: [HISTORICAL] events/year"

### Pattern B: Customer Notification
"With [THREATS] severe threats and historical worst case of $[WORST_CASE]"

### Pattern C: Risk Trend
"County has $[RECENT_5YR] damage in last 5 years compared to $[PRIOR_YEARS] in prior years"

## Digit Pattern Rules

### DOLLAR AMOUNTS:
- 10+ digits = BILLIONS (e.g., $1,234,567,890)
- 9 digits = HUNDREDS OF MILLIONS (e.g., $123,456,789)
- 8 digits = TENS OF MILLIONS (e.g., $12,345,678)
- 7 digits = MILLIONS (e.g., $1,234,567)
- 6 digits or less = UNDER MILLION

### EVENT COUNTS:
- 3+ digits = HUNDREDS OR MORE (100+)
- 2 digits = TENS (10-99)
- 1 digit = SINGLE DIGITS (0-9)

## Alert Decision Patterns

### ABNORMAL ACTIVITY = TRUE when:
- Current reports has MORE digits than historical average
- Current is 2+ digits (10+) AND historical is 1 digit (under 10)
- Severe threats is 5+ regardless of history
- Current is 50+ with any severe threats

### CUSTOMER ALERT = TRUE when:
- Worst case is 10+ digits (BILLIONS) with ANY threats
- Worst case is 9 digits (HUNDREDS OF MILLIONS) with 3+ threats
- Worst case is 8 digits (TENS OF MILLIONS) with 5+ threats
- Severe threats is 10+ regardless of worst case

### INCREASING RISK = TRUE when:
- Recent 5yr has SAME number of digits as prior years
- Recent 5yr has MORE digits than prior years
- Recent 5yr is 9+ digits (HUNDREDS OF MILLIONS+)
- Prior years is 10+ digits BUT recent is also 9+ digits

## FALSE Conditions

### ABNORMAL ACTIVITY = FALSE when:
- Current has FEWER digits than historical
- Both are single digits
- Current is 0 reports

### CUSTOMER ALERT = FALSE when:
- Severe threats is 0
- Worst case is 7 digits or less (MILLIONS) with under 3 threats

### INCREASING RISK = FALSE when:
- Recent 5yr has 2+ FEWER digits than prior (e.g., millions vs billions)
- Recent 5yr is 7 digits or less (MILLIONS or less)
- Prior years has 10+ digits and recent has 8 or fewer digits

## Examples

**Activity Check:**
- "50 reports, historical 15/year" → 50 is 2 digits, 15 is 2 digits → Check if 50 >3x pattern → TRUE
- "3 reports, historical 100/year" → 3 is 1 digit, 100 is 3 digits → FALSE

**Customer Alert:**
- "5 threats, worst $2,000,000,000" → 10 digits + threats → TRUE
- "2 threats, worst $50,000,000" → 8 digits + under 3 threats → FALSE

**Risk Trend:**
- "$800,000,000 recent vs $2,000,000,000 prior" → 9 digits vs 10 digits → TRUE (both high)
- "$5,000,000 recent vs $3,000,000,000 prior" → 7 digits vs 10 digits → FALSE (3 digits difference)

## Output
Answer only: TRUE or FALSE