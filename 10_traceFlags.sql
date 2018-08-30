/*
DBCC TRACEON(1117, -1)	-- Grows all data files at once, else it goes in turns

DBCC TRACEON(1118, -1)	-- Switches allocations in tempDB from 1pg at a time (for first 8 pages) to one extent. 
						-- There is now a cache of temp tables. When a new temp table is created on a cold system it uses the same mechanism as for SQL 8. 
						-- When it is dropped though, instead of all the pages being deallocated completely, one IAM page & one data page are left allocated, then the temp table is put into a special cache. 
						-- Subsequent temp table creations will look in the cache to see if they can just grab a pre-created temp table. 
						-- If so, this avoids accessing the allocation bitmaps completely. 
						-- The temp table cache isn't huge (32 tables), but this can still lead to a big drop in latch contention in tempdb. 
						-- http://www.sqlskills.com/BLOGS/PAUL/post/Misconceptions-around-TF-1118.aspx This link is external to TechNet Wiki. 
						-- It will open in a new window.

DBCC TRACEON(3226, -1)	-- Suppress BACKUP COMPLETED log entries going to WIN and SQL logs. Scope: global

--DBCC TRACEON(8048, -1)	-- Newer hardware with multi-core CPUs can present more than 8 CPUs within a single NUMA node. 
--						-- Microsoft has observed that when you approach and exceed 8 CPUs per node the NODE based partitioning may not scale as well for specific query patterns. 
--						-- However, using trace flag 8048 (startup parameter only requiring restart of the SQL Server process) all NODE based partitioning is upgraded to CPU based partitioning. 
--						-- Remember this requires more memory overhead but can provide performance increases on these systems


*/
DBCC TRACESTATUS(-1)