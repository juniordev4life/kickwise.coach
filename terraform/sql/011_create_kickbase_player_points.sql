-- Kickbase per-matchday point history per player. One row per (player,
-- season, matchday). Fed by the nightly player-snapshot job in Scout — it
-- already calls the Kickbase player detail endpoint which carries the
-- pointsHistory array.
--
-- Used by the projection model to estimate recent form (last N matchdays)
-- and by the backtest to score historical predictions against the real
-- Kickbase output (Phase 3+).

CREATE TABLE IF NOT EXISTS `kickwise-prod.kickwise_main.kickbase_player_points` (
  player_id       STRING    NOT NULL OPTIONS(description="Kickbase player id (matches players.player_id)"),
  season_id       STRING    NOT NULL OPTIONS(description="'YYYY/YYYY+1', e.g. '2025/2026'"),
  matchday        INT64     NOT NULL OPTIONS(description="Bundesliga matchday 1–34"),
  points          INT64     OPTIONS(description="Kickbase points scored that matchday"),
  has_played      BOOL      OPTIONS(description="TRUE if the player actually appeared (vs. on bench)"),
  source          STRING    OPTIONS(description="'kickbase-snapshot' for now"),
  last_synced_at  TIMESTAMP
)
CLUSTER BY player_id, season_id
OPTIONS (
  description = "Kickbase per-matchday points per player. Composite key (player_id, season_id, matchday)."
);
