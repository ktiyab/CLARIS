-- Step 2.1.2.A: Create risk narrative preparation table
-- This table prepares structured text for LLM processing
CREATE OR REPLACE TABLE `{DATASET_ID}.risk_narrative_prep` AS
SELECT 
  county_fips,
  county_name,
  state,
  current_severe_threats,
  
  -- Construct comprehensive risk narrative
  CONCAT(
    'County: ', county_name, ', ', state, '. ',
    'Historical Profile: ',
    CAST(total_historical_events AS STRING), ' total events recorded, ',
    'causing $', CAST(ROUND(total_historical_damage, 0) AS STRING), ' in damages. ',
    'Average monthly damage: $', CAST(ROUND(avg_monthly_damage, 0) AS STRING), '. ',
    'Worst single event: $', CAST(ROUND(worst_case_event, 0) AS STRING), '. ',
    'Event diversity: ', CAST(event_type_diversity AS STRING), ' different hazard types. ',
    'Recent 5-year trend: ', CAST(recent_5yr_events AS STRING), ' events ',
    'with $', CAST(ROUND(recent_5yr_damage, 0) AS STRING), ' in damages. ',
    'Current status: ', CAST(current_activity_level AS STRING), ' reports in last 30 days, ',
    CAST(current_severe_threats AS STRING), ' severe threats. ',
    'Risk classification: ', preliminary_risk_classification, '. ',
    'Volatility: ', volatility_category, '. ',
    'Trend: ', risk_trend
  ) AS risk_context,
  
  -- Construct risk summary for embedding
  CONCAT(
    preliminary_risk_classification, ' risk zone with ',
    volatility_category, ' and ', risk_trend, '. ',
    'Primary threats from ', 
    ARRAY_TO_STRING(
      ARRAY(SELECT event_type FROM UNNEST(top_damage_event_types) GROUP BY 1), 
      ', '
    )
  ) AS risk_summary,
  
  -- Include key metrics for reference
  total_historical_damage,
  recent_5yr_damage,
  current_activity_level,
  preliminary_risk_classification
  
FROM `{DATASET_ID}.enriched_location_master`;

-- Step 2.1.2.B: Create assessment prompt preparation table
-- Prepare specific prompts for different AI tasks
CREATE OR REPLACE TABLE `{DATASET_ID}.assessment_prompts` AS
SELECT 
    county_fips,
    county_name,
    state,
    risk_context,
    risk_summary,
    current_activity_level,
    current_severe_threats,
    preliminary_risk_classification,
    total_historical_damage,
    
    -- Underwriting assessment prompt (with embedded business rules)
    CONCAT(
      '{COUNTY_RISK_EVALUATION_PROMPT}',
      'Context: Analyzing ', CAST((EXTRACT(YEAR FROM CURRENT_DATE()) - 1950) AS STRING), ' years of cumulative NOAA severe weather data (1950-', CAST(EXTRACT(YEAR FROM CURRENT_DATE()) AS STRING), ') at county aggregate level. ',
      'This represents total county exposure, not individual property risk. ',
      'Data includes all reported events and damages for the entire county over this historical period. ',
      'Review this county-level historical risk profile: ',
      risk_context,
      ' Based on this ', CAST((EXTRACT(YEAR FROM CURRENT_DATE()) - 1950) AS STRING), ' year aggregate data',
      'Note: Average monthly damage represents historical average over ', CAST((EXTRACT(YEAR FROM CURRENT_DATE()) - 1950) AS STRING), ' years, not current monthly exposure.'
    ) AS underwriting_prompt,
    
    -- Monitoring alert prompt  
    CONCAT(
      'Context: Comparing current 30-day activity against ', CAST((EXTRACT(YEAR FROM CURRENT_DATE()) - 1950) AS STRING), ' year historical baseline for county-wide events. ',
      'Evaluate recent activity pattern: ',
      'Location has ', CAST(current_activity_level AS STRING), ' reports in last 30 days with ',
      CAST(current_severe_threats AS STRING), ' severe events. ',
      'Historical baseline (', CAST((EXTRACT(YEAR FROM CURRENT_DATE()) - 1950) AS STRING), ' year county aggregate): ', risk_summary,
      ' Question: Does current activity suggest unusual pattern compared to historical baseline? ',
      'Identify specific factors that merit human analyst attention. ',
      'Distinguish between normal seasonal variation and potentially significant deviation.'
    ) AS monitoring_prompt,
    
    -- Comparative analysis prompt
    CONCAT(
      'Context: Comparing ', CAST((EXTRACT(YEAR FROM CURRENT_DATE()) - 1950) AS STRING), ' year cumulative county-level data across ', state, '. ',
      'All figures represent total historical impact, not annual rates. ',
      'Compare this county ', CAST((EXTRACT(YEAR FROM CURRENT_DATE()) - 1950) AS STRING), ' year profile to other ', state, ' counties: ',
      risk_summary,
      ' Considering this is cumulative historical data for the entire county: ',
      '1) What distinguishes this county risk pattern from others in the state? ',
      '2) Are there unique hazard combinations or frequencies to investigate? ',
      '3) What additional data would help validate these observations? '
    ) AS comparative_prompt
  
FROM `{DATASET_ID}.risk_narrative_prep`;