USE SS16Test; -- must be in database with appropriate compatability level

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

PRINT 'Beginning REPLICATE(8000)...';

SELECT
 TOP (8000) ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS inRowNum
FROM STRING_SPLIT(REPLICATE(CHAR(32),8000),CHAR(32));

PRINT 'Beginning SPACE(8000)...';

SELECT
 TOP (8000) ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS inRowNum
FROM STRING_SPLIT(SPACE(8000),CHAR(32));

PRINT 'Beginning JSON 8000...'

SELECT
CONVERT(int,[key]) as inRowNum
FROM OPENJSON('[1' + REPLICATE(CONVERT(varchar(max),',1'),8000-1) + +']');

PRINT 'Beginning CROSS JOINs 8000...';

WITH
L0   AS(SELECT 1 AS c UNION ALL SELECT 1),
L1   AS(SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
L2   AS(SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
L3   AS(SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
L4   AS(SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
L5   AS(SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
Nums AS(SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS n FROM L5)
SELECT TOP (8000) n FROM Nums ORDER BY n;

PRINT 'Beginning R 8000...';
 
exec sp_execute_external_script  @language =N'R',    
@script=N'
x <- array(1:8000);
OutputDataSet<-as.data.frame(x);'
with result sets ((n int));

PRINT 'Beginning 1M Replicate...';

SELECT
 TOP (1000000) ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS inRowNum
FROM STRING_SPLIT(REPLICATE(CONVERT(VARCHAR(MAX),CHAR(32)),1000000),CHAR(32));

PRINT 'Beginning 1M Replicate/Space...';

SELECT
 TOP (1000000) ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS inRowNum
FROM STRING_SPLIT(REPLICATE(CONVERT(VARCHAR(MAX),SPACE(8000)),125),CHAR(32));

PRINT 'Beginning 1M JSON...'

SELECT
CONVERT(int,[key]) as inRowNum
FROM OPENJSON('[1' + REPLICATE(CONVERT(varchar(max),',1'),1000000-1) + +']');

PRINT 'Beginning 1M CROSS JOINs...';

WITH
L0   AS(SELECT 1 AS c UNION ALL SELECT 1),
L1   AS(SELECT 1 AS c FROM L0 AS A CROSS JOIN L0 AS B),
L2   AS(SELECT 1 AS c FROM L1 AS A CROSS JOIN L1 AS B),
L3   AS(SELECT 1 AS c FROM L2 AS A CROSS JOIN L2 AS B),
L4   AS(SELECT 1 AS c FROM L3 AS A CROSS JOIN L3 AS B),
L5   AS(SELECT 1 AS c FROM L4 AS A CROSS JOIN L4 AS B),
Nums AS(SELECT ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS n FROM L5)
SELECT TOP (1000000) n FROM Nums ORDER BY n;


PRINT 'Beginning 1M R...';

exec sp_execute_external_script  @language =N'R',    
@script=N'
x <- array(1:1000000);
OutputDataSet<-as.data.frame(x);'
with result sets ((n int));