SELECT
	Id,
	CAST(Date AS Date) AS "date",
	CAST(WeightKg AS Decimal(4,1)) AS weight_kg,
	CAST(WeightPounds AS Decimal(4,1)) AS weight_lbs,
	CAST(Fat AS int) AS fat,
	CAST(BMI AS Decimal(4,2)) AS bmi,
	IsManualReport AS is_maunal_report,
	CAST(LogId AS bigint) AS log_id
INTO dbo.WeightLog
FROM weightLogInfo_merged;

---check for duplicates

WITH duplicate AS (
SELECT
	CONCAT(Id,' ',date) AS Id_date,
	*
FROM WeightLog
)
SELECT
	ROW_NUMBER() OVER (PARTITION BY Id_date ORDER BY Id_date) AS RowNumber,
	*
INTO test_weight
FROM duplicate;

SELECT * 
FROM test_weight
WHERE RowNumber > 1;

--no duplicates found

DROP TABLE
test_weight;

SELECT * FROM WeightLog

---Data quality

---check for missing records in WeightLog---
---how many records per Id---

SELECT 
	DISTINCT Id,
	COUNT(date) AS number_of_records
FROM WeightLog
GROUP BY Id
ORDER BY number_of_records;

---only 8 participants logged weight at all, only 2 logged more than 20 days, 6 logges 5 or fewer days