-- Step 2.1.6.A: Create alert condition prompts
CREATE OR REPLACE TABLE `{DATASET_ID}.alert_conditions` AS
SELECT 
  county_fips,
  county_name,
  state,
  current_activity_level,
  current_severe_threats,
  annual_event_frequency,
  worst_case_event,
  recent_5yr_damage,
  total_historical_damage,
  
  -- Abnormal activity detection prompt
  CONCAT(
    '{COUNTY_ALERT_CLASSIFICATION_PROMPT}', 
    'County ', county_name, ' has ',
    CAST(current_activity_level AS STRING), ' recent reports with ',
    CAST(current_severe_threats AS STRING), ' severe threats. ',
    'Historical average: ', CAST(ROUND(annual_event_frequency, 1) AS STRING), ' events/year. ',
    'Is this an abnormal situation requiring immediate attention? Answer only TRUE or FALSE.'
  ) AS abnormal_activity_prompt,
  
  -- Customer notification decision prompt
  CONCAT(
    '{COUNTY_ALERT_CLASSIFICATION_PROMPT}',
    'With ', CAST(current_severe_threats AS STRING), ' severe threats reported ',
    'and historical worst case of $', CAST(ROUND(worst_case_event, 0) AS STRING), ', ',
    'should customers be notified of elevated risk? Answer only TRUE or FALSE.'
  ) AS customer_alert_prompt,
  
  -- Risk trend evaluation prompt
  CONCAT(
    '{COUNTY_ALERT_CLASSIFICATION_PROMPT}',  
    'County has $', CAST(ROUND(recent_5yr_damage, 0) AS STRING), ' damage in last 5 years ',
    'compared to $', CAST(ROUND(total_historical_damage - recent_5yr_damage, 0) AS STRING), ' in prior years. ',
    'Is the risk trend significantly increasing? Answer only TRUE or FALSE.'
  ) AS increasing_risk_prompt,
  
  -- Priority for routing
  CASE 
    WHEN current_severe_threats >= 5 THEN 'CRITICAL'
    WHEN current_severe_threats >= 2 THEN 'HIGH'
    WHEN current_activity_level >= 10 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS suggested_priority
  
FROM `{DATASET_ID}.enriched_location_master`
WHERE current_activity_level > 0;  -- Only evaluate active counties

-- Step 2.1.6.B: Generate boolean alerts
CREATE OR REPLACE TABLE `{DATASET_ID}.alert_triggers` AS
SELECT
  county_fips,
  county_name,
  state,
  current_activity_level,
  current_severe_threats,
  
  -- Generate three boolean decisions
  AI.GENERATE_BOOL(
    abnormal_activity_prompt,
    connection_id => '{PROJECT_ID}.{VERTEX_AI_CONNECTION_LOCATION}.{VERTEX_AI_CONNECTION_ID}',
    endpoint => '{VERTEX_AI_CONNECTION_MODEL}'
  ).result AS is_abnormal_activity,
  
  AI.GENERATE_BOOL(
    customer_alert_prompt,
    connection_id => '{PROJECT_ID}.{VERTEX_AI_CONNECTION_LOCATION}.{VERTEX_AI_CONNECTION_ID}',
    endpoint => '{VERTEX_AI_CONNECTION_MODEL}'
  ).result AS should_alert_customers,
  
  AI.GENERATE_BOOL(
    increasing_risk_prompt,
    connection_id => '{PROJECT_ID}.{VERTEX_AI_CONNECTION_LOCATION}.{VERTEX_AI_CONNECTION_ID}',
    endpoint => '{VERTEX_AI_CONNECTION_MODEL}'
  ).result AS has_increasing_risk,
  
  suggested_priority AS alert_priority,
  CURRENT_TIMESTAMP() AS evaluation_timestamp
  
FROM `{DATASET_ID}.alert_conditions`;