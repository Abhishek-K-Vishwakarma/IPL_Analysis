CREATE TABLE matches (id int,
					 city varchar,
					 date date,
					 player_of_match varchar,
					 venue varchar,
					 neutral_venue int,
					 team1 varchar,
					 team2 varchar,
					 toss_winner varchar,
					 toss_decision varchar,
					 winner varchar,
					 result varchar,
					 result_margin int,
					 eliminator varchar,
					 method varchar,
					 umpire1 varchar,
					 umpire2 varchar);
					 
copy matches from 'C:\Program Files\PostgreSQL\15\data\IPL Dataset\IPL_matches.csv' DELIMITER ',' CSV HEADER;

SELECT * FROM matches;

CREATE TABLE deliveries (id int,
						inning int,
						over int,
						ball int,
						batsman varchar,
						non_striker varchar,
						bowler varchar,
						batsman_runs int,
						extra_runs int,
						total_runs int,
						is_wicket int,
						dismissal_kind varchar,
						player_dismissed varchar,
						fielder varchar,
						extra_type varchar,
						batting_team varchar,
						bowling_team varchar);
						
copy deliveries from 'C:\Program Files\PostgreSQL\15\data\IPL Dataset\IPL_Ball.csv' DELIMITER ',' CSV HEADER;

SELECT * FROM deliveries;

--TASK 1
SELECT batsman, SUM(batsman_runs) AS runs, COUNT(ball) AS balls,
(CAST(SUM(batsman_runs) AS FLOAT) / COUNT(ball))*100 AS sr
FROM deliveries
WHERE NOT (extra_type = 'wides')
GROUP BY batsman
HAVING COUNT(ball) >= 500
ORDER BY sr desc
LIMIT 10;

--TASK 2
SELECT b.batsman, CAST(SUM(b.batsman_runs) AS FLOAT) / COUNT(CASE WHEN b.is_wicket = 1 THEN 1 END) AS average_runs,
SUM(b.is_wicket) AS dismissals,
COUNT(DISTINCT(EXTRACT(YEAR FROM m.date))) AS seasons_played
FROM deliveries AS b INNER JOIN matches AS m
ON b.id = m.id
GROUP BY b.batsman
HAVING COUNT(CASE WHEN b.is_wicket = 1 THEN 1 END) >= 1 AND COUNT(DISTINCT(EXTRACT(YEAR FROM m.date))) > 2
ORDER BY average_runs desc
LIMIT 10;

--TASK 3
SELECT b.batsman,
SUM(CASE WHEN b.batsman_runs = 6 OR b.batsman_runs = 4 THEN b.batsman_runs ELSE 0 END) AS boundry_runs,
SUM(b.batsman_runs) AS total_runs,
(CAST(SUM(CASE WHEN b.batsman_runs = 6 OR b.batsman_runs = 4 THEN batsman_runs ELSE 0 END) AS FLOAT) / SUM(b.batsman_runs)) * 100 AS boundry_percentage,
COUNT(DISTINCT(EXTRACT(YEAR FROM m.date))) AS seasons_played
FROM deliveries AS b INNER JOIN matches AS m
ON b.id = m.id
GROUP BY b.batsman
HAVING COUNT(DISTINCT(EXTRACT(YEAR FROM m.date))) > 2
ORDER BY boundry_percentage desc
LIMIT 10;

--TASK 4
SELECT bowler, COUNT(ball) AS balls_bowled, COUNT(ball)/6 AS over_bowled, SUM(total_runs) AS runs_conceded,
CAST(SUM(total_runs) AS FLOAT) / (COUNT(ball)/6) AS economy_rate
FROM deliveries
GROUP BY bowler
HAVING COUNT(ball) > 500
ORDER BY economy_rate
LIMIT 10;

--TASK 5
SELECT bowler, COUNT(ball) AS balls_bowled, COUNT(CASE WHEN is_wicket = 1 THEN 1 END) AS wickets_taken,
COUNT(ball) / COUNT(CASE WHEN is_wicket = 1 THEN 1 END) AS bowler_sr
FROM deliveries
GROUP BY bowler
HAVING COUNT(ball) > 500
ORDER BY bowler_sr
LIMIT 10;

--TASK 6
SELECT a.batsman AS all_rounder_player, SUM(batsman_runs) AS runs,(CAST(SUM(batsman_runs) AS FLOAT) / COUNT(ball))*100 AS batting_sr,
COUNT(is_wicket) AS wickets, b.bowler_sr
FROM deliveries AS a
INNER JOIN
(SELECT bowler, COUNT(ball) AS balls_bowled, COUNT(CASE WHEN is_wicket = 1 THEN 1 END) AS wickets_taken,
COUNT(ball) / COUNT(CASE WHEN is_wicket = 1 THEN 1 END) AS bowler_sr
FROM deliveries
GROUP BY bowler
HAVING COUNT(ball) > 500) AS b
ON a.batsman = b.bowler
WHERE NOT (extra_type = 'wides')
GROUP BY a.batsman, b.bowler_sr
HAVING COUNT(ball) > 500
ORDER BY batting_sr desc, bowler_sr asc
LIMIT 10;

--ADDITIONAL QUERY 1
SELECT COUNT(DISTINCT city) AS cities_hosted FROM matches;

--ADDITIONAL QUERY 2
CREATE TABLE deliveries_v02 AS SELECT *,
CASE WHEN 
total_runs >= 4 THEN 'Boundry'
WHEN total_runs = 0 THEN 'Dot'
ELSE 'Other'
END AS ball_result
FROM deliveries;

SELECT * FROM deliveries_v02;

--ADDITIONAL QUERY 3
SELECT COUNT(ball_result) AS no_boundry_dot FROM deliveries_v02
WHERE ball_result = 'Boundry' or ball_result = 'Dot';

--ADDITIONAL QUERY 4
SELECT batting_team AS team,
COUNT(ball_result) AS boundries
FROM deliveries_v02
WHERE ball_result = 'Boundry'
GROUP BY team
ORDER BY boundries DESC;

--ADDITIONAL QUERY 5
SELECT bowling_team,
COUNT(ball_result) AS dot_ball
FROM deliveries_v02
WHERE ball_result = 'Dot'
GROUP BY bowling_team
ORDER BY dot_ball DESC;

--ADDITIONAL QUERY 6
SELECT dismissal_kind,
COUNT(dismissal_kind) AS no_of_dismissals
FROM deliveries_v02
WHERE NOT (dismissal_kind = 'NA')
GROUP BY dismissal_kind;

--ADDITIONAL QUERY 7
SELECT bowler,
SUM(extra_runs) AS extra_runs_conceded
FROM deliveries
GROUP BY bowler
ORDER BY extra_runs_conceded DESC
LIMIT 5;

--ADDITIONAL QUERY 8
CREATE TABLE deliveries_v03 AS SELECT a.*,
b.venue, b.date AS match_date
FROM deliveries_v02 AS a
INNER JOIN
matches AS b
ON a.id = b.id;

SELECT * FROM deliveries_v03;

--ADDITIONAL QUERY 9
SELECT venue,
SUM(total_runs) AS runs_scored
FROM deliveries_v03
GROUP BY venue
ORDER BY runs_scored DESC;

--ADDITIONAL QUERY 10
SELECT DISTINCT(EXTRACT(YEAR FROM match_date)) AS years,
SUM(total_runs) AS runs_scored
FROM deliveries_v03
WHERE venue = 'Eden Gardens'
GROUP BY years
ORDER BY runs_scored DESC;

SELECT COUNT(CASE WHEN ball_result = 'Boundry' THEN 1 END) AS no_boundries,
COUNT(CASE WHEN ball_result = 'Dot' THEN 1 END) AS no_dot
FROM deliveries_v02;
