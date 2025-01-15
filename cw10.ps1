$downloadUrl = "http://home.agh.edu.pl/~wsarlej/dyd/bdp2/materialy/cw10/InternetSales_new.zip"
$password = "bdp2agh"
$outputDir = "./OUTPUT"
$processedDir = "./PROCESSED"
$logFile = "./$processedDir/cw10_$(Get-Date -Format "yyyyMMddHHmmss").log"
$dbName = "AdventureWorksDW2019"
$tableName = "CUSTOMERS_407454"
$csvFileName = "InternetSales.csv"
$filename = "InternetSales_new.txt"
$sqlServer = "LAPTOP-HLGFF2FQ\MSSQLSERVER2"

# Utwórz katalogi wyjściowe
New-Item -ItemType Directory -Force -Path $outputDir, $processedDir

# Funkcja logowania
function Log-Step {
    param (
        [string]$stepDescription,
        [bool]$success
    )
    $timestamp = (Get-Date -Format "yyyyMMddHHmmss")
    $status = if ($success) { "Successful" } else { "Failed" }
    $logMessage = "$timestamp - $stepDescription - $status"
    Write-Output $logMessage | Out-File -Append -FilePath $logFile
}

# Krok a: Pobierz plik8
try {
    $downloadedFile = "$outputDir\downloaded.zip"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadedFile
    Log-Step "Downloading File" $true
} catch {
    Log-Step "Downloading File" $false
    throw
}

# Krok b: Rozpakuj plik
try {
    Expand-7Zip -ArchiveFileName $downloadedFile -TargetPath $outputDir -Password $password
    Log-Step "Unzipping File" $true
} catch {
    Log-Step "Unzipping File" $false
    throw
}

# Krok c: Walidacja pliku
$InputFile = "$outputDir\$filename"
$ValidFile = "C:\Users\HP\AppData\InternetSales_validated.csv"
$BadFile = "$outputDir\InternetSales_new.bad_$(Get-Date -Format "yyyyMMddHHmmss")"


Log-Step -Message "Validating and processing file $InputFile" -Status "Started"
try {
    $Header = Get-Content $InputFile -TotalCount 1
    $ExpectedColumns = $Header -split '\|'
    
    # Kolekcja do przechowywania unikalnych wierszy
    $SeenLines = @()
    # Funkcja do sprawdzania wartości liczbowych
function Is-Numeric {
    param ([string]$Value)
    return $Value -match "^\d+(\.\d+)?$"
}

    Get-Content $InputFile |
        Where-Object { $_ -and $_ -ne $Header } |
        ForEach-Object {
            $Columns = $_ -split '\|'
            
            # Sprawdzamy, czy $Columns[6] nie jest pusty
            if (-not [string]::IsNullOrEmpty($Columns[6])) {
                # Jeśli już widzieliśmy ten wiersz, pomijamy go
                if ($SeenLines -contains $_) {
                    return  # Kontynuuje następną iterację pętli
                }

                # Zapisujemy do $BadFile, jeśli wiersz nie jest pusty
                $_ | Out-File -Append -FilePath $BadFile
                $SeenLines += $_  # Dodajemy wiersz do kolekcji unikalnych wierszy
                return
            }

            # Jeśli wiersz spełnia inne warunki i jest unikalny
            if ($Columns.Count -eq $ExpectedColumns.Count -and
                [int]$Columns[4] -le 100 -and
                (Is-Numeric $Columns[0]) -and
                (Is-Numeric $Columns[3]) -and
                (Is-Numeric $Columns[4]) -and
                (Is-Numeric $Columns[5].Replace(",", "."))) {

                $CustomerName = $Columns[2] -replace '"', ''
                if ($CustomerName -match '^(?<LastName>[^,]+),(?<FirstName>.+)$') {
                    $Columns[2] = $Matches['FirstName'] + '|' + $Matches['LastName']
                    $Columns[5] = $Columns[5] -replace ',', '.'
                    $NewLine = $Columns -join '|'

                    # Jeśli wiersz nie był jeszcze widziany, dodajemy do wyników
                    if ($SeenLines -notcontains $NewLine) {
                        $SeenLines += $NewLine
                        $NewLine
                    }
                }
            } else {
                # Zapisujemy do $BadFile w przypadku innych błędów
                $_ | Out-File -Append -FilePath $BadFile
            }
        } | Set-Content -Path $ValidFile -Encoding UTF8

    Log-Step -Message "Validating and processing file $InputFile" -Status "Successful"
} catch {
    Log-Step -Message "Validating and processing file $InputFile" -Status "Failed"
    throw $_
}

# Krok d: Tworzenie tabeli w bazie danych
try {
    $createTableQuery = "
DROP TABLE IF EXISTS $tableName;
CREATE TABLE $tableName (
    ProductKey VARCHAR(100),
    CurrencyAlternateKey VARCHAR(100),
    FIRST_NAME VARCHAR(100),
    LAST_NAME VARCHAR(100),
    OrderDateKey VARCHAR(100),
    OrderQuantity INT,
    UnitPrice VARCHAR(100),
    SecretCode VARCHAR(255)
);"
    Invoke-Sqlcmd -ServerInstance $sqlServer -Query $createTableQuery -Database $dbName
    Log-Step "Creating Table" $true
} catch {
    Log-Step "Creating Table" $false
    throw
}

# Krok e: Załaduj dane do tabeli
try {
    $bulkInsertQuery = "BULK INSERT $tableName FROM '$ValidFile' WITH (FIELDTERMINATOR='|', ROWTERMINATOR='\n');"
    Invoke-Sqlcmd -ServerInstance $sqlServer -Query $bulkInsertQuery -Database $dbName
    Log-Step "Loading Data to Table" $true
} catch {
    Log-Step "Loading Data to Table" $false
    throw
}

# Krok g: Aktualizacja SecretCode w tabeli
try {
    $updateQuery = "UPDATE $tableName SET SecretCode = LEFT(REPLACE(NEWID(), '-', ''), 10);"
    Invoke-Sqlcmd -ServerInstance $sqlServer -Query $updateQuery -Database $dbName
    Log-Step "Updating SecretCode" $true
} catch {
    Log-Step "Updating SecretCode" $false
    throw
}

# Krok h: Eksportuj tabelę do pliku CSV
try {
    $exportFile = "$outputDir\$tableName.csv"
    $exportQuery = "SELECT * FROM $tableName;"
    Invoke-Sqlcmd -ServerInstance $sqlServer -Query $exportQuery -Database $dbName | Export-Csv -Path $exportFile -NoTypeInformation
    Log-Step "Exporting Table to CSV" $true
} catch {
    Log-Step "Exporting Table to CSV" $false
    throw
}
try {
    (Get-Content $exportFile) | ForEach-Object { $_ -replace '"', '' } | Set-Content $exportFile
    Log-Step "Deleting quotations" $true
} catch {
    Log-Step "Deleting quotations" $false
    throw
}

try {
    $timestampedFileName = "$(Get-Date -Format "yyyyMMddHHmmss")_$csvFileName"
    Move-Item -Path $exportFile -Destination "$processedDir\$timestampedFileName"
    Log-Step "Moving Processed File" $true
} catch {
    Log-Step "Moving Processed File" $false
    throw
}

# Krok i: Kompresja pliku CSV
try {
    Compress-Archive -Path "$processedDir\$timestampedFileName" -DestinationPath "$processedDir\$timestampedFileName.zip"
    Log-Step "Compressing CSV File" $true
} catch {
    Log-Step "Compressing CSV File" $false
    throw
}
