DECLARE
	@Animals TABLE (Animal varchar(50), Trait varchar(50));

INSERT INTO @Animals (Animal, Trait)
	SELECT 'Cat', 'Cuddly' UNION ALL
	SELECT 'Cat', 'Curious' UNION ALL
	SELECT 'Cow', 'Large' UNION ALL
	SELECT 'Dog', 'Loyal' UNION ALL
	SELECT 'Dog', 'Playful';

WITH Animals AS
(
	SELECT
		Animal,
		CONVERT(varchar(max),Trait) AS Trait,
		ROW_NUMBER() OVER (PARTITION BY Animal ORDER BY Trait) AS TraitNum
	FROM		@Animals
), RecursiveCTE AS
(
	-- Anchor Query
	SELECT
		Animal,
		Trait,
		TraitNum
	FROM		Animals
	WHERE		TraitNum = 1

	UNION ALL

	-- Recursive Part
	SELECT
		Animals.Animal,
		Animals.Trait + ', ' + RecursiveCTE.Trait AS TraitList,
		Animals.TraitNum
	FROM		Animals
	JOIN		RecursiveCTE
	ON			Animals.Animal = RecursiveCTE.Animal
	AND			Animals.TraitNum = RecursiveCTE.TraitNum + 1
), RecursiveCTEWithMaxTraitNum AS
(
	SELECT		*,
				MAX(TraitNum) OVER (PARTITION BY Animal) AS MaxTraitNum
	FROM		RecursiveCTE
)
SELECT
	Animal,
	Trait AS TraitList
FROM		RecursiveCTEWithMaxTraitNum
WHERE		TraitNum = MaxTraitNum
ORDER BY	Animal;