Create database Spotify_data;

Use Spotify_data;

Select * from combined_spotify_data;

--Total Unique Tracks and Unique Artists Played and Total Playtime in Hours
Select Count(distinct trackName) AS Total_Tracks_Played,Count(distinct artistName) AS Total_Artists_Played,CAST(ROUND(SUM(msPlayed) / 3600000.0, 3) AS DECIMAL(10, 3))AS Total_Playtime_hours from combined_spotify_data; 

--Total Playtime by Artist
Select Top 10 artistName,CAST(ROUND(SUM(msPlayed) / 3600000.0, 3) AS DECIMAL(10, 3)) AS Total_Playtime_hours from combined_spotify_data
Group by artistName
Order by Total_Playtime_hours desc;

--Total Playtime by Track
Select Top 10 trackName,CAST(ROUND(SUM(msPlayed) / 3600000.0, 3) AS DECIMAL(10, 3))AS Total_Playtime_hours from combined_spotify_data
Group by trackName
Order by Total_Playtime_hours desc;

--Most Played Artist
Select Top 10 artistName,Count(artistName) AS times_played from combined_spotify_data
Group by artistName
Order by times_played desc;

--Most Played Tracks
Select Top 10 trackName,Count(trackName) AS times_played from combined_spotify_data
Group by trackName
Order by times_played desc;

-- Listening Activity Over Time (Date)
SELECT 
    CAST(endTime AS DATE) AS listeningDate,
    CAST(ROUND(SUM(msPlayed) / 3600000.0, 3) AS DECIMAL(10, 3)) AS totalPlaytime
FROM combined_spotify_data
GROUP BY CAST(endTime AS DATE)
ORDER BY listeningDate;

-- Listening Activity Over Time (Month)
SELECT 
    YEAR(endTime) AS Year,
    MONTH(endTime) AS Month,
    CAST(ROUND(SUM(msPlayed) / 3600000.0, 3) AS DECIMAL(10, 3)) AS totalPlaytimeInHours
FROM 
    combined_spotify_data
GROUP BY 
    YEAR(endTime),
    MONTH(endTime)
ORDER BY 
    Year,
    Month;

-- Listening Activity by Day of the Week
SELECT 
    DATENAME(WEEKDAY, endTime) AS DayOfWeek,
    CAST(ROUND(SUM(msPlayed) / 3600000.0, 3) AS DECIMAL(10, 3)) AS totalPlaytimeInHours
FROM 
    combined_spotify_data
GROUP BY 
    DATENAME(WEEKDAY, endTime)
ORDER BY 
    CASE 
        WHEN DATENAME(WEEKDAY, endTime) = 'Sunday' THEN 1
        WHEN DATENAME(WEEKDAY, endTime) = 'Monday' THEN 2
        WHEN DATENAME(WEEKDAY, endTime) = 'Tuesday' THEN 3
        WHEN DATENAME(WEEKDAY, endTime) = 'Wednesday' THEN 4
        WHEN DATENAME(WEEKDAY, endTime) = 'Thursday' THEN 5
        WHEN DATENAME(WEEKDAY, endTime) = 'Friday' THEN 6
        WHEN DATENAME(WEEKDAY, endTime) = 'Saturday' THEN 7
    END;

-- Listening Activity by Hour of the Day
SELECT 
    DATEPART(HOUR, endTime) AS HourOfDay,
    CAST(ROUND(SUM(msPlayed) / 3600000.0, 3) AS DECIMAL(10, 3)) AS totalPlaytimeInHours
FROM 
    combined_spotify_data
GROUP BY 
    DATEPART(HOUR, endTime)
ORDER BY 
    HourOfDay;

-- Growth in Listening Time
WITH MonthlyPlaytime AS (
    SELECT 
        DATEPART(YEAR, endTime) AS Year,
        DATEPART(MONTH, endTime) AS Month,
        CAST(ROUND(SUM(msPlayed) / 3600000.0, 3) AS DECIMAL(10, 3)) AS totalPlaytimeInHours
    FROM 
        combined_spotify_data
    GROUP BY 
        DATEPART(YEAR, endTime),
        DATEPART(MONTH, endTime)
)
SELECT 
    Year,
    Month,
    totalPlaytimeInHours,
    LAG(totalPlaytimeInHours) OVER (ORDER BY Year, Month) AS previousMonthPlaytime,
    totalPlaytimeInHours - LAG(totalPlaytimeInHours) OVER (ORDER BY Year, Month) AS growthInPlaytime,
    SUM(totalPlaytimeInHours) OVER (ORDER BY Year, Month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulativePlaytime
FROM 
    MonthlyPlaytime
ORDER BY 
    Year, Month;


-- Average Listening Time per Track (Top 10 Tracks by Playtime)
SELECT 
    trackName, 
    CAST(ROUND(AVG(msPlayed) / 1000.0, 3) AS DECIMAL(10, 3)) AS avgPlaytime
FROM 
    combined_spotify_data
WHERE 
    trackName IN (
        SELECT TOP 10 
            trackName
        FROM 
            combined_spotify_data
        GROUP BY 
            trackName
        ORDER BY 
            SUM(msPlayed) DESC
    )
GROUP BY 
    trackName
ORDER BY 
    avgPlaytime DESC;

-- Average Listening Time per Artist (Top 10 Artist by Playtime)
SELECT 
    artistName, 
    CAST(ROUND(AVG(msPlayed) / 1000.0, 3) AS DECIMAL(10, 3)) AS avgPlaytime
FROM 
    combined_spotify_data
WHERE 
    artistName IN (
        SELECT TOP 10 
            artistName
        FROM 
            combined_spotify_data
        GROUP BY 
            artistName
        ORDER BY 
            SUM(msPlayed) DESC
    )
GROUP BY 
    artistName
ORDER BY 
    avgPlaytime DESC;


-- Skip Rate
SELECT 
    CAST(SUM(CASE WHEN msPlayed < 30000 THEN 1 ELSE 0 END) AS DECIMAL(10, 3)) / COUNT(*) * 100 AS skipRatePercentage
FROM 
    combined_spotify_data;

-- Skip Rate Per Hour of the Day
SELECT 
    DATEPART(HOUR, endTime) AS HourOfDay,
    CAST(SUM(CASE WHEN msPlayed < 30000 THEN 1 ELSE 0 END) AS DECIMAL(10, 2)) / COUNT(*) * 100 AS skipRatePercentage
FROM 
    combined_spotify_data
GROUP BY 
    DATEPART(HOUR, endTime)
ORDER BY 
    HourOfDay;


-- Repeatability Rate 
WITH TrackPlayCounts AS (
    SELECT 
        trackName,
        COUNT(*) AS playCount
    FROM 
        combined_spotify_data
    GROUP BY 
        trackName
),
RepeatTracks AS (
    SELECT 
        COUNT(*) AS repeatTrackCount
    FROM 
        TrackPlayCounts
    WHERE 
        playCount > 1
),
TotalDistinctTracks AS (
    SELECT 
        COUNT(*) AS totalDistinctTrackCount
    FROM 
        TrackPlayCounts
)
SELECT 
    ROUND(
        CAST(RepeatTracks.repeatTrackCount AS DECIMAL(10, 2)) 
        / TotalDistinctTracks.totalDistinctTrackCount * 100, 
        2
    ) AS repeatabilityRatePercentage
FROM 
    RepeatTracks, TotalDistinctTracks;
