cls
###########################################################################
# #AppNome# #DBNomeBase# #distro# #DBNomeServidor# will be replace in the SQL query
# Example: select TOP 1 '#AppNome#' as 'AppNome', '#DBNomeBase#' as 'DBNomeBase', '#distro#' as 'Distro', IsToConnectWithOnePass from GEN_Config order by id desc

$Query = "
--1 Compression
ALTER TABLE GEN_REVISAO REBUILD WITH (xml_compression = on)

--2 Shrinking
DECLARE @DATABASE_NAME VARCHAR(50) = (SELECT DB_NAME())
SELECT @DATABASE_NAME
DBCC SHRINKDATABASE(@DATABASE_NAME)
"

$ExportToCsv = $True
$ExportToCsvPath = "$PSScriptRoot\DBTOOLS.csv"
$ExportToCsvDelimiter = ','

$DistrosToRun = @{
    "firmbr" = $True
    "corpbr" = $True
    "firmar" = $True
    "corpar" = $False
    "corpes" = $False
} 

###########################################################################

$SQLAccount = "SELECT AppNome, DBNomeBase, DBNomeServidor FROM NVJ_Escritorio WHERE DBNomeBase in
(
) 
"

Remove-Item $ExportToCsvPath

class Customer{
    [string]$AppNome
    [string]$DBNomeBase
    
    [System.Collections.ArrayList]$Lista

    Customer(){
        $this.Lista = [System.Collections.ArrayList]::new()
    }
}

function PrepareQuery($Query, $tokenList) {
    $PreparedQuery = $Query
    foreach( $token in $tokenList.GetEnumerator() )
    {
        $pattern = '#{0}#' -f $token.key
        $PreparedQuery = $PreparedQuery -replace $pattern, $token.Value
    }
    return $PreparedQuery
}

workflow Invoke-SqlcmdParallel
{
    param
    (
        $paramsOffices,
        $ExportToCsv,
        $ExportToCsvPath,
        $ExportToCsvDelimiter
    )
    
    foreach -parallel ($paramsOffice in $paramsOffices)
    {
        $result = Invoke-Sqlcmd @paramsOffice

        if ($ExportToCsv) {
            $result | Export-Csv -Path $ExportToCsvPath -NoTypeInformation -Append -Delimiter $ExportToCsvDelimiter
        }
    }
}
#############################################################

if ($ExportToCsv) {
    if (Test-Path $ExportToCsvPath) {
        Remove-Item $ExportToCsvPath
    }
}

$ListaClientes = [System.Collections.ArrayList]::new()

$dbsparams = @{
    "firmbr"=@{
        'Database'       = "account_firm_br"
        'ServerInstance' = "firmbr-prod.database.windows.net"
        'Username'       = "cloud"
        'Password'       = "Y6t5r4e3w2q1@"
        'ApplicationName'= "runSQLAllDatabases"
        'Query'          = $SQLAccount
    };
    "corpbr"=@{
        'Database'       = "account_corp_br"
        'ServerInstance' = "legalone-prod-eastus2.database.windows.net"
        'Username'       = "cloud"
        'Password'       = "Y6t5r4e3w2q1@"
        'ApplicationName'= "runSQLAllDatabases"
        'Query'          = $SQLAccount
    };
    "firmar"=@{
        'Database'       = "account_firm_ar"
        'ServerInstance' = "legalone-prod-eastus2.database.windows.net"
        'Username'       = "cloud"
        'Password'       = "Y6t5r4e3w2q1@"
        'ApplicationName'= "runSQLAllDatabases"
        'Query'          = $SQLAccount
    };
    "corpar"=@{
        'Database'       = "l1-corp-ar-account"
        'ServerInstance' = "legalone-prod-eastus2.database.windows.net"
        'Username'       = "cloud"
        'Password'       = "Y6t5r4e3w2q1@"
        'ApplicationName'= "runSQLAllDatabases"
        'Query'          = $SQLAccount
    };
    "corpes"=@{
        'Database'       = "l1-corp-es-account"
        'ServerInstance' = "legalone-prod-uksouth.database.windows.net"
        'Username'       = "cloud"
        'Password'       = "Y6t5r4e3w2q1@"
        'ApplicationName'= "runSQLAllDatabases"
        'Query'          = $SQLAccount
    };
}


foreach($distroAccount in $dbsparams.Keys) {
    if (!($DistrosToRun."$distroAccount")) {
        continue
    }

    $params = $dbsparams."$distroAccount"
    $Customers = Invoke-Sqlcmd @params

    foreach($Customer in $Customers) {
        $Customer.DBNomeBase
        $querytorun = PrepareQuery -Query $Query -tokenList @{
            AppNome = $Customer.AppNome
            DBNomeBase = $Customer.DBNomeBase
            DBNomeServidor = $Customer.DBNomeServidor
            distro = $distroAccount
        }

        $paramsOffice = @{
            'Database'       = $Customer.DBNomeBase
            'ServerInstance' = $Customer.DBNomeServidor
            'Username'       = "cloud"
            'Password'       = "Y6t5r4e3w2q1@"
            'ApplicationName'= "runSQLAllDatabases"
            'Query'          = $querytorun
        }
        $result = Invoke-Sqlcmd @paramsOffice

        if ($ExportToCsv) {
            $result | Export-Csv -Path $ExportToCsvPath -NoTypeInformation -Append  -Delimiter $ExportToCsvDelimiter
        }

    }
    
}

"finished"
