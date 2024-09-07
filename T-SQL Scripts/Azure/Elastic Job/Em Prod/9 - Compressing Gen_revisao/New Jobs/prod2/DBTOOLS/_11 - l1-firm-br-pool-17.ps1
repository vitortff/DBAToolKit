﻿cls
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
$ExportToCsvPath = "$PSScriptRoot\DBTOOLS11.csv"
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
'NOVAJUS_FULL_8200673',
'NOVAJUS_FULL_8195861',
'NOVAJUS_FULL_8214343',
'NOVAJUS_FULL_8214682',
'NOVAJUS_FULL_8196121',
'NOVAJUS_FULL_8200812',
'NOVAJUS_FULL_8196308',
'NOVAJUS_FULL_8191595',
'NOVAJUS_FULL_8196156',
'NOVAJUS_FULL_8192291',
'NOVAJUS_FULL_8195349',
'NOVAJUS_FULL_8192838',
'NOVAJUS_FULL_8194030',
'NOVAJUS_FULL_8196159',
'NOVAJUS_FULL_8214694',
'NOVAJUS_FULL_8194822',
'NOVAJUS_FULL_8213489',
'NOVAJUS_FULL_8200453',
'NOVAJUS_FULL_8200731',
'NOVAJUS_FULL_8199996',
'NOVAJUS_FULL_8191592',
'NOVAJUS_FULL_8196126',
'NOVAJUS_FULL_8195293',
'NOVAJUS_FULL_8214083',
'NOVAJUS_FULL_8196269',
'NOVAJUS_FULL_8192478',
'NOVAJUS_FULL_8193884',
'NOVAJUS_FULL_8196255',
'NOVAJUS_FULL_8196525',
'NOVAJUS_FULL_8200478',
'NOVAJUS_FULL_8191316',
'NOVAJUS_FULL_8193067',
'NOVAJUS_FULL_8214685',
'NOVAJUS_FULL_8195090',
'NOVAJUS_FULL_8213555',
'NOVAJUS_FULL_8196415',
'NOVAJUS_FULL_8191085',
'NOVAJUS_FULL_8200471',
'NOVAJUS_FULL_8192328',
'NOVAJUS_FULL_8200908',
'NOVAJUS_FULL_8199870',
'NOVAJUS_FULL_8195740',
'NOVAJUS_FULL_8195018',
'NOVAJUS_FULL_8196349',
'NOVAJUS_FULL_8180196',
'NOVAJUS_FULL_8213130',
'NOVAJUS_FULL_8165337',
'NOVAJUS_FULL_8196177',
'NOVAJUS_FULL_8190824',
'NOVAJUS_FULL_8205395',
'NOVAJUS_FULL_8195256',
'NOVAJUS_FULL_8167660',
'NOVAJUS_FULL_8189422',
'NOVAJUS_FULL_8165009',
'NOVAJUS_FULL_8199922',
'NOVAJUS_FULL_8200460',
'NOVAJUS_FULL_8166983',
'NOVAJUS_FULL_8195246',
'NOVAJUS_FULL_8200446',
'NOVAJUS_FULL_8192616',
'NOVAJUS_FULL_8200382',
'NOVAJUS_FULL_8193194',
'NOVAJUS_FULL_8200945',
'NOVAJUS_FULL_8196419',
'NOVAJUS_FULL_8166379',
'NOVAJUS_FULL_8195790',
'NOVAJUS_FULL_8205937',
'NOVAJUS_FULL_8214607',
'NOVAJUS_FULL_8191009',
'NOVAJUS_FULL_8205135',
'NOVAJUS_FULL_8203506',
'NOVAJUS_FULL_8205875',
'NOVAJUS_FULL_8192635',
'NOVAJUS_FULL_8192672',
'NOVAJUS_FULL_8195020',
'NOVAJUS_FULL_8203372',
'NOVAJUS_FULL_8192433',
'NOVAJUS_FULL_8193164',
'NOVAJUS_FULL_8200203',
'NOVAJUS_FULL_8196141',
'NOVAJUS_FULL_8199804',
'NOVAJUS_FULL_8214609',
'NOVAJUS_FULL_8163072',
'NOVAJUS_FULL_8194645',
'NOVAJUS_FULL_8212102',
'NOVAJUS_FULL_8213120',
'NOVAJUS_FULL_8214594',
'NOVAJUS_FULL_8185167',
'NOVAJUS_FULL_8204799',
'NOVAJUS_FULL_8196319',
'NOVAJUS_FULL_8200259',
'NOVAJUS_FULL_8192505',
'NOVAJUS_FULL_8212341',
'NOVAJUS_FULL_8213021',
'NOVAJUS_FULL_8195646',
'NOVAJUS_FULL_8165483',
'NOVAJUS_FULL_8166719',
'NOVAJUS_FULL_8190996',
'NOVAJUS_FULL_8214434',
'NOVAJUS_FULL_8187816',
'NOVAJUS_FULL_8204472',
'NOVAJUS_FULL_8191635',
'NOVAJUS_FULL_8191733',
'NOVAJUS_FULL_8199831',
'NOVAJUS_FULL_8212807',
'NOVAJUS_FULL_8213311',
'NOVAJUS_FULL_8214642',
'NOVAJUS_FULL_8206680',
'NOVAJUS_FULL_8214718',
'NOVAJUS_FULL_8165172',
'NOVAJUS_FULL_8212852',
'NOVAJUS_FULL_8214722',
'NOVAJUS_FULL_8180526',
'NOVAJUS_FULL_8196113',
'NOVAJUS_FULL_8203548',
'NOVAJUS_FULL_8204721',
'NOVAJUS_FULL_8214531',
'NOVAJUS_FULL_8199643',
'NOVAJUS_FULL_8205894',
'NOVAJUS_FULL_8200532',
'NOVAJUS_FULL_8204530',
'NOVAJUS_FULL_8212437',
'NOVAJUS_FULL_8212621',
'NOVAJUS_FULL_8213247',
'NOVAJUS_FULL_8214113',
'NOVAJUS_FULL_8214445',
'NOVAJUS_FULL_8203317',
'NOVAJUS_FULL_8195204',
'NOVAJUS_FULL_8213102',
'NOVAJUS_FULL_8214463',
'NOVAJUS_FULL_8200527',
'NOVAJUS_FULL_8212738',
'NOVAJUS_FULL_8213481',
'NOVAJUS_FULL_8213819',
'NOVAJUS_FULL_8165370',
'NOVAJUS_FULL_8205517',
'NOVAJUS_FULL_8212133',
'NOVAJUS_FULL_8212393',
'NOVAJUS_FULL_8213570',
'NOVAJUS_FULL_8187629',
'NOVAJUS_FULL_8214468',
'NOVAJUS_FULL_8196301',
'NOVAJUS_FULL_8211876',
'NOVAJUS_FULL_8212110',
'NOVAJUS_FULL_8180380',
'NOVAJUS_FULL_8190961',
'NOVAJUS_FULL_8200187',
'NOVAJUS_FULL_8211638',
'NOVAJUS_FULL_8211907',
'NOVAJUS_FULL_8212631',
'NOVAJUS_FULL_8214100',
'NOVAJUS_FULL_8214602',
'NOVAJUS_FULL_8184455',
'NOVAJUS_FULL_8211928',
'NOVAJUS_FULL_8212838',
'NOVAJUS_FULL_8214362',
'NOVAJUS_FULL_8182010',
'NOVAJUS_FULL_8196151',
'NOVAJUS_FULL_8200280',
'NOVAJUS_FULL_8212063',
'NOVAJUS_FULL_8212681',
'NOVAJUS_FULL_8212689',
'NOVAJUS_FULL_8212913',
'NOVAJUS_FULL_8214596',
'NOVAJUS_FULL_8180930',
'NOVAJUS_FULL_8192890',
'NOVAJUS_FULL_8211702',
'NOVAJUS_FULL_8214453',
'NOVAJUS_FULL_8175905',
'NOVAJUS_FULL_8188692',
'NOVAJUS_FULL_8199937',
'NOVAJUS_FULL_8211506',
'NOVAJUS_FULL_8212771',
'NOVAJUS_FULL_8213039',
'NOVAJUS_FULL_8213815',
'NOVAJUS_FULL_8214432',
'NOVAJUS_FULL_8214455',
'NOVAJUS_FULL_8214589',
'NOVAJUS_FULL_8195564',
'NOVAJUS_FULL_8205760',
'NOVAJUS_FULL_8211620',
'NOVAJUS_FULL_8211953',
'NOVAJUS_FULL_8212019',
'NOVAJUS_FULL_8212068',
'NOVAJUS_FULL_8212477',
'NOVAJUS_FULL_8213175',
'NOVAJUS_FULL_8182541',
'NOVAJUS_FULL_8183079',
'NOVAJUS_FULL_8200283',
'NOVAJUS_FULL_8205330',
'NOVAJUS_FULL_8205332',
'NOVAJUS_FULL_8212413',
'NOVAJUS_FULL_8212801',
'NOVAJUS_FULL_8213862',
'NOVAJUS_FULL_8214732',
'NOVAJUS_FULL_8192598',
'NOVAJUS_FULL_8214520',
'NOVAJUS_FULL_8214637',
'NOVAJUS_FULL_8181906',
'NOVAJUS_FULL_8194736',
'NOVAJUS_FULL_8211669',
'NOVAJUS_FULL_8211683',
'NOVAJUS_FULL_8212643',
'NOVAJUS_FULL_8212649',
'NOVAJUS_FULL_8212819',
'NOVAJUS_FULL_8214518',
'NOVAJUS_FULL_8200182',
'NOVAJUS_FULL_8200482',
'NOVAJUS_FULL_8211426',
'NOVAJUS_FULL_8211581',
'NOVAJUS_FULL_8211772',
'NOVAJUS_FULL_8212120',
'NOVAJUS_FULL_8212512',
'NOVAJUS_FULL_8212641',
'NOVAJUS_FULL_8212907',
'NOVAJUS_FULL_8214660',
'NOVAJUS_FULL_8214670',
'NOVAJUS_FULL_8214720',
'NOVAJUS_FULL_8181222',
'NOVAJUS_FULL_8188755',
'NOVAJUS_FULL_8190992',
'NOVAJUS_FULL_8200388',
'NOVAJUS_FULL_8211373',
'NOVAJUS_FULL_8211584',
'NOVAJUS_FULL_8211775',
'NOVAJUS_FULL_8212115',
'NOVAJUS_FULL_8212249',
'NOVAJUS_FULL_8212330',
'NOVAJUS_FULL_8212638',
'NOVAJUS_FULL_8213096',
'NOVAJUS_FULL_8213245',
'NOVAJUS_FULL_8214040',
'NOVAJUS_FULL_8214525',
'NOVAJUS_FULL_8163849',
'NOVAJUS_FULL_8163876',
'NOVAJUS_FULL_8165549',
'NOVAJUS_FULL_8166958',
'NOVAJUS_FULL_8167718',
'NOVAJUS_FULL_8174909',
'NOVAJUS_FULL_8175161',
'NOVAJUS_FULL_8175317',
'NOVAJUS_FULL_8175640',
'NOVAJUS_FULL_8175769',
'NOVAJUS_FULL_8175853',
'NOVAJUS_FULL_8177733',
'NOVAJUS_FULL_8178102',
'NOVAJUS_FULL_8180777',
'NOVAJUS_FULL_8181463',
'NOVAJUS_FULL_8182021',
'NOVAJUS_FULL_8182643',
'NOVAJUS_FULL_8182675',
'NOVAJUS_FULL_8187163',
'NOVAJUS_FULL_8189151',
'NOVAJUS_FULL_8190745',
'NOVAJUS_FULL_8190814',
'NOVAJUS_FULL_8191131',
'NOVAJUS_FULL_8191629',
'NOVAJUS_FULL_8191677',
'NOVAJUS_FULL_8191681',
'NOVAJUS_FULL_8192150',
'NOVAJUS_FULL_8192652',
'NOVAJUS_FULL_8192858',
'NOVAJUS_FULL_8193261',
'NOVAJUS_FULL_8193265',
'NOVAJUS_FULL_8193269',
'NOVAJUS_FULL_8193273',
'NOVAJUS_FULL_8193277',
'NOVAJUS_FULL_8193363',
'NOVAJUS_FULL_8193461',
'NOVAJUS_FULL_8193469',
'NOVAJUS_FULL_8193474',
'NOVAJUS_FULL_8193478',
'NOVAJUS_FULL_8193491',
'NOVAJUS_FULL_8193496',
'NOVAJUS_FULL_8193508',
'NOVAJUS_FULL_8193825',
'NOVAJUS_FULL_8196259',
'NOVAJUS_FULL_8211557',
'NOVAJUS_FULL_8211615',
'NOVAJUS_FULL_8211641',
'NOVAJUS_FULL_8211892',
'NOVAJUS_FULL_8211897',
'NOVAJUS_FULL_8211930',
'NOVAJUS_FULL_8212247',
'NOVAJUS_FULL_8212350',
'NOVAJUS_FULL_8212398',
'NOVAJUS_FULL_8212441',
'NOVAJUS_FULL_8212455',
'NOVAJUS_FULL_8212627',
'NOVAJUS_FULL_8212691',
'NOVAJUS_FULL_8212805',
'NOVAJUS_FULL_8212817',
'NOVAJUS_FULL_8212827',
'NOVAJUS_FULL_8212829',
'NOVAJUS_FULL_8212983',
'NOVAJUS_FULL_8212989',
'NOVAJUS_FULL_8213031',
'NOVAJUS_FULL_8213526',
'NOVAJUS_FULL_8213746',
'NOVAJUS_FULL_8213749',
'NOVAJUS_FULL_8213773',
'NOVAJUS_FULL_8213990',
'NOVAJUS_FULL_8214043',
'NOVAJUS_FULL_8214071',
'NOVAJUS_FULL_8214627',
'NOVAJUS_FULL_8214631',
'NOVAJUS_FULL_8214640',
'NOVAJUS_FULL_8214688',
'NOVAJUS_FULL_8211697',
'NOVAJUS_FULL_8212011'
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
