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
$ExportToCsvPath = "$PSScriptRoot\DBTOOLS6.csv"
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
'NOVAJUS_FULL_8160631',
'NOVAJUS_FULL_8161862',
'NOVAJUS_FULL_8158458',
'NOVAJUS_FULL_8164538',
'NOVAJUS_FULL_8181434',
'NOVAJUS_FULL_8166257',
'NOVAJUS_FULL_8165473',
'NOVAJUS_FULL_8167332',
'NOVAJUS_FULL_8168148',
'NOVAJUS_FULL_8163561',
'NOVAJUS_FULL_8208666',
'NOVAJUS_FULL_8160813',
'NOVAJUS_FULL_8166117',
'NOVAJUS_FULL_8159532',
'NOVAJUS_FULL_8167210',
'NOVAJUS_FULL_8159638',
'NOVAJUS_FULL_8158785',
'NOVAJUS_FULL_8165052',
'NOVAJUS_FULL_8164975',
'NOVAJUS_FULL_8160253',
'NOVAJUS_FULL_8166425',
'NOVAJUS_FULL_8162352',
'NOVAJUS_FULL_8168231',
'NOVAJUS_FULL_8161277',
'NOVAJUS_FULL_8163845',
'NOVAJUS_FULL_8168218',
'NOVAJUS_FULL_8160512',
'NOVAJUS_FULL_8165174',
'NOVAJUS_FULL_8168030',
'NOVAJUS_FULL_8165478',
'NOVAJUS_FULL_8161760',
'NOVAJUS_FULL_8160123',
'NOVAJUS_FULL_8160458',
'NOVAJUS_FULL_8161225',
'NOVAJUS_FULL_8161126',
'NOVAJUS_FULL_8162945',
'NOVAJUS_FULL_8158783',
'NOVAJUS_FULL_8166865',
'NOVAJUS_FULL_8163791',
'NOVAJUS_FULL_8159293',
'NOVAJUS_FULL_8185203',
'NOVAJUS_FULL_8157818',
'NOVAJUS_FULL_8161039',
'NOVAJUS_FULL_8164965',
'NOVAJUS_FULL_8163110',
'NOVAJUS_FULL_8163889',
'NOVAJUS_FULL_8159683',
'NOVAJUS_FULL_8162337',
'NOVAJUS_FULL_8163273',
'NOVAJUS_FULL_8160300',
'NOVAJUS_FULL_8166260',
'NOVAJUS_FULL_8181125',
'NOVAJUS_FULL_8158097',
'NOVAJUS_FULL_8161030',
'NOVAJUS_FULL_8183071',
'NOVAJUS_FULL_8159516',
'NOVAJUS_FULL_8162650',
'NOVAJUS_FULL_8163908',
'NOVAJUS_FULL_8167697',
'NOVAJUS_FULL_8158570',
'NOVAJUS_FULL_8166526',
'NOVAJUS_FULL_8158672',
'NOVAJUS_FULL_8160017',
'NOVAJUS_FULL_8161330',
'NOVAJUS_FULL_8162752',
'NOVAJUS_FULL_8160724',
'NOVAJUS_FULL_8165062',
'NOVAJUS_FULL_8161326',
'NOVAJUS_FULL_8157881',
'NOVAJUS_FULL_8167293',
'NOVAJUS_FULL_8161698',
'NOVAJUS_FULL_8167619',
'NOVAJUS_FULL_8158954',
'NOVAJUS_FULL_8161045',
'NOVAJUS_FULL_8164326',
'NOVAJUS_FULL_8182937',
'NOVAJUS_FULL_8207202',
'NOVAJUS_FULL_8158506',
'NOVAJUS_FULL_8164187',
'NOVAJUS_FULL_8158189',
'NOVAJUS_FULL_8159773',
'NOVAJUS_FULL_8168226',
'NOVAJUS_FULL_8163298',
'NOVAJUS_FULL_8159545',
'NOVAJUS_FULL_8158015',
'NOVAJUS_FULL_8160251',
'NOVAJUS_FULL_8166406',
'NOVAJUS_FULL_8157824',
'NOVAJUS_FULL_8158408',
'NOVAJUS_FULL_8206281',
'NOVAJUS_FULL_8165717',
'NOVAJUS_FULL_8159673',
'NOVAJUS_FULL_8206239',
'NOVAJUS_FULL_8161133',
'NOVAJUS_FULL_8166206',
'NOVAJUS_FULL_8162926',
'NOVAJUS_FULL_8183791',
'NOVAJUS_FULL_8160496',
'NOVAJUS_FULL_8161371',
'NOVAJUS_FULL_8160412',
'NOVAJUS_FULL_8162961',
'NOVAJUS_FULL_8174065',
'NOVAJUS_FULL_8165350',
'NOVAJUS_FULL_8167187',
'NOVAJUS_FULL_8158893',
'NOVAJUS_FULL_8205914',
'NOVAJUS_FULL_8159033',
'NOVAJUS_FULL_8165601',
'NOVAJUS_FULL_8160053',
'NOVAJUS_FULL_8163385',
'NOVAJUS_FULL_8160531',
'NOVAJUS_FULL_8177817',
'NOVAJUS_FULL_8162464',
'NOVAJUS_FULL_8183168',
'NOVAJUS_FULL_8160849',
'NOVAJUS_FULL_8162203',
'NOVAJUS_FULL_8163266',
'NOVAJUS_FULL_8163974',
'NOVAJUS_FULL_8177627',
'NOVAJUS_FULL_8165720',
'NOVAJUS_FULL_8185839',
'NOVAJUS_FULL_8207519',
'NOVAJUS_FULL_8166667',
'NOVAJUS_FULL_8165375',
'NOVAJUS_FULL_8176920',
'NOVAJUS_FULL_8162271',
'NOVAJUS_FULL_8159252',
'NOVAJUS_FULL_8166713',
'NOVAJUS_FULL_8178337',
'NOVAJUS_FULL_8208871',
'NOVAJUS_FULL_8208982',
'NOVAJUS_FULL_8182759',
'NOVAJUS_FULL_8191019',
'NOVAJUS_FULL_8168034',
'NOVAJUS_FULL_8184452',
'NOVAJUS_FULL_8184471',
'NOVAJUS_FULL_8183282',
'NOVAJUS_FULL_8162810',
'NOVAJUS_FULL_8184976',
'NOVAJUS_FULL_8181179',
'NOVAJUS_FULL_8182796',
'NOVAJUS_FULL_8180223',
'NOVAJUS_FULL_8167336',
'NOVAJUS_FULL_8207798',
'NOVAJUS_FULL_8161406',
'NOVAJUS_FULL_8162174',
'NOVAJUS_FULL_8205871',
'NOVAJUS_FULL_8204157',
'NOVAJUS_FULL_8167700',
'NOVAJUS_FULL_8181503',
'NOVAJUS_FULL_8184410',
'NOVAJUS_FULL_8204559',
'NOVAJUS_FULL_8182677',
'NOVAJUS_FULL_8162571',
'NOVAJUS_FULL_8208989',
'NOVAJUS_FULL_8163880',
'NOVAJUS_FULL_8208624',
'NOVAJUS_FULL_8204304',
'NOVAJUS_FULL_8166921',
'NOVAJUS_FULL_8176861',
'NOVAJUS_FULL_8183540',
'NOVAJUS_FULL_8207600',
'NOVAJUS_FULL_8205657',
'NOVAJUS_FULL_8205774',
'NOVAJUS_FULL_8205881',
'NOVAJUS_FULL_8215349',
'NOVAJUS_FULL_8177343',
'NOVAJUS_FULL_8208173',
'NOVAJUS_FULL_8215320',
'NOVAJUS_FULL_8208959',
'NOVAJUS_FULL_8160853',
'NOVAJUS_FULL_8205951',
'NOVAJUS_FULL_8205959',
'NOVAJUS_FULL_8207403',
'NOVAJUS_FULL_8176850',
'NOVAJUS_FULL_8162569',
'NOVAJUS_FULL_8176721',
'NOVAJUS_FULL_8166359',
'NOVAJUS_FULL_8178703',
'NOVAJUS_FULL_8203781',
'NOVAJUS_FULL_8208596',
'NOVAJUS_FULL_8158094',
'NOVAJUS_FULL_8206696',
'NOVAJUS_FULL_8203880',
'NOVAJUS_FULL_8203392',
'NOVAJUS_FULL_8215098',
'NOVAJUS_FULL_8175726',
'NOVAJUS_FULL_8176040',
'NOVAJUS_FULL_8214988',
'NOVAJUS_FULL_8208576',
'NOVAJUS_FULL_8165100',
'NOVAJUS_FULL_8205099',
'NOVAJUS_FULL_8159519',
'NOVAJUS_FULL_8208695',
'NOVAJUS_FULL_8166770',
'NOVAJUS_FULL_8215175',
'NOVAJUS_FULL_8167057',
'NOVAJUS_FULL_8204233',
'NOVAJUS_FULL_8203877',
'NOVAJUS_FULL_8205206',
'NOVAJUS_FULL_8203865',
'NOVAJUS_FULL_8208869',
'NOVAJUS_FULL_8204321',
'NOVAJUS_FULL_8215182',
'NOVAJUS_FULL_8164418',
'NOVAJUS_FULL_8207471',
'NOVAJUS_FULL_8174131',
'NOVAJUS_FULL_8176949',
'NOVAJUS_FULL_8204159',
'NOVAJUS_FULL_8205095',
'NOVAJUS_FULL_8166791',
'NOVAJUS_FULL_8181393',
'NOVAJUS_FULL_8206906',
'NOVAJUS_FULL_8204498',
'NOVAJUS_FULL_8208904',
'NOVAJUS_FULL_8181175',
'NOVAJUS_FULL_8208283',
'NOVAJUS_FULL_8194643',
'NOVAJUS_FULL_8205821',
'NOVAJUS_FULL_8206211',
'NOVAJUS_FULL_8215281',
'NOVAJUS_FULL_8215003',
'NOVAJUS_FULL_8207912',
'NOVAJUS_FULL_8208064',
'NOVAJUS_FULL_8204166',
'NOVAJUS_FULL_8205020',
'NOVAJUS_FULL_8205006',
'NOVAJUS_FULL_8208470',
'NOVAJUS_FULL_8209001',
'NOVAJUS_FULL_8203573',
'NOVAJUS_FULL_8215104',
'NOVAJUS_FULL_8208961',
'NOVAJUS_FULL_8214953',
'NOVAJUS_FULL_8215346',
'NOVAJUS_FULL_8208214',
'NOVAJUS_FULL_8215309',
'NOVAJUS_FULL_8187377',
'NOVAJUS_FULL_8215341',
'NOVAJUS_FULL_8208278',
'NOVAJUS_FULL_8208991',
'NOVAJUS_FULL_8168027',
'NOVAJUS_FULL_8189671',
'NOVAJUS_FULL_8208342',
'NOVAJUS_FULL_8198224',
'NOVAJUS_FULL_8215079',
'NOVAJUS_FULL_8208261',
'NOVAJUS_FULL_8207634',
'NOVAJUS_FULL_8208633',
'NOVAJUS_FULL_8183794',
'NOVAJUS_FULL_8203358',
'NOVAJUS_FULL_8215284',
'NOVAJUS_FULL_8208627',
'NOVAJUS_FULL_8215294',
'NOVAJUS_FULL_8207957',
'NOVAJUS_FULL_8208568',
'NOVAJUS_FULL_8208157',
'NOVAJUS_FULL_8215313',
'NOVAJUS_FULL_8207833',
'NOVAJUS_FULL_8208662',
'NOVAJUS_FULL_8215008',
'NOVAJUS_FULL_8215354',
'NOVAJUS_FULL_8207891',
'NOVAJUS_FULL_8208907',
'NOVAJUS_FULL_8209005',
'NOVAJUS_FULL_8215125',
'NOVAJUS_FULL_8208217',
'NOVAJUS_FULL_8214995',
'NOVAJUS_FULL_8215019',
'NOVAJUS_FULL_8215506',
'NOVAJUS_FULL_8208097',
'NOVAJUS_FULL_8208332',
'NOVAJUS_FULL_8215297',
'NOVAJUS_FULL_8208849',
'NOVAJUS_FULL_8188003',
'NOVAJUS_FULL_8215187',
'NOVAJUS_FULL_8207620',
'NOVAJUS_FULL_8208075',
'NOVAJUS_FULL_8208221',
'NOVAJUS_FULL_8208668',
'NOVAJUS_FULL_8208777',
'NOVAJUS_FULL_8215432',
'NOVAJUS_FULL_8207388',
'NOVAJUS_FULL_8208899',
'NOVAJUS_FULL_8215168',
'NOVAJUS_FULL_8158341',
'NOVAJUS_FULL_8207491',
'NOVAJUS_FULL_8208379',
'NOVAJUS_FULL_8215121',
'NOVAJUS_FULL_8207810',
'NOVAJUS_FULL_8208855',
'NOVAJUS_FULL_8215447',
'NOVAJUS_FULL_8208351',
'NOVAJUS_FULL_8208639',
'NOVAJUS_FULL_8215161',
'NOVAJUS_FULL_8207440',
'NOVAJUS_FULL_8215035',
'NOVAJUS_FULL_8215315',
'NOVAJUS_FULL_8208231',
'NOVAJUS_FULL_8208300',
'NOVAJUS_FULL_8207803',
'NOVAJUS_FULL_8207848',
'NOVAJUS_FULL_8214870',
'NOVAJUS_FULL_8214951',
'NOVAJUS_FULL_8215377',
'NOVAJUS_FULL_8208095',
'NOVAJUS_FULL_8208312',
'NOVAJUS_FULL_8208610',
'NOVAJUS_FULL_8208636',
'NOVAJUS_FULL_8207735',
'NOVAJUS_FULL_8208193',
'NOVAJUS_FULL_8208507',
'NOVAJUS_FULL_8215088',
'NOVAJUS_FULL_8215311',
'NOVAJUS_FULL_8160034',
'NOVAJUS_FULL_8207399',
'NOVAJUS_FULL_8208133',
'NOVAJUS_FULL_8208335',
'NOVAJUS_FULL_8208880',
'NOVAJUS_FULL_8208940',
'NOVAJUS_FULL_8209015',
'NOVAJUS_FULL_8215082',
'NOVAJUS_FULL_8215191',
'NOVAJUS_FULL_8215287',
'NOVAJUS_FULL_8207632',
'NOVAJUS_FULL_8207893',
'NOVAJUS_FULL_8208622',
'NOVAJUS_FULL_8215170',
'NOVAJUS_FULL_8215172',
'NOVAJUS_FULL_8215300',
'NOVAJUS_FULL_8215336',
'NOVAJUS_FULL_8159974',
'NOVAJUS_FULL_8162070',
'NOVAJUS_FULL_8168182',
'NOVAJUS_FULL_8168260',
'NOVAJUS_FULL_8168276',
'NOVAJUS_FULL_8168280',
'NOVAJUS_FULL_8168305',
'NOVAJUS_FULL_8177479',
'NOVAJUS_FULL_8177870',
'NOVAJUS_FULL_8178061',
'NOVAJUS_FULL_8180682',
'NOVAJUS_FULL_8188252',
'NOVAJUS_FULL_8189055',
'NOVAJUS_FULL_8189540',
'NOVAJUS_FULL_8189725',
'NOVAJUS_FULL_8206784',
'NOVAJUS_FULL_8207556',
'NOVAJUS_FULL_8207906',
'NOVAJUS_FULL_8207928',
'NOVAJUS_FULL_8208110',
'NOVAJUS_FULL_8208660',
'NOVAJUS_FULL_8215092',
'NOVAJUS_FULL_8215179',
'NOVAJUS_FULL_8215516'
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
