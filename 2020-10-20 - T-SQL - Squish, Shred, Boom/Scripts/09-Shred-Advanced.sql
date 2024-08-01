USE Test;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

DECLARE
	@ColDelim nvarchar(10) = N',',
	@RowDelim nvarchar(10) = CHAR(13)+CHAR(10),
	@t nvarchar(max) =
N'CustomerID,Customer,CustomerEmail
1,<Lorem Associates,LoremAssociates@example.com
2,😀Purus In Molestie Associates,PurusInMolestieAssociates@example.com
3,\Non Nisi Corporation,NonNisiCorporation@example.com
4,"Libero At Auctor PC,LiberoAtAuctorPC@example.com
5,Nec Limited,NecLimited@example.com
6,Non Lobortis Corp.,NonLobortisCorp.@example.com
7,Auctor Company,AuctorCompany@example.com
8,Semper Erat In Corporation,SemperEratInCorporation@example.com
9,Consequat Auctor Company,ConsequatAuctorCompany@example.com
10,Sapien Institute,SapienInstitute@example.com';

SELECT					/* XML Shredder */
	--ScrubXML.*, t1.*, t2.*, t3.*, t4.*
	ShreddedRows.*	
FROM		(
				SELECT
					t = @t,
					ColDelim = @ColDelim,
					RowDelim = @RowDelim
			) AS c
CROSS APPLY	(
				SELECT
					CleanXML = 
						(
							SELECT
								c.t AS '*'
							FOR XML PATH('')
						),
					ColDelimXML =
						(
							SELECT
								c.ColDelim AS '*'
							FOR XML PATH('')
						),
					RowDelimXML =
						(
							SELECT
								c.RowDelim AS '*'
							FOR XML PATH('')
						)
			) ScrubXML
CROSS APPLY	(
				SELECT
					ChangedColDelims = REPLACE(ScrubXML.CleanXML,ScrubXML.ColDelimXML,N'</c><c>')
			) AS t1
CROSS APPLY	(
				SELECT
					ChangedRowDelims = REPLACE(ChangedColDelims,ScrubXML.RowDelimXML,N'</c></r><r><c>')
			) AS t2
CROSS APPLY	(
				SELECT
					FullXMLText = N'<t><r><c>' + t2.ChangedRowDelims + N'</c></r></t>'
			) AS t3
CROSS APPLY	(
				SELECT
					FullXML = CONVERT(xml,t3.FullXMLText)
			) AS t4
CROSS APPLY	(
				SELECT
					RowNum = (ROW_NUMBER() OVER (ORDER BY (SELECT 1))) - 1,
					Col1 = t.r.value('(./c/text())[1]','nvarchar(50)'),
					Col2 = t.r.value('(./c/text())[2]','nvarchar(50)'),
					Col3 = t.r.value('(./c/text())[3]','nvarchar(50)')
				FROM		t4.FullXML.nodes('/t/r') AS t(r)
			) AS ShreddedRows
WHERE		ShreddedRows.RowNum > 0;
				

				

SELECT					/* JSON Shredder */
	RowNum = r.RowNum,
	Col1 = MAX(CASE WHEN CellValues.ColNum = 1 THEN CellValues.ColValue ELSE NULL END),
	Col2 = MAX(CASE WHEN CellValues.ColNum = 2 THEN CellValues.ColValue ELSE NULL END),
	Col3 = MAX(CASE WHEN CellValues.ColNum = 3 THEN CellValues.ColValue ELSE NULL END)
FROM		(
				SELECT
					t = @t,
					ColDelim = @ColDelim,
					RowDelim = @RowDelim,
					GoodColDelim = NCHAR(29),
					GoodRowDelim = NCHAR(30)
			) AS c
CROSS APPLY	(
				SELECT
					ChangedColDelims = REPLACE(@t,c.ColDelim,c.GoodColDelim)
			) AS t1
CROSS APPLY	(
				SELECT
					ChangedRowDelims = REPLACE(t1.ChangedColDelims,c.RowDelim,c.GoodRowDelim)
			) AS t2
CROSS APPLY	(
				SELECT
					EscapedSlashes = REPLACE(t2.ChangedRowDelims,'\','\\')
			) AS t3
CROSS APPLY	(
				SELECT
					EscapedQuotes = REPLACE(t3.EscapedSlashes,'"','\"')
			) AS t4
CROSS APPLY	(
				SELECT
					ColDelims = REPLACE(t4.EscapedQuotes,c.GoodColDelim,'","')
			) AS t5
CROSS APPLY	(
				SELECT
					RowDelims = REPLACE(t5.ColDelims,c.GoodRowDelim,'"],["')
			) AS t6
CROSS APPLY	(
				SELECT
					FullJSON = '[["' + t6.RowDelims + '"]]'
			) AS t7
CROSS APPLY	(
				SELECT
					RowNum = CONVERT(int,JSONRows.[key]),
					RowValue = JSONRows.value
				FROM		OPENJSON(t7.FullJSON) AS JSONRows
			) AS r
CROSS APPLY	(
				SELECT
					ColNum = CONVERT(int,JSONCols.[key]) + 1,
					ColValue = JSONCols.value
				FROM		OPENJSON(r.RowValue) AS JSONCols
			) AS CellValues
WHERE		r.RowNum > 0
GROUP BY	r.RowNum;



SELECT					/* split_string Shredder */
	RowNum = r.RowNum,
	Col1 = MAX(CASE WHEN CellValues.ColNum = 1 THEN CellValues.ColValue ELSE NULL END),
	Col2 = MAX(CASE WHEN CellValues.ColNum = 2 THEN CellValues.ColValue ELSE NULL END),
	Col3 = MAX(CASE WHEN CellValues.ColNum = 3 THEN CellValues.ColValue ELSE NULL END)
FROM		(
				SELECT
					t = @t,
					ColDelim = @ColDelim,
					RowDelim = @RowDelim,
					GoodColDelim = NCHAR(29),
					GoodRowDelim = NCHAR(30),
					JSONEncap = N'"',
					JSONArrayDelim = N','
			) AS c
CROSS APPLY	(
				SELECT
					ChangedColDelims = REPLACE(@t,c.ColDelim,c.GoodColDelim)
			) AS t1
CROSS APPLY	(
				SELECT
					ChangedRowDelims = REPLACE(t1.ChangedColDelims,c.RowDelim,c.GoodRowDelim)
			) AS t2
CROSS APPLY	(
				SELECT
					RowNum = (ROW_NUMBER() OVER (ORDER BY (SELECT 1))) - 1,
					RowValue = RowSplit.value
				FROM		string_split
							(
								t2.ChangedRowDelims,
								c.GoodRowDelim
							) AS RowSplit
			) AS r
CROSS APPLY	(
				SELECT
					ColNum = ROW_NUMBER() OVER (ORDER BY (SELECT 1)),
					ColValue = cols.value
				FROM		string_split
							(
								r.RowValue,
								c.GoodColDelim
							) AS cols
			) AS CellValues
WHERE		r.RowNum > 0
GROUP BY	r.RowNum;


/* Note: none of these work with quote-encapsulated data. */