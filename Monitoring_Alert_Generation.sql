-- Query 2.1.3.B: Generate monitoring alerts
CREATE OR REPLACE TABLE `{DATASET_ID}.monitoring_alerts_generated` AS
SELECT
  -- Extract the monitoring assessment text
  ml_generate_text_result['candidates'][0]['content']['parts'][0]['text'] AS monitoring_alert_text,
  
  -- Include relevant fields
  county_fips,
  county_name,
  state,
  current_activity_level,
  current_severe_threats,
  monitoring_prompt,
  CURRENT_TIMESTAMP() AS alert_timestamp
  
FROM
  ML.GENERATE_TEXT(
    MODEL `{DATASET_ID}.{VERTEX_AI_CONNECTION_MODEL_ENDPOINT}`,
    (
      SELECT
        county_fips,
        county_name,
        state,
        current_activity_level,
        current_severe_threats,
        monitoring_prompt,
        monitoring_prompt AS prompt  -- Required column name
      FROM
        `{DATASET_ID}.assessment_prompts{SET_SAMPLE}`
      WHERE 
        county_fips IS NOT NULL 
        AND county_name IS NOT NULL 
        AND state IS NOT NULL
        AND current_activity_level > 0  -- Only process active areas
    ),
    STRUCT(
      {TEMPERATURE} AS temperature,  -- Lower temperature for consistent alerts
      {MAX_OUTPUT_TOKEN} AS max_output_tokens,
      {TOP_P} AS top_p
    )
  );