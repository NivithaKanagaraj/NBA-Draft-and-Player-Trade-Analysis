--all season average
  select 
    sum(case when TEAM_NAME is null then 1 else 0 end) as TEAM_NAME, 
    sum(case when SEASON is null then 1 else 0 end) as SEASON, 
    sum(case when AVG_PTS is null then 1 else 0 end) as AVG_PTS,
	sum(case when AVG_FG_PCT is null then 1 else 0 end) as AVG_FG_PCT,
	sum(case when AVG_FT_PCT is null then 1 else 0 end) as AVG_FT_PCT,
	sum(case when AVG_FG3_PCT is null then 1 else 0 end) as AVG_FG3_PCT,
	sum(case when AVG_AST is null then 1 else 0 end) as AVG_AST,
	sum(case when AVG_REB is null then 1 else 0 end) as AVG_REB,
	sum(case when AVG_BLK is null then 1 else 0 end) as AVG_BLK,
	sum(case when AVG_STL is null then 1 else 0 end) as AVG_STL,
	sum(case when AVG_TO is null then 1 else 0 end) as AVG_TO
from [nba_dataset].[dbo].[AllSeason_AVG]  


--all season standings
    select 
    sum(case when TEAM is null then 1 else 0 end) as TEAM, 
    sum(case when Team_Name is null then 1 else 0 end) as Team_Name, 
    sum(case when SEASON is null then 1 else 0 end) as SEASON,
	sum(case when Total_Games is null then 1 else 0 end) as Total_Games,
	sum(case when Win is null then 1 else 0 end) as Win,
	sum(case when Lose is null then 1 else 0 end) as Lose,
	sum(case when win_PCT is null then 1 else 0 end) as win_PCT
from [nba_dataset].[dbo].[AllSeasonStandings]

--nba season data


    select 
    sum(case when TEAM_NAME is null then 1 else 0 end) as TEAM_NAME, 
    sum(case when SEASON is null then 1 else 0 end) as SEASON, 
		sum(case when Total_Games is null then 1 else 0 end) as Total_Games,
	sum(case when Win is null then 1 else 0 end) as Win,
	sum(case when Lose is null then 1 else 0 end) as Lose,
	sum(case when win_PCT is null then 1 else 0 end) as win_PCT,
    sum(case when AVG_PTS is null then 1 else 0 end) as AVG_PTS,
	sum(case when AVG_FG_PCT is null then 1 else 0 end) as AVG_FG_PCT,
	sum(case when AVG_FT_PCT is null then 1 else 0 end) as AVG_FT_PCT,
	sum(case when AVG_FG3_PCT is null then 1 else 0 end) as AVG_FG3_PCT,
	sum(case when AVG_AST is null then 1 else 0 end) as AVG_AST,
	sum(case when AVG_REB is null then 1 else 0 end) as AVG_REB,
	sum(case when AVG_BLK is null then 1 else 0 end) as AVG_BLK,
	sum(case when AVG_STL is null then 1 else 0 end) as AVG_STL,
	sum(case when AVG_TO is null then 1 else 0 end) as AVG_TO
from [nba_dataset].[dbo].[NBA_SeasonData]