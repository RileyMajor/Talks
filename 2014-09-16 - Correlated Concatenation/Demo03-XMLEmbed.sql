DECLARE
	@Animals TABLE (Animal varchar(50), Trait varchar(50));

INSERT INTO @Animals (Animal, Trait)
	SELECT 'Cat', 'Cuddly' UNION ALL
	SELECT 'Cat', 'Curious' UNION ALL
	SELECT 'Cow', 'Large' UNION ALL
	SELECT 'Dog', 'Loyal' UNION ALL
	SELECT 'Dog', 'Playful';

WITH AnimalsDistinct AS
(
	SELECT
		DISTINCT Animal
	FROM		@Animals
)
SELECT
	Animal,
	(
		SELECT
			Trait + ', ' AS Trait
		FROM		@Animals a
		WHERE		a.Animal = AnimalsDistinct.Animal
		FOR XML PATH (''), TYPE
	).value('.','varchar(max)')
FROM		AnimalsDistinct;