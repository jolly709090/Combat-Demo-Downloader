Function ConvertFrom-Gzip
{
<#
.SYNOPSIS
This function will decompress the contents of a GZip file and output it to the pipeline.  Each line in the converted file is
output as distinct object.

.DESCRIPTION
Using the System.IO.GZipstream class this function will decompress a GZip file and send the contents into
the pipeline.  The output is one System.String object per line.  It supports the various types of encoding
provided by the System.text.encoding class.

.EXAMPLE
ConvertFrom-Gzip -path c:\test.gz

test content

.EXAMPLE
get-childitem c:\archive -recure -filter *.gz | convertfrom-Gzip -encoding unicode | select-string -pattern "Routing failed" -simplematch

Looks through the c:\archive folder for all .gz files, those files are then converted to system.string
objects, all that data is piped to select-string.  Strings which match the pattern "Routing failed" are returned to the console.

.EXAMPLE
get-item c:\file.txt.gz | convertfrom-Gzip | out-string | out-file c:\file.txt

Converts c:\file.txt.gz to a string array and then into a single string object.  That string object is then written into a new file.

.NOTES
Written by Jason Morgan
Created on 1/10/2013
Last Modified 7/11/2014
# added support for relative paths

#>
[CmdletBinding()]
Param
    (
        # Enter the path to the target GZip file, *.gz
        [Parameter(
        Mandatory = $true,
        ValueFromPipeline=$True,
        ValueFromPipelineByPropertyName=$True,
        HelpMessage="Enter the path to the target GZip file, *.gz",
        ParameterSetName='Default')]
        [Alias("Fullname")]
        [ValidateScript({$_.endswith(".gz")})]
        [String]$Path,
        # Specify the type of encoding of the original file, acceptable formats are, "ASCII","Unicode","BigEndianUnicode","Default","UTF32","UTF7","UTF8"
        [Parameter(Mandatory=$false,
        ParameterSetName='Default')]
        [ValidateSet("ASCII","Unicode","BigEndianUnicode","Default","UTF32","UTF7","UTF8")]
        [String]$Encoding = "ASCII"
    )
Begin
    {
        Set-StrictMode -Version Latest
        Write-Verbose "Create Encoding object"
        $enc= [System.Text.Encoding]::$encoding
    }
Process
    {
        Write-Debug "Beginning process for file at path: $Path"
        Write-Verbose "test path"
        if (-not ([system.io.path]::IsPathRooted($path)))
          {
            Write-Verbose 'Generating absolute path'
            Try {$path = (Resolve-Path -Path $Path -ErrorAction Stop).Path} catch {throw 'Failed to resolve path'}
            Write-Debug "New Path: $Path"
          }
        Write-Verbose "Opening file stream for $path"
        $file = New-Object System.IO.FileStream $path, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
        Write-Verbose "Create MemoryStream Object, the MemoryStream will hold the decompressed data until it is loaded into `$array"
        $stream = new-object -TypeName System.IO.MemoryStream
        Write-Verbose "Construct a new [System.IO.GZipStream] object, created in Decompress mode"
        $GZipStream = New-object -TypeName System.IO.Compression.GZipStream -ArgumentList $file, ([System.IO.Compression.CompressionMode]::Decompress)
        Write-Verbose "Open a Buffer that will be used to move the decompressed data from `$GZipStream to `$stream"
        $buffer = New-Object byte[](1024)
        Write-Verbose "Instantiate `$count outside of the Do/While loop"
        $count = 0
        Write-Verbose "Start Do/While loop, this loop will perform the job of reading decopressed data from the gzipstream object into the MemoryStream object.  The Do/While loop continues until `$GZipStream has been emptied of all data, which is when `$count = 0"
        do
            {
                $count = $gzipstream.Read($buffer, 0, 1024)
                if ($count -gt 0)
                    {
                        $Stream.Write($buffer, 0, $count)
                    }
            }
        While ($count -gt 0)
        Write-Verbose "Take the data from the MemoryStream and convert it to a Byte Array"
        $array = $stream.ToArray()
        Write-Verbose "Close the GZipStream object instead of waiting for a garbage collector to perform this function"
        $GZipStream.Close()
        Write-Verbose "Close the MemoryStream object instead of waiting for a garbage collector to perform this function"
        $stream.Close()
        Write-Verbose "Close the FileStream object instead of waiting for a garbage collector to perform this function"
        $file.Close()
        Write-Verbose "Create string(s) from byte array, a split is added after the conversion to ensure each new line character creates a new string"
        $enc.GetString($array).Split("`n")
    }
End {}
}
