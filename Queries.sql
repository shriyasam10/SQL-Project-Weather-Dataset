USE Weather;

/*1.	Determine the date range of the records in the Temperature table*/
Select MIN(Date_Last_Change) as Last_Date,  MAX(Date_Last_Change) as First_Date
from Temperature;



/*2.	Find the minimum, maximum and average temperature for each state*/


/*Select State_Name, MIN(t.Daily_High_Temp) as Minimum_Temp, MAX(t.Daily_High_Temp) as Maximum_Temp, t.Average_Temp
from AQS_Sites aqs
left join Temperature t
on aqs.State_Code = t.State_Code
group by aqs.State_Name, t.Average_Temp
order by  aqs.State_Name ASC;*/

Select distinct  State_Name, MIN(t.Daily_High_Temp) as Minimum_Temp, MAX(t.Daily_High_Temp) as Maximum_Temp,AVG(t.Average_Temp) as Average_Temp 
from Temperature t, AQS_Sites aqs
where aqs.State_Code = t.State_Code
group by aqs.State_Name
order by  aqs.State_Name ASC;



/*3.	The results from question #2 show issues with the database.  Obviously, a temperature of -99 degrees Fahrenheit in Arizona is not an accurate reading as most likely is 135.5 degrees.  Write the queries to find all suspect temperatures (below -39o and above 105o). Sort your output by State Name and Average Temperature.*/

Select * from 
(Select distinct  aqs.State_Name, aqs.State_Code, aqs.County_Code, aqs.Site_Number, AVG(t.Average_Temp) as Average_Temp,  t.Date_Local
from temp_temp t, AQS_Sites aqs
where aqs.State_Code = t.State_Code
group by aqs.State_Name, aqs.State_Code, aqs.County_Code, aqs.Site_Number, t.Date_Local) a
where a.Average_Temp between -39 and 105
order by  a.State_Name ASC;









