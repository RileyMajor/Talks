DECLARE
@i int, @x xml =
'<x>
	<Element attribute="Attribute Value">Element Value</Element>
	<y><z>Hello</z></y>
</x>';

EXEC sp_xml_preparedocument @i OUTPUT, @x;

SELECT * FROM OPENXML (@i,'/');

EXEC sp_xml_removedocument @i;