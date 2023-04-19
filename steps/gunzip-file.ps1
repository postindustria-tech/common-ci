
Param(
    $Source,
    $Destination = ($Source -replace '\.gz$','')
    )

$FileLength = $(Get-Item $Source).Length
try {
    $In = New-Object System.IO.FileStream $Source, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
    $Out = New-Object System.IO.FileStream $Destination, ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
    $GzipStream = New-Object System.IO.Compression.GzipStream $In, ([IO.Compression.CompressionMode]::Decompress)

    $Buffer = New-Object byte[](1024)
    $Progress = 0
    while ($True) {
        $Read = $Gzipstream.Read($Buffer, 0, 1024)
        if ($Read -le 0) { break }
        $Out.Write($Buffer, 0, $Read)
        if ($Progress -lt $($GzipStream.BaseStream.Position / $FileLength)) {
            $Progress = $GzipStream.BaseStream.Position / $FileLength
            Write-Progress -Activity "Extracting" -PercentComplete $($Progress * 100)
        }
    }
}
finally {
    $GzipStream.Close()
    $Out.Close()
    $In.Close()
}