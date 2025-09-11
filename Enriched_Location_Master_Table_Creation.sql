-- Create comprehensive location profiles combining historical and current signals
-- IMPORTANT: This table aggregates 75 years of NOAA data (1950-2025) at county level
-- All damage figures represent cumulative totals over this period, not annual amounts
-- Classifications are preliminary patterns for investigation, not insurance ratings
CREATE OR REPLACE TABLE `{DATASET_ID}.enriched_location_master` AS
WITH historical_summary AS (
  -- Aggregate historical data at county level (75-year cumulative totals)
  SELECT 
    county_fips,
    county_name,
    state,
    
    -- Overall risk metrics (cumulative since 1950)
    COUNT(DISTINCT year_month) AS months_with_events,
    COUNT(DISTINCT event_type) AS event_type_diversity,
    SUM(event_count) AS total_historical_events,
    SUM(total_damage) AS total_historical_damage,
    -- Correct monthly average: total damage divided by months in dataset
    SAFE_DIVIDE(
      SUM(total_damage), 
      (EXTRACT(YEAR FROM CURRENT_DATE()) - 1950) * 12
    ) AS avg_monthly_damage,
    STDDEV(total_damage) AS damage_volatility,
    MAX(max_single_event_damage) AS worst_case_event,
    
    -- Human impact summary (75-year totals)
    SUM(total_deaths) AS total_historical_deaths,
    SUM(total_injuries) AS total_historical_injuries,
    
    -- Recent trend indicators (last 5 years vs. historical baseline)
    SUM(CASE 
      WHEN event_year >= EXTRACT(YEAR FROM CURRENT_DATE()) - 5 
      THEN total_damage ELSE 0 
    END) AS recent_5yr_damage,
    
    SUM(CASE 
      WHEN event_year >= EXTRACT(YEAR FROM CURRENT_DATE()) - 5 
      THEN event_count ELSE 0 
    END) AS recent_5yr_events,
    
    -- Seasonal patterns
    STRING_AGG(DISTINCT seasonal_risk_period, ', ') AS seasonal_patterns,
    
    -- Most common and severe event types
    ARRAY_AGG(
      STRUCT(event_type, total_damage) 
      ORDER BY total_damage DESC 
      LIMIT 3
    ) AS top_damage_event_types
    
  FROM `{DATASET_ID}.historical_risk_master`
  GROUP BY 1, 2, 3
),
recent_reports_summary AS (
  -- Aggregate recent preliminary reports (real-time monitoring)
  SELECT 
    county,
    state,
    
    -- Recent activity indicators
    COUNT(*) AS preliminary_report_count_30d,
    COUNT(DISTINCT report_type) AS active_threat_types,
    
    -- Severity distributions
    SUM(CASE WHEN severity_category = 'SEVERE' THEN 1 ELSE 0 END) AS severe_reports_30d,
    SUM(CASE WHEN severity_category = 'MODERATE' THEN 1 ELSE 0 END) AS moderate_reports_30d,
    
    -- Evidence quality
    AVG(report_quality_score) AS avg_report_quality,
    SUM(CASE WHEN from_social_media THEN 1 ELSE 0 END) AS social_media_reports,
    
    -- Storm system indicators
    SUM(CASE WHEN part_of_storm_system THEN 1 ELSE 0 END) AS system_events_count,
    MAX(local_event_density) AS max_event_clustering,
    
    -- Most recent activity
    MAX(timestamp) AS last_report_timestamp,
    MIN(hours_since_report) AS hours_since_last_report
    
  FROM `{DATASET_ID}.event_reports_master`
  WHERE hours_since_report <= 720  -- Last 30 days
  GROUP BY 1, 2
),
-- Combine all location intelligence
location_profiles AS (
  SELECT 
    h.county_fips,
    h.county_name,
    h.state,
    
    -- Historical risk profile (75-year cumulative)
    h.total_historical_events,
    h.total_historical_damage,
    h.avg_monthly_damage,  -- Now correctly calculated as historical average
    h.damage_volatility,
    h.worst_case_event,
    h.event_type_diversity,
    h.recent_5yr_damage,
    h.recent_5yr_events,
    
    -- Current activity signals
    IFNULL(r.preliminary_report_count_30d, 0) AS current_activity_level,
    IFNULL(r.severe_reports_30d, 0) AS current_severe_threats,
    IFNULL(r.hours_since_last_report, 999999) AS hours_since_activity,
    
    -- Risk indicators (normalized for meaningful comparison)
    CASE 
      -- Volatility relative to average damage
      WHEN SAFE_DIVIDE(h.damage_volatility, h.avg_monthly_damage) > 100 THEN 'HIGH_VOLATILITY'
      WHEN SAFE_DIVIDE(h.damage_volatility, h.avg_monthly_damage) > 10 THEN 'MODERATE_VOLATILITY'
      ELSE 'LOW_VOLATILITY'
    END AS volatility_category,
    
    -- Trend analysis (comparing recent 5 years to historical average)
    CASE 
      WHEN h.recent_5yr_damage > 
        -- Calculate expected 5-year damage based on historical average
        SAFE_DIVIDE(h.total_historical_damage, EXTRACT(YEAR FROM CURRENT_DATE()) - 1950) * 5 * 2
      THEN 'INCREASING_RISK'  -- Recent damage is 2x+ the historical average
      ELSE 'STABLE_OR_DECREASING'
    END AS risk_trend,
    
    -- Combined risk score components (for AI processing)
    SAFE_DIVIDE(h.total_historical_damage, h.total_historical_events) AS damage_per_event,
    SAFE_DIVIDE(h.recent_5yr_events, 5.0) AS annual_event_frequency,
    
    -- Metadata
    h.top_damage_event_types,
    h.seasonal_patterns,
    CURRENT_TIMESTAMP() AS last_updated_timestamp
    
  FROM historical_summary h
  LEFT JOIN recent_reports_summary r
    ON h.county_name = r.county 
    AND h.state = r.state
)
SELECT 
  *,
  -- PRELIMINARY risk patterns for investigation (not insurance classifications)
  -- Based on 75-year cumulative totals and recent activity patterns
  CASE 
    -- Pattern suggesting need for immediate investigation
    WHEN (total_historical_damage > 500000000  -- $500M cumulative over 75 years
          AND recent_5yr_damage > total_historical_damage * 0.5)  -- 50%+ in last 5 years
      OR current_severe_threats > 10  -- Unusual current activity
      OR (worst_case_event > 100000000 AND recent_5yr_events > 5)  -- High severity + frequency
    THEN 'EXTREME_RISK_ZONE'  -- Flag for detailed actuarial analysis
    
    -- Pattern suggesting elevated attention needed
    WHEN total_historical_damage > 100000000  -- $100M cumulative over 75 years
      OR (current_severe_threats > 3 AND worst_case_event > 10000000)
      OR (recent_5yr_damage > total_historical_damage * 0.3)  -- 30%+ in last 5 years
    THEN 'HIGH_RISK_ZONE'  -- Warrants monitoring and verification
    
    -- Pattern suggesting moderate historical activity
    WHEN total_historical_damage > 10000000  -- $10M cumulative over 75 years
      OR total_historical_events > 50  -- Frequent but lower-severity events
    THEN 'MODERATE_RISK_ZONE'  -- Standard monitoring appropriate
    
    -- Limited historical activity pattern
    ELSE 'LOW_RISK_ZONE'  -- Baseline monitoring
  END AS preliminary_risk_classification
  -- NOTE: These classifications are AI-generated hypotheses for investigation,
  -- not industry-standard insurance risk ratings. Actual risk assessment requires
  -- population normalization, inflation adjustment, and professional actuarial analysis.

FROM location_profiles;