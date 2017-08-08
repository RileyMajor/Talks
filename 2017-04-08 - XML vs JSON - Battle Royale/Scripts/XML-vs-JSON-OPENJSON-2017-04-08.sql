DECLARE @j varchar(max) =
'{
	"NULL": null,
	"String": "Hello",
	"Number": 123.4E05,
	"Boolean": true,
	"Array":[1,2,3],
	"JSON": {"a":"b"}
}';
SELECT		*
FROM		OPENJSON(@j);