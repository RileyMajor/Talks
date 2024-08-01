declare @a varchar(max), @j varchar(max), @v varchar(max), @x xml;
set statistics io on;
set statistics time on;
select @j = (select j = row_number() over (order by (select 1)) from sysobjects for json auto);
select @x = (select x = row_number() over (order by (select 1)) from sysobjects for xml auto);
select @a = (select j = '[' + string_agg(convert(varchar(max),n),',') from (select n = row_number() over (order by (select 1)) from sysobjects) as ns) + ']';
select datalength(@j), datalength(convert(varchar(max),@x)), datalength(@x), datalength(@a);
select @j, @a, ISJSON(@j), ISJSON(@a);
select * from openjson(@a)
