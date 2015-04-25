DECLARE
	@LetterNumbers TABLE (PersonID int, Letter varchar(50), Number int, Seq int);


INSERT INTO @LetterNumbers (PersonID, Letter, Number, Seq)
	SELECT 1, 'A', 0, 1 UNION ALL
	SELECT 1, 'B', 0, 2 UNION ALL
	SELECT 1, 'C', 1, 3 UNION  ALL 
	SELECT 2, 'C', 1, 1 UNION ALL
	SELECT 2, 'D', 0, 2 UNION ALL
	SELECT 2, 'A', 1, 3;

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Your query, with some fixes:
PRINT CHAR(13) + CHAR(10) + 'Original Query' + CHAR(13) + CHAR(10);
SELECT
	PersonID
	,(SELECT Letter FROM @LetterNumbers AS BD WHERE bd.PersonID = BDP.PersonID ORDER BY Seq FOR XML PATH(''), TYPE).value('.','varchar(max)') AS ResponseString
	,(SELECT Number FROM @LetterNumbers AS BD WHERE bd.PersonID = BDP.PersonID ORDER BY Seq FOR XML PATH(''), TYPE).value('.','varchar(max)') AS ScoreString
FROM		@LetterNumbers AS BDP;

-- First, let's eliminate duplicates, as I assume that's what you'll want in the end, and we want a fair comparison.
PRINT CHAR(13) + CHAR(10) + 'No Dupes' + CHAR(13) + CHAR(10);
WITH PersonList AS
(
	SELECT
		DISTINCT
		PersonID
	FROM @LetterNumbers
)
SELECT
	PersonID
	,(SELECT Letter FROM @LetterNumbers AS BD WHERE bd.PersonID = BDP.PersonID ORDER BY Seq FOR XML PATH(''), TYPE).value('.','varchar(max)') AS ResponseString
	,(SELECT Number FROM @LetterNumbers AS BD WHERE bd.PersonID = BDP.PersonID ORDER BY Seq FOR XML PATH(''), TYPE).value('.','varchar(max)') AS ScoreString
FROM		PersonList AS BDP;

-- Although the query plan shows a very slightly higher cost, it actually cuts the scan count by more than than half (13 vs 5). I assume this is because it isn't computing the munged strings once for each row of the table, but rather only once for each person ID.

-- Now, let's use a CROSS APPLY with our XML query trick.
PRINT CHAR(13) + CHAR(10) + 'CROSS APPLY' + CHAR(13) + CHAR(10);
WITH PersonList AS
(
	SELECT
		DISTINCT
		PersonID
	FROM @LetterNumbers
)
SELECT
	PersonID,
	Combo.ComboXML.query('(/Letter)').value('.','varchar(max)') AS ResponseString,
	Combo.ComboXML.query('(/Number)').value('.','varchar(max)') AS ScoreString
FROM		PersonList AS BDP
CROSS APPLY	(
				SELECT
					(
						SELECT
							Letter,
							Number
						FROM		@LetterNumbers AS BD
						WHERE		bd.PersonID = BDP.PersonID
						ORDER BY	Seq
						FOR XML PATH (''), TYPE
					) AS ComboXML
			) AS Combo;

-- This is the same thing, but with an alternate syntax requiring one less sub-select in the CROSS APPLY.
PRINT CHAR(13) + CHAR(10) + 'CROSS APPLY (alt syntax)' + CHAR(13) + CHAR(10);
WITH PersonList AS
(
	SELECT
		DISTINCT
		PersonID
	FROM @LetterNumbers
)
SELECT
	PersonID,
	Combo.ComboXML.query('(/Letter)').value('.','varchar(max)') AS ResponseString,
	Combo.ComboXML.query('(/Number)').value('.','varchar(max)') AS ScoreString
FROM		PersonList AS BDP
CROSS APPLY	(
				SELECT
					Letter,
					Number
				FROM		@LetterNumbers AS BD
				WHERE		bd.PersonID = BDP.PersonID
				ORDER BY	Seq
				FOR XML PATH (''), TYPE
			) AS Combo(ComboXML);

-- Note that both of these CROSS APPLY options have about half the logical reads of the other query.

-- But can we do even better? Instead of constructing a separate set of XML for each person, let's try constructing only one set of XML and mining it repeatedly...
PRINT CHAR(13) + CHAR(10) + 'One XML' + CHAR(13) + CHAR(10);
WITH PersonList AS
(
	SELECT
		DISTINCT
		PersonID
	FROM @LetterNumbers
),
XMLDataTable(XMLData) AS
(
		SELECT
			*
		FROM		@LetterNumbers AS BD
		ORDER BY	PersonID,
					Seq
		FOR XML PATH ('Row'), TYPE
)
SELECT
	PersonID,
	XMLData.query('/Row[PersonID[text() = sql:column("PersonID")]]/Letter').value('.','varchar(max)') AS ResponseString,
	XMLData.query('/Row[PersonID[text() = sql:column("PersonID")]]/Number').value('.','varchar(max)') AS ScoreString
FROM		PersonList
CROSS JOIN	XMLDataTable;

-- Sure enough, we dropped another 33% of reads (3 to 2). But is that really better?
--	It probably depends on whether the engine is better at traversing the XML or tables.
--	The elapsed time from the statistics indicates that this might be slower.
--	So it probably depends on the volume and complexity of the underlying data query.

-- Can we go even further? Let's try getting the whole data query in XML format once and not hitting it again.
PRINT CHAR(13) + CHAR(10) + 'One Table Hit' + CHAR(13) + CHAR(10);
WITH XMLDataTable(XMLData) AS
(
		SELECT
			*
		FROM		@LetterNumbers AS BD
		ORDER BY	PersonID,
					Seq
		FOR XML PATH ('Row'), TYPE
), PersonList AS
(
	SELECT
		DISTINCT
		x.value('.','varchar(max)') AS PersonID
	FROM		XMLDataTable
	CROSS APPLY	XMLDataTable.XMLData.nodes('/Row/PersonID') AS T(x)
)
SELECT
	PersonID,
	XMLData.query('/Row[PersonID[text() = sql:column("PersonID")]]/Letter').value('.','varchar(max)') AS ResponseString,
	XMLData.query('/Row[PersonID[text() = sql:column("PersonID")]]/Number').value('.','varchar(max)') AS ScoreString
FROM		PersonList
CROSS JOIN	XMLDataTable;

-- This didn't actually decrease our scan count, but it might still be better performance. You'd have to run it on a larger data set instead.
-- This still does some context switching between XML processing and SQL processing.
--	(You can see the Sort (Distinct Sort) operator in the query plan.)

-- Let's see if we can stay in XML the whole time:
PRINT CHAR(13) + CHAR(10) + 'Pure XML' + CHAR(13) + CHAR(10);
WITH XMLDataTable(XMLData) AS
(
		SELECT
			*
		FROM		@LetterNumbers AS BD
		ORDER BY	PersonID,
					Seq
		FOR XML PATH ('Row'), TYPE
), PersonListXML AS
(
	SELECT
		XMLData.query(
		'
			for $e in distinct-values(/Row/PersonID)
				return <PersonID>{$e}</PersonID>
		') AS PersonList
	FROM		XMLDataTable
), PersonList AS
(
	SELECT
		x.value('.','varchar(max)') AS PersonID
	FROM		PersonListXML
	CROSS APPLY	PersonListXML.PersonList.nodes('/PersonID') AS T(x)
)
SELECT
	PersonID,
	XMLData.query('/Row[PersonID[text() = sql:column("PersonID")]]/Letter').value('.','varchar(max)') AS ResponseString,
	XMLData.query('/Row[PersonID[text() = sql:column("PersonID")]]/Number').value('.','varchar(max)') AS ScoreString
FROM		PersonList
CROSS JOIN	XMLDataTable

-- That works, but it doesn't seem to have saved any reads. Let's try another approach, where we reconstruct the XML in a proper hierarchy:
PRINT CHAR(13) + CHAR(10) + 'Pure XML Version 2' + CHAR(13) + CHAR(10);
WITH XMLDataTable(XMLData) AS
(
		SELECT
			*
		FROM		@LetterNumbers AS BD
		ORDER BY	PersonID,
					Seq
		FOR XML PATH ('Row'), TYPE
), PersonListXML AS
(
	SELECT
		XMLData.query(
		'
			for $e in distinct-values(/Row/PersonID)
				return
					<PersonRow>
						<PersonID>{$e}</PersonID>
						<Responses>
							{
								for $f in (/Row[PersonID = $e]/Letter)
									return
										<Response>
											{data($f)}
										</Response>
							}
						</Responses>
						<Scores>
							{
								for $f in (/Row[PersonID = $e]/Number)
									return
										<Score>
											{data($f)}
										</Score>
							}
						</Scores>
					</PersonRow>
		') AS PersonList
	FROM		XMLDataTable
)
SELECT
	x.value('(./PersonID)[1]','varchar(max)') AS PersonID,
	x.value('(./Responses)[1]','varchar(max)') AS ResponseString,
	x.value('(./Scores)[1]','varchar(max)') AS ScoreString
	-- To review the XML it constructs, un-comment these:
	--,
	--PersonList.query('.') AS FullXML,
	--x.query('.') AS PersonXML
FROM		PersonListXML
CROSS APPLY	PersonListXML.PersonList.nodes('/PersonRow') AS T(x)

-- And we're down to one read. But the query plan cost is very high. Most of these examples trade IO for CPU, but each decrease in IO might cost even more CPU, so you'd have to find the right balance for your data and your server specs.

-- You can simplify the flwor syntax (the for each stuff) by having it grab the values and smoosh them together
PRINT CHAR(13) + CHAR(10) + 'Pure XML Version 3' + CHAR(13) + CHAR(10);
WITH XMLDataTable(XMLData) AS
(
		SELECT
			*
		FROM		@LetterNumbers AS BD
		ORDER BY	PersonID,
					Seq
		FOR XML PATH ('Row'), TYPE
), PersonListXML AS
(
	SELECT
		XMLData.query(
		'
			for $e in distinct-values(/Row/PersonID)
				return
					<PersonRow>
						<PersonID>{$e}</PersonID>
						<Responses>{data(/Row[PersonID = $e]/Letter)}</Responses>
						<Scores>{data(/Row[PersonID = $e]/Number)}</Scores>
					</PersonRow>
		') AS PersonList
	FROM		XMLDataTable
)
SELECT
	x.value('(./PersonID)[1]','varchar(max)') AS PersonID,
	-- Unfortunately, the "for each" flwor function puts a space between our values, so we have to filter that out
	REPLACE(x.value('(./Responses)[1]','varchar(max)'),' ','') AS ResponseString,
	REPLACE(x.value('(./Scores)[1]','varchar(max)'),' ','') AS ScoreString
	-- To review the XML it constructs, un-comment these:
	--,
	--PersonList.query('.') AS FullXML,
	--x.query('.') AS PersonXML
FROM		PersonListXML
CROSS APPLY	PersonListXML.PersonList.nodes('/PersonRow') AS T(x)

-- These last examples were heavily inspired by:
--	http://stackoverflow.com/questions/11803020/xquery-to-combine-node-values-with-group-by-logic