-- Step 2.1.6.A: Create intermediate alert conditions table with prompts
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
  
  -- Construct alert evaluation prompts for debugging visibility
  CONCAT(
    '''{COUNTY_ALERT_CLASSIFICATION_PROMPT}''', 
    'County ', county_name, ' has ',
    CAST(current_activity_level AS STRING), ' recent reports with ',
    CAST(current_severe_threats AS STRING), ' severe threats. ',
    'Historical average: ', CAST(ROUND(annual_event_frequency, 1) AS STRING), ' events/year. ',
    'Is this an abnormal situation requiring immediate attention? Answer only TRUE or FALSE.'
  ) AS abnormal_activity_prompt,
  
  CONCAT(
    '''{COUNTY_ALERT_CLASSIFICATION_PROMPT}''',
    'With ', CAST(current_severe_threats AS STRING), ' severe threats reported ',
    'and historical worst case of $', CAST(ROUND(worst_case_event, 0) AS STRING), ', ',
    'should customers be notified of elevated risk? Answer only TRUE or FALSE.'
  ) AS customer_alert_prompt,
  
  CONCAT(
    '''{COUNTY_ALERT_CLASSIFICATION_PROMPT}''',  
    'County has $', CAST(ROUND(recent_5yr_damage, 0) AS STRING), ' damage in last 5 years ',
    'compared to $', CAST(ROUND(total_historical_damage - recent_5yr_damage, 0) AS STRING), ' in prior years. ',
    'Is the risk trend significantly increasing? Answer only TRUE or FALSE.'
  ) AS increasing_risk_prompt,
  
  -- Pre-calculate alert priority for reference
  CASE 
    WHEN current_severe_threats >= 5 THEN 'CRITICAL'
    WHEN current_severe_threats >= 2 THEN 'HIGH'
    WHEN current_activity_level >= 10 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS suggested_priority,
  
  CURRENT_TIMESTAMP() AS prompt_creation_timestamp
  
FROM `{DATASET_ID}.enriched_location_master`
WHERE current_activity_level > 0;  -- Only evaluate counties with recent activity

-- Step 2.1.6.B: Generate alert triggers using AI.GENERATE_BOOL on prepared prompts
CREATE OR REPLACE TABLE `{DATASET_ID}.alert_triggers` AS
SELECT
  county_fips,
  county_name,
  state,
  current_activity_level,
  current_severe_threats,
  
  -- Generate boolean alert for abnormal activity
  AI.GENERATE_BOOL(
    abnormal_activity_prompt,
    connection_id => '{PROJECT_ID}.{VERTEX_AI_CONNECTION_LOCATION}.{VERTEX_AI_CONNECTION_ID}',
    endpoint => '{VERTEX_AI_CONNECTION_MODEL}'
  ).result AS is_abnormal_activity,
  
  -- Generate boolean alert for customer notification
  AI.GENERATE_BOOL(
    customer_alert_prompt,
    connection_id => '{PROJECT_ID}.{VERTEX_AI_CONNECTION_LOCATION}.{VERTEX_AI_CONNECTION_ID}',
    endpoint => '{VERTEX_AI_CONNECTION_MODEL}'
  ).result AS should_alert_customers,
  
  -- Generate boolean alert for increasing risk trend
  AI.GENERATE_BOOL(
    increasing_risk_prompt,
    connection_id => '{PROJECT_ID}.{VERTEX_AI_CONNECTION_LOCATION}.{VERTEX_AI_CONNECTION_ID}',
    endpoint => '{VERTEX_AI_CONNECTION_MODEL}'
  ).result AS has_increasing_risk,
  
  -- Include the suggested priority from conditions table
  suggested_priority AS alert_priority,
  
  -- Include context for alert actions
  CASE
    WHEN current_severe_threats > 0 THEN 
      CONCAT('Active severe threats detected: ', CAST(current_severe_threats AS STRING))
    WHEN current_activity_level > annual_event_frequency * 2 THEN
      'Activity level significantly above historical average'
    ELSE 'Monitoring for changes'
  END AS alert_context,
  
  -- Include original prompts for audit trail
  abnormal_activity_prompt AS abnormal_prompt_used,
  customer_alert_prompt AS customer_prompt_used,
  increasing_risk_prompt AS risk_trend_prompt_used,
  
  CURRENT_TIMESTAMP() AS evaluation_timestamp
  
FROM `{DATASET_ID}.alert_conditions`;
