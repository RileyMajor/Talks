SELECT
	CONVERT(xml,'<TextXML>I typed this.</TextXML>') AS 'OuterTag'
FOR XML PATH('');

SELECT
	'{"TextJSON":"I typed this."}' AS 'OuterTag'
FOR JSON PATH;

SELECT
	(
		SELECT
			'I typed this.' AS TextJSON
		FOR JSON PATH
	) AS 'OuterTag'
FOR JSON PATH;