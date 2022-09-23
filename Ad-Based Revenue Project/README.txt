Process for Ad-Based Revenue Project

*Click on the shortcut Interactive Browser Report to view the report if you do not have PowerBI to run the .pbix file*
The SQL queries work on the AdBasedRevenueUserData dataset, after it has been cleaned in Excel by the process outlined below.

Data Cleaning

1) 
First thing was to apply filters to each of the columns in
the 2 worksheets to see if there were any errors or weird entries.

Noticed in the date_from_install column that there were a bunch
of NUM errors. I filtered only by NUM to see what the problem was.
The =DATEDIF function was returning this error because somehow,
the values for date and date_installed were switched for all of these.

Basically DATEDIF was trying to show the amount of days from a startdate
that occured after the enddate.

To fix this, I created 2 duplicate columns for date and date_installed.
I deleted the entries in these columns where date_from_install was returning the error,
and referenced the correct data in the new duplicate columns. I then changed date_from_install
to reference the correct data as well, and now we have no more errors.

I then hid the original date & date_installed (renamed to fakedate and fakedate_installed),
if you were to delete them, then the references would also be deleted. These columns can be
removed later in SQL or PowerBI for the viz process.

2)
I then noticed that in the Users table, the earliest data for installation date is 8/15/2014,
but data in the RevenueData table (which I will now reference as just RevenueTable) goes back to 7/29/2014. 

Through some quick SQL queries, I found that from 7/31/2014-8/14, less than 1% of totalrevenue ($4026.61) is generated, 
and 99.006% of totalrevenue ($400,853.76) is generated after 8/15/2014. 

From here, I decided to update the Users table to show more data through SQL queries, and to also include the dates before 8/15.
In the Users table, each group of users who installed is broken down by color and date. For each date, there are two colors, red and blue, and the amount of users who installed for each.
I was able to show the amount of users from each group actually generating revenue [usersgeneratingrevenue], and the percent total for such through joins and counting.

I was also able to show the total amount of revenue generated from each color group from each install date. 
Then we are able to see the avg. amount of days it took for each group to create revenue from their install date.
Lastly, each groups ARPU is shown. Some of the

When making this, I had to break the queries into 2 sections. Pre 8/15/2014 and post 8/15/2014, since there is no data for amount of users installed on the days before 8/15/2014.
This means I would have to make some estimations for amount of users installed on the dates before that, and also estimate the ARPU. Some of these columns end up being unused in the final visualization, but they are good to have anyways and didn't take up any space or extra time.

