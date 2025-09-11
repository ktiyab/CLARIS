-- Query 2.1.3.A: Generate comprehensive risk narratives
CREATE OR REPLACE TABLE `{DATASET_ID}.risk_narratives_generated` AS
SELECT
  -- Extract the generated text from the nested response structure
  ml_generate_text_result['candidates'][0]['content']['parts'][0]['text'] AS risk_assessment_text,
  
  -- Include all original fields except the raw ML result
  county_fips,
  county_name,
  state,
  risk_context,
  risk_summary,
  underwriting_prompt,
  CURRENT_TIMESTAMP() AS generation_timestamp
  
FROM
  ML.GENERATE_TEXT(
    MODEL `{DATASET_ID}.{VERTEX_AI_CONNECTION_MODEL_ENDPOINT}`,
    (
      -- Subquery must have a column named 'prompt' for ML.GENERATE_TEXT
      SELECT
        county_fips,
        county_name,
        state,
        risk_context,
        risk_summary,
        underwriting_prompt,
        underwriting_prompt AS prompt  -- Required column name for ML.GENERATE_TEXT
      FROM
        `{DATASET_ID}.assessment_prompts{SET_SAMPLE}`
        WHERE county_fips IS NOT NULL 
        AND county_name IS NOT NULL 
        AND state IS NOT NULL
    ),
    STRUCT(
      {TEMPERATURE} AS temperature,      -- e.g., 0.2 for consistent output
      {MAX_OUTPUT_TOKEN} AS max_output_tokens,  -- e.g., 1500
      {TOP_P} AS top_p,                  -- e.g., 0.8
      {TOP_K} AS top_k                   -- e.g., 40
    )
  );