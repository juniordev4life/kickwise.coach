CREATE TABLE IF NOT EXISTS `kickwise-prod.kickwise_main.seasons` (
  season_id   STRING    NOT NULL OPTIONS(description="Saison-Identifier, z.B. '2024/2025'"),
  league      STRING    NOT NULL OPTIONS(description="Liga-Code, z.B. 'BL1' für 1. Bundesliga"),
  start_date  DATE      OPTIONS(description="Erstes Spiel der Saison"),
  end_date    DATE      OPTIONS(description="Letztes Spiel der Saison"),
  is_current  BOOL      OPTIONS(description="Aktuelle Saison"),
  last_synced_at TIMESTAMP OPTIONS(description="Zeitpunkt des letzten Scout-Imports")
)
OPTIONS (
  description = "Bundesliga-Saisons. Geführt vom Scout-Service."
);
