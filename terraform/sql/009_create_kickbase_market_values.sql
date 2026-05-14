CREATE TABLE IF NOT EXISTS `kickwise-prod.kickwise_main.kickbase_market_values` (
  player_id              STRING    NOT NULL,
  snapshot_date          DATE      NOT NULL,
  market_value           INT64,
  delta_24h              INT64,
  delta_7d               INT64,
  kickbase_total_points  INT64,
  last_synced_at         TIMESTAMP
)
PARTITION BY snapshot_date
CLUSTER BY player_id
OPTIONS (
  description = "Tägliche Marktwert-Snapshots pro Spieler aus der Kickbase-API. Composite key (player_id, snapshot_date)."
);
