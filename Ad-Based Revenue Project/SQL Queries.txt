--Showing data for before 8/15/2014
SELECT CONVERT(DATE, date_installed) AS date_installed, 
	color,
	COUNT(date_from_install) AS usersgeneratingrevenue,
	SUM(revenue) as RevenueGenerated,
	AVG(date_from_install) AS [Avg. Days from Install to Revenue]
FROM Revenue
WHERE date_installed < '20140815'
GROUP BY date_installed, color
ORDER BY 1, 2;

--Showing data after 8/15/2014
WITH post815 AS
(
	SELECT CONVERT(DATE, r.date_installed) AS date_installed, 
		r.color, 
		u.users,
		COUNT(r.date_from_install) AS usersgeneratingrevenue,
		SUM(r.revenue) as RevenueGenerated,
		AVG(r.date_from_install) AS [Avg. Days From Install To Revenue]
	FROM Revenue r
	JOIN Users u
		ON r.date_installed = u.date_installed
		AND r.color = u.color
	GROUP BY r.date_installed, r.color, u.users
)
SELECT *, 
	CAST(RevenueGenerated/Users AS MONEY) AS ARPU,
	FORMAT(usersgeneratingrevenue/users, 'P2') AS [%usersgeneratingrevenue]
FROM post815;

--After running these queries, I uploaded the results back into the original AdRevenueUserData file under the Users table.