/* Idea is to clean UFO sightings data in SQL queries
	and prepare them to clear visualization*/

-- 1. Data review

select * from [dbo].[UFO_sightings]
--order by latitude DESC

select DISTINCT(datetime) from [dbo].[UFO_sightings] -- there are duplicates

select DISTINCT(country) from [dbo].[UFO_sightings] -- 5 countries + 1 blank


-- 2. Date standardization (date posted)

select [date posted], CONVERT(Date, [date posted]) from [dbo].[UFO_sightings]

ALTER TABLE [dbo].[UFO_sightings]
ADD [date posted converted] Date

UPDATE [dbo].[UFO_sightings]
SET [date posted converted] = CONVERT(Date, [date posted])
 
ALTER TABLE [dbo].[UFO_sightings]
DROP COLUMN [date posted]

-- 3. Information in bracket separation from city name

select city from [dbo].[UFO_sightings]
--where city is NULL

select 
city
, SUBSTRING(city, 1, CHARINDEX(' (', city))
, SUBSTRING(city, CHARINDEX('(', city), LEN(city))
, SUBSTRING(city, CHARINDEX('(', city), CHARINDEX(')', city))
from [dbo].[UFO_sightings]

ALTER TABLE [dbo].[UFO_sightings]
ADD CityInfo nvarchar(255)

UPDATE [dbo].[UFO_sightings]
SET CityInfo = SUBSTRING(city, CHARINDEX('(', city), CHARINDEX(')', city))

UPDATE [dbo].[UFO_sightings]
SET CityInfo = 'no info'
where LEN(CityInfo) < 2

select city, CityInfo from [dbo].[UFO_sightings]

-- 4. Implement long country name instead of shortcut

select DISTINCT(country), state from [dbo].[UFO_sightings]

select country,
CASE
	WHEN country = 'de' THEN 'Denmark'
	WHEN country = 'gb' THEN 'Great Britain'
	WHEN country = 'au' THEN 'Australia'
	WHEN country = 'ca' THEN 'Canada'
	WHEN country = 'us' THEN 'United States of America'
	ELSE NULL
END
from [dbo].[UFO_sightings]


UPDATE [dbo].[UFO_sightings]
SET country = CASE
	WHEN country = 'de' THEN 'Denmark'
	WHEN country = 'gb' THEN 'Great Britain'
	WHEN country = 'au' THEN 'Australia'
	WHEN country = 'ca' THEN 'Canada'
	WHEN country = 'us' THEN 'United States of America'
	ELSE NULL
	END

-- 5. Fill NULL country names with use of state

select * from [dbo].[UFO_sightings]

select country, state from [dbo].[UFO_sightings]
where state = 'ia' -- example that state is the same but country is 'United States of America' or NULL

select a.state, a.country, b.state, b.country, ISNULL(a.country, b.country)
from [dbo].[UFO_sightings] a
INNER JOIN [dbo].[UFO_sightings] b
on a.state = b.state
and a.datetime <> b.datetime
where a.country is null

UPDATE a
SET country = ISNULL(a.country, b.country)
from [dbo].[UFO_sightings] a
INNER JOIN [dbo].[UFO_sightings] b
on a.state = b.state
and a.datetime <> b.datetime

-- 6. Looking for duplicates

WITH RowNumCTE AS(
select *,
	ROW_NUMBER() OVER(
	PARTITION BY 
	datetime
	, city
	, state
	, country
	, latitude
	, longitude
	ORDER BY datetime
	) repetition
from [dbo].[UFO_sightings]
)

select * from RowNumCTE
where  repetition > 1
order by repetition desc

-- Result: There are duplicates that have the same columns value except comments