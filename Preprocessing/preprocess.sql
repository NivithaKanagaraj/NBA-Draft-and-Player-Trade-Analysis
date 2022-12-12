/*The data contains every basketball game played from 2003 to 2021.*/

/*rename column 'TO' to 'TurnOvers'  to avoid syntax complications*/
sp_RENAME 'games_details.TO', 'TurnOvers', 'COLUMN'



/*Queries from game_details and combines the individual stats of each player for every game played
in order to get average steals, blocks*/
WITH CTE_steals_blocks as(
SELECT GAME_ID, TEAM_abbreviation, TEAM_ID,
		SUM(CAST(STL as decimal)) AS total_STL, 
		SUM(CAST(BLK as decimal)) AS total_BLK,
		SUM(CAST(games_details.TurnOvers as decimal)) AS total_TO
FROM games_details
WHERE games_details.STL != ' ' and games_details.STL is not NULL
GROUP BY GAME_ID, TEAM_ID, TEAM_ID, TEAM_ABBREVIATION
)

/* adds the table created above which contains steals, blocks, turnovers, into temp dbo.games_MoreStats,
which contains other important stats for every game played */
SELECT games.*,TB.total_BLK AS home_BLK, tb. total_STL AS HOME_STL, TB.total_TO AS home_TO, 
		ta.total_BLK AS away_BLK, ta.total_STL AS away_STL, ta.total_TO AS away_TO
INTO dbo.#games_MoreStats
FROM games
INNER JOIN CTE_steals_blocks as TB on games.GAME_ID = tb.GAME_ID AND games.HOME_TEAM_ID =  tb.TEAM_ID
INNER JOIN CTE_steals_blocks as TA on games.GAME_ID = ta.GAME_ID AND games.VISITOR_TEAM_ID = ta.TEAM_ID
ORDER BY GAME_ID DESC

/*We are interested in the season averages, not the individual games played by each team. So, we 
need to aggregate the data to obtain the season averages*/
--Acquiring the average stats each season for the home games*/
SELECT HOME_TEAM_ID  AS TEAM_ID,
	SEASON,
	AVG(CAST(PTS_home AS decimal(6,3))) as AVG_PTS, 
	AVG(CAST(FG_PCT_home AS decimal(6,3))) as AVG_FG_PCT,
	AVG(CAST(FT_PCT_home AS decimal(6,3))) as AVG_FT_PCT,
	AVG(CAST(FG3_PCT_home AS decimal(6,3))) as AVG_FG3_PCT,
	AVG(CAST(AST_HOME AS decimal(6,3))) as AVG_AST,
	AVG(CAST(REB_HOME AS decimal(6,3))) as AVG_REB,
	AVG(CAST(home_BLK AS decimal(6,3))) as AVG_BLK,
	AVG(CAST(home_STL AS decimal(6,3))) as AVG_STL,
	AVG(CAST(home_TO AS decimal(6,3))) as AVG_TO
INTO dbo.#TempALLHOME
FROM dbo.#games_MoreStats
WHERE (PTS_home != ' '  and PTS_home IS NOT NULL) 
GROUP BY HOME_TEAM_ID, SEASON
ORDER BY SEASON DESC


/*Acquiring the average stats each season for the away games*/
SELECT VISITOR_TEAM_ID  AS TEAM_ID,
	SEASON,
	AVG(CAST(PTS_away AS decimal(6,3))) as AVG_PTS, 
	AVG(CAST(FG_PCT_away AS decimal(6,3))) as AVG_FG_PCT,
	AVG(CAST(FT_PCT_away AS decimal(6,3))) as AVG_FT_PCT,
	AVG(CAST(FG3_PCT_away AS decimal(6,3))) as AVG_FG3_PCT,
	AVG(CAST(AST_away AS decimal(6,3))) as AVG_AST,
	AVG(CAST(REB_away AS decimal(6,3))) as AVG_REB,
	AVG(CAST(away_BLK AS decimal(6,3))) as AVG_BLK,
	AVG(CAST(away_STL AS decimal(6,3))) as AVG_STL,
	AVG(CAST(away_TO AS decimal(6,3))) as AVG_TO
INTO dbo.#TempALLAWAY
FROM dbo.#games_MoreStats
WHERE (PTS_away != ' '  and PTS_away IS NOT NULL) 
GROUP BY VISITOR_TEAM_ID, SEASON
ORDER BY SEASON DESC


/*Each team has games where they play at home court, and away. To get the average statistics of a team in that season, we need to combine 
the stats of the individual games they play at home, and away.*/

--combine both temp tables to get yearly averages for each team into  dbo.allSeasonAVG in db*/
SELECT #TempALLHOME.TEAM_ID,
	teams.ABBREVIATION AS TEAM_NAME,
	#TempALLHOME.SEASON,
	(#TempALLHOME.AVG_PTS + #TempALLAWAY.AVG_PTS)/2 as AVG_PTS,
	(#TempALLHOME.AVG_FG_PCT + #TempALLAWAY.AVG_FG_PCT)/2 as AVG_FG_PCT,
	(#TempALLHOME.AVG_FT_PCT + #TempALLAWAY.AVG_FT_PCT)/2 as AVG_FT_PCT,
	(#TempALLHOME.AVG_FG3_PCT + #TempALLAWAY.AVG_FG3_PCT)/2 as AVG_FG3_PCT,
	(#TempALLHOME.AVG_AST +#TempALLAWAY.AVG_AST)/2 as AVG_AST,
	(#TempALLHOME.AVG_REB + #TempALLAWAY.AVG_REB)/2 as AVG_REB,
	(#TempALLHOME.AVG_BLK + #TempALLAWAY.AVG_BLK)/2 as AVG_BLK,
	(#TempALLHOME.AVG_STL + #TempALLAWAY.AVG_STL)/2 as AVG_STL,
	(#TempALLHOME.AVG_TO + #TempALLAWAY.AVG_STL)/2 as AVG_TO
INTO dbo.All_SeasonAverage
FROM #TempALLHOME
FULL JOIN #TempALLAWAY
ON #TempALLHOME.TEAM_ID = #TempALLAWAY.TEAM_ID and #TempALLAWAY.SEASON = #TempALLHOME.SEASON
RIGHT JOIN dbo.teams
ON teams.TEAM_ID = #TempALLHOME.TEAM_ID
ORDER BY #TempALLHOME.SEASON DESC



/*In the rankings table, we want the total wins, losses, and win percentage of each team at the end of the season. However, 
the data contained the current standings of each team everyday from the beginning of the season to the end.
We needed to determine just the final standings at the end of the season, so we acquired this based on the 
most games played, most wins, and most losses(ranking.G)*/

--Replace team names to their abbreviation to keep data consistent throughout the tables
 SELECT TEAM, 
		CASE WHEN team = 'Sacramento' THEN REPLACE(team, 'Sacramento', 'SAC')
	     WHEN team = 'Denver' THEN REPLACE(team, 'Denver', 'DEN')
		 WHEN team = 'Dallas' THEN REPLACE(team, 'Dallas', 'DAL')
		 WHEN team = 'L.A. Lakers' THEN REPLACE(team, 'L.A. Lakers', 'LAL')
		 WHEN team = 'New Orleans' THEN REPLACE(team, 'New Orleans', 'NOP')
		 WHEN team = 'Golden State' THEN REPLACE(team, 'Golden State', 'GSW')
		 WHEN team = 'Houston' THEN REPLACE(team, 'Houston', 'HOU')
		 WHEN team = 'Memphis' THEN REPLACE(team, 'Memphis', 'MEM')
		 WHEN team = 'Minnesota' THEN REPLACE(team, 'Minnesota', 'MIN')
		 WHEN team = 'Phoenix' THEN REPLACE(team, 'Phoenix', 'PHX')
		 WHEN team = 'Portland' THEN REPLACE(team, 'Portland', 'POR')
		 WHEN team = 'Utah' THEN REPLACE(team, 'Utah', 'UTA')
		 WHEN team = 'LA Clippers' THEN REPLACE(team, 'LA Clippers', 'LAC')
		 WHEN team = 'L.A. Clippers' THEN REPLACE(team, 'L.A. Clippers', 'LAC')
		 WHEN team = 'Oklahoma City' THEN REPLACE(team, 'Oklahoma City', 'OKC')
		 WHEN team = 'San Antonio' THEN REPLACE(team, 'San Antonio', 'SAS')
		 WHEN team = 'Philadelphia' THEN REPLACE(team, 'Philadelphia', 'PHI')
		 WHEN team = 'Brooklyn' THEN REPLACE(team, 'Brooklyn', 'BKN')
		 WHEN team = 'Milwaukee' THEN REPLACE(team, 'Milwaukee', 'MIL')
		 WHEN team = 'New York' THEN REPLACE(team, 'New York', 'NYK')
		 WHEN team = 'Atlanta' THEN REPLACE(team, 'Atlanta', 'ATL')
		 WHEN team = 'Miami' THEN REPLACE(team, 'Miami', 'MIA')
		 WHEN team = 'Boston' THEN REPLACE(team, 'Boston', 'BOS')
		 WHEN team = 'Washington' THEN REPLACE(team, 'Washington', 'WAS')
		 WHEN team = 'Indiana' THEN REPLACE(team, 'Indiana', 'IND')
		 WHEN team = 'Charlotte' THEN REPLACE(team, 'Charlotte', 'CHA')
		 WHEN team = 'Chicago' THEN REPLACE(team, 'Chicago', 'CHI')
		 WHEN team = 'Toronto' THEN REPLACE(team, 'Toronto', 'TOR')
		 WHEN team = 'Cleveland' THEN REPLACE(team, 'Cleveland', 'CLE')
		 WHEN team = 'Orlando' THEN REPLACE(team, 'Orlando', 'ORL')
		 WHEN team = 'Detroit' THEN REPLACE(team, 'Detroit', 'DET')	 
         WHEN team = 'Seattle' THEN REPLACE(team, 'Seattle', 'OKC')
         WHEN team = 'New Orleans/Oklahoma City' THEN REPLACE(team, 'New Orleans/Oklahoma City', 'NOP')
         WHEN team = 'New Jersey' THEN REPLACE(team, 'New Jersey', 'BKN')
	END AS Team_Name, 		
	SUBSTRING(SEASON_ID, 2,4)+1 AS SEASON,  /*Season ID was in awkward format, used substring to adjust to appropriate year*/
	MAX(CAST(ranking.G AS INT)) AS Total_Games, 
	MAX(CAST(ranking.W AS INT)) AS Win,
	MAX(CAST(ranking.L AS INT)) AS Lose
 INTO dbo.All_SeasonStandings
 FROM ranking 
 GROUP BY SEASON_ID, team
 --Filtering the total games with 82 or 66 as the total games for that season, so we can get the final season standings.
 HAVING  (MAX(CAST(ranking.G AS INT)) = 66 or  MAX(CAST(ranking.G AS INT)) = 82) and CAST(SUBSTRING(SEASON_ID, 2,4)+1 as int) < 2020
 ORDER BY SEASON_ID desc

/*CREATE NEW COLUMN and adding WIN_PCT*/
ALTER TABLE All_SeasonStandings
ADD win_PCT decimal(8,3)

/*acquired win percenteage*/
UPDATE All_SeasonStandings
SET win_PCT = (CAST(win AS decimal(8,3))/CAST(total_games AS decimal(8,3)))



/* We now have one table containing the season standings and win percentage, and another with just 
the average stats of each season. Now we combine them  into nba_SeasonAVG_final*/
SELECT All_SeasonAverage.TEAM_NAME,
		All_SeasonAverage.SEASON,
		Total_Games,
		Win,
		Lose,
		win_PCT,
		AVG_PTS,
		AVG_AST,
		AVG_REB,
		AVG_FT_PCT,
		AVG_FG_PCT,
		AVG_FG3_PCT,
		AVG_BLK,
		AVG_STL,
		AVG_TO
INTO NBA_SeasonData
FROM All_SeasonAverage
INNER JOIN All_SeasonStandings ON
All_SeasonAverage.TEAM_NAME = All_SeasonStandings.Team_name and All_SeasonStandings.SEASON = All_SeasonAverage.SEASON
ORDER BY All_SeasonStandings.season desc
