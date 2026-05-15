-- Match-Predictions pro Modell-Run. Mehrere Versionen werden archiviert, sodass
-- wir später Modelle vergleichen können (poisson-xg-v1 vs. v2 vs. ML).
--
-- Phase 2 schreibt aktuell Records on-the-fly über die Engine, das Cachen in
-- diese Tabelle folgt in einem zweiten Schritt (Batch-Run, manuelles MERGE
-- siehe Engine `cacheService`).

CREATE TABLE IF NOT EXISTS `kickwise-prod.kickwise_main.predictions` (
  match_id            STRING    NOT NULL OPTIONS(description="openligadb match id (FK to matches.match_id)"),
  model_version       STRING    NOT NULL OPTIONS(description="z. B. 'poisson-xg-v1'"),
  run_at              TIMESTAMP NOT NULL OPTIONS(description="Zeitpunkt der Berechnung"),
  prob_home_win       FLOAT64,
  prob_draw           FLOAT64,
  prob_away_win       FLOAT64,
  expected_home_goals FLOAT64,
  expected_away_goals FLOAT64,
  features            JSON      OPTIONS(description="Snapshot der Feature-Werte (Form, xG-Avg, Home-Advantage, ...) damit der Run reproduzierbar bleibt")
)
PARTITION BY DATE(run_at)
CLUSTER BY match_id
OPTIONS (
  description = "Match-Predictions pro Modell-Run. Eine Zeile pro (match, model_version, run_at)."
);
