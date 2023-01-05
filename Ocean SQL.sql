use ocean;

DROP TABLE IF EXISTS ocean_health;
DROP TABLE IF EXISTS subgoal;
DROP TABLE IF EXISTS region;
DROP TABLE IF EXISTS goal;

/*Target tables created*/
CREATE TABLE goal (
goal_id VARCHAR(6), 
goal_description VARCHAR(50),
PRIMARY KEY (goal_id));

CREATE TABLE subgoal (
subgoal_id VARCHAR(4),
goal_id VARCHAR(3),
PRIMARY KEY (subgoal_id),
FOREIGN KEY (goal_id) REFERENCES goal(goal_id));

CREATE TABLE region (
region_id int,
region_name VARCHAR(100),
PRIMARY KEY (region_id));

CREATE TABLE ocean_health (
year int,
goal_id VARCHAR(5),
dimension VARCHAR(20),
region_id int,
value decimal (5,2),
PRIMARY KEY (year, goal_id, dimension, region_id),
FOREIGN KEY (goal_id) REFERENCES goal (goal_id),
FOREIGN KEY (region_id) REFERENCES region (region_id));

/*Restrict possible values in dimension field*/
ALTER TABLE ocean_health
ADD CHECK (dimension IN ("future", "pressures", "resilience", "score", "status", "trend"));

/*Cleaning*/
UPDATE ocean_health_src
SET value = NULL
WHERE value = "NA";

ALTER TABLE ocean_health_src
CHANGE value value DECIMAL(5,2);

INSERT INTO goal (goal_id, goal_description)
SELECT *
from goal_src;

INSERT INTO subgoal (subgoal_id, goal_id)
SELECT *
FROM subgoal_src;

INSERT INTO region (region_id, region_name)
SELECT *
FROM region_src;

INSERT INTO ocean_health (year, goal_id, dimension, region_id, value)
SELECT *
FROM ocean_health_src;

/*All information about Egypt's Coastal Protection*/
SELECT *
FROM ocean_health 
JOIN region ON region.region_id = ocean_health.region_id
WHERE region.region_name = "Egypt" AND ocean_health.goal_id = (SELECT goal_id FROM goal WHERE goal_description = "Coastal Protection") AND YEAR = 2021
ORDER BY dimension;

/*Listing unique year and value for years with highest or lowest value of the score dimension and of the index goal.*/
SELECT *
FROM ocean_health
WHERE (value = (SELECT min(value) FROM ocean_health WHERE dimension = "score" AND goal_id = "Index") AND dimension = "score")
OR (value = (SELECT max(value) FROM ocean_health WHERE dimension = "score" AND goal_id = "Index") AND dimension = "score")
ORDER BY year ASC, value desc;

/*South American countries not in study (those with no coastlines)*/
DROP TABLE IF EXISTS south_america;

CREATE table south_america(
country VARCHAR (30)); 

INSERT INTO south_america (country)
VALUES ('Argentina'), ('Bolivia'), ('Brazil'), ('Chile'), ('Colombia'), ('Ecuador'), ('Guyana'), ('Paraguay'), ('Peru'), ('Suriname'), ('Uruguay'), ('Venezuela');

SELECT country
FROM south_america
WHERE country NOT IN (SELECT region_name FROM region WHERE region_name IN ('Argentina', 'Bolivia', 'Brazil', 'Chile', 'Colombia',  'Ecuador', 'Guyana', 'Paraguay', 'Peru', 'Suriname', 'Uruguay', 'Venezuela'))
ORDER BY country asc;

/*List of highest Biodivesity value for each year*/
SELECT *
FROM ocean_health
NATURAL JOIN goal
NATURAL JOIN region
WHERE goal_id = 'BD' AND dimension = 'score' AND value IN (SELECT max(value) FROM ocean_health NATURAL JOIN goal NATURAL JOIN region WHERE goal_id = 'BD' AND dimension = 'score' GROUP BY year);

/*Tuples with current (2021) status value either >90 or<10 with 'fish' in description to see regions best for fishing*/
DROP TABLE IF EXISTS fish;

 CREATE temporary table fish AS
 SELECT *, 
 CASE
	WHEN value >= 90 THEN 'VISIT'
    WHEN value <= 10 THEN 'AVOID'
    END AS fishing_status
 FROM goal
 NATURAL JOIN ocean_health
 NATURAL JOIN region
 WHERE goal_description LIKE '%fish%' AND dimension = 'status' AND year = 2021;
 
 SELECT year, goal_id, goal_description, dimension, region_id, region_name, value, fishing_status
 FROM fish
 WHERE fishing_status IS NOT NULL
 ORDER BY value desc, region_id asc;

/*List of goals that are not subgoals*/
SELECT goal.goal_id, goal_description
FROM goal
LEFT JOIN subgoal ON goal.goal_id = subgoal.subgoal_id
WHERE subgoal_id IS NULL;

/*Listing of each subgoal with their top-level goals*/
SELECT goal_id, goal_description, CONCAT(subgoal_id, ' ', goal_description) AS subgoal_description
FROM goal
NATURAL JOIN subgoal
ORDER BY goal_description, subgoal_description;

/*Pivoting part of table (for India's measurements)*/

DROP TABLE IF EXISTS india_measurement;

CREATE TABLE india_measurement(
region_id int,
region_name varchar(100),
goal_id varchar(6),
goal_description varchar(50),
dimension varchar(20),
value_2012 decimal(5,2),
value_2015 decimal(5,2),
value_2018 decimal(5,2),
value_2021 decimal(5,2));

INSERT INTO india_measurement(region_id, region_name, goal_id, goal_description, dimension)
SELECT ocean_health.region_id, region_name, ocean_health.goal_id, goal_description, dimension FROM region JOIN ocean_health ON region.region_id = ocean_health.region_id JOIN goal ON goal.goal_id = ocean_health.goal_id  WHERE region_name = 'India' AND (dimension = "status" OR dimension = "trend") AND year = 2012;

UPDATE india_measurement 
SET value_2012 = 
(SELECT value FROM ocean_health JOIN region ON region.region_id = ocean_health.region_id WHERE region_name = "India" AND year = 2012 AND india_measurement.goal_description = goal_description AND india_measurement.dimension = dimension AND india_measurement.goal_id = goal_id);

UPDATE india_measurement 
SET value_2015 = 
(SELECT value FROM ocean_health JOIN region ON region.region_id = ocean_health.region_id WHERE region_name = "India" AND year = 2015 AND india_measurement.goal_description = goal_description AND india_measurement.dimension = dimension AND india_measurement.goal_id = goal_id);

UPDATE india_measurement 
SET value_2018 = 
(SELECT value FROM ocean_health JOIN region ON region.region_id = ocean_health.region_id WHERE region_name = "India" AND year = 2018 AND india_measurement.goal_description = goal_description AND india_measurement.dimension = dimension AND india_measurement.goal_id = goal_id);

UPDATE india_measurement 
SET value_2021 = 
(SELECT value FROM ocean_health JOIN region ON region.region_id = ocean_health.region_id WHERE region_name = "India" AND year = 2021 AND india_measurement.goal_description = goal_description AND india_measurement.dimension = dimension AND india_measurement.goal_id = goal_id);

SELECT *
FROM india_measurement;

