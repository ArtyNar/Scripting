#!/usr/bin/env pwsh
# Artem Koval
# Lab 8 - PowerShell
# CS 3030 - Scripting Languages

# Checking for right num of arguments
if ($args.length -ne 3)
{
    write-host ("Usage: ./filemaker.ps1 <commandfile> <outputfile> <recordcount>")
    exit 1
}

# Checking for a correct input of records
try 
{
    $recordCount = [int]$args[2]
    Write-Output $recordCount
}
catch 
{
    Write-Host "Error1"
    exit 1;
}

# Opening an input file and passing it into an array
try
{
    $inputCommands = Get-Content -path $args[0] -erroraction stop
}
catch 
{
    #write-host ("Error opening or reading command file: $($_)")

    Write-Host "Error2"
    exit 1
}

# Opening an output file
try
{
    $outputFile = $args[1]
    New-Item -path $outputFile -erroraction stop | out-null
}
catch 
{
    #write-host ("Error opening output file: $($_)") 
    Write-Host "Error3"
    exit 1
}

# A function that will output stuff for us
function writeToFile ($outputFile, $outputString) 
{ 
    $outputString = $outputString -replace [regex]::escape("\t"), "`t"
    $outputString = $outputString -replace [regex]::escape("\n"), "`n"
    try 
    {
        add-content -path $outputFile -value $outputString -nonewline 
    }
    catch 
    {
        #write-host "Write failed to file $($outputFile): $_"
        Write-Host "Error4"
        exit 1
    }
}

# Initializing needed dictionaries
$randomFiles = @{}
$randomData = @{}
$header = 0

foreach ($command in $inputCommands)
{
    #Write-Output $command
    if ($command -match '^HEADER\s+"(.*)"$' -and $header -ne 1) { 

        writeToFile $outputFile $matches.1
        
        $header = 1
    }

    if ($command -match '^WORD\s+(.*)\s+"(.*)"$') 
    { 
        $WORDFilename = $matches.2
        try 
        {
            $randomFiles[$WORDFilename] = Get-Content -path $WORDFilename -erroraction stop
        }
        catch 
        {
            Write-Host "Error5"
            exit 1
        }
    }
}

function processData ($rows)
{
    for ($i = 0; $i -lt $rows; $i++)
    {
        foreach ($command in $inputCommands)
        {
            if ($command -match '^STRING\s+"(.*)"$' -or $command -match "^STRING\s+'(.*)'$" ) 
            { 
                $stringValue = $matches.1
                writeToFile $outputFile $stringValue
            }

            if ($command -match '^WORD\s+(.*)\s+"(.*)"$') 
            { 
                $WORDFilename = $matches.2
                $WORDLabel = $matches.1
                $randomWord = Get-Random -inputobject $randomFiles[$WORDFilename]
                $randomData[$WORDLabel] = $randomWord
                writeToFile $outputFile $randomWord
            }

            if ($command -match '^INTEGER\s+(\w+)\s+(\d+)\s+(\d+)$') 
            { 
                $integerMin = $($matches.2).toInt32($null) 
                $integerMax = $($matches.3).toInt32($null) 

                $randomInteger = Get-Random -min $integerMin -max $integerMax
                $integerLabel = $matches.1

                writeToFile $outputFile $randomInteger
                $randomData[$integerLabel] = $randomInteger
            }

            if ($command -match '^REFER\s+(\w+)$' ) { 
                $referLabel = $matches.1
                writeToFile $outputFile $randomData[$referLabel]
            }
        }
    }
}

processData($recordCount)