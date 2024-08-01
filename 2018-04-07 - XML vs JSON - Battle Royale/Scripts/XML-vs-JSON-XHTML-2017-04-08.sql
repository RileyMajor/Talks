SELECT
	'Hello, world!' AS 'div',
	NULL, /* If this isn't here, SQL Server will squish both divs into one. */
	'Hello, world again!' AS 'div'
FOR
	XML
	PATH ('body'),
	ROOT('html'),
	TYPE;