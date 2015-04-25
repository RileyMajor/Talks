DECLARE
	@Letters TABLE (Letter varchar(50));

INSERT INTO @Letters (Letter)
	SELECT 'A' UNION ALL
	SELECT 'B' UNION ALL
	SELECT 'C';

-- Raw Table
SELECT
	Letter
FROM	@Letters

-- Use FOR XML to Construct XML (specifying root node and row node names)
SELECT
	Letter
FROM		@Letters
FOR XML PATH ('RowNodeName'), ROOT('RootNodeName'), TYPE;

-- Simplified FOR XML Syntax (ignore node names)
SELECT
	Letter
FROM		@Letters
FOR XML PATH, TYPE;

-- Wrap it into a SELECT to give it a name
SELECT
	(
		SELECT
			Letter
		FROM		@Letters
		FOR XML PATH, TYPE
	) AS LettersXML;

-- Magic Concatenation
SELECT
	(
		SELECT
			Letter
		FROM		@Letters
		FOR XML PATH, TYPE
	).value('.','varchar(max)');

-- Cleanup and Customization
SELECT
	STUFF
	(
		(
			SELECT
				', ' + Letter
			FROM		@Letters
			ORDER BY	Letter DESC
			FOR XML PATH, TYPE
		).value('.','varchar(max)')
		, 1, 2, ''
	);