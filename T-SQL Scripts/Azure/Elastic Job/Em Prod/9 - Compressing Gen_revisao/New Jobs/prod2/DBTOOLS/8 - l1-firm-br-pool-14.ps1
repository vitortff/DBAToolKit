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
$ExportToCsvPath = "$PSScriptRoot\DBTOOLS8.csv"
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
'NOVAJUS_FULL_8169814',
'NOVAJUS_FULL_8171310',
'NOVAJUS_FULL_8173066',
'NOVAJUS_FULL_8171516',
'NOVAJUS_FULL_8168315',
'NOVAJUS_FULL_8183157',
'NOVAJUS_FULL_8172130',
'NOVAJUS_FULL_8171958',
'NOVAJUS_FULL_8170884',
'NOVAJUS_FULL_8170908',
'NOVAJUS_FULL_8170935',
'NOVAJUS_FULL_8173717',
'NOVAJUS_FULL_8170132',
'NOVAJUS_FULL_8169819',
'NOVAJUS_FULL_8173275',
'NOVAJUS_FULL_8170178',
'NOVAJUS_FULL_8172694',
'NOVAJUS_FULL_8174192',
'NOVAJUS_FULL_8172863',
'NOVAJUS_FULL_8172886',
'NOVAJUS_FULL_8168234',
'NOVAJUS_FULL_8171104',
'NOVAJUS_FULL_8171667',
'NOVAJUS_FULL_8173042',
'l1_firm_br_8085777',
'NOVAJUS_FULL_8171099',
'NOVAJUS_FULL_8169400',
'NOVAJUS_FULL_8169809',
'NOVAJUS_FULL_8169848',
'NOVAJUS_FULL_8169765',
'NOVAJUS_FULL_8169249',
'NOVAJUS_FULL_8170851',
'NOVAJUS_FULL_8186627',
'NOVAJUS_FULL_8169452',
'NOVAJUS_FULL_8172249',
'NOVAJUS_FULL_8171084',
'NOVAJUS_FULL_8186590',
'NOVAJUS_FULL_8169283',
'NOVAJUS_FULL_8169776',
'NOVAJUS_FULL_8186644',
'NOVAJUS_FULL_8170124',
'NOVAJUS_FULL_8171846',
'NOVAJUS_FULL_8169909',
'NOVAJUS_FULL_8168604',
'NOVAJUS_FULL_8169881',
'NOVAJUS_FULL_8170180',
'NOVAJUS_FULL_8172901',
'NOVAJUS_FULL_8171166',
'NOVAJUS_FULL_8173539',
'NOVAJUS_FULL_8173641',
'NOVAJUS_FULL_8170367',
'NOVAJUS_FULL_8172273',
'NOVAJUS_FULL_8171572',
'NOVAJUS_FULL_8171040',
'NOVAJUS_FULL_8169247',
'NOVAJUS_FULL_8170476',
'NOVAJUS_FULL_8168547',
'NOVAJUS_FULL_8172618',
'NOVAJUS_FULL_8171712',
'NOVAJUS_FULL_8169228',
'NOVAJUS_FULL_8172347',
'NOVAJUS_FULL_8173868',
'NOVAJUS_FULL_8170759',
'NOVAJUS_FULL_8173222',
'NOVAJUS_FULL_8170270',
'NOVAJUS_FULL_8172602',
'NOVAJUS_FULL_8169749',
'NOVAJUS_FULL_8171656',
'NOVAJUS_FULL_8172021',
'NOVAJUS_FULL_8168328',
'NOVAJUS_FULL_8168550',
'NOVAJUS_FULL_8172179',
'NOVAJUS_FULL_8171786',
'NOVAJUS_FULL_8171522',
'NOVAJUS_FULL_8186550',
'NOVAJUS_FULL_8169434',
'NOVAJUS_FULL_8186588',
'NOVAJUS_FULL_8168995',
'NOVAJUS_FULL_8180980',
'NOVAJUS_FULL_8183365',
'NOVAJUS_FULL_8173643',
'NOVAJUS_FULL_8170651',
'NOVAJUS_FULL_8181005',
'NOVAJUS_FULL_8170755',
'InfolexOne_AR_8194182',
'NOVAJUS_FULL_8172827',
'NOVAJUS_FULL_8173647',
'NOVAJUS_FULL_8169539',
'NOVAJUS_FULL_8172995',
'NOVAJUS_FULL_8169960',
'NOVAJUS_FULL_8183414',
'NOVAJUS_FULL_8171317',
'NOVAJUS_FULL_8171673',
'NOVAJUS_FULL_8171928',
'NOVAJUS_FULL_8180065',
'NOVAJUS_FULL_8186351',
'NOVAJUS_FULL_8170099',
'NOVAJUS_FULL_8173797',
'InfolexOne_AR_8193555',
'NOVAJUS_FULL_8172329',
'NOVAJUS_FULL_8186556',
'NOVAJUS_FULL_8184467',
'NOVAJUS_FULL_8168773',
'NOVAJUS_FULL_8177392',
'InfolexOne_AR_8192893',
'NOVAJUS_FULL_8169204',
'NOVAJUS_FULL_8169758',
'NOVAJUS_FULL_8172808',
'NOVAJUS_FULL_8173427',
'NOVAJUS_FULL_8172057',
'NOVAJUS_FULL_8186079',
'NOVAJUS_FULL_8186490',
'InfolexOne_AR_8193465',
'NOVAJUS_FULL_8181776',
'InfolexOne_AR_8191980',
'NOVAJUS_FULL_8173422',
'NOVAJUS_FULL_8180386',
'InfolexOne_AR_8192554',
'InfolexOne_AR_8193537',
'NOVAJUS_FULL_8169325',
'NOVAJUS_FULL_8172673',
'NOVAJUS_FULL_8173214',
'NOVAJUS_FULL_8175155',
'NOVAJUS_FULL_8178050',
'NOVAJUS_FULL_8179567',
'NOVAJUS_FULL_8180061',
'NOVAJUS_FULL_8181805',
'NOVAJUS_FULL_8182773',
'NOVAJUS_FULL_8183191',
'NOVAJUS_FULL_8186482'
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
