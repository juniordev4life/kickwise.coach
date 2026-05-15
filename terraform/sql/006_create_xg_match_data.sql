CREATE TABLE IF NOT EXISTS `kickwise-prod.kickwise_main.xg_match_data` (
  match_id              STRING    NOT NULL OPTIONS(description="openligadb match id (FK to matches.match_id)"),
  team_id               STRING    NOT NULL OPTIONS(description="openligadb team id"),
  season_id             STRING    OPTIONS(description="'YYYY/YYYY+1' to match seasons.season_id"),
  is_home               BOOL      OPTIONS(description="TRUE when this row represents the home side of the match"),
  xg                    FLOAT64   OPTIONS(description="Team-level expected goals scored"),
  xga                   FLOAT64   OPTIONS(description="Team-level expected goals against (opponent's xG)"),
  shots                 INT64,
  shots_on_target       INT64,
  deep_passes           INT64     OPTIONS(description="Passes completed within ~20m of the opponent goal"),
  ppda                  FLOAT64   OPTIONS(description="Opponent passes per defensive action — pressing intensity"),
  source                STRING    OPTIONS(description="'understat' for now"),
  understat_match_id    STRING,
  last_synced_at        TIMESTAMP
)
CLUSTER BY match_id, team_id
OPTIONS (
  description = "Team-level xG and shot statistics per match. One row per team per match. Sourced from Understat."
);
