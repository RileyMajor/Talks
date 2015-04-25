DECLARE
	@Animals TABLE (Animal varchar(50), Trait varchar(50));

INSERT INTO @Animals (Animal, Trait)
	SELECT 'Cat', 'Cuddly' UNION ALL
	SELECT 'Cat', 'Curious';

DECLARE
	@TraitList_NoOrder varchar(max), @TraitList_Ordered varchar(max);
SELECT
	@TraitList_NoOrder = '', @TraitList_Ordered = '';

SELECT
	@TraitList_NoOrder = @TraitList_NoOrder + LTRIM(RTRIM(Trait)) + ', '
FROM		@Animals
ORDER BY	Trait;

SELECT
	@TraitList_Ordered = @TraitList_Ordered + LTRIM(RTRIM(Trait)) + ', '
FROM		@Animals
ORDER BY	LTRIM(RTRIM(Trait));

SELECT
	@TraitList_NoOrder AS 'TraitList Without ORDER BY',
	@TraitList_Ordered AS 'TraitList With ORDER BY';