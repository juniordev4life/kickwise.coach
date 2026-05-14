CREATE TABLE IF NOT EXISTS `kickwise-prod.kickwise_main.teams` (
  team_id      STRING NOT NULL OPTIONS(description="Stabiler Team-Identifier, primär von openligadb"),
  name         STRING NOT NULL,
  short_name   STRING OPTIONS(description="Kurzform, z.B. 'RBL'"),
  league       STRING,
  founded_year INT64,
  logo_url     STRING,
  last_synced_at TIMESTAMP
)
OPTIONS (
  description = "Bundesliga-Vereine. Geführt vom Scout-Service."
);
