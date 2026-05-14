CREATE TABLE IF NOT EXISTS `kickwise-prod.kickwise_main.matches` (
  match_id        STRING    NOT NULL OPTIONS(description="Stabiler Match-Identifier"),
  season_id       STRING    NOT NULL,
  matchday        INT64     NOT NULL,
  home_team_id    STRING    NOT NULL,
  away_team_id    STRING    NOT NULL,
  kickoff_at      TIMESTAMP NOT NULL,
  home_score      INT64,
  away_score      INT64,
  status          STRING    OPTIONS(description="'scheduled' | 'live' | 'finished' | 'postponed'"),
  last_synced_at  TIMESTAMP
)
PARTITION BY DATE(kickoff_at)
CLUSTER BY season_id, home_team_id, away_team_id
OPTIONS (
  description = "Alle Bundesliga-Spiele (historisch + zukünftig). Geführt vom Scout-Service."
);
