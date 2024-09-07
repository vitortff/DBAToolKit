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
$ExportToCsvPath = "$PSScriptRoot\DBTOOLS2.csv"
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
'NOVAJUS_FULL_8166732',
'NOVAJUS_FULL_8211342',
'l1_firm_br_8104628',
'NOVAJUS_FULL_8175368',
'NOVAJUS_FULL_8201032',
'NOVAJUS_FULL_8209043',
'NOVAJUS_FULL_8200177',
'NOVAJUS_FULL_8164628',
'NOVAJUS_FULL_8167478',
'NOVAJUS_FULL_8166953',
'NOVAJUS_FULL_8200711',
'NOVAJUS_FULL_8164496',
'NOVAJUS_FULL_8163378',
'NOVAJUS_FULL_8194500',
'NOVAJUS_FULL_8167034',
'NOVAJUS_FULL_8165476',
'NOVAJUS_FULL_8166479',
'NOVAJUS_FULL_8164971',
'NOVAJUS_FULL_8164348',
'NOVAJUS_FULL_8206637',
'NOVAJUS_FULL_8167503',
'NOVAJUS_FULL_8166377',
'NOVAJUS_FULL_8205835',
'NOVAJUS_FULL_8210125',
'NOVAJUS_FULL_8167869',
'NOVAJUS_FULL_8194522',
'NOVAJUS_FULL_8194484',
'NOVAJUS_FULL_8209514',
'NOVAJUS_FULL_8194486',
'NOVAJUS_FULL_8200996',
'NOVAJUS_FULL_8210793',
'InfolexOne_AR_8202657',
'NOVAJUS_FULL_8210312',
'NOVAJUS_FULL_8194145',
'NOVAJUS_FULL_8194569',
'InfolexOne_AR_8206307',
'NOVAJUS_FULL_8194046',
'NOVAJUS_FULL_8209759',
'NOVAJUS_FULL_8211063',
'InfolexOne_AR_8200609',
'NOVAJUS_FULL_8209096',
'NOVAJUS_FULL_8194503',
'InfolexOne_AR_8204823',
'NOVAJUS_FULL_8210808',
'NOVAJUS_FULL_8200970',
'NOVAJUS_FULL_8210244',
'NOVAJUS_FULL_8209480',
'InfolexOne_AR_8216120',
'NOVAJUS_FULL_8211026',
'NOVAJUS_FULL_8209901',
'NOVAJUS_FULL_8210669',
'NOVAJUS_FULL_8209036',
'NOVAJUS_FULL_8210664',
'NOVAJUS_FULL_8200648',
'NOVAJUS_FULL_8205570',
'NOVAJUS_FULL_8210677',
'NOVAJUS_FULL_8211086',
'InfolexOne_AR_8211624',
'NOVAJUS_FULL_8211252',
'NOVAJUS_FULL_8194107',
'NOVAJUS_FULL_8210796',
'InfolexOne_AR_8210610',
'InfolexOne_AR_8201944',
'NOVAJUS_FULL_8209207',
'NOVAJUS_FULL_8210938',
'NOVAJUS_FULL_8209253',
'NOVAJUS_FULL_8211035',
'NOVAJUS_FULL_8200807',
'NOVAJUS_FULL_8210587',
'NOVAJUS_FULL_8194567',
'NOVAJUS_FULL_8209504',
'NOVAJUS_FULL_8210325',
'NOVAJUS_FULL_8205605',
'NOVAJUS_FULL_8209200',
'NOVAJUS_FULL_8210644',
'NOVAJUS_FULL_8209303',
'NOVAJUS_FULL_8210374',
'NOVAJUS_FULL_8210426',
'NOVAJUS_FULL_8209846',
'NOVAJUS_FULL_8210620',
'InfolexOne_AR_8202150',
'InfolexOne_AR_8208091',
'NOVAJUS_FULL_8209876',
'NOVAJUS_FULL_8209895',
'NOVAJUS_FULL_8210839',
'NOVAJUS_FULL_8210122',
'NOVAJUS_FULL_8210145',
'NOVAJUS_FULL_8209486',
'NOVAJUS_FULL_8209996',
'NOVAJUS_FULL_8210386',
'NOVAJUS_FULL_8210432',
'NOVAJUS_FULL_8209273',
'NOVAJUS_FULL_8210068',
'NOVAJUS_FULL_8209038',
'NOVAJUS_FULL_8209226',
'NOVAJUS_FULL_8209643',
'NOVAJUS_FULL_8209914',
'NOVAJUS_FULL_8210051',
'NOVAJUS_FULL_8210259',
'NOVAJUS_FULL_8210798',
'InfolexOne_AR_8198083',
'NOVAJUS_FULL_8209728',
'NOVAJUS_FULL_8210198',
'NOVAJUS_FULL_8210623',
'InfolexOne_AR_8203986',
'InfolexOne_AR_8213767',
'NOVAJUS_FULL_8187395',
'NOVAJUS_FULL_8192696',
'NOVAJUS_FULL_8209300',
'NOVAJUS_FULL_8210767',
'InfolexOne_AR_8202233',
'NOVAJUS_FULL_8209441',
'NOVAJUS_FULL_8210764',
'NOVAJUS_FULL_8210924',
'InfolexOne_AR_8208129',
'NOVAJUS_FULL_8209294',
'NOVAJUS_FULL_8211061',
'NOVAJUS_FULL_8211100',
'NOVAJUS_FULL_8209757',
'NOVAJUS_FULL_8205830',
'NOVAJUS_FULL_8209826',
'NOVAJUS_FULL_8210608',
'NOVAJUS_FULL_8210777',
'InfolexOne_AR_8199742',
'InfolexOne_AR_8200783',
'NOVAJUS_FULL_8205687',
'NOVAJUS_FULL_8210783',
'NOVAJUS_FULL_8210919',
'NOVAJUS_FULL_8210921',
'InfolexOne_AR_8204732',
'NOVAJUS_FULL_8210769',
'NOVAJUS_FULL_8209352',
'NOVAJUS_FULL_8210771',
'InfolexOne_AR_8195799',
'NOVAJUS_FULL_8209848',
'NOVAJUS_FULL_8211091',
'InfolexOne_AR_8202593',
'NOVAJUS_FULL_8209410',
'NOVAJUS_FULL_8210044',
'NOVAJUS_FULL_8211119',
'InfolexOne_AR_8206088',
'InfolexOne_AR_8210946',
'NOVAJUS_FULL_8209153',
'InfolexOne_AR_8197127',
'InfolexOne_AR_8209842',
'NOVAJUS_FULL_8201000',
'NOVAJUS_FULL_8209428',
'NOVAJUS_FULL_8210348',
'InfolexOne_AR_8212075',
'InfolexOne_AR_8215939',
'NOVAJUS_FULL_8209114',
'NOVAJUS_FULL_8209945',
'InfolexOne_AR_8204182',
'NOVAJUS_FULL_8210940',
'InfolexOne_AR_8208819',
'InfolexOne_AR_8209629',
'NOVAJUS_FULL_8210775',
'InfolexOne_AR_8194186',
'InfolexOne_AR_8204155',
'InfolexOne_AR_8204338',
'InfolexOne_AR_8211422',
'NOVAJUS_FULL_8200199',
'NOVAJUS_FULL_8203633',
'NOVAJUS_FULL_8209209',
'NOVAJUS_FULL_8210580',
'NOVAJUS_FULL_8210666',
'NOVAJUS_FULL_8210800',
'NOVAJUS_FULL_8210803',
'InfolexOne_AR_8213788',
'InfolexOne_AR_8214667',
'NOVAJUS_FULL_8209617',
'NOVAJUS_FULL_8210471',
'NOVAJUS_FULL_8210849',
'InfolexOne_AR_8194475',
'InfolexOne_AR_8208775',
'InfolexOne_AR_8208996',
'NOVAJUS_FULL_8210195',
'NOVAJUS_FULL_8210482',
'NOVAJUS_FULL_8211154',
'InfolexOne_AR_8205425',
'InfolexOne_AR_8209671',
'InfolexOne_AR_8215439',
'NOVAJUS_FULL_8205832',
'NOVAJUS_FULL_8209277',
'NOVAJUS_FULL_8210154',
'NOVAJUS_FULL_8210737',
'NOVAJUS_FULL_8210806',
'NOVAJUS_FULL_8211129',
'InfolexOne_AR_8194703',
'InfolexOne_AR_8198844',
'InfolexOne_AR_8200714',
'InfolexOne_AR_8208286',
'InfolexOne_AR_8211592',
'NOVAJUS_FULL_8210319',
'NOVAJUS_FULL_8210452',
'NOVAJUS_FULL_8210704',
'NOVAJUS_FULL_8210832',
'InfolexOne_AR_8202978',
'InfolexOne_AR_8217488',
'NOVAJUS_FULL_8209443',
'NOVAJUS_FULL_8209594',
'NOVAJUS_FULL_8210539',
'NOVAJUS_FULL_8210702',
'NOVAJUS_FULL_8210835',
'NOVAJUS_FULL_8210916',
'NOVAJUS_FULL_8211102',
'NOVAJUS_FULL_8211225',
'InfolexOne_AR_8199369',
'InfolexOne_AR_8202229',
'InfolexOne_AR_8203949',
'InfolexOne_AR_8204912',
'InfolexOne_AR_8213763',
'InfolexOne_AR_8217219',
'NOVAJUS_FULL_8209041',
'NOVAJUS_FULL_8210101',
'NOVAJUS_FULL_8210240',
'NOVAJUS_FULL_8210381',
'NOVAJUS_FULL_8210388',
'NOVAJUS_FULL_8210844',
'InfolexOne_AR_8198518',
'InfolexOne_AR_8198840',
'InfolexOne_AR_8200605',
'InfolexOne_AR_8201936',
'InfolexOne_AR_8202597',
'InfolexOne_AR_8203669',
'InfolexOne_AR_8204100',
'InfolexOne_AR_8204168',
'InfolexOne_AR_8204413',
'InfolexOne_AR_8207102',
'InfolexOne_AR_8207353',
'InfolexOne_AR_8209635',
'InfolexOne_AR_8209663',
'InfolexOne_AR_8209694',
'InfolexOne_AR_8210942',
'InfolexOne_AR_8211693',
'InfolexOne_AR_8211708',
'InfolexOne_AR_8212100',
'InfolexOne_AR_8212974',
'InfolexOne_AR_8213869',
'InfolexOne_AR_8216283',
'InfolexOne_AR_8217468',
'NOVAJUS_FULL_8209161',
'NOVAJUS_FULL_8209450',
'NOVAJUS_FULL_8210826',
'NOVAJUS_FULL_8211186',
'InfolexOne_AR_8193295',
'InfolexOne_AR_8194456',
'InfolexOne_AR_8194754',
'InfolexOne_AR_8197055',
'InfolexOne_AR_8197210',
'InfolexOne_AR_8199738',
'InfolexOne_AR_8200779',
'InfolexOne_AR_8202132',
'InfolexOne_AR_8204282',
'InfolexOne_AR_8205008',
'InfolexOne_AR_8206363',
'InfolexOne_AR_8207098',
'InfolexOne_AR_8208825',
'InfolexOne_AR_8209639',
'InfolexOne_AR_8209652',
'InfolexOne_AR_8210744',
'InfolexOne_AR_8211302',
'InfolexOne_AR_8212079',
'InfolexOne_AR_8212243',
'InfolexOne_AR_8212848',
'InfolexOne_AR_8213759',
'InfolexOne_AR_8216084',
'InfolexOne_AR_8216383',
'NOVAJUS_FULL_8193257',
'NOVAJUS_FULL_8193281',
'NOVAJUS_FULL_8193285',
'NOVAJUS_FULL_8193484',
'NOVAJUS_FULL_8193500',
'NOVAJUS_FULL_8193504',
'NOVAJUS_FULL_8193814',
'NOVAJUS_FULL_8194120',
'NOVAJUS_FULL_8194219',
'NOVAJUS_FULL_8194424',
'NOVAJUS_FULL_8194470',
'NOVAJUS_FULL_8200595',
'NOVAJUS_FULL_8203534',
'NOVAJUS_FULL_8204386',
'NOVAJUS_FULL_8209421',
'NOVAJUS_FULL_8209897',
'NOVAJUS_FULL_8210169',
'NOVAJUS_FULL_8210242',
'NOVAJUS_FULL_8210501',
'NOVAJUS_FULL_8210741',
'NOVAJUS_FULL_8210754',
'NOVAJUS_FULL_8210846',
'NOVAJUS_FULL_8211074',
'NOVAJUS_FULL_8211256',
'NOVAJUS_FULL_8211285',
'NOVAJUS_FULL_8211298',
'NOVAJUS_FULL_8210156'
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
