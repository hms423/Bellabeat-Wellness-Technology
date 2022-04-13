-----create new table with correct data types for all columns (permanently change string to date, int, decimal, etc.)
SELECT
	Id,
	CAST(SleepDay AS Date) AS sleep_date,
	CAST(TotalSleepRecords AS int) AS total_sleep_records,
	CAST(TotalMinutesAsleep AS int) AS total_asleep_minutes,
	CAST(TotalTimeInBed AS int) AS total_time_in_bed
INTO dbo.DailySleep
FROM sleepDay_merged;


---check for duplicates in DailySleep

WITH duplicate AS (
SELECT
	CONCAT(Id,' ',sleep_date) AS Id_date,
	*
FROM DailySleep
)
SELECT
	ROW_NUMBER() OVER (PARTITION BY Id_date ORDER BY Id_date) AS RowNumber,
	*
INTO test_sleep
FROM duplicate;

SELECT * 
FROM test_sleep
WHERE RowNumber > 1;

---found 3 duplicate values
DELETE FROM test_sleep
WHERE RowNumber >1;

SELECT * 
FROM test_sleep
WHERE RowNumber > 1;
---duplicated deleted

---data quality

---check for missing values
---total_sleep_records column seems to be counting the number of records for that individual in each day. I am wanting to know how many days their sleep was recorded.

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

SELECT * FROM DailySleep
WHERE total_asleep_minutes = 0
OR total_time_in_bed = 0;

---there are no blank entries