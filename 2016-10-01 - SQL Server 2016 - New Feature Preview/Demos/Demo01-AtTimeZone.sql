DECLARE
	@DateTimeWithOffsetInDaylightSavings datetimeoffset = '2016-11-25T13:15:00+00:00',
	@DateTimeWithOffsetNoDaylightSavings datetimeoffset = '2016-10-25T13:15:00+00:00';
SELECT
	@DateTimeWithOffsetInDaylightSavings AS RawDateTimeWithOffsetInDaylightSavings,
	@DateTimeWithOffsetInDaylightSavings AT TIME ZONE 'Central Standard Time' AS ConvertedDateTimeWithOffsetInDaylightSavings;
SELECT
	@DateTimeWithOffsetNoDaylightSavings AS RawDateTimeWithOffsetNoDaylightSavings,
	@DateTimeWithOffsetNoDaylightSavings AT TIME ZONE 'Central Standard Time' AS ConvertedDateTimeWithOffsetNoDaylightSavings;