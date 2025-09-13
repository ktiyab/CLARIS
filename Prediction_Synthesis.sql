-- Synthesize all AI outputs into unified predictions
CREATE OR REPLACE TABLE `{DATASET_ID}.prediction_synthesis` AS
SELECT
  l.county_fips,
  l.county_name,
  l.state,
  
  -- Combine all AI-generated insights
  n.risk_assessment_text AS risk_narrative,
  c.risk_score,
  c.risk_tier,
  c.confidence_level,
  c.primary_hazard,
  c.premium_factor,
  IFNULL(a.is_abnormal_activity, FALSE) AS has_abnormal_activity,
  IFNULL(a.should_alert_customers, FALSE) AS customer_alert_needed,
  
  -- Include source metrics for validation
  l.total_historical_damage,
  l.recent_5yr_damage,
  l.current_activity_level,
  
  CURRENT_TIMESTAMP() AS synthesis_timestamp
  
FROM `{DATASET_ID}.enriched_location_master` l
LEFT JOIN `{DATASET_ID}.risk_narratives_generated` n
  ON l.county_fips = n.county_fips 
  AND l.county_name = n.county_name 
  AND l.state = n.state
LEFT JOIN `{DATASET_ID}.ai_risk_classifications` c
  ON l.county_fips = c.county_fips 
  AND l.county_name = c.county_name 
  AND l.state = c.state
LEFT JOIN `{DATASET_ID}.alert_triggers` a
  ON l.county_fips = a.county_fips 
  AND l.county_name = a.county_name 
  AND l.state = a.state;