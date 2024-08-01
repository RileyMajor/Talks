DROP FUNCTION IF EXISTS CalcFunnyName;
GO
CREATE FUNCTION CalcFunnyName 
(	
	@text varchar(50), @NumLeadingChars int, @NumTrailingChars int, @FunkyTuesdays bit, @Today datetime
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT
		*
	FROM		(
					SELECT
						IsTuesday = CASE WHEN DATEPART(WEEKDAY,@Today) = 3 THEN 1 ELSE 0 END
				) AS CalcIsTuesday
	CROSS APPLY	(
					SELECT
						LeadingChunkLen = @NumLeadingChars,
						TrailingChunkLen = CASE WHEN CalcIsTuesday.IsTuesday <> 0 AND @FunkyTuesdays <> 0 THEN @NumTrailingChars * 2 ELSE @NumTrailingChars END
				) AS ChunkLengths
	CROSS APPLY	(
					SELECT
						LeadingChars = LEFT(@text,ChunkLengths.LeadingChunkLen),
						TrailingChars = RIGHT(@text,ChunkLengths.TrailingChunkLen)
				) AS TextChunks
	CROSS APPLY	(
					SELECT
						ReverseLeadingChars = REVERSE(TextChunks.LeadingChars),
						ReverseTrailingChars = REVERSE(TextChunks.TrailingChars)
				) AS ReverseChunks
	CROSS APPLY	(
					SELECT
						FunnyName = ReverseChunks.ReverseTrailingChars + ReverseChunks.ReverseLeadingChars
				) AS FinalResult
)
GO