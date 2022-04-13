Use Practice 
---Question#1: What are trends in smart device usage? i.e. what measurements were being taken and how consistently
---Question 2: How could these trends apply to Bellabeat customers?
---Question 3: How could these trends help influence Bellabeat marketing strategy?

---During cleaning, I noticed 77 rows with all 0 values. A date was entered, but no measurements, indicating the devices were either not worn at all or not worn correctly
SELECT 
	(SELECT COUNT (*) FROM DailyActivity WHERE total_steps >0) AS activity_entries,
	COUNT (*) AS total_entries,
	CAST((SELECT CAST(COUNT(*) AS FLOAT) FROM DailyActivity WHERE total_steps>0)/1023 *100  AS DECIMAL(4,2)) AS percentage_activity_tracked
FROM DailyActivity;

---Of 1023 possible entries (31 days * 33 participants), there are 940 entries (not 0s), which is 84.36 percent 


---Check for how often the devices were worn and functionally entering measurements by person

SELECT 
	DISTINCT Id,
	COUNT(activity_date) AS days_measured,
	CAST(CAST(COUNT(activity_date) AS DECIMAL(4,2))/31*100 AS DECIMAL(6,2)) AS percent_days_measured
FROM DailyActivity
WHERE total_steps >0
GROUP BY Id
ORDER BY percent_days_measured;

---categorize measurement percentage 

WITH pm AS (
	SELECT 
	DISTINCT Id AS Id,
	COUNT(activity_date) AS days_measured,
	CAST(CAST(COUNT(activity_date) AS DECIMAL(4,2))/31*100 AS DECIMAL(6,2)) AS percent_days_measured
FROM DailyActivity
WHERE total_steps >0
GROUP BY Id
)
SELECT
	pm.Id,
	pm.days_measured,
	pm.percent_days_measured,
	CASE
		WHEN pm.percent_days_measured <40.00 THEN 'Low'
		WHEN pm.percent_days_measured BETWEEN 40.01 AND 79.99 THEN 'Medium'
		ELSE 'High' 
	END AS participation_level
INTO #temp_test
FROM pm
ORDER BY pm.percent_days_measured;

---Find percentage of participants in each particpation level category

SELECT
	(SELECT COUNT(participation_level) FROM #temp_test WHERE participation_level = 'Low') AS pl_low,
	(SELECT COUNT(participation_level) FROM #temp_test WHERE participation_level = 'Medium') AS pl_medium,
	(SELECT COUNT(participation_level) FROM #temp_test WHERE participation_level = 'High') AS pl_high
INTO #temp_test2

SELECT
	 CAST((CAST(pl_low AS FLOAT)/33)*100 AS DECIMAL(4,2)) AS percent_low,
	 CAST((CAST(pl_medium AS FLOAT)/33)*100 AS DECIMAL(4,2)) AS percent_medium,
	 CAST((CAST(pl_high AS FLOAT)/33)*100 AS DECIMAL(4,2)) AS percent_high
FROM #temp_test2

---check for number of entries for each date and day of week

SELECT
	DISTINCT activity_date,
	DATENAME(dw,activity_date) AS day_of_week,
	COUNT(DISTINCT Id) AS number_of_entries
FROM DailyActivity
WHERE total_steps >0
GROUP BY activity_date
Order BY activity_date;
---results show all participants wore devices at beginning of the timeperiod, and compliance decreased a bit over time

---Is there a correlation to the date and the days measurements were not entered (all 0 values) Do weekend/weekdays affect results

SELECT
	DISTINCT activity_date,
	DATENAME(dw,activity_date) AS day_of_week,
	COUNT(DISTINCT Id) AS number_of_blank_entries
FROM DailyActivity
WHERE total_steps = 0
GROUP BY activity_date
Order BY day_of_week;

---Find avg activity level for each participant. Do not factor in dates with all 0 values, as these are most likely errors and not 100% sedentary days

SELECT
	DISTINCT Id,
	AVG(total_steps) AS avg_steps,
	AVG(total_distance) AS avg_distance,
	AVG(tracker_distance) AS avg_tracker_distance,
	AVG(logged_activities_distance) AS avg_logged_activity_distance,
	AVG(very_active_minutes) AS avg_very_active_minutes,
	AVG(fairly_active_minutes) AS avg_fair_active_minutes,
	AVG(lightly_active_minutes) AS avg_light_active_minutes,
	AVG(sedentary_minutes)	AS avg_sed_minutes,
	AVG(Calories) AS avg_calories
FROM DailyActivity
WHERE total_steps >0
GROUP BY Id
ORDER BY avg_steps;

/*from this we see that the logged_activity_distance was not often a used tool. I want to find out more about the tracker_distance, which seem to be the same on first glance.
Did any of the participants have different measurements for avg_distance and avg_tracker_distance?*/

SELECT
	DISTINCT Id,
	AVG(total_steps) AS avg_steps,
	AVG(total_distance) AS avg_distance,
	AVG(tracker_distance) AS avg_tracker_distance,
	CASE
		WHEN AVG(total_distance)=AVG(tracker_distance) THEN 'same'
		ELSE 'different'
	END AS distances_match,
	AVG(logged_activities_distance) AS avg_logged_activity_distance
FROM DailyActivity
WHERE total_steps >0
GROUP BY Id
ORDER BY avg_distance;

---for all but 2 participants, these values are the same. For the two where there is a difference, .066 and .48 difference

SELECT * FROM DailyActivity
WHERE Id = 7007744171;
/*Inspection shows no clear pattern or association with other values. Since I cannot go to the source for more information and the difference is small, 
I wilwork with total_distance value*/

---I want to see the connection between daily activity and sleep
SELECT 
	da.Id,
	da.activity_date,
	da.total_steps,
	da.total_distance,
	da.very_active_minutes AS time_very_active,
	(da.fairly_active_minutes+da.lightly_active_minutes) AS time_moderately_active,
	da.sedentary_minutes AS time_inactive,
	da.Calories,
	ds.total_asleep_minutes,
	ds.total_time_in_bed,
	(ds.total_time_in_bed-ds.total_asleep_minutes) AS time_not_asleep
FROm DailyActivity AS da
JOIN DailySleep AS ds
ON da.Id = ds.Id AND da.activity_date = ds.sleep_date
ORDER BY total_steps;

---see averages by person
SELECT 
	da.Id,
	AVG(da.total_steps) AS avg_steps,
	AVG(da.total_distance) AS avg_distance,
	AVG(da.very_active_minutes) AS avg_time_very_active,
	AVG(da.fairly_active_minutes+da.lightly_active_minutes) AS avg_time_moderately_active,
	AVG(da.sedentary_minutes) AS avg_time_inactive,
	AVG(da.Calories) AS avg_calories,
	AVG(ds.total_asleep_minutes) AS avg_asleep_minutes,
	AVG(ds.total_time_in_bed-ds.total_asleep_minutes) AS avg_bedtime_not_asleep
FROm DailyActivity AS da
JOIN DailySleep AS ds
ON da.Id = ds.Id AND da.activity_date = ds.sleep_date
GROUP BY da.Id
ORDER BY avg_steps;
---- this table only allows me to see the 24 participants who entered values for sleep. I want to revisit the idea of how often the sleep measurement feature was used.

SELECT 
	DISTINCT Id,
	COUNT(sleep_date) AS number_of_records
FROM DailySleep
GROUP BY Id
ORDER BY number_of_records;

---of the 33 participants, only 24 have records in sleep table
---12 of those have 15 or fewer records, 9 have less than 10
SELECT * FROM DailySleep
ORDER BY total_asleep_minutes;

--look at all DailyActivity entries, showing nulls for times when sleep was not measured.

SELECT 
	da.Id,
	da.activity_date,
	da.total_steps,
	da.total_distance,
	da.very_active_minutes AS time_very_active,
	(da.fairly_active_minutes+da.lightly_active_minutes) AS time_moderately_active,
	da.sedentary_minutes AS time_inactive,
	da.Calories,
	ds.total_asleep_minutes,
	ds.total_time_in_bed,
	(ds.total_time_in_bed-ds.total_asleep_minutes) AS time_not_asleep
--INTO #SleepTracked
FROm DailyActivity AS da
LEFT JOIN DailySleep AS ds
ON da.Id = ds.Id AND da.activity_date = ds.sleep_date
WHERE da.total_steps != 0;

--percentage of possible entries (31days * 33 participants = 1023) where sleep was tracked
SELECT 
	(SELECT COUNT (*) FROM #SleepTracked WHERE total_asleep_minutes IS NOT NULL) AS sleep_tracked,
	COUNT (*) AS total_entries,
	CAST((SELECT CAST(COUNT (*) AS FLOAT) FROM #SleepTracked WHERE total_asleep_minutes IS NOT NULL)/1023 AS DECIMAL(4,2)) AS percentage_sleep_tracked
FROM #SleepTracked;

--shows sleep was only tracked 40%
--how often was weight tracked

SELECT * FROM WeightLog

---how many records per Id---
SELECT 
	DISTINCT Id,
	COUNT(date) AS number_of_records
FROM WeightLog
GROUP BY Id
ORDER BY number_of_records;

---only 8 participants logged weight. 1 logged 30 times, 1 logged 24 times, and 6 logged five or fewer times. 
--were they weighing start/finish, weekly?

SELECT
	Id,
	date,
	weight_kg,
	CASE
		WHEN date = '2016-04-12' THEN 'START'
		WHEN date = '2016-05-12' THEN 'END'
		ELSE 'Other'
	END AS when_logged
FROM WeightLog;

---Where weight entries manual or using a smart device?
SELECT 
	(SELECT COUNT (*) FROM WeightLog WHERE is_maunal_report = 'True') AS manual,
	COUNT (*) AS total_entries,
	CAST((SELECT CAST(COUNT (*) AS FLOAT) FROM WeightLog WHERE is_maunal_report = 'True')/CAST(COUNT (*)AS FLOAT) AS DECIMAL(4,2)) AS percentage_manual_tracked
FROM WeightLog;
---61% of enties were tracked manually

---from all entries, how frequently was weight tracked in any way?

SELECT 
	da.Id,
	da.activity_date,
	da.total_steps,
	da.total_distance,
	da.very_active_minutes AS time_very_active,
	(da.fairly_active_minutes+da.lightly_active_minutes) AS time_moderately_active,
	da.sedentary_minutes AS time_inactive,
	da.Calories,
	w.weight_kg,
	w.fat,
	w.bmi	
INTO #Weight
FROm DailyActivity AS da
LEFT JOIN WeightLog AS w
ON da.Id = w.Id AND da.activity_date = w.date
WHERE da.total_steps != 0;

--percentage of possible entries (31days * 33 participants = 1023) where weight was tracked
SELECT 
	(SELECT COUNT (*) FROM #Weight WHERE weight_kg IS NOT NULL) AS weight_tracked,
	COUNT (*) AS total_entries,
	CAST((SELECT CAST(COUNT (*) AS FLOAT) FROM #Weight WHERE weight_kg IS NOT NULL)/1023 AS DECIMAL(4,2)) AS percentage_weight_tracked
FROM #Weight

---Weight was only tracked 7% of all dates in the study
---What percentage of participants logged weight at all?

SELECT 
	COUNT(DISTINCT Id) AS number_participants_tracked_weight,
	CAST(CAST(COUNT(DISTINCT Id) AS FLOAT)/33 *100 AS DECIMAL(4,2)) AS percentage_participants_tracked_weight
FROM WeightLog;

---only 24% of participants tracked weight at all

---number of complete entries by date for activity, sleep, and weight
SELECT
	DISTINCT da.activity_date,
	DATENAME(dw,da.activity_date) AS day_of_week,
	COUNT(DISTINCT da.Id) AS number_of_activity_entries,
	COUNT(DISTINCT ds.Id) AS number_of_sleep_entries,
	COUNT(DISTINCT wl.Id) AS number_of_weigth_entries
FROM DailyActivity AS da
LEFT JOIN DailySleep AS ds
ON da.Id = ds.Id AND da.activity_date = ds.sleep_date
LEFT JOIN WeightLog AS wl
ON da.Id = wl.Id AND da.activity_date = wl.date
WHERE da.total_steps >0
GROUP BY activity_date
Order BY activity_date;

/*Initial summary:  This study is small and short. I would strongly recommend finding a longer and/or larger study or doing their own research on Bellabeat products if possible

Question#1: What are trends in smart device usage? i.e. what measurements were being taken and how consistently
Trackers were worn most of the time by most of the participants. There are some outliers, days with 0 recordings or very few steps. In my mind, these outliers probably indicate the 
device either wasn't working properly or not being worn the whole day.

Just using the date where more than 0 steps are recorded, most participants did not wear the device to track sleep or weight 

Question 2: How could these trends apply to Bellabeat customers?
Question 3: How could these trends help influence Bellabeat marketing strategy?

I think there is an opportunity for devices to track sleep and/or weight. Possibly a survey where participants can rate their desire to track these numbers and factors that may
hinder them from doing so (device comfort, ease of use/connectivity, etc.)
Bellabeat devices are different from the Fitbits in the study, becuase they are designed as jewelry, have no face to display data for privacy, and track other metrics, such as female 
cycle, etc.
I would like to see research showing how much these features weigh in consumers' decision to purchase Bellabeat over other smart devices, as well as answers to the questions above. 
*/
