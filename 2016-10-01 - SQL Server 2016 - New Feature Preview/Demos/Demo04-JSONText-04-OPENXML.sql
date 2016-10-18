DECLARE
	@i int,
	@x xml = '<x><a>1</a><a>2</a></x>';

EXEC sp_xml_preparedocument @i OUTPUT, @x;

SELECT		*
FROM		OPENXML (@i, '/x/a', 2)
WITH		(a varchar(10) '.');
GO

DECLARE
	@x xml = '<x><a>1</a><a>2</a></x>';
SELECT		a.value('.','varchar(10)')
FROM		@x.nodes('/x/a') AS x(a);
GO