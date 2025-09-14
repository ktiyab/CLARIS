# County-Level Augmented Risk Intelligence System (CLARIS): A BigQuery AI-Powered Approach to Insurance Risk Pattern Discovery

## The context

Traditional data analytics excels at finding statistical correlations—calculating averages, detecting outliers, running regressions. 
But businesses increasingly need something different: the ability to recognize complex patterns in context, understand narrative relationships, and generate hypotheses from incomplete information. This is pattern matching, and it requires semantic understanding rather than just mathematical computation.
Until recently, this type of analysis required either manual review by domain experts or complex custom ML pipelines maintained by specialized teams.
BigQuery evolved from warehouse to intelligence platform through integrated GenAI functions that transform SQL into a pattern recognition language.

## The pilot

To demonstrate these capabilities, we've built a pilot system that processes 75 years of NOAA severe weather data for insurance risk assessment. The database currently contains data from January 1950 to April 2025, as entered by NOAA's National Weather Service (NWS). This dataset provides an ideal test case because it combines:
- Structured numerical data (wind speeds, damage estimates, geographic coordinates)
- Unstructured text (event descriptions, observer comments, preliminary reports)
- Real business value (insurance companies need better catastrophe risk assessment)
- Verifiable outcomes (historical weather events have known insurance impacts)

The pilot, called CLARIS (County-Level Augmented Risk Intelligence System), shows how BigQuery's GenAI functions can transform raw weather observations into actionable risk intelligence. 
McKinsey estimates that AI technologies could add up to $1.1 trillion in annual value for the global insurance industry—the approach demonstrated here contributes to capturing that value.

## The BigQuery ML functions

This tutorial showcases BigQuery ML functions processing 75 years of NOAA data entirely within SQL, no external platforms, no data movement, just queries invoking VertexAI models through native integration. Each function adds distinct pattern matching capabilities that traditional SQL cannot achieve.

The GoogleCloud BigQuery GenAI toolkit demonstrated:

- ML.GENERATE_TEXT: Transforms structured data into reasoned narratives, converting risk profiles into business-specific assessments with rating factors and portfolio recommendations
- ML.GENERATE_EMBEDDING: Creates 768-dimensional semantic fingerprints from risk summaries, encoding complex patterns into searchable vectors that capture meaning beyond numerical similarity
- VECTOR_SEARCH: Discovers analogous risk patterns across 3,000+ counties using cosine similarity, revealing non-obvious relationships like coastal hurricane zones matching inland tornado alleys in risk structure
- AI.GENERATE_TABLE: Produces schema-compliant structured outputs from unstructured assessments, generating typed columns (risk_score INT64, premium_factor FLOAT64) that integrate directly with downstream systems
- AI.GENERATE_BOOL: Converts complex evaluations into binary decisions, distinguishing genuine anomalies from noise by comparing current activity against historical baselines for automated alert routing

## What this article demonstrates

Through the CLARIS implementation, we'll show:

- How to prepare data for GenAI pattern matching—creating narrative structures that large language models can effectively process
- How to implement pattern matching pipelines in BigQuery—using ML.GENERATE_TEXT for narrative generation, AI.GENERATE_TABLE for structured hypothesis generation, ML.GENERATE_EMBEDDING for semantic fingerprinting, and VECTOR_SEARCH for pattern discovery.
- How pattern matching complements traditional analytics—augmenting rather than replacing statistical methods
- How to maintain rigor and traceability—ensuring AI-generated insights remain auditable and explainable

Each technical chapter includes actual SQL queries that readers can adapt for their own use cases. The goal isn't just to showcase what's possible, but to provide a practical template for implementing pattern matching in any domain where understanding context and relationships matters as much as calculating statistics.

- Pattern Matching at Scale with BigQuery's Generative AI - Part 1: https://ktiyab.substack.com/p/pattern-matching-at-scale-with-bigquerys
- Pattern Matching at Scale with BigQuery's Generative AI - Part 2: https://ktiyab.substack.com/p/pattern-matching-at-scale-with-bigquerys-617
