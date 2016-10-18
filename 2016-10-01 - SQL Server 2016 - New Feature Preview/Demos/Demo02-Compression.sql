DECLARE
	@CompressedData varbinary(max),
	@DoubleCompressedData varbinary(max),
	@vcData varchar(max) = REPLICATE(CONVERT(varchar(max),'Hello'), 1000000);

SELECT
	@CompressedData = COMPRESS(@vcData);

SELECT
	@DoubleCompressedData = COMPRESS(@CompressedData);

SELECT
	@CompressedData AS CompressedDataBinary,
	CONVERT(varchar(max),@CompressedData) AS CompressedDataText,
	CONVERT(varchar(max),DECOMPRESS(@CompressedData)) AS DecompressedData,
	UNCOMPRESS(@CompressedData) AS  UncompressedData,
	DATALENGTH(@vcData) AS OrigDataSize,
	DATALENGTH(@CompressedData) AS CompressedDataSize,
	DATALENGTH(@DoubleCompressedData) AS DoubleCompressedSize,
	CONVERT(varchar(max),DECOMPRESS(DECOMPRESS(@DoubleCompressedData))) AS DoubleDecompressedData;