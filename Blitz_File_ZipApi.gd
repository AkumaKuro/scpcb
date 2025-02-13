
const ZIPAPI_DEFLATED: int = 8

const ZIPAPI_APPEND_CREATE= 0

const ZIPAPI_APPEND_CREATEAFTER = 1

const ZIPAPI_APPEND_ADDINZIP = 2

const ZIPAPI_DEFAULT_COMPRESSION: int = -1

const ZIPAPI_NO_COMPRESSION = 0

const ZIPAPI_BEST_SPEED = 1

const ZIPAPI_BEST_COMPRESSION = 9

# -- Constants for extended compression methods
Const ZIPAPI_MAX_WBITS%= 15
Const ZIPAPI_DEF_MEM_LEVEL= 8
Const ZIPAPI_DEFAULT_STRATEGY= 0



Const ZIPAPI_DATA_HEADER%			= 10101982

# --------------------------------------------------
# -- Function Return Constants
# --------------------------------------------------



Const ZIPAPI_OK%					= 0



Const ZIPAPI_EOF					= 0




Const ZIPAPI_STREAM_END				= 1




Const ZIPAPI_NEED_DICT				= 2




Const ZIPAPI_ERRNO					= -1




Const ZIPAPI_STREAM_ERROR			= -2



Const ZIPAPI_DATA_ERROR				= -3



Const ZIPAPI_MEM_ERROR				= -4



Const ZIPAPI_BUF_ERROR				= -5




Const ZIPAPI_VERSION_ERROR			= -6




Const ZIPAPI_END_OF_LIST_OF_FILE%	= -100



Const ZIPAPI_PARAMERROR%			= -102



Const ZIPAPI_BADZIPFILE				= -103



Const ZIPAPI_INTERNALERROR			= -104



Const ZIPAPI_CRCERROR				= -105

# -- Custom Blitz Return Constants




Const ZIPAPI_INVALIDPOINTER%		= -51



Const ZIPAPI_INVALIDBANK%			= -50

# -- Custom constants



Const ZIPAPI_HEADER_INT%			= 67324752

# --------------------------------------------------
# -- Compress Bank / Decompress Bank Functions
# --------------------------------------------------







Function ZipApi_CompressBank%(bankHandle%, compressionLevel% = ZIPAPI_DEFAULT_COMPRESSION)

	# Check inputs
	If bankHandle < 1 Then Return ZIPAPI_INVALIDBANK

	# Compress the bank and append our data to the end
	Local compressedBank	= ZipApi_Compress(bankHandle, compressionLevel)

	# Check it worked - return if not
	If compressedBank < 1 Then Return compressedBank

	# Resize the result to accomodata header, then add our header data
	# and uncompressed length to the end of the bank
	ResizeBank(compressedBank, BankSize(compressedBank) + 8)

	PokeInt(compressedBank, BankSize(compressedBank) - 8, ZIPAPI_DATA_HEADER)
	PokeInt(compressedBank, BankSize(compressedBank) - 4, BankSize(bankHandle))

	Return compressedBank

End Function






Function ZipApi_UnCompressBank%(bankHandle%)

	# Check inputs (valid bank & has header)
	If bankHandle < 1 Then Return ZIPAPI_INVALIDBANK
	If PeekInt(bankHandle, BankSize(bankHandle) - 8) <> ZIPAPI_DATA_HEADER Then Return ZIPAPI_INVALIDBANK

	# Get new size
	Local dataSize	= PeekInt(bankHandle, BankSize(bankHandle) - 4)

	# Create a new bank from resized data( so we don't alter the original input )
	Local dataBank	= CreateBank(BankSize(bankHandle) - 8)
	CopyBank(bankHandle, 0, dataBank, 0, BankSize(dataBank))

	# Uncompress it
	Local returnBank	= ZipApi_UnCompress(dataBank, dataSize)

	# Cleanup & return
	FreeBank dataBank
	Return returnBank

End Function

# --------------------------------------------------
# -- Compress / Decompress Functions
# --------------------------------------------------






Function ZipApi_Compress%(bankHandle%, compressionLevel% = ZIPAPI_DEFAULT_COMPRESSION)

	# Check bank input - return 0 if invalid
	If bankHandle < 1 Then Return False
	If BankSize(bankHandle) < 1 Then Return False

	# Check compression level and limit appropriately
	If compressionLevel < 1 Then compressionLevel = 1
	If compressionLevel > 9 Then compressionLevel = 9

	# Create a bank to place compressed data into
	Local destBank	= CreateBank(ZlibWapi_CompressBound(BankSize(bankHandle)))

	# Create bank to store dest size & populate
	Local destSize	= CreateBank(4)
	PokeInt(destSize, 0, BankSize(destBank))

	# Compress
	Local zipResult	= ZlibWapi_Compress2(destBank, destSize, bankHandle, BankSize(bankHandle), compressionLevel)

	# Check bank was compressed properly
	If zipResult <> ZIPAPI_OK Then

		# Failed, so cleanup & return error
		FreeBank destSize
		FreeBank destBank
		Return zipResult

	EndIf

	# Resize result
	ResizeBank(destBank, PeekInt(destSize, 0))

	# Cleanup & return result
	FreeBank destSize
	Return destBank

End Function






Function ZipApi_UnCompress%(bankHandle%, unpackedSize% = 0)

	# Check bank input - return 0 if invalid
	If bankHandle < 1 Then Return ZIPAPI_INVALIDBANK
	If BankSize(bankHandle) < 1 Then Return ZIPAPI_INVALIDBANK

	# Create a bank to place uncompressed data into
	# If no size is specified, use input * 100 just to be safe
	If unpackedSize = 0 Then unpackedSize = BankSize(bankHandle) * 100
	Local destBank	= CreateBank(unpackedSize)

	# Create bank to store uncompressed size & populate
	Local destSize	= CreateBank(4)
	PokeInt(destSize, 0, BankSize(destBank))

	# Compress
	Local zipResult	= ZlibWapi_UnCompress(destBank, destSize, bankHandle, BankSize(bankHandle))

	# Check bank was compressed properly
	If zipResult <> ZIPAPI_OK Then

		# Failed, so cleanup & return error
		FreeBank destSize
		FreeBank destBank
		Return zipResult

	EndIf

	# Resize result
	ResizeBank(destBank, PeekInt(destSize, 0))

	# Cleanup & return result
	FreeBank destSize
	Return destBank

End Function

func ZipApi_Open(fileName: String) -> int:
	return ZlibWapi_UnzOpen(fileName)

Function ZipApi_Close%(zipHandle%, cleanUp% = True)

	If cleanUp Then

		ZipApi_GotoFirstFile(zipHandle)

		Repeat

			Local currentFile.ZIPAPI_UnzFileInfo	= ZipApi_GetCurrentFileInfo(zipHandle)

			If currentFile <> Null Then
				If FileType(SystemProperty("tempdir") + File_GetFileName(currentFile\FileName)) = FILETYPE_FOUND Then
					DeleteFile(SystemProperty("tempdir") + File_GetFileName(currentFile\FileName))
				EndIf

			EndIf

		Until ZipApi_GotoNextFile(zipHandle) = ZIPAPI_END_OF_LIST_OF_FILE

	EndIf

	Return ZlibWapi_UnzClose(zipHandle)

End Function








Function ZipApi_ExtractFile$(zipHandle, fileName$, destName$ = "", password$ = "")

	# Check inputs
	If zipHandle < 1 Then Return ""
	If fileName = "" Then Return ""

	# Get the name of the extracted file
	If destName = "" Then destName = SystemProperty("TEMPDIR") + File_GetFileName(fileName)

	Local prevFile.ZIPAPI_UnzFileInfo	= ZipApi_GetCurrentFileInfo(zipHandle)
	ZipApi_GotoFirstFile(zipHandle)

	# Find file
	If ZlibWapi_UnzLocateFile(zipHandle, File_ConvertSlashes(fileName), False) = ZIPAPI_END_OF_LIST_OF_FILE Then	# Couldn't find it

		# Reset
		If prevFile <> Null Then
			ZlibWapi_UnzLocateFile(zipHandle, prevFile\FileName, False)
			ZIPAPI_UnzFileInfo_Dispose(prevFile)
		EndIf

		Return ""

	EndIf

	Local fileInfo.ZIPAPI_UnzFileInfo = ZipApi_GetCurrentFileInfo(zipHandle)

	# Create a buffer to store unpacked contents in
	Local fileBuffer	= CreateBank(fileInfo\UnCompressedSize)

	# Open the file for reading, read all bytes and cleanup
	Local fileHandle

	# Check if we're using a password
	If password <> "" Then
		# Password protected
		fileHandle	= ZlibWapi_UnzOpenCurrentFilePassword(zipHandle, password$)
	Else
		fileHandle	= ZlibWapi_UnzOpenCurrentFile(zipHandle)
	EndIf

	If fileHandle <> ZIPAPI_OK Then
		Return ""
	EndIf

	# Read all bytes (depacks too)
	Local bytesRead	= ZlibWapi_UnzReadCurrentFile%(zipHandle, fileBuffer, BankSize(fileBuffer))

	If bytesRead = ZIPAPI_DATA_ERROR Then # Extraction error
		destName = ""
	EndIf

	# Cleanup
	ZlibWapi_UnzCloseCurrentFile(zipHandle)

	If bytesRead = fileInfo\UnCompressedSize Then
		# Save
		Local fileOut = WriteFile(destName)
		WriteBytes(fileBuffer, fileOut, 0, BankSize(fileBuffer))
		CloseFile(fileOut)
	EndIf

	# Reset
	If prevFile <> Null Then
		ZlibWapi_UnzLocateFile(zipHandle, prevFile\FileName, False)
		ZIPAPI_UnzFileInfo_Dispose(prevFile)
	EndIf

	# Cleanup
	FreeBank fileBuffer

	Return destName

End Function







Function ZipApi_ExtractFileAsBank%(zipHandle, fileName$, password$ = "")

	# Check inputs
	If zipHandle < 1 Then Return ZIPAPI_INVALIDPOINTER
	If fileName = "" Then Return ZIPAPI_END_OF_LIST_OF_FILE

	# Find file & get quick information
	Local prevFile.ZIPAPI_UnzFileInfo	= ZipApi_GetCurrentFileInfo(zipHandle)
	ZipApi_GotoFirstFile(zipHandle)

	# Find file
	If ZlibWapi_UnzLocateFile(zipHandle, File_ConvertSlashes(fileName), False) = ZIPAPI_END_OF_LIST_OF_FILE Then	# Couldn't find it

		# Reset
		If prevFile <> Null Then
			ZlibWapi_UnzLocateFile(zipHandle, prevFile\FileName, False)
			ZIPAPI_UnzFileInfo_Dispose(prevFile)
		EndIf

		Return ZIPAPI_END_OF_LIST_OF_FILE

	EndIf

	Local fileInfo.ZIPAPI_UnzFileInfo = ZipApi_GetCurrentFileInfoFast(zipHandle)

	# Create a buffer to store unpacked contents in
	Local fileBuffer	= CreateBank(fileInfo\UnCompressedSize)

	# Open the file for reading, read all bytes and cleanup
	Local fileHandle

	# Check if we're using a password
	If password <> "" Then
		# Password protected
		fileHandle	= ZlibWapi_UnzOpenCurrentFilePassword(zipHandle, password$)
	Else
		fileHandle	= ZlibWapi_UnzOpenCurrentFile(zipHandle)
	EndIf

	If fileHandle <> ZIPAPI_OK Then
		Return 0
	EndIf

	# Read all bytes (depacks too)
	Local bytesRead	= ZlibWapi_UnzReadCurrentFile%(zipHandle, fileBuffer, BankSize(fileBuffer))
	If bytesRead = ZIPAPI_DATA_ERROR Then
		FreeBank fileBuffer
		fileBuffer = 0
	EndIf

	# Reset
	If prevFile <> Null Then
		ZlibWapi_UnzLocateFile(zipHandle, prevFile\FileName, False)
		ZIPAPI_UnzFileInfo_Dispose(prevFile)
	EndIf

	# Cleanup
	ZlibWapi_UnzCloseCurrentFile(zipHandle)

	Return fileBuffer

End Function








func ZipApi_GetFileInfo(zipHandle: int, fileName: String, caseSensitive: int = False) -> ZIPAPI_UnzFileInfo:

	if zipHandle < 1:
		return null
	if fileName == "":
		return null

	var previousFile: ZIPAPI_UnzFileInfo = ZipApi_GetCurrentFileInfo(zipHandle)
	var fileInfo: ZIPAPI_UnzFileInfo = null

	if ZlibWapi_UnzLocateFile(zipHandle, fileName, caseSensitive) == ZIPAPI_END_OF_LIST_OF_FILE Then

		Return null
	EndIf


	fileInfo = ZipApi_GetCurrentFileInfo(zipHandle)


	ZlibWapi_UnzLocateFile(zipHandle, previousFile\FileName, False)


	ZIPAPI_UnzFileInfo_Dispose(previousFile)

	Return fileInfo

End Function





Function ZipApi_GotoFirstFile(zipHandle%)
	If zipHandle < 1:
		return ZIPAPI_INVALIDPOINTER
	Return ZlibWapi_UnzGoToFirstFile(zipHandle)
End Function





Function ZipApi_GotoNextFile(zipHandle)
	If zipHandle < 1 Then Return ZIPAPI_INVALIDPOINTER
	Return ZlibWapi_UnzGoToNextFile(zipHandle)
End Function

### <summary>Gets information about the current file pointed at in the zip.</summary>
### <param name="zipHandle">Handle to a ZIP resource opened with ZipApi_Open.</param>
### <returns>A ZIPAPI_UnzFileInfo object on success, or Null if there was an error.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZipApi_GetCurrentFileInfo.ZIPAPI_UnzFileInfo(zipHandle%)
	If zipHandle < 1 Then Return Null

	# Get default information
	Local fileInfo.ZIPAPI_UnzFileInfo	= ZipApi_GetCurrentFileInfoFast(zipHandle)

	# Now we want to get filename and other fields
	Local tBank				= CreateBank(ZIPAPI_UNZFILEINFO_LENGTH)
	Local fileNameBank		= CreateBank(fileInfo\FileNameLength + 1)
	Local extraFieldBank	= CreateBank(fileInfo\ExtraFieldLength + 1)
	Local commentBank		= CreateBank(fileInfo\CommentLength + 1)

	# Call method a second time - this is so we get the exact length of these fields
	ZlibWapi_UnzGetCurrentFileInfo(zipHandle, tBank, fileNameBank, fileInfo\FileNameLength, extraFieldBank, fileInfo\ExtraFieldLength, commentBank, fileInfo\CommentLength)

	# Peek our strings
	fileInfo\FileName	= PeekString(fileNameBank, 0)
	fileInfo\ExtraField	= PeekString(extraFieldBank, 0)
	fileInfo\Comment	= PeekString(commentBank, 0)

	# Cleanup & Return
	FreeBank tBank
	FreeBank fileNameBank
	FreeBank extraFieldBank
	FreeBank commentBank

	Return fileInfo

End Function

### <summary>Gets information about an open zip file, such as how many files it contains.</summary>
### <param name="zipHandle">Handle to a ZIP resource opened with ZipApi_Open.</param>
### <returns>ZIPAPI_GlobalInfo object containing file information, or Null if there was an error.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZipApi_GetGlobalInfo.ZIPAPI_GlobalInfo(zipHandle)

	If zipHandle < 1 Then Return Null

	Local zipInfo.ZIPAPI_GlobalInfo = Null

	# Create buffer bank and get global info
	Local infoBank = CreateBank(ZIPAPI_GLOBALINFO_LENGTH)

	If ZlibWapi_UnzGetGlobalInfo(zipHandle, infoBank) <> ZIPAPI_OK Then
		# TODO: Error message here
		Return Null
	EndIf

	zipInfo = ZIPAPI_GlobalInfo_FromBank(infoBank)

	# Now get the comment
	Local commentBank	= CreateBank(zipInfo\CommentLength + 1)

	If ZlibWapi_UnzGetGlobalComment(zipHandle, commentBank, zipInfo\CommentLength) <> ZIPAPI_OK Then
		# TODO: Error message here
		Return Null
	EndIf

	zipInfo\Comment		= PeekString(commentBank, 0)

	# Cleanup & Return
	FreeBank infoBank
	FreeBank commentBank

	Return zipInfo

End Function

### <summary>Gets the total uncompressed size of a Zip file.</summary>
### <param name="zipHandle">Zip file handle.</param>
### <returns>Integer containing the total uncompressed size in bytes, or an error code.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZipApi_GetUnpackedSize%(zipHandle%)

	# Check inputs
	If zipHandle < 1 Then Return ZIPAPI_INVALIDPOINTER

	Local totalSize	= 0

	# Iterate through files, getting their uncompressed size and adding it to the total
	ZipApi_GotoFirstFile(zipHandle)
	Repeat
		Local fileInfo.ZIPAPI_UnzFileInfo	= ZipApi_GetCurrentFileInfo(zipHandle)

		If fileInfo <> Null Then
			totalSize	= totalSize + fileInfo\UnCompressedSize
			ZIPAPI_UnzFileInfo_Dispose(fileInfo)
		EndIf

	Until ZipApi_GotoNextFile(zipHandle) = ZIPAPI_END_OF_LIST_OF_FILE

	Return totalSize

End Function

### <summary>Check that a file has the correct header.</summary>
### <param name="fileName">The name of the file to check.</param>
### <remarks>Use this to verify a zip file's validity.</remarks>
### <returns>True if the file is valid, or false if not.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZipApi_VerifyZipFileHeader(fileName$)

	If FileType(fileName) <> 1 Then Return False

	# Open the file and read the first four bytes
	Local fileIn	= ReadFile(fileName)
	Local header	= ReadInt(fileIn)
	CloseFile(fileIn)

	Return (header = ZIPAPI_HEADER_INT)

End Function

# --------------------------------------------------
# -- Creating & Writing To Zips
# --------------------------------------------------

### <summary>Create and open a new ZIP file for adding files to.</summary>
### <param name="fileName">The name of the zip file to create.</param>
### <param name="fileMode">The file mode to use. Can be ZIPAPI_APPEND_CREATE, ZIPAPI_APPEND_CREATEAFTER or ZIPAPI_APPEND_ADDINZIP.</param>
### <returns>Handle to opened file, or 0 if it could not be opened.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZipApi_CreateZip(fileName$, fileMode% = ZIPAPI_APPEND_CREATE)
	Return ZlibWapi_ZipOpen(fileName, fileMode)
End Function

### <summary>Add a file to a ZIP that has been opened with ZipApi_CreateZip.</summary>
### <param name="zipHandle">Handle to a ZIP resource opened with ZipApi_CreateZip.</param>
### <param name="fileName">The name of the file to add.</param>
### <param name="includePath">If the file is passed with a full path, setting this to false will exclude the path from the zip entry.</param>
### <returns>True if the file was added, false if not.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZipApi_AddFile%(zipHandle, fileName$, includePath% = True, password$ = "")

	# Check inputs
	If zipHandle < 1 Then Return False
	If fileName$ = "" Then Return False
	If FileType(fileName) <> 1 Then Return False

	# Read file data into memory
	Local fileData	= CreateBank(FileSize(fileName$))
	Local fileIn	= ReadFile(fileName)
	ReadBytes(fileData, fileIn, 0, BankSize(fileData))
	CloseFile fileIn

	# Generate the filename as it will appear in the Zip archive
	Local zipFileName$	= fileName
	If includePath = False Then 	# Strip path
		zipFileName = File_GetFileName(zipFileName)
	EndIf

	# Add file data to the zip (possible password protected)
	If password = "" Then
		ZipApi_ZipOpenFileInZip(zipHandle, zipFileName$, ZIPAPI_Date_FromFile(fileName))
	Else
		ZipApi_ZipOpenFileInZip(zipHandle, zipFileName$, ZIPAPI_Date_FromFile(fileName), "", 0, 0, True, ZIPAPI_DEFAULT_COMPRESSION, password, ZipApi_Crc32(fileData))
	EndIf

	# Write our data
	ZlibWapi_ZipWriteFileInZip%(zipHandle%, fileData, BankSize(fileData))

	# Cleanup & Close
	FreeBank fileData
	ZlibWapi_ZipCloseFileInZip(zipHandle)

	Return True

End Function

### <summary>Add a file to a ZIP directly from bank data.</summary>
### <param name="zipHandle">Handle to a ZIP resource opened with ZipApi_CreateZip.</param>
### <param name="bankHandle">Bank containing the data to add.</param>
### <param name="fileName">The name of the file entry in this zip.</param>
### <param name="password">Optional password to encrypt the data with.</param>
### <returns>True if the data was added, false if not.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZipApi_AddBankAsFile%(zipHandle, bankHandle%, fileName$, password$ = "")

	# Check inputs
	If zipHandle < 1 Then Return False
	If bankHandle < 1 Then Return False
	If fileName$ = "" Then Return False

	# Add file data to the zip
	If password = "" Then
		ZipApi_ZipOpenFileInZip(zipHandle, fileName$, ZIPAPI_Date_Create())
	Else
		# Password protected
		ZipApi_ZipOpenFileInZip(zipHandle, fileName$, ZIPAPI_Date_Create(), "", 0, 0, True, ZIPAPI_DEFAULT_COMPRESSION, password, ZipApi_Crc32(bankHandle))
	EndIf

	# Write our data
	Local fileResult = ZlibWapi_ZipWriteFileInZip%(zipHandle%, bankHandle, BankSize(bankHandle))

	# Cleanup & Close
	ZlibWapi_ZipCloseFileInZip(zipHandle)

	Return (fileResult = ZIPAPI_OK)

End Function

### <summary>Closes a ZIP resource that was opened with ZipApi_CreateZip.</summary>
### <param name="zipHandle">Handle to a ZIP resource opened with ZipApi_CreateZip.</param>
### <param name="globalComment">Optional global comment for this ZIP.</param>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZipApi_CloseZip(zipHandle%, globalComment$ = "")
	ZlibWapi_ZipClose(zipHandle, globalComment$)
End Function

# --------------------------------------------------
# -- Checksum Functions
# --------------------------------------------------

### <summary>Calculates the CRC32 value a bank.</summary>
### <param name="bankHandle">The bank to generate a CRC for.</param>
### <returns>The CRC checksum for this bank, or 0 if if couldn't be generated.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZipApi_Crc32%(bankHandle%)

	# Check bank handle
	If bankHandle < 1 Then Return 0

	# Initialise CRC with an empty bank
	Local tempBank	= CreateBank(0)
	Local crcValue	= ZlibWapi_Crc32(0, tempBank, 0)
	FreeBank tempBank

	# Calculate & return
	crcValue	=  ZlibWapi_Crc32(crcValue, bankHandle, BankSize(bankHandle))

	Return crcValue

End Function

### <summary>Calculates the Adler32 of a bank.</summary>
### <param name="bankHandle">The bank to generate an Adler32 for.</param>
### <returns>The Adler32 checksum for this bank, or 0 if if couldn't be generated.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZipApi_Adler32%(bankHandle%)

	# Check bank handle
	If bankHandle < 1 Then Return 0

	# Initialise CRC with an empty bank
	Local tempBank		= CreateBank(0)
	Local adlerValue	= ZlibWapi_Adler32(0, tempBank, 0)
	FreeBank tempBank

	# Calculate & return
	adlerValue	=  ZlibWapi_Adler32(adlerValue, bankHandle, BankSize(bankHandle))

	Return adlerValue

End Function

# --------------------------------------------------
# -- Internal Utility Functions
# --------------------------------------------------

### <summary>A slightly simpler interface to ZlibWapi_ZipOpenNewFileInZip. Still horrible though, and ZipApi_AddFile does the hard work for you.</summary>
### <param name="zipHandle">ZIP handle opened with ZipApi_Create.</param>
### <param name="fileName">The name of the file entry to open. Doesn't have to be a file that exists.</param>
### <param name="fileDate">The date information for this file.</param>
### <param name="comment">Optional comment for the file.</param>
### <param name="extraFieldLocal">Optional bank containing extra field information for the file.</param>
### <param name="extraFieldGlobal">Optional bank containing extra global field information.</param>
### <param name="compress">If true, file will be compressed. If false, it will be stored.</param>
### <param name="compressionLevel">The compression level to use.</param>
### <param name="password">An optional password for the file.</param>
### <param name="crc32">The CRC32 value of the data to compress. Only required if using a password.</para>
### <returns>True on success, false on failure.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZipApi_ZipOpenFileInZip%(zipHandle, fileName$, fileDate.ZIPAPI_Date, comment$ = "", extraFieldLocal% = 0, extraFieldGlobal% = 0, compress=True, compressionLevel% = ZIPAPI_DEFAULT_COMPRESSION, password$ = "", crc32 = 0)

	# Check inputs
	If zipHandle < 1 Then Return False

	# Set compression mode
	Local compressionMethod
	If compress Then compressionMethod = ZIPAPI_DEFLATED Else compressionMethod = 0

	# Create zipInfo bank
	Local zipInfo = CreateBank (36)
	ZipApi_Date_ToBank(fileDate, zipInfo, 0)

	Local localFieldBank%	= extraFieldLocal
	Local globalFieldBank%	= extraFieldGlobal

	# Create banks for extra fields (if appropriate)
	If localFieldBank	= 0 Then localFieldBank = CreateBank(0)
	If globalFieldBank	= 0 Then globalFieldBank = CreateBank(0)

	# Open zip file
	Local openFileResult
	If password = "" Then
		openFileResult = ZlibWapi_ZipOpenNewFileInZip(zipHandle, fileName, zipInfo, localFieldBank, BankSize(localFieldBank), globalFieldBank, BankSize(globalFieldBank), comment, compressionMethod, compressionLevel)
	Else
		# Password Protected
		openFileResult = ZlibWapi_ZipOpenNewFileInZip3(zipHandle, fileName, zipInfo, localFieldBank, BankSize(localFieldBank), globalFieldBank, BankSize(globalFieldBank), comment, compressionMethod, compressionLevel, 0, -ZIPAPI_MAX_WBITS, ZIPAPI_DEF_MEM_LEVEL, ZIPAPI_DEFAULT_STRATEGY, password, crc32)
	EndIf

	# Cleanup
	FreeBank(zipInfo)
	If extraFieldLocal	= 0 Then FreeBank(localFieldBank)
	If extraFieldGlobal	= 0 Then FreeBank(globalFieldBank)

	Return (openFileResult = ZIPAPI_OK)

End Function

### <summary>Gets information about the current file in an opened ZIP.</summary>
### <param name="zipHandle">ZIP handle opened with ZipApi_Open.</param>
### <returns>ZIPAPI_UnzFileInfo object, or null if it failed.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZipApi_GetCurrentFileInfoFast.ZIPAPI_UnzFileInfo(zipHandle%)
	If zipHandle < 1 Then Return Null

	Local fileInfo.ZIPAPI_UnzFileInfo	= Null

	# Create a bank for file information
	Local infoBank	= CreateBank(ZIPAPI_UNZFILEINFO_LENGTH)

	# A temporary bank, because it tends to crash if 0 is passed
	Local tBank		= CreateBank(0)

	# Get information
	ZlibWapi_UnzGetCurrentFileInfo(zipHandle, infoBank, tBank, 0, tBank, 0, tBank, 0)
	fileInfo = ZIPAPI_UnzFileInfo_FromBank(infoBank)

	# Check file info is valid
	If fileInfo = Null Then Return Null

	# Don't get anything else, just cleanup and done
	FreeBank tBank
	FreeBank infoBank

	Return fileInfo

End Function

# --------------------------------------------------
# -- Type : ZIPAPI_UnzFileInfo
# --------------------------------------------------

### <summary>Size of the ZIPAPI_UnzFileInfo type in bytes.</summary>
### <subsystem>Blitz.File.ZipApi</subsystem>
Const ZIPAPI_UNZFILEINFO_LENGTH% 	= 80

### <summary>Information about a file within a Zip archive.</summary>
### <subsystem>Blitz.File.ZipApi</subsystem>
Type ZIPAPI_UnzFileInfo

	Field Version%				### The Zip version this file was made by.
	Field VersionNeeded%		### Zip version needed to extract.
	Field Flag%					### General purpose bit flag.
	Field CompressionMethod%	### Compression method.
	Field DosDate%				### Last mod file data in Dos format.
	Field Crc32					### CRC-32 of the file.
	Field CompressedSize%		### Compressed size in bytes.
	Field UnCompressedSize%		### UnCompressed size in bytes.

	Field DiskNumberStart%		### Disk number start.
	Field InternalFileAttr%		### Internal file attributes.
	Field ExternalFileAttr%		### External file attributes.

	Field Date.ZIPAPI_Date		### Date modified.

	#== Blitz Specific Fields - saves you having to mess around with strings ==#
	Field FileName$				### File name
	Field ExtraField$			### Extra field
	Field Comment$				### Comment

	# == Internal
	Field FileNameLength%		### Length of the filename.
	Field ExtraFieldLength%		### Length of the extra field.
	Field CommentLength%		### Length of the file comment.

End Type

### <summary>Create a ZIPAPI_UnzFileInfo object and read data from the contents of a bank.</summary>
### <param name="bankIn">The bank to read from.</param>
### <returns>ZIPAPI_UnzFileInfo, or Null if it couldn't be read.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZIPAPI_UnzFileInfo_FromBank.ZIPAPI_UnzFileInfo(bankIn%)

	# Check inputs
	If bankIn < 1 Then Return Null
	If BankSize(bankIn) <> ZIPAPI_UNZFILEINFO_LENGTH Then Return Null

	Local this.ZIPAPI_UnzFileInfo = New ZIPAPI_UnzFileInfo

	this\Version			= PeekInt(bankIn, 0)
	this\VersionNeeded		= PeekInt(bankIn, 4)
	this\Flag				= PeekInt(bankIn, 8)
	this\CompressionMethod	= PeekInt(bankIn, 12)
	this\DosDate			= PeekInt(bankIn, 16)
	this\Crc32				= PeekInt(bankIn, 20)
	this\CompressedSize		= PeekInt(bankIn, 24)
	this\UnCompressedSize	= PeekInt(bankIn, 28)
	this\FileNameLength		= PeekInt(bankIn, 32)
	this\ExtraFieldLength	= PeekInt(bankIn, 36)
	this\CommentLength		= PeekInt(bankIn, 40)
	this\DiskNumberStart	= PeekInt(bankIn, 44)
	this\InternalFileAttr	= PeekInt(bankIn, 48)
	this\ExternalFileAttr	= PeekInt(bankIn, 52)

	# Grab the date - copy date information to a bank so we don't have to mess around with offsets
	Local dateBank			= CreateBank(ZIPAPI_DATE_LENGTH)
	CopyBank(bankIn, 56, dateBank, 0, ZIPAPI_DATE_LENGTH)
	this\Date				= ZipApi_Date_FromBank(dateBank)

	# Cleanup & return
	FreeBank dateBank

	Return this

End Function

### <summary>Free the memory used by a ZIPAPI_UnzFileInfo object.</summary>
### <param name="this">ZIPAPI_UnzFileInfo object to delete.</param>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZIPAPI_UnzFileInfo_Dispose(this.ZIPAPI_UnzFileInfo)
	ZIPAPI_Date_Dispose(this\Date)
	Delete this
End Function

# --------------------------------------------------
# -- Type : ZIPAPI_GlobalInfo
# --------------------------------------------------

### <summary>Size of the ZIPAPI_GlobalInfo type in bytes.</summary>
### <subsystem>Blitz.File.ZipApi</subsystem>
Const ZIPAPI_GLOBALINFO_LENGTH	= 8

### <summary>Information about a ZIP file.</summary>
### <subsystem>Blitz.File.ZLib</subsystem>
Type ZIPAPI_GlobalInfo
	Field NumberOfEntries%			### The number of files in this zip.
	Field CommentLength%			### The length of the comment string.

	# == Blitz Specific == #
	Field Comment$					### Global comment string.
End Type

### <summary>Create a ZIPAPI_GlobalInfo object and read data from the contents of a bank.</summary>
### <param name="bankIn">The bank to read from.</param>
### <returns>ZIPAPI_GlobalInfo, or Null if it couldn't be read.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZIPAPI_GlobalInfo_FromBank.ZIPAPI_GlobalInfo(bankIn%)
	Local this.ZIPAPI_GlobalInfo = New ZIPAPI_GlobalInfo

	this\NumberOfEntries	= PeekInt(bankIn, 0)
	this\CommentLength		= PeekInt(bankIn, 4)

	Return this
End Function

### <summary>Free the memory used by a ZIPAPI_GlobalInfo object and delete it.</summary>
### <param name="this">The ZIPAPI_GlobalInfo object to delete.</param>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZIPAPI_GlobalInfo_Dispose(this.ZIPAPI_GlobalInfo)
	Delete this
End Function

# --------------------------------------------------
# -- Type : ZIPAPI_Date
# --------------------------------------------------

### <summary>Size of the ZIPAPI_Date type in bytes.</summary>
### <subsystem>Blitz.File.ZipApi</subsystem>
Const ZIPAPI_DATE_LENGTH%		= 24

### <summary>The date information for a file in a ZIP archive.</summary>
### <subsystem>Blitz.File.ZipApi</subsystem>
Type ZIPAPI_Date
	Field Seconds%			### Seconds after the minute 	[0,59]
	Field Minutes%			### Minutes after the hour		[0,59]
	Field Hours%			### Hours since midnight		[0,23]
	Field Day%				### Day of the month			[1,31]
	Field Month%			### Months since January		[0,11]
	Field Year%				### Years						[1980, 2044]
End Type

### <summary>Create and return a new ZIPAPI_Date object, based on the current time and date.</summary>
### <returns>ZIPAPI_Date object for the current time and date.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZIPAPI_Date_Create.ZIPAPI_Date()

	Local this.ZIPAPI_Date	= New ZIPAPI_Date

	# Get the current date
	this\Day	= Int(Left(CurrentDate(), 2))
	this\Year	= Int(Right(CurrentDate(), 4) ) - 1980

	Select Upper(Mid(CurrentDate(), 4, 3))
		Case "JAN" : this\Month = 0
		Case "FEB" : this\Month = 1
		Case "MAR" : this\Month = 2
		Case "APR" : this\Month = 3
		Case "MAY" : this\Month = 4
		Case "JUN" : this\Month = 5
		Case "JUL" : this\Month = 6
		Case "AUG" : this\Month = 7
		Case "SEP" : this\Month = 8
		Case "OCT" : this\Month = 9
		Case "NOV" : this\Month = 10
		Case "DEC" : this\Month = 11
	End Select

	# Get the current time
	this\Seconds	= Int (Right(CurrentTime(), 2))
	this\Minutes	= Int (Mid(CurrentTime(), 4, 2))
	this\Hours		= Int (Left(CurrentTime(), 2))

	Return this

End Function

### <summary>Create and return a new ZIPAPI_Date object, based on the information for a file.</summary>
### <param name="fileName">The name of the file to get information about.</param>
### <remarks>NOT YET IMPLEMENTED - Returns current time and date.</remarks>
### <returns>ZIPAPI_Date object containing the file's creation date and time.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZIPAPI_Date_FromFile.ZIPAPI_Date(fileName$)
	# TODO: Make this work. Will probably need to access Windows dlls
	Return ZipApi_Date_Create()
End Function

### <summary>Creates a new ZipApi_Date object and reads its contents from a bank.</summary>
### <param name="bankIn">The bank to read information from.</param>
### <returns>The ZIPAPI_Date object, or null if it could not be read.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZIPAPI_Date_FromBank.ZIPAPI_Date(bankIn)

	# Check inputs
	If BankSize(bankIn) < ZIPAPI_DATE_LENGTH Then Return Null

	Local this.ZIPAPI_Date	= New ZIPAPI_Date

	this\Seconds	= PeekInt(bankIn, 0)
	this\Minutes	= PeekInt(bankIn, 4)
	this\Hours		= PeekInt(bankIn, 8)
	this\Day		= PeekInt(bankIn, 12)
	this\Month		= PeekInt(bankIn, 16)
	this\Year		= PeekInt(bankIn, 20)

	Return this

End Function

### <summary>Places the contents of a ZIPAPI_Date object into a bank.</summary>
### <param name="this">The ZIPAPI_Date object to poke.</param>
### <param name="bankOut">The handle of the bank to write the date to.</param>
### <param name="offset">Optional offset to start writing from.</param>
### <returns>True if the operation was successful, false if not.</returns>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZIPAPI_Date_ToBank(this.ZIPAPI_Date, bankOut, offset = 0)

	# Check inputs
	If this = Null Then Return False
	If bankOut < 1 Then Return False

	# Check bank can hold it
	If BankSize(bankOut) < offset + ZIPAPI_DATE_LENGTH Then Return False

	# Poke it!
	PokeInt bankOut, offset + 0 , this\Seconds
	PokeInt bankOut, offset + 4 , this\Minutes
	PokeInt bankOut, offset + 8 , this\Hours
	PokeInt bankOut, offset + 12, this\Day
	PokeInt bankOut, offset + 16, this\Month
	PokeInt bankOut, offset + 20, this\Year

	Return True

End Function

### <summary>Frees the memory used by a ZIPAPI_Date object and deletes it.</summary>
### <param name="this">The ZIPAPI_Date object to delete.</param>
### <subsystem>Blitz.File.ZipApi</subsystem>
Function ZIPAPI_Date_Dispose(this.ZIPAPI_Date)
	Delete this
End Function
#~IDEal Editor Parameters:
#~C: floatBlitz3D
