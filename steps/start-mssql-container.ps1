param(
    [Parameter(Mandatory = $true)]
    [string]$Password
)

docker run -d --name sqlcontainer --hostname sqlcontainer `
    -p 1433:1433 `
    -e "ACCEPT_EULA=Y" `
    -e "MSSQL_SA_PASSWORD=$Password" `
    -e "MSSQL_PID=Developer" `
    -e "MSSQL_AGENT_ENABLED=true" `
    mcr.microsoft.com/mssql/server:2022-latest

docker ps --filter name=sqlcontainer
