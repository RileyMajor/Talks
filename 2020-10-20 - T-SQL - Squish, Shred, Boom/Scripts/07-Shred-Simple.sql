USE Test;

/* **************************** XML **************************** */

SELECT 'XML';

DECLARE
	@x xml =
		CONVERT
		(
			xml,
			N'
				<t>
					<r>
						<c>Row 1 Col 1</c>
						<c>Row 1 Col 2</c>
						<c>Row 1 Col 3</c>
					</r>
					<r>
						<c>Row 2 Col 1</c>
						<c>Row 2 Col 2</c>
						<c>Row 2 Col 3</c>
					</r>
				</t>
			'
		);

SELECT
	x = @x;

SELECT
	t.r.query('.')
FROM		@x.nodes('/t/r') AS t(r);

SELECT
	Col1 = t.r.value('(./c/text())[1]','nvarchar(50)'),
	Col2 = t.r.value('(./c/text())[2]','nvarchar(50)'),
	Col3 = t.r.value('(./c/text())[3]','nvarchar(50)')
FROM		@x.nodes('/t/r') AS t(r);

/* **************************** JSON **************************** */			

SELECT 'JSON';

DECLARE
	@j nvarchar(max) =
N'
[
	["Row 1 Col 1", "Row 1 Col 2", "Row 1 Col 3"],
	["Row 2 Col 1", "Row 2 Col 2", "Row 2 Col 3"]
]';

SELECT
	RowValue = JSONRows.value
FROM		OPENJSON(@j) AS JSONRows;

SELECT
	Col1 = JSON_VALUE(JSONRows.value,'$[0]'),
	Col2 = JSON_VALUE(JSONRows.value,'$[1]'),
	Col3 = JSON_VALUE(JSONRows.value,'$[2]')
FROM		OPENJSON(@j) AS JSONRows;

/* **************************** String_Split **************************** */

SELECT 'String_Split';

DECLARE
	@t nvarchar(max) =
		N'Row 1 Col 1,Row 1 Col 2,Row 1 Col 3/Row 2 Col 1,Row 2 Col 2,Row 2 Col 3';

SELECT
	RowValue = r.[value]
FROM		string_split(@t,'/') AS r;

SELECT
	Col1 = (SELECT c.[value] FROM string_split(r.[value],',') AS c ORDER BY (SELECT 1) OFFSET 0 ROW FETCH NEXT 1 ROW ONLY),
	Col2 = (SELECT c.[value] FROM string_split(r.[value],',') AS c ORDER BY (SELECT 1) OFFSET 1 ROW FETCH NEXT 1 ROW ONLY),
	Col3 = (SELECT c.[value] FROM string_split(r.[value],',') AS c ORDER BY (SELECT 1) OFFSET 2 ROW FETCH NEXT 1 ROW ONLY)
FROM		string_split(@t,'/') AS r;