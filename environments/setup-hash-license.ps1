
$Secrets = ConvertFrom-Json $env:SECRETS_CONTEXT -AsHashtable 
echo DEVICE_DETECTION_KEY=$($Secrets.DEVICE_DETECTION_KEY) | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append