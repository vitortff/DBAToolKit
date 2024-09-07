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
$ExportToCsvPath = "$PSScriptRoot\DBTOOLS7.csv"
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
'NOVAJUS_FULL_8178519',
'NOVAJUS_FULL_8158140',
'NOVAJUS_FULL_8180006',
'NOVAJUS_FULL_8161319',
'NOVAJUS_FULL_8180634',
'NOVAJUS_FULL_8177026',
'NOVAJUS_FULL_8205339',
'NOVAJUS_FULL_8184928',
'InfolexOne_AR_8162388',
'NOVAJUS_FULL_8174918',
'NOVAJUS_FULL_8179073',
'NOVAJUS_FULL_8177181',
'NOVAJUS_FULL_8179601',
'NOVAJUS_FULL_8178972',
'NOVAJUS_FULL_8174508',
'NOVAJUS_FULL_8179442',
'NOVAJUS_FULL_8161864',
'NOVAJUS_FULL_8175692',
'NOVAJUS_FULL_8179342',
'NOVAJUS_FULL_8174807',
'NOVAJUS_FULL_8174487',
'NOVAJUS_FULL_8177861',
'NOVAJUS_FULL_8174826',
'NOVAJUS_FULL_8178313',
'NOVAJUS_FULL_8177413',
'NOVAJUS_FULL_8175721',
'NOVAJUS_FULL_8175514',
'NOVAJUS_FULL_8183644',
'NOVAJUS_FULL_8158629',
'NOVAJUS_FULL_8183092',
'NOVAJUS_FULL_8184644',
'NOVAJUS_FULL_8176877',
'NOVAJUS_FULL_8174820',
'InfolexOne_AR_8159811',
'NOVAJUS_FULL_8178947',
'NOVAJUS_FULL_8180191',
'NOVAJUS_FULL_8177739',
'NOVAJUS_FULL_8179960',
'NOVAJUS_FULL_8178472',
'InfolexOne_AR_8160063',
'NOVAJUS_FULL_8175505',
'NOVAJUS_FULL_8180467',
'NOVAJUS_FULL_8183607',
'NOVAJUS_FULL_8186830',
'NOVAJUS_FULL_8175694',
'NOVAJUS_FULL_8180319',
'NOVAJUS_FULL_8183534',
'NOVAJUS_FULL_8201545',
'NOVAJUS_FULL_8205341',
'NOVAJUS_FULL_8176530',
'NOVAJUS_FULL_8174338',
'NOVAJUS_FULL_8201862',
'NOVAJUS_FULL_8185559',
'NOVAJUS_FULL_8177620',
'NOVAJUS_FULL_8182189',
'NOVAJUS_FULL_8205234',
'NOVAJUS_FULL_8181300',
'InfolexOne_AR_8160944',
'InfolexOne_AR_8161618',
'InfolexOne_AR_8159824',
'InfolexOne_AR_8161499',
'NOVAJUS_FULL_8196517',
'NOVAJUS_FULL_8203389',
'NOVAJUS_FULL_8196143',
'NOVAJUS_FULL_8205404',
'InfolexOne_AR_8159744',
'NOVAJUS_FULL_8205644',
'InfolexOne_AR_8161227',
'InfolexOne_AR_8161533',
'NOVAJUS_FULL_8205179',
'InfolexOne_AR_8159387',
'NOVAJUS_FULL_8203295',
'NOVAJUS_FULL_8196174',
'InfolexOne_AR_8159708',
'InfolexOne_AR_8162459',
'NOVAJUS_FULL_8205391',
'NOVAJUS_FULL_8204802',
'NOVAJUS_FULL_8205363',
'NOVAJUS_FULL_8196252',
'InfolexOne_AR_8158618',
'NOVAJUS_FULL_8205400',
'InfolexOne_AR_8160503',
'NOVAJUS_FULL_8205202',
'NOVAJUS_FULL_8205765',
'NOVAJUS_FULL_8203234',
'NOVAJUS_FULL_8203913',
'NOVAJUS_FULL_8204149',
'NOVAJUS_FULL_8204331',
'NOVAJUS_FULL_8205471',
'InfolexOne_AR_8159129',
'NOVAJUS_FULL_8205171',
'NOVAJUS_FULL_8205483',
'NOVAJUS_FULL_8205159',
'NOVAJUS_FULL_8205224',
'NOVAJUS_FULL_8205477',
'NOVAJUS_FULL_8204985',
'NOVAJUS_FULL_8205370',
'NOVAJUS_FULL_8205762',
'NOVAJUS_FULL_8203219',
'NOVAJUS_FULL_8196314',
'NOVAJUS_FULL_8203275',
'NOVAJUS_FULL_8205429',
'InfolexOne_AR_8161606',
'NOVAJUS_FULL_8205168',
'InfolexOne_AR_8158972',
'NOVAJUS_FULL_8205163',
'NOVAJUS_FULL_8205185',
'NOVAJUS_FULL_8196432',
'NOVAJUS_FULL_8205365',
'InfolexOne_AR_8161478',
'NOVAJUS_FULL_8203541',
'InfolexOne_AR_8163766',
'NOVAJUS_FULL_8205486',
'NOVAJUS_FULL_8203281',
'NOVAJUS_FULL_8203356',
'NOVAJUS_FULL_8204315',
'NOVAJUS_FULL_8205249',
'NOVAJUS_FULL_8205347',
'NOVAJUS_FULL_8204632',
'NOVAJUS_FULL_8205017',
'NOVAJUS_FULL_8204487',
'NOVAJUS_FULL_8196538',
'NOVAJUS_FULL_8205074',
'NOVAJUS_FULL_8205177',
'NOVAJUS_FULL_8205069',
'NOVAJUS_FULL_8205511',
'NOVAJUS_FULL_8196548',
'NOVAJUS_FULL_8205138',
'NOVAJUS_FULL_8203443',
'InfolexOne_AR_8163434',
'InfolexOne_AR_8159383',
'NOVAJUS_FULL_8203497',
'NOVAJUS_FULL_8203216',
'NOVAJUS_FULL_8205480',
'NOVAJUS_FULL_8203387',
'NOVAJUS_FULL_8205807',
'NOVAJUS_FULL_8203812',
'InfolexOne_AR_8159246',
'NOVAJUS_FULL_8183704',
'NOVAJUS_FULL_8203278',
'NOVAJUS_FULL_8203612',
'NOVAJUS_FULL_8204513',
'NOVAJUS_FULL_8204496',
'InfolexOne_AR_8163625',
'NOVAJUS_FULL_8204299',
'InfolexOne_AR_8159241',
'InfolexOne_AR_8160843',
'NOVAJUS_FULL_8203508',
'NOVAJUS_FULL_8203814',
'NOVAJUS_FULL_8204046',
'NOVAJUS_FULL_8204324',
'InfolexOne_AR_8158610',
'InfolexOne_AR_8159712',
'InfolexOne_AR_8160570',
'InfolexOne_AR_8161483',
'InfolexOne_AR_8162059',
'NOVAJUS_FULL_8196554',
'NOVAJUS_FULL_8196563',
'NOVAJUS_FULL_8203394',
'NOVAJUS_FULL_8203575',
'NOVAJUS_FULL_8203875',
'NOVAJUS_FULL_8204417'
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
