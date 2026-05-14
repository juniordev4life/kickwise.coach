CREATE TABLE IF NOT EXISTS `kickwise-prod.kickwise_main.players` (
  player_id      STRING NOT NULL,
  name           STRING NOT NULL,
  team_id        STRING,
  position       STRING OPTIONS(description="'GK' | 'DEF' | 'MID' | 'FWD'"),
  dob            DATE,
  nationality    STRING,
  shirt_number   INT64,
  last_synced_at TIMESTAMP
)
CLUSTER BY team_id
OPTIONS (
  description = "Bundesliga-Spieler. Phase 1: grobe Stammdaten von openligadb. Phase 2: angereichert mit FBref/Understat-Daten."
);
