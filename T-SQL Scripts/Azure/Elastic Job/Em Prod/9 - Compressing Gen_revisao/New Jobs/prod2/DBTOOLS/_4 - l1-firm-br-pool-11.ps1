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
$ExportToCsvPath = "$PSScriptRoot\DBTOOLS4.csv"
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
'NOVAJUS_FULL_8160958',
'NOVAJUS_FULL_8164025',
'NOVAJUS_FULL_8158705',
'NOVAJUS_FULL_8172867',
'l1_firm_br_8095481',
'NOVAJUS_FULL_8159064',
'NOVAJUS_FULL_8159497',
'NOVAJUS_FULL_8212506',
'NOVAJUS_FULL_8160387',
'InfolexOne_AR_8168755',
'NOVAJUS_FULL_8164929',
'NOVAJUS_FULL_8173019',
'NOVAJUS_FULL_8199356',
'NOVAJUS_FULL_8158176',
'NOVAJUS_FULL_8190998',
'NOVAJUS_FULL_8194395',
'NOVAJUS_FULL_8161060',
'NOVAJUS_FULL_8198418',
'NOVAJUS_FULL_8196769',
'NOVAJUS_FULL_8199515',
'NOVAJUS_FULL_8199279',
'NOVAJUS_FULL_8196883',
'NOVAJUS_FULL_8197476',
'NOVAJUS_FULL_8198335',
'NOVAJUS_FULL_8198700',
'NOVAJUS_FULL_8158432',
'NOVAJUS_FULL_8160601',
'NOVAJUS_FULL_8197912',
'NOVAJUS_FULL_8164483',
'NOVAJUS_FULL_8213033',
'NOVAJUS_FULL_8197702',
'InfolexOne_AR_8174996',
'NOVAJUS_FULL_8198482',
'NOVAJUS_FULL_8175586',
'NOVAJUS_FULL_8196942',
'NOVAJUS_FULL_8199376',
'NOVAJUS_FULL_8198265',
'NOVAJUS_FULL_8199395',
'InfolexOne_AR_8173530',
'NOVAJUS_FULL_8193325',
'NOVAJUS_FULL_8198343',
'NOVAJUS_FULL_8199578',
'InfolexOne_AR_8174988',
'NOVAJUS_FULL_8202843',
'NOVAJUS_FULL_8199103',
'NOVAJUS_FULL_8198095',
'NOVAJUS_FULL_8197154',
'NOVAJUS_FULL_8198207',
'NOVAJUS_FULL_8202935',
'NOVAJUS_FULL_8197619',
'NOVAJUS_FULL_8198601',
'NOVAJUS_FULL_8197446',
'NOVAJUS_FULL_8199474',
'NOVAJUS_FULL_8199314',
'NOVAJUS_FULL_8196754',
'NOVAJUS_FULL_8216498',
'NOVAJUS_FULL_8215808',
'NOVAJUS_FULL_8198060',
'NOVAJUS_FULL_8197863',
'l1_firm_br_8105077',
'NOVAJUS_FULL_8198905',
'NOVAJUS_FULL_8203186',
'NOVAJUS_FULL_8197491',
'NOVAJUS_FULL_8197798',
'NOVAJUS_FULL_8198055',
'NOVAJUS_FULL_8203201',
'NOVAJUS_FULL_8202588',
'NOVAJUS_FULL_8168581',
'NOVAJUS_FULL_8216618',
'NOVAJUS_FULL_8197243',
'NOVAJUS_FULL_8199612',
'NOVAJUS_FULL_8203155',
'NOVAJUS_FULL_8197282',
'NOVAJUS_FULL_8198586',
'NOVAJUS_FULL_8197691',
'NOVAJUS_FULL_8198075',
'NOVAJUS_FULL_8198816',
'NOVAJUS_FULL_8202148',
'NOVAJUS_FULL_8197942',
'InfolexOne_AR_8174116',
'NOVAJUS_FULL_8198628',
'NOVAJUS_FULL_8203046',
'NOVAJUS_FULL_8189447',
'NOVAJUS_FULL_8216403',
'NOVAJUS_FULL_8192952',
'NOVAJUS_FULL_8197794',
'NOVAJUS_FULL_8198440',
'NOVAJUS_FULL_8199381',
'NOVAJUS_FULL_8202707',
'NOVAJUS_FULL_8197886',
'NOVAJUS_FULL_8193840',
'NOVAJUS_FULL_8187290',
'NOVAJUS_FULL_8197288',
'NOVAJUS_FULL_8198304',
'NOVAJUS_FULL_8216301',
'NOVAJUS_FULL_8198420',
'NOVAJUS_FULL_8198998',
'NOVAJUS_FULL_8199229',
'NOVAJUS_FULL_8199610',
'NOVAJUS_FULL_8198436',
'NOVAJUS_FULL_8197397',
'NOVAJUS_FULL_8216298',
'NOVAJUS_FULL_8216398',
'NOVAJUS_FULL_8198267',
'NOVAJUS_FULL_8215995',
'NOVAJUS_FULL_8194527',
'NOVAJUS_FULL_8197400',
'NOVAJUS_FULL_8198318',
'NOVAJUS_FULL_8202624',
'NOVAJUS_FULL_8216385',
'NOVAJUS_FULL_8196853',
'NOVAJUS_FULL_8197962',
'NOVAJUS_FULL_8216261',
'NOVAJUS_FULL_8199047',
'NOVAJUS_FULL_8198584',
'NOVAJUS_FULL_8198703',
'NOVAJUS_FULL_8203152',
'NOVAJUS_FULL_8191670',
'NOVAJUS_FULL_8197671',
'NOVAJUS_FULL_8194429',
'NOVAJUS_FULL_8216052',
'NOVAJUS_FULL_8197275',
'NOVAJUS_FULL_8203203',
'NOVAJUS_FULL_8193849',
'NOVAJUS_FULL_8198125',
'NOVAJUS_FULL_8198373',
'NOVAJUS_FULL_8202193',
'NOVAJUS_FULL_8198058',
'NOVAJUS_FULL_8215983',
'InfolexOne_AR_8162819',
'NOVAJUS_FULL_8199274',
'NOVAJUS_FULL_8203159',
'NOVAJUS_FULL_8197894',
'NOVAJUS_FULL_8198045',
'NOVAJUS_FULL_8197724',
'NOVAJUS_FULL_8194342',
'NOVAJUS_FULL_8197357',
'NOVAJUS_FULL_8191878',
'NOVAJUS_FULL_8197500',
'NOVAJUS_FULL_8199166',
'NOVAJUS_FULL_8199573',
'NOVAJUS_FULL_8203130',
'NOVAJUS_FULL_8216607',
'NOVAJUS_FULL_8187213',
'NOVAJUS_FULL_8197498',
'NOVAJUS_FULL_8203174',
'NOVAJUS_FULL_8216046',
'NOVAJUS_FULL_8215634',
'NOVAJUS_FULL_8216006',
'NOVAJUS_FULL_8189053',
'NOVAJUS_FULL_8189754',
'NOVAJUS_FULL_8189665',
'NOVAJUS_FULL_8216464',
'NOVAJUS_FULL_8216219',
'NOVAJUS_FULL_8191581',
'NOVAJUS_FULL_8215862',
'NOVAJUS_FULL_8215895',
'NOVAJUS_FULL_8197513',
'NOVAJUS_FULL_8198422',
'NOVAJUS_FULL_8198101',
'NOVAJUS_FULL_8199479',
'NOVAJUS_FULL_8216445',
'NOVAJUS_FULL_8216605',
'NOVAJUS_FULL_8199407',
'NOVAJUS_FULL_8216313',
'NOVAJUS_FULL_8202719',
'NOVAJUS_FULL_8198525',
'NOVAJUS_FULL_8216315',
'NOVAJUS_FULL_8216193',
'NOVAJUS_FULL_8192698',
'NOVAJUS_FULL_8193974',
'NOVAJUS_FULL_8216389',
'NOVAJUS_FULL_8196818',
'NOVAJUS_FULL_8216009',
'NOVAJUS_FULL_8190451',
'NOVAJUS_FULL_8199551',
'NOVAJUS_FULL_8197487',
'NOVAJUS_FULL_8198609',
'NOVAJUS_FULL_8203199',
'NOVAJUS_FULL_8199162',
'NOVAJUS_FULL_8215821',
'NOVAJUS_FULL_8216453',
'NOVAJUS_FULL_8198510',
'NOVAJUS_FULL_8201301',
'NOVAJUS_FULL_8215992',
'NOVAJUS_FULL_8216309',
'NOVAJUS_FULL_8187587',
'NOVAJUS_FULL_8194332',
'NOVAJUS_FULL_8197906',
'NOVAJUS_FULL_8215627',
'NOVAJUS_FULL_8198179',
'NOVAJUS_FULL_8198183',
'NOVAJUS_FULL_8202615',
'NOVAJUS_FULL_8216523',
'NOVAJUS_FULL_8197442',
'NOVAJUS_FULL_8216289',
'NOVAJUS_FULL_8193858',
'NOVAJUS_FULL_8196624',
'NOVAJUS_FULL_8199007',
'l1_firm_br_8092050',
'NOVAJUS_FULL_8193972',
'NOVAJUS_FULL_8199576',
'NOVAJUS_FULL_8202324',
'NOVAJUS_FULL_8202889',
'NOVAJUS_FULL_8205607',
'NOVAJUS_FULL_8216050',
'NOVAJUS_FULL_8198307',
'NOVAJUS_FULL_8199209',
'NOVAJUS_FULL_8203031',
'NOVAJUS_FULL_8216167',
'NOVAJUS_FULL_8215679',
'l1_firm_br_8088306',
'NOVAJUS_FULL_8197438',
'NOVAJUS_FULL_8197753',
'NOVAJUS_FULL_8199379',
'NOVAJUS_FULL_8199460',
'NOVAJUS_FULL_8199506',
'NOVAJUS_FULL_8215524',
'NOVAJUS_FULL_8215531',
'NOVAJUS_FULL_8215533',
'NOVAJUS_FULL_8216163',
'NOVAJUS_FULL_8216199',
'NOVAJUS_FULL_8216513',
'NOVAJUS_FULL_8216597',
'NOVAJUS_FULL_8215537'

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
