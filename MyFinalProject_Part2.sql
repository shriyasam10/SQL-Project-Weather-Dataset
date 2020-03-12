/*by pg395, svj28, sss329*/ 
Use Weather;

/*Query 1*/

DECLARE @VAR AS VARCHAR(8000);
SET @VAR =
  STUFF((select ',' + CAST([Day Of The Year] as varchar(20)) + ' ' + CAST(Rolling_Avg_Temp as varchar(20)) 
			from (select TDay.[Day Of The Year], 
						AVG(TDay.Average_Temp) Over (Partition by TDay.City_Name Order by TDay.[Day of the Year] 
													ROWS BETWEEN 3 Preceding AND 1 following) as Rolling_Avg_Temp
					from (select distinct City_Name, DATEPART(dy, t.Date_Local) as 'Day Of The Year', 
											AVG(t.Average_Temp) as Average_Temp 
							from  Temperature t, AQS_Sites a 
							where a.State_Code = t.State_Code and 
								a.Site_Number = t.Site_Num and 
								a.County_Code = t.County_Code and 
								a.City_Name = 'Tucson'
					group by a.City_Name, DATEPART(dy, t.Date_Local)) TDay
					/*order by city_name,dayOfTheYear*/
					) LineGraph FOR XML PATH('')), 1, 1, '');
SELECT geometry::STGeomFromText( 'LINESTRING(' + @VAR + ')', 0 );


/*Query 2*/
DECLARE @VAR01 AS VARCHAR(8000);
DECLARE @VAR02 AS VARCHAR(8000);
DECLARE @RES AS VARCHAR(8000);

SET @VAR01 =  
  STUFF((Select ',' + CAST([Day Of The Year] as varchar(4)) + ' ' + CAST(Rolling_Avg_Temp as varchar(10)) 
			From (Select TDay.[Day Of The Year], 
					FORMAT(AVG(TDay.Average_Temp) Over (Partition by TDay.City_Name Order by TDay.[Day of the Year] 
												ROWS BETWEEN 3 Preceding AND 1 following),'0.00') as Rolling_Avg_Temp
					From (Select distinct City_Name, DATEPART(dy, t.Date_Local) as 'Day Of The Year', 
											AVG(t.Average_Temp) as Average_Temp 
							From  Temperature t, AQS_Sites a 
							Where a.State_Code = t.State_Code and 
								a.Site_Number = t.Site_Num and 
								a.County_Code = t.County_Code and 
								a.City_Name = 'Tucson'
					Group by a.City_Name, DATEPART(dy, t.Date_Local)) TDay
					) LineGraph FOR XML PATH('')), 1, 1, '');

SET @VAR02 = 
  STUFF((Select ','+ CAST([Day Of The Year] as varchar(4)) + ' ' + CAST(Rolling_Avg_Temp as varchar(10)) 
			From (Select TDay.[Day Of The Year], 
						FORMAT(AVG(TDay.Average_Temp) Over (Partition by TDay.City_Name Order by TDay.[Day of the Year] 
											ROWS BETWEEN 3 Preceding AND 1 following),'0.00') as Rolling_Avg_Temp
					From (Select distinct City_Name, DATEPART(dy, t.Date_Local) as 'Day Of The Year', 
											AVG(t.Average_Temp) as Average_Temp 
							From  Temperature t, AQS_Sites a 
							Where a.State_Code = t.State_Code and 
								a.Site_Number = t.Site_Num and 
								a.County_Code = t.County_Code and 
								a.City_Name = 'Mission'
					Group by a.City_Name, DATEPART(dy, t.Date_Local)) TDay
					) LineGraph FOR XML PATH('')), 1, 1, '');

	SET  @RES = 'MULTILINESTRING((' + @VAR01 +'),('+ @VAR02+ '))';
	
	Select geometry::STGeomFromText(@RES,0)


/*Query 3*/
DECLARE @VAR03 AS VARCHAR(max);

SET @VAR03 = 
	STUFF	((Select ',' + CAST([Day Of The Year] AS CHAR(4)) + ' ' + CAST(ROUND(Rolling_Avg_Temp,2) AS VARCHAR(10))
				From ((Select TDayT.[Day Of The Year], 
					FORMAT(AVG(TDayT.Average_Temp) Over (Partition by TDayT.City_Name Order by TDayT.[Day of the Year] 
											ROWS BETWEEN 3 Preceding AND 1 following),'0.00') as Rolling_Avg_Temp
						From (Select distinct City_Name, DATEPART(dy, t.Date_Local) as 'Day Of The Year', 
											AVG(t.Average_Temp) as Average_Temp 
								From  Temperature t, AQS_Sites a 
								Where a.State_Code = t.State_Code and 
									a.Site_Number = t.Site_Num and 
									a.County_Code = t.County_Code and 
									a.City_Name = 'Tucson'
						Group by a.City_Name, DATEPART(dy, t.Date_Local)) TDayT)
								UNION
					(Select TDayM.[Day Of The Year], 
					FORMAT(AVG(TDayM.Average_Temp) Over (Partition by TDayM.City_Name Order by TDayM.[Day of the Year] 
											ROWS BETWEEN 3 Preceding AND 1 following),'0.00') as Rolling_Avg_Temp
					From (Select distinct City_Name, DATEPART(dy, t.Date_Local) as 'Day Of The Year', 
											AVG(t.Average_Temp) as Average_Temp 
							From  Temperature t, AQS_Sites a 
							Where a.State_Code = t.State_Code and 
								a.Site_Number = t.Site_Num and 
								a.County_Code = t.County_Code and 
								a.City_Name = 'Mission'
					Group by a.City_Name, DATEPART(dy, t.Date_Local)) TDayM)) DiffGraph
					Order by [Day Of The Year] FOR XML PATH('')), 1, 1, '');
					
Select geometry::STGeomFromText( 'LINESTRING(' + @VAR03 + ')', 0  );
					
					