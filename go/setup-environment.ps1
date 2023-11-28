Write-Output "Installing go-junit-report..."
go install github.com/jstemmer/go-junit-report/v2@latest || $(throw "go-junit-report installation failed")
go-junit-report -version || $(throw "go-junit-report not available")
