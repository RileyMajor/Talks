SELECT
	(
		SELECT	*
		FROM	(VALUES 
				('Yes, you can put XML in JSON!'),
				('But why would you do this?')) AS DataList(DataElement)
		FOR XML AUTO
	) AS UnholyUnion
FOR JSON PATH;

SELECT
	(
		SELECT	*
		FROM	(VALUES 
				('Yes, you can put JSON in XML!'),
				('But why would you do this?')) AS DataList(DataElement)
		FOR JSON AUTO
	) AS UnholyUnion
FOR XML PATH;