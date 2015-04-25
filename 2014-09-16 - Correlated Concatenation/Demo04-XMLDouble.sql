DECLARE
	@LetterNumbers TABLE (Letter varchar(50), Number int);

INSERT INTO @LetterNumbers (Letter, Number)
	SELECT 'A', 1 UNION ALL
	SELECT 'B', 2 UNION ALL
	SELECT 'C', 3;

-- Use FOR XML to Construct XML (specifying root node and row node names)
SELECT
	Letter, Number
FROM		@LetterNumbers
FOR XML PATH ('RowNodeName'), ROOT('RootNodeName'), TYPE;

-- Simplified FOR XML Syntax (ignore node names)
SELECT
	Letter, Number
FROM		@LetterNumbers
FOR XML PATH, TYPE;

-- Wrap it in a SELECT to give it a name
SELECT
	(
		SELECT
			Letter, Number
		FROM		@LetterNumbers
		FOR XML PATH, TYPE
	) AS LetterNumberXML;

SET STATISTICS IO ON;

-- Extract Each List Separately
SELECT
(
	SELECT
		Letter
	FROM		@LetterNumbers
	FOR XML PATH, TYPE
).value('.','varchar(max)'),
(
	SELECT
		Number
	FROM		@LetterNumbers
	FOR XML PATH, TYPE
).value('.','varchar(max)');

-- Notice that @LetterNumbers is accessed twice.
-- Instead, we can create XML which has all of the data we need,
-- and then extract each list separately.

WITH LetterNumberXMLTable AS
(
	SELECT
		(
			SELECT
				Letter,
				Number
			FROM		@LetterNumbers
			FOR XML PATH, TYPE
		) AS LetterNumberXML
)
SELECT
	LetterNumberXMLTable.LetterNumberXML.query('(//Letter)').value('.','varchar(max)') AS LetterList,
	LetterNumberXMLTable.LetterNumberXML.query('(//Number)').value('.','varchar(max)') AS NumberList
FROM	LetterNumberXMLTable;

-- Alternative Syntax (one less nested SELECT in CTE, replaced with CTE column naming technique)
WITH LetterNumberXMLTable (LetterNumberXML) AS
(
	SELECT
		Letter,
		Number
	FROM		@LetterNumbers
	FOR XML PATH, TYPE
)
SELECT
	LetterNumberXMLTable.LetterNumberXML.query('(//Letter)').value('.','varchar(max)') AS LetterList,
	LetterNumberXMLTable.LetterNumberXML.query('(//Number)').value('.','varchar(max)') AS NumberList
FROM	LetterNumberXMLTable;

SET STATISTICS IO OFF;