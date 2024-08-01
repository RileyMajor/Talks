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
	*
FROM		(
				SELECT
					RowNum = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
					RowValue = XMLRows.XMLRow.query('.')
				FROM		@x.nodes('/t/r') AS XMLRows(XMLRow)
			) AS r
CROSS APPLY	(
				SELECT
					ColNum = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
					ColValue = XMLCols.XMLCol.value('text()[1]','varchar(50)')
				FROM		r.RowValue.nodes('./r/c') AS XMLCols(XMLCol)
			) AS CellValues;

SELECT
	Col1 = MAX(CASE WHEN CellValues.ColNum = 1 THEN CellValues.ColValue ELSE NULL END),
	Col2 = MAX(CASE WHEN CellValues.ColNum = 2 THEN CellValues.ColValue ELSE NULL END),
	Col3 = MAX(CASE WHEN CellValues.ColNum = 3 THEN CellValues.ColValue ELSE NULL END)
FROM		(
				SELECT
					RowNum = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
					RowValue = XMLRows.XMLRow.query('.')
				FROM		@x.nodes('/t/r') AS XMLRows(XMLRow)
			) AS r
CROSS APPLY	(
				SELECT
					ColNum = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
					ColValue = XMLCols.XMLCol.value('text()[1]','varchar(50)')
				FROM		r.RowValue.nodes('./r/c') AS XMLCols(XMLCol)
			) AS CellValues
GROUP BY	r.RowNum;


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
	RowNum = CONVERT(int,JSONRows.[key]) + 1,
	RowValue = JSONRows.value
FROM		OPENJSON(@j) AS JSONRows;


SELECT
	*
FROM		(
				SELECT
					RowNum = CONVERT(int,JSONRows.[key]) + 1,
					RowValue = JSONRows.value
				FROM		OPENJSON(@j) AS JSONRows
			) AS r
CROSS APPLY	(
				SELECT
					ColNum = CONVERT(int,JSONCols.[key]) + 1,
					ColValue = JSONCols.value
				FROM		OPENJSON(r.RowValue) AS JSONCols
			) AS CellValues
WHERE		r.RowNum > 0;


SELECT
	Col1 = MAX(CASE WHEN CellValues.ColNum = 1 THEN CellValues.ColValue ELSE NULL END),
	Col2 = MAX(CASE WHEN CellValues.ColNum = 2 THEN CellValues.ColValue ELSE NULL END),
	Col3 = MAX(CASE WHEN CellValues.ColNum = 3 THEN CellValues.ColValue ELSE NULL END)
FROM		(
				SELECT
					RowNum = CONVERT(int,JSONRows.[key]) + 1,
					RowValue = JSONRows.value
				FROM		OPENJSON(@j) AS JSONRows
			) AS r
CROSS APPLY	(
				SELECT
					ColNum = CONVERT(int,JSONCols.[key]) + 1,
					ColValue = JSONCols.value
				FROM		OPENJSON(r.RowValue) AS JSONCols
			) AS CellValues
WHERE		r.RowNum > 0
GROUP BY	r.RowNum;


/* **************************** String_Split **************************** */

SELECT 'String_Split';

DECLARE
	@t nvarchar(max) =
		N'Row 1 Col 1,Row 1 Col 2,Row 1 Col 3/Row 2 Col 1,Row 2 Col 2,Row 2 Col 3';

SELECT
	RowNum = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
	RowValue = r.[value]
FROM		string_split(@t,'/') AS r;

SELECT
	*
FROM		(
				SELECT
					RowNum = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),	/* No guarantee of order! */
					RowValue = r.[value]
				FROM		string_split(@t,'/') AS r
			) AS Split_Rows
CROSS APPLY	(
				SELECT
					ColNum = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
					ColValue = c.[value]
				FROM		string_split(Split_Rows.RowValue,',') AS c
			) Split_Cols;

SELECT
	Col1 = MAX(CASE WHEN Split_Cols.ColNum = 1 THEN Split_Cols.ColValue ELSE NULL END),
	Col2 = MAX(CASE WHEN Split_Cols.ColNum = 2 THEN Split_Cols.ColValue ELSE NULL END),
	Col3 = MAX(CASE WHEN Split_Cols.ColNum = 3 THEN Split_Cols.ColValue ELSE NULL END)
FROM		(
				SELECT
					RowNum = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
					RowValue = r.[value]
				FROM		string_split(@t,'/') AS r
			) AS Split_Rows
CROSS APPLY	(
				SELECT
					ColNum = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
					ColValue = c.[value]
				FROM		string_split(Split_Rows.RowValue,',') AS c
			) Split_Cols
GROUP BY	Split_Rows.RowNum;
