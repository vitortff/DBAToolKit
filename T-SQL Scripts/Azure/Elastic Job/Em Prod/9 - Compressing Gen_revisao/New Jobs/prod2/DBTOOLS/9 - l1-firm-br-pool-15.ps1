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
$ExportToCsvPath = "$PSScriptRoot\DBTOOLS9.csv"
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
'NOVAJUS_FULL_8177258',
'NOVAJUS_FULL_8192006',
'NOVAJUS_FULL_8178508',
'NOVAJUS_FULL_8174667',
'NOVAJUS_FULL_8184232',
'NOVAJUS_FULL_8194696',
'NOVAJUS_FULL_8191812',
'NOVAJUS_FULL_8188670',
'NOVAJUS_FULL_8178766',
'NOVAJUS_FULL_8176523',
'NOVAJUS_FULL_8190504',
'NOVAJUS_FULL_8181331',
'NOVAJUS_FULL_8178003',
'NOVAJUS_FULL_8190866',
'NOVAJUS_FULL_8175288',
'NOVAJUS_FULL_8193335',
'NOVAJUS_FULL_8189261',
'NOVAJUS_FULL_8191248',
'NOVAJUS_FULL_8177285',
'NOVAJUS_FULL_8185823',
'NOVAJUS_FULL_8179416',
'NOVAJUS_FULL_8193240',
'NOVAJUS_FULL_8190560',
'NOVAJUS_FULL_8202661',
'NOVAJUS_FULL_8188099',
'NOVAJUS_FULL_8200243',
'NOVAJUS_FULL_8194804',
'NOVAJUS_FULL_8182533',
'NOVAJUS_FULL_8187354',
'NOVAJUS_FULL_8189354',
'NOVAJUS_FULL_8179683',
'NOVAJUS_FULL_8193843',
'NOVAJUS_FULL_8190695',
'NOVAJUS_FULL_8191246',
'NOVAJUS_FULL_8192133',
'NOVAJUS_FULL_8188673',
'NOVAJUS_FULL_8185796',
'NOVAJUS_FULL_8192091',
'NOVAJUS_FULL_8177422',
'NOVAJUS_FULL_8188278',
'NOVAJUS_FULL_8180316',
'NOVAJUS_FULL_8189659',
'NOVAJUS_FULL_8203861',
'NOVAJUS_FULL_8180757',
'NOVAJUS_FULL_8199989',
'NOVAJUS_FULL_8184246',
'NOVAJUS_FULL_8189145',
'NOVAJUS_FULL_8185184',
'NOVAJUS_FULL_8178483',
'NOVAJUS_FULL_8188981',
'NOVAJUS_FULL_8179772',
'NOVAJUS_FULL_8188719',
'NOVAJUS_FULL_8190783',
'NOVAJUS_FULL_8193323',
'NOVAJUS_FULL_8174157',
'NOVAJUS_FULL_8190190',
'NOVAJUS_FULL_8187778',
'NOVAJUS_FULL_8183798',
'NOVAJUS_FULL_8194126',
'NOVAJUS_FULL_8189906',
'NOVAJUS_FULL_8171884',
'NOVAJUS_FULL_8187449',
'NOVAJUS_FULL_8190228',
'NOVAJUS_FULL_8193199',
'NOVAJUS_FULL_8181024',
'NOVAJUS_FULL_8197379',
'NOVAJUS_FULL_8209224',
'NOVAJUS_FULL_8209698',
'NOVAJUS_FULL_8198921',
'NOVAJUS_FULL_8209088',
'NOVAJUS_FULL_8192714',
'NOVAJUS_FULL_8180509',
'NOVAJUS_FULL_8187608',
'NOVAJUS_FULL_8202557',
'NOVAJUS_FULL_8187666',
'NOVAJUS_FULL_8196824',
'NOVAJUS_FULL_8188354',
'NOVAJUS_FULL_8189723',
'NOVAJUS_FULL_8191319',
'NOVAJUS_FULL_8211784',
'NOVAJUS_FULL_8191238',
'NOVAJUS_FULL_8187733',
'NOVAJUS_FULL_8189774',
'NOVAJUS_FULL_8187410',
'NOVAJUS_FULL_8203537',
'NOVAJUS_FULL_8191589',
'NOVAJUS_FULL_8189293',
'NOVAJUS_FULL_8188276',
'NOVAJUS_FULL_8193073',
'NOVAJUS_FULL_8201999',
'NOVAJUS_FULL_8189993',
'NOVAJUS_FULL_8193059',
'NOVAJUS_FULL_8189273',
'NOVAJUS_FULL_8191891',
'NOVAJUS_FULL_8188703',
'NOVAJUS_FULL_8191950',
'NOVAJUS_FULL_8198603',
'NOVAJUS_FULL_8190513',
'NOVAJUS_FULL_8195462',
'NOVAJUS_FULL_8189776',
'NOVAJUS_FULL_8191659',
'NOVAJUS_FULL_8211458',
'NOVAJUS_FULL_8187208',
'NOVAJUS_FULL_8187324',
'NOVAJUS_FULL_8190384',
'NOVAJUS_FULL_8191082',
'NOVAJUS_FULL_8191971',
'NOVAJUS_FULL_8189396',
'NOVAJUS_FULL_8202852',
'NOVAJUS_FULL_8193970',
'NOVAJUS_FULL_8191369',
'NOVAJUS_FULL_8205040',
'NOVAJUS_FULL_8204402',
'NOVAJUS_FULL_8196630',
'NOVAJUS_FULL_8193846',
'NOVAJUS_FULL_8197149',
'NOVAJUS_FULL_8194833',
'NOVAJUS_FULL_8201185',
'NOVAJUS_FULL_8188757',
'NOVAJUS_FULL_8204189',
'NOVAJUS_FULL_8209430',
'NOVAJUS_FULL_8195211',
'NOVAJUS_FULL_8188421',
'NOVAJUS_FULL_8187976',
'NOVAJUS_FULL_8188079',
'NOVAJUS_FULL_8204342',
'NOVAJUS_FULL_8188091',
'NOVAJUS_FULL_8211358',
'NOVAJUS_FULL_8187548',
'NOVAJUS_FULL_8204938',
'NOVAJUS_FULL_8189913',
'NOVAJUS_FULL_8196115',
'NOVAJUS_FULL_8193482',
'NOVAJUS_FULL_8193115',
'NOVAJUS_FULL_8190780',
'NOVAJUS_FULL_8195356',
'NOVAJUS_FULL_8199171',
'NOVAJUS_FULL_8204179',
'NOVAJUS_FULL_8192743',
'NOVAJUS_FULL_8204489',
'NOVAJUS_FULL_8188960',
'NOVAJUS_FULL_8190378',
'NOVAJUS_FULL_8197339',
'NOVAJUS_FULL_8191349',
'NOVAJUS_FULL_8191623',
'NOVAJUS_FULL_8192688',
'NOVAJUS_FULL_8199219',
'NOVAJUS_FULL_8194691',
'NOVAJUS_FULL_8188345',
'NOVAJUS_FULL_8195208',
'NOVAJUS_FULL_8217243',
'NOVAJUS_FULL_8187154',
'NOVAJUS_FULL_8192928',
'NOVAJUS_FULL_8198234',
'NOVAJUS_FULL_8194327',
'NOVAJUS_FULL_8198217',
'NOVAJUS_FULL_8187801',
'NOVAJUS_FULL_8190268',
'NOVAJUS_FULL_8195037',
'NOVAJUS_FULL_8206314',
'NOVAJUS_FULL_8188352',
'NOVAJUS_FULL_8194143',
'NOVAJUS_FULL_8190163',
'NOVAJUS_FULL_8192371',
'NOVAJUS_FULL_8189675',
'NOVAJUS_FULL_8191579',
'NOVAJUS_FULL_8192086',
'NOVAJUS_FULL_8191618',
'NOVAJUS_FULL_8190287',
'NOVAJUS_FULL_8189356',
'NOVAJUS_FULL_8191184',
'NOVAJUS_FULL_8194865',
'NOVAJUS_FULL_8194871',
'NOVAJUS_FULL_8217086',
'NOVAJUS_FULL_8216629',
'NOVAJUS_FULL_8191310',
'NOVAJUS_FULL_8191135',
'NOVAJUS_FULL_8199215',
'NOVAJUS_FULL_8217185',
'NOVAJUS_FULL_8216912',
'NOVAJUS_FULL_8216824',
'NOVAJUS_FULL_8217017',
'NOVAJUS_FULL_8217092',
'NOVAJUS_FULL_8216680',
'NOVAJUS_FULL_8217258',
'NOVAJUS_FULL_8217502',
'NOVAJUS_FULL_8217444',
'NOVAJUS_FULL_8216716',
'NOVAJUS_FULL_8216856',
'NOVAJUS_FULL_8216903',
'NOVAJUS_FULL_8217308',
'NOVAJUS_FULL_8216797',
'NOVAJUS_FULL_8216774',
'NOVAJUS_FULL_8216844',
'NOVAJUS_FULL_8217102',
'NOVAJUS_FULL_8217416',
'NOVAJUS_FULL_8217478',
'NOVAJUS_FULL_8217024',
'NOVAJUS_FULL_8217269',
'NOVAJUS_FULL_8216779',
'NOVAJUS_FULL_8216706',
'NOVAJUS_FULL_8216714',
'NOVAJUS_FULL_8216872',
'NOVAJUS_FULL_8217201',
'NOVAJUS_FULL_8217211',
'NOVAJUS_FULL_8217213',
'NOVAJUS_FULL_8217310',
'NOVAJUS_FULL_8216634',
'NOVAJUS_FULL_8217013',
'NOVAJUS_FULL_8217084',
'NOVAJUS_FULL_8217182',
'NOVAJUS_FULL_8217256',
'NOVAJUS_FULL_8217500',
'NOVAJUS_FULL_8217672',
'NOVAJUS_FULL_8216720',
'NOVAJUS_FULL_8216766',
'NOVAJUS_FULL_8216841',
'NOVAJUS_FULL_8217297',
'NOVAJUS_FULL_8217306',
'NOVAJUS_FULL_8217319',
'NOVAJUS_FULL_8217380',
'NOVAJUS_FULL_8217404',
'NOVAJUS_FULL_8217475',
'NOVAJUS_FULL_8217580',
'NOVAJUS_FULL_8217665',
'NOVAJUS_FULL_8217758',
'NOVAJUS_FULL_8216677',
'NOVAJUS_FULL_8216890',
'NOVAJUS_FULL_8216917',
'NOVAJUS_FULL_8216955',
'NOVAJUS_FULL_8217011',
'NOVAJUS_FULL_8217149',
'NOVAJUS_FULL_8217193',
'NOVAJUS_FULL_8217197',
'NOVAJUS_FULL_8217203',
'NOVAJUS_FULL_8217265',
'NOVAJUS_FULL_8217271',
'NOVAJUS_FULL_8217290',
'NOVAJUS_FULL_8217457',
'NOVAJUS_FULL_8217459',
'NOVAJUS_FULL_8217510',
'NOVAJUS_FULL_8217512',
'NOVAJUS_FULL_8217517',
'NOVAJUS_FULL_8217598',
'NOVAJUS_FULL_8217623',
'NOVAJUS_FULL_8217627',
'NOVAJUS_FULL_8217696',
'NOVAJUS_FULL_8217710',
'NOVAJUS_FULL_8217727',
'NOVAJUS_FULL_8217860',
'NOVAJUS_FULL_8217880',
'NOVAJUS_FULL_8217882'
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
