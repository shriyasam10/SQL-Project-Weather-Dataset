/*by pg395, svj28, sss329*/
Use Weather;

/*Assign Keys to reference tables*/

ALTER TABLE AQS_Sites ALTER COLUMN State_Code VARCHAR(50) NOT NULL
ALTER TABLE AQS_Sites ALTER COLUMN County_Code VARCHAR(50) NOT NULL
ALTER TABLE AQS_Sites ALTER COLUMN Site_Number VARCHAR(50) NOT NULL

ALTER TABLE AQS_Sites ADD PRIMARY KEY (State_Code, County_Code, Site_Number)

ALTER TABLE Temperature ALTER COLUMN State_Code VARCHAR(50) NOT NULL
ALTER TABLE Temperature ALTER COLUMN County_Code VARCHAR(50) NOT NULL
ALTER TABLE Temperature ALTER COLUMN Site_Num VARCHAR(50) NOT NULL
ALTER TABLE Temperature ALTER COLUMN Date_Local datetime NOT NULL

/*ALTER TABLE Temperature ADD PRIMARY KEY (State_Code, County_Code, Site_Num, Date_Local)*/
ALTER TABLE Temperature ADD FOREIGN KEY (State_Code, County_Code, Site_Num) 
						REFERENCES AQS_Sites(State_Code, County_Code, Site_Number)

/*1.	Determine the date range of the records in the Temperature table*/

Select CONVERT(char(10),MIN(Date_Local),110) as 'First Date', 
		CONVERT(char(10),MAX(Date_Local),110) as 'Last Date' 
From Temperature

/*2.	Find the minimum, maximum and average temperature for each state*/


Select t.State_Name, MIN(t.Average_Temp) as 'Minimum Temp', MAX(t.Average_Temp) as 'Maximum Temp',
		AVG(t.Average_Temp) as 'Average Temp' 
From (Select a.State_Name, a.State_Code, a.County_Code, a.Site_Number, t.Average_Temp
		From Temperature t, AQS_Sites a
		Where a.State_Code = t.State_Code and
			a.County_Code = t.County_Code and
			a.Site_Number = t.Site_Num) t
Group by t.State_Name
Order by t.State_Name

/*03.	The results from question #2 show issues with the database.  Obviously, a temperature of 
-99 degrees Fahrenheit in Arizona is not an accurate reading as most likely is 135.5 degrees. 
Write the queries to find all suspect temperatures (below -39o and above 105o). Sort your 
output by State Name and Average Temperature.*/


Select ta.State_Name, ta.State_Code, ta.County_Code, ta.Site_Num, t1.Average_Temp, 
		CONVERT(char(10),t1.Date_Local,110)
From (Select a.State_Name, t.State_Code, t.County_Code, t.Site_Num, MIN(t.Average_Temp) as MIN_Temp, 
		MAX(t.Average_Temp) as MAX_Temp
		From Temperature t, AQS_Sites a
		where a.State_Code = t.State_Code and
			a.County_Code = t.County_Code and
			a.Site_Number = t.Site_Num 
		Group by a.State_Name, t.State_Code, t.County_Code, t.Site_Num) ta, Temperature t1
Where ta.State_Code = t1.State_Code and
		ta.County_Code = t1.County_Code and
		ta.Site_Num = t1.Site_Num and
		((ta.MIN_Temp = t1.Average_Temp and ta.MIN_Temp < -39) or
		 (ta.MAX_Temp = t1.Average_Temp and ta.MAX_Temp > 108))
Order by ta.State_Name desc, t1.Average_Temp asc


/*4.	You noticed that the average temperatures become questionable below -39 o and above 125 o and 
		that it is unreasonable to have temperatures over 105 o for state codes 30, 29, 37, 26, 18, 38. 
		Write the queries that remove the questionable entries for these 3 set of circumstances.*/

Delete From Temperature Where Average_Temp < -39 OR
							Average_Temp > 125

Delete From Temperature Where Average_Temp > 105 AND
							State_Code IN (30, 29, 37, 26, 18, 38)
	
/*5.	Using the SQL RANK statement, rank the states by Average Temperature*/


Select tm.State_Name, tm.MIN_Temp, tm.MAX_Temp, tm.Average_Temp, 
	RANK() Over (Order by ta.Average_Temp desc) as State_Rank
From (Select a.State_Name, t.State_Code, MIN(t.Average_Temp) as MIN_Temp, 
		MAX(t.Average_Temp) as MAX_Temp, AVG(t.Average_Temp) as Average_Temp
		From Temperature t, AQS_Sites a
		where a.State_Code = t.State_Code and
			a.County_Code = t.County_Code and
			a.Site_Number = t.Site_Num 
		Group by a.State_Name, t.State_Code) tm

/*6.	You decide that you are only interested in living in the United States, not Canada or the US 
territories. You will need to include SQL statements in all the remaining queries to limit the data 
returned in the remaining queries.*/

/*(Canada, Guam, Puerto Rico, Virgin Islands, Country of Mexico) has to be left out
	Where State_Code <> 'CC', 66, 72, 78, 80 */

/*7.	At this point, you’ve started to become annoyed at the amount of time each query is taking to 
		run. You’ve heard that creating indexes can speed up queries. Create 5 indexes for your database.
		2 of the indexes should index the temperature fields in the Temperature table, 1 index for the 
		date in the Temperature table and 2 would index the columns used for joining the 2 tables 
		(state, County and Site codes in the Temperate and aqs_site tables). */

IF EXISTS (SELECT *  FROM sys.indexes  WHERE name='AvgTemp_idx' 
    AND object_id = OBJECT_ID('[dbo].[Temperature]'))
  begin
    DROP INDEX [AvgTemp_idx] ON [dbo].[Temperature];
  end

CREATE INDEX AvgTemp_idx ON Temperature(Average_Temp);

IF EXISTS (SELECT *  FROM sys.indexes  WHERE name='DailyHigh_idx' 
    AND object_id = OBJECT_ID('[dbo].[Temperature]'))
  begin
    DROP INDEX [DailyHigh_idx] ON [dbo].[Temperature];
  end

CREATE INDEX DailyHigh_idx ON Temperature(Daily_High_Temp);

IF EXISTS (SELECT *  FROM sys.indexes  WHERE name='Date_idx' 
    AND object_id = OBJECT_ID('[dbo].[Temperature]'))
  begin
    DROP INDEX [Date_idx] ON [dbo].[Temperature];
  end

CREATE INDEX Date_idx ON Temperature(Date_Local);

IF EXISTS (SELECT *  FROM sys.indexes  WHERE name='FK_idx' 
    AND object_id = OBJECT_ID('[dbo].[Temperature]'))
  begin
    DROP INDEX [FK_idx] ON [dbo].[Temperature];
  end

CREATE INDEX FK_idx ON Temperature(State_Code,County_Code,Site_Num);

IF EXISTS (SELECT *  FROM sys.indexes  WHERE name='PK_idx' 
    AND object_id = OBJECT_ID('[dbo].[AQS_Sites]'))
  begin
    DROP INDEX [PK_idx] ON [dbo].[AQS_Sites];
  end

CREATE INDEX PK_idx ON AQS_Sites(State_Code,County_Code,Site_Number);

/*To see if the indexing help, add print statements that write the start and stop time for the query in 
question #2 and run the query before and after the indexes are created. Note the differences in the 
times. Also make sure that the create index steps include a check to see if the index exists before 
trying to create it.*/

/*The following is a sample of the output that should appear in the messages tab that you will need to 
calculate the difference in execution times before and after the indexes are created*/

/*Begin Question 6 before Index Create At - 13:40:03
(777 row(s) affected)
Complete Question 6 before Index Create At - 13:45:18*/

Print 'Begin Question 2 before Index Create At - ' + 
		(CAST(convert(varchar,getdate(),108) AS nvarchar(30)))
Select tm.State_Name, MIN(tm.Average_Temp) as 'Minimum Temp', MAX(tm.Average_Temp) as 'Maximum Temp',
		AVG(tm.Average_Temp) as 'Average Temp' 
From (Select a.State_Name, a.State_Code, a.County_Code, a.Site_Number, t.Average_Temp, t.Daily_High_Temp
		From Temperature t, AQS_Sites a
		Where a.State_Code = t.State_Code and
			a.County_Code = t.County_Code and
			a.Site_Number = t.Site_Num) tm
Group by tm.State_Name
Order by tm.State_Name
Print 'Complete Question 2 before Index Create At - ' + 
		(CAST(convert(varchar,getdate(),108) AS nvarchar(30)))

--Begin Question 6 after Index Create At - 13:40:03
--(777 row(s) affected)
--Complete Question 6 after Index Create At - 13:45:18

Print 'Begin Question 2 after Index Create At - ' + 
		(CAST(convert(varchar,getdate(),108) AS nvarchar(30)))
Select tm.State_Name, MIN(tm.Average_Temp) as 'Minimum Temp', MAX(tm.Average_Temp) as 'Maximum Temp',
		AVG(tm.Average_Temp) as 'Average Temp' 
From (Select a.State_Name, a.State_Code, a.County_Code, a.Site_Number, t.Average_Temp, t.Daily_High_Temp
		From Temperature t, AQS_Sites a
		Where a.State_Code = t.State_Code and
			a.County_Code = t.County_Code and
			a.Site_Number = t.Site_Num) tm
Group by tm.State_Name
Order by tm.State_Name
Print 'Complete Question 2 after Index Create At - ' + 
		(CAST(convert(varchar,getdate(),108) AS nvarchar(30)))

/*8.	You’ve decided that you want to see the ranking of each high temperatures for each city in each 
	state to see if that helps you decide where to live. Write a query that ranks (using the rank 
	function) the states by averages temperature and then ranks the cities in each state. The ranking 
	of the cities should restart at 1 when the query returns a new state. You also want to only show 
	results for the 15 states with the highest average temperatures.

Note: you will need to use multiple nested queries to get the State and City rankings, join them 
together and then apply a where clause to limit the state ranks shown.*/


Select ts.State_Rank, ts.State_Name, tc.City_Rank, tc.City_Name, tc.City_Average_Temp as Average_Temp
From	(Select ta.State_Name, ta.State_code, ta.Average_Temp, 
			RANK() Over (Order by ta.Average_Temp desc) as State_Rank
			From (Select a.State_Name, t.State_Code, AVG(t.Average_Temp) as Average_Temp
					From Temperature t, AQS_Sites a
					where a.State_Code = t.State_Code and
						a.County_Code = t.County_Code and
						a.Site_Number = t.Site_Num and 
						t.State_Code NOT IN ('CC', 66, 72, 78, 80)
					Group by a.State_Name, t.State_Code) ta) ts,
		(Select tc.State_Name, tc.City_Name, tc.City_Average_Temp, 
			RANK() Over (Partition by tc.State_Name Order by tc.City_Average_Temp desc) as City_Rank
			From (Select a.State_Name, a.City_Name, AVG(t.Average_Temp) as City_Average_Temp
					From Temperature t, AQS_Sites a
					where a.State_Code = t.State_Code and
						a.County_Code = t.County_Code and
						a.Site_Number = t.Site_Num and 
						--a.City_Name <> 'Not in a city' and
						t.State_Code NOT IN ('CC', 66, 72, 78, 80)
					Group by a.State_Name, a.City_Name) tc) tc
Where ts.State_Name = tc.State_Name and
		--tc.City_Name <> 'Not in a city' and
		ts.State_Rank <= 15		
Order by ts.State_Rank, tc.City_Rank

/*9.	You notice in the results that sites with Not in a City as the City Name are include but do not 
	provide you useful information. Exclude these sites from all future answers.*/

--	City_Name <> 'Not in a city'
 
/*10.	You’ve decided that the results in #8 provided too much information and you only want to 
	2 cities with the highest temperatures and group the results by state rank then city rank. */



Select ts.State_Rank, ts.State_Name, tc.City_Rank, tc.City_Name, tc.City_Average_Temp as Average_Temp
From	(Select ta.State_Name, ta.Average_Temp, 
			RANK() Over (Order by ta.Average_Temp desc) as State_Rank
			From (Select a.State_Name, t.State_Code, AVG(t.Average_Temp) as Average_Temp
					From Temperature t, AQS_Sites a
					where a.State_Code = t.State_Code and
						a.County_Code = t.County_Code and
						a.Site_Number = t.Site_Num and 
						t.State_Code NOT IN ('CC', 66, 72, 78, 80)
					Group by a.State_Name, t.State_Code) ta) ts,
		(Select tc.State_Name, tc.City_Name, tc.City_Average_Temp, 
			RANK() Over (Partition by tc.State_Name Order by tc.City_Average_Temp desc) as City_Rank
			From (Select a.State_Name, a.City_Name, AVG(t.Average_Temp) as City_Average_Temp
					From Temperature t, AQS_Sites a
					where a.State_Code = t.State_Code and
						a.County_Code = t.County_Code and
						a.Site_Number = t.Site_Num and 
						a.City_Name <> 'Not in a city' and
						t.State_Code NOT IN ('CC', 66, 72, 78, 80)
					Group by a.State_Name, a.City_Name) tc) tc
Where ts.State_Name = tc.State_Name and
	ts.State_Rank <= 15	and 
	tc.City_Rank <= 02		
Order by ts.State_Rank, tc.City_Rank

/*11.	You decide you like the average temperature to be in the 80's' so you decide to research 
	Pinellas Park, Mission, and Tucson in more detail. For Ludlow, California, calculate the average 
	temperature by month. You also decide to include a count of the number of records for each of the 
	cities to make sure your comparisons are being made with comparable data for each city.*/

--Hint, use the datepart function to identify the month for your calculations.



Select a.City_Name, DATEPART(MONTH,Date_Local) as Month, COUNT(*) as '# of Records', 
		AVG(t.Average_Temp) as Average_Temp
From Temperature t, AQS_Sites a
Where a.State_Code = t.State_Code and 
	a.County_Code = t.County_Code and
	a.Site_Number = t.Site_Num and
	a.City_Name IN ('Pinellas Park', 'Mission', 'Tucson', 'Ludlow') and
	a.State_Name IN ('Florida', 'Texas', 'Arizona', 'California')	--- State_Name to avoid similar city in other states
Group by a.City_Name, DATEPART(MONTH,Date_Local)
Order by a.City_Name, DATEPART(MONTH,Date_Local)

/*12.	You assume that the temperatures follow a normal distribution and that the majority of the 
	temperatures will fall within the 40% to 60% range of the cumulative distribution. Using the 
	CUME_DIST function, show the temperatures for the same 3 cities that fall within the range.*/



Select *
From	(Select distinct a.City_Name, t.Average_Temp, 
			CUME_DIST() Over (Partition by a.City_Name Order by t.Average_Temp) as Temp_Cume_Dist
			From Temperature t, AQS_Sites a
			Where a.State_Code = t.State_Code and 
				a.County_Code = t.County_Code and
				a.Site_Number = t.Site_Num and
				a.City_Name IN ('Pinellas Park', 'Mission', 'Tucson') and
				a.State_Name IN ('Florida', 'Texas', 'Arizona')) TCum
Where TCum.Temp_Cume_Dist between 0.4 and 0.6

/*13.	You decide this is helpful, but too much information. You decide to write a query that shows 
	the first temperature and the last temperature that fall within the 40% and 60% range for the 
	3 cities your focusing on.*/



Select TAll.City_Name, MIN(TAll.Average_Temp) as '40 Percentile Temp', MAX(TAll.Average_Temp) as '60 Percentile Temp'
From (Select * 
		From (Select distinct a.City_Name, t.Average_Temp, 
					CUME_DIST() Over (Partition by a.City_Name Order by t.Average_Temp) as Temp_Cume_Dist
				From Temperature t, AQS_Sites a
				Where a.State_Code = t.State_Code and 
					a.County_Code = t.County_Code and
					a.Site_Number = t.Site_Num and
					a.City_Name IN ('Pinellas Park', 'Mission', 'Tucson') and
					a.State_Name IN ('Florida', 'Texas', 'Arizona')) TCum
		Where TCum.Temp_Cume_Dist between 0.4 and 0.6) TAll
Group by TAll.City_Name

/*14.	You decide you want more detail regarding the temperature ranges and you think of using the 
	NTILE function to group the temperatures into 10 groups. You write a query that shows the minimum 
	and maximum temperature in each of the ntiles by city for the 3 cities you are focusing on.*/



Select tt.City_Name, tt.Percentile, MIN(tt.Average_Temp) as MIN_Temp, MAX(tt.Average_Temp) as MAX_Temp
From	(Select a.City_Name, t.Average_Temp, 
			NTILE(10) Over (Partition by a.City_Name Order by t.Average_Temp) as Percentile
			From Temperature t, AQS_Sites a
			Where a.State_Code = t.State_Code and 
				a.County_Code = t.County_Code and
				a.Site_Number = t.Site_Num and
				a.City_Name IN ('Pinellas Park', 'Mission', 'Tucson') and
				a.State_Name IN ('Florida', 'Texas', 'Arizona')) tt
Group by tt.City_Name, tt.Percentile

/*15.	You now want to see the percent of the time that will be at a given average temperature. To 
	make the percentages meaningful, you only want to use the whole number portion of the average 
	temperature. You write a query that uses the percent_rank function to create a table of each 
	temperature for each of the 3 cities sorted by percent_rank. The percent_rank needs to be formatted 
	as a percentage with 2 decimal places. */



Select temp.City_Name, temp.Average_Temp,
	FORMAT(PERCENT_RANK() Over (Partition by tt.City_Name Order by tt.Average_Temp), 'P') as 'Percentage'
From (Select distinct a.City_Name, CAST(t.Average_Temp as INT) as Average_Temp
			From Temperature t, AQS_Sites a
			Where a.State_Code = t.State_Code and 
				a.County_Code = t.County_Code and
				a.Site_Number = t.Site_Num and
				a.City_Name IN ('Pinellas Park', 'Mission', 'Tucson') and
				a.State_Name IN ('Florida', 'Texas', 'Arizona')	) temp 

/*16.	You remember from your statistics classes that to get a smoother distribution of the 
	temperatures and eliminate the small daily changes that you should use a moving average instead of 
	the actual temperatures. Using the windowing within a ranking function to create a 4 day moving 
	average, calculate the moving average for each day of the year.*/ 

--Hint: You will need to datepart to get the day of the year for your moving average. You moving 
--average should use the 3 days prior and 1 day after for the moving average.



Select TDay.City_Name, TDay.[Day of the Year], 
	AVG(TDay.Average_Temp) Over (Partition by TDay.City_Name Order by TDay.[Day of the Year] 
									ROWS BETWEEN 3 Preceding AND 1 following) as Rolling_Avg_Temp
From	(Select distinct a.City_Name, DATEPART(DY, t.Date_Local) as 'Day of the Year', AVG(t.Average_Temp) as Average_Temp
			From Temperature t, AQS_Sites a
			Where a.State_Code = t.State_Code and 
				a.County_Code = t.County_Code and
				a.Site_Number = t.Site_Num and
				a.City_Name IN ('Pinellas Park', 'Mission', 'Tucson') and
				a.State_Name IN ('Florida', 'Texas', 'Arizona')	
			Group by a.City_Name, DATEPART(DY,t.Date_Local)) TDay
