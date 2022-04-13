use Practice
---create new table with correct data types for all columns (permanently change string to date, int, decimal, etc.)

SELECT
	Id,
	CAST(ActivityDate AS Date) AS activity_date,
	CAST(TotalSteps AS int) AS total_steps,
	CAST(TotalDistance AS Decimal(4,2)) AS total_distance,
	CAST(TrackerDistance AS Decimal(4,2)) AS tracker_distance,
	CAST(LoggedActivitiesDistance AS Decimal(4,2)) AS logged_activities_distance,
	CAST(VeryActiveDistance AS Decimal(4,2)) AS very_active_distance,
	CAST(ModeratelyActiveDistance AS Decimal(4,2)) AS moderate_active_distance,
	CAST(LightActiveDistance AS Decimal(4,2)) AS light_active_distance,
	CAST(SedentaryActiveDistance AS Decimal(4,2)) AS sedentary_active_distance,
	CAST(VeryActiveMinutes AS int) AS very_active_minutes,
	CAST(FairlyActiveMinutes AS int) AS fairly_active_minutes,
	CAST(LightlyActiveMinutes AS int) AS lightly_active_minutes,
	CAST(SedentaryMinutes AS int) AS sedentary_minutes,
	CAST(calories AS int) AS calories
INTO dbo.DailyActivity
FROM dailyActivity_merged;


--check to see if the date range was the same for all participants in the study

SELECT
	DISTINCT activity_date
FROM DailyActivity
Order BY activity_date;

---check for duplicates in DailyActivity, 
WITH duplicate AS (
SELECT
	CONCAT(Id,' ',activity_date) AS Id_date,
	*
FROM DailyActivity
)
SELECT
	ROW_NUMBER() OVER (PARTITION BY Id_date ORDER BY Id_date) AS row_number,
	*
INTO test
FROM duplicate;

SELECT * 
FROM test
WHERE row_number > 1;

---no duplicates found

DROP TABLE
test;

---data quality

---check for missing records in DailyActivity---
---how many records per Id---

SELECT 
	DISTINCT Id,
	COUNT(activity_date) AS number_of_records
FROM DailyActivity
GROUP BY Id
ORDER BY number_of_records;

/*results here show there are 33 participants in total, only 21 of which completed a whole  31 day month. 
4 participants completed 20 days or less. 1 participant only completed four days.*/


---Check min, max, and avg records entered---

WITH records AS
(SELECT
	DISTINCT Id,
	COUNT(activity_date) AS number_of_records
FROM DailyActivity
GROUP BY Id)

SELECT
	MIN(number_of_records) AS min_records,
	MAX(number_of_records) AS max_records,
	AVG(number_of_records) AS avg_records
FROM records;

---while the minimum number of records is 4, which is quite low, the average is 28, which is close to the max of 31.

---get details about participant with lowest number of records

SELECT * 
FROM DailyActivity
WHERE ID = 4057192912; 

-- The participant with only 4 records includes a day with all 0 values. Check for other records with all 0 values

SELECT * 
FROM DailyActivity
WHERE total_steps = 0;

/*There are 77 rows that contain a date, but all 0 entries for other fields. This important to know for final reporting (speaks to compliance with the study 
and/or ability of devices to record measurements), but these records will skew any calculations measuring actual activity and/or correlations of other measurements to activity levels*/

---how many records include days when the device was not worn an entire day

SELECT
	Id,
	activity_date,
	SUM(very_active_minutes+fairly_active_minutes+lightly_active_minutes+sedentary_minutes) AS total_minutes_worn
FROM DailyActivity
GROUP BY activity_date, Id
ORDER BY total_minutes_worn;

---classify time worn

With TimeWorn AS 
(SELECT
	Id,
	activity_date,
	SUM(very_active_minutes+fairly_active_minutes+lightly_active_minutes+sedentary_minutes) AS total_minutes_worn
FROM DailyActivity
GROUP BY activity_date, Id
) 
SELECT
	(SELECT COUNT(total_minutes_worn) FROM TimeWorn WHERE total_minutes_worn = 1440) AS twentyfour,
	(SELECT COUNT(total_minutes_worn) FROM TimeWorn WHERE total_minutes_worn BETWEEN 960 AND 1439) AS sixteen_twentyfour,
	(SELECT COUNT(total_minutes_worn) FROM TimeWorn WHERE total_minutes_worn BETWEEN 720 AND 959) AS twelve_sixteen,
	(SELECT COUNT(total_minutes_worn) FROM TimeWorn WHERE total_minutes_worn <720) AS less_than_twelve
INTO #TempHoursWorn

SELECT
	CAST(CAST(twentyfour AS FLOAT)/940 *100 AS DECIMAL(4,2)) AS percent_twentyfour,
	CAST(CAST(sixteen_twentyfour AS FLOAT)/940 *100 AS DECIMAL(4,2)) AS percent_sixteen_twentyfour,
	CAST(CAST(twelve_sixteen AS FLOAT)/940 *100 AS DECIMAL(4,2)) AS percent_twelve_sixteen,
	CAST(CAST(less_than_twelve AS FLOAT)/940*100 AS DECIMAL(4,2))AS percent_less_than_twelve
FROM #TempHoursWorn

/* 25 records where device was worn less than 12 hours, of those 25, 13 records where device was worn less than 8 hours. Out of 940 records, that is not a huge number.
I will not delete 0 value days or low use days, because I will use this speaks to device use and helps describe the quality and completeness of the data, but I plan to 
exclude some of these values from some calculations*/

--- check for outliers

SELECT * FROM DailyActivity
ORDER BY total_steps;

SELECT * FROM DailyActivity
ORDER BY sedentary_minutes DESC;

SELECT 
	MIN(total_steps) AS min_steps,
	MAX(total_steps) AS max_steps,
	AVG(total_steps) AS avg_steps
FROM DailyActivity
WHERE
	total_steps <> 0;

SELECT 
	(SELECT COUNT(*)  FROM DailyActivity WHERE total_steps = 0) AS zero_steps,
	(SELECT COUNT(*)  FROM DailyActivity WHERE total_steps BETWEEN 1 AND 1000) AS under_1000,
	(SELECT COUNT(*)  FROM DailyActivity WHERE total_steps BETWEEN 1001 AND 3000) AS onethousand_3000,
	(SELECT COUNT(*)  FROM DailyActivity WHERE total_steps BETWEEN 3001 AND 5000) AS threethousand_5000,
	(SELECT COUNT(*)  FROM DailyActivity WHERE total_steps BETWEEN 5001 AND 7000) AS fivethousand_7000,
	(SELECT COUNT(*)  FROM DailyActivity WHERE total_steps > 7000)  AS over_7000;

SELECT
	MIN(calories) AS min_calories,
	MAX(calories) AS max_calories,
	AVG(calories) AS avg_calories
FROM DailyActivity
WHERE Calories <> 0;






	