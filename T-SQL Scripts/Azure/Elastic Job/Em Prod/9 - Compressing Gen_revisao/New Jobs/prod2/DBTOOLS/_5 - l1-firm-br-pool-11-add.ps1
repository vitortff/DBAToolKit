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
$ExportToCsvPath = "$PSScriptRoot\DBTOOLS5.csv"
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
'l1_firm_br_8117634_New',
'NOVAJUS_FULL_8185436',
'NOVAJUS_FULL_8174357',
'NOVAJUS_FULL_8185544',
'NOVAJUS_FULL_8174528',
'NOVAJUS_FULL_8199083',
'InfolexOne_AR_8165730',
'NOVAJUS_FULL_8185605',
'NOVAJUS_FULL_8189576',
'NOVAJUS_FULL_8186271',
'NOVAJUS_FULL_8208307',
'NOVAJUS_FULL_8204564',
'NOVAJUS_FULL_8185630',
'NOVAJUS_FULL_8186043',
'NOVAJUS_FULL_8186269',
'NOVAJUS_FULL_8174017',
'NOVAJUS_FULL_8207488',
'NOVAJUS_FULL_8185405',
'NOVAJUS_FULL_8185563',
'InfolexOne_AR_8167483',
'InfolexOne_AR_8172529',
'NOVAJUS_FULL_8205151',
'NOVAJUS_FULL_8207955',
'NOVAJUS_FULL_8186235',
'NOVAJUS_FULL_8212418',
'InfolexOne_AR_8176936',
'NOVAJUS_FULL_8212518',
'InfolexOne_AR_8170534',
'NOVAJUS_FULL_8199758',
'NOVAJUS_FULL_8185452',
'NOVAJUS_FULL_8207655',
'NOVAJUS_FULL_8206733',
'NOVAJUS_FULL_8213797',
'InfolexOne_AR_8172091',
'InfolexOne_AR_8168986',
'InfolexOne_AR_8176311',
'NOVAJUS_FULL_8207629',
'NOVAJUS_FULL_8212450',
'NOVAJUS_FULL_8203525',
'NOVAJUS_FULL_8186309',
'NOVAJUS_FULL_8206034',
'InfolexOne_AR_8171222',
'NOVAJUS_FULL_8208466',
'NOVAJUS_FULL_8213257',
'InfolexOne_AR_8177272',
'NOVAJUS_FULL_8203464',
'NOVAJUS_FULL_8205946',
'NOVAJUS_FULL_8203384',
'NOVAJUS_FULL_8207597',
'NOVAJUS_FULL_8213279',
'NOVAJUS_FULL_8203477',
'NOVAJUS_FULL_8188533',
'NOVAJUS_FULL_8208844',
'NOVAJUS_FULL_8203667',
'NOVAJUS_FULL_8187296',
'InfolexOne_AR_8183255',
'NOVAJUS_FULL_8181697',
'InfolexOne_AR_8172622',
'NOVAJUS_FULL_8189742',
'NOVAJUS_FULL_8213044',
'NOVAJUS_FULL_8204289',
'NOVAJUS_FULL_8202491',
'InfolexOne_AR_8164670',
'NOVAJUS_FULL_8214763',
'NOVAJUS_FULL_8189071',
'InfolexOne_AR_8164301',
'NOVAJUS_FULL_8190400',
'NOVAJUS_FULL_8182828',
'NOVAJUS_FULL_8190223',
'NOVAJUS_FULL_8187760',
'NOVAJUS_FULL_8188990',
'NOVAJUS_FULL_8207454',
'NOVAJUS_FULL_8190217',
'NOVAJUS_FULL_8212345',
'NOVAJUS_FULL_8193202',
'InfolexOne_AR_8180913',
'NOVAJUS_FULL_8193967',
'NOVAJUS_FULL_8185664',
'NOVAJUS_FULL_8185927',
'NOVAJUS_FULL_8174759',
'NOVAJUS_FULL_8203785',
'NOVAJUS_FULL_8191926',
'NOVAJUS_FULL_8188864',
'NOVAJUS_FULL_8191710',
'NOVAJUS_FULL_8204097',
'NOVAJUS_FULL_8212657',
'NOVAJUS_FULL_8208924',
'NOVAJUS_FULL_8213036',
'NOVAJUS_FULL_8207721',
'NOVAJUS_FULL_8188664',
'NOVAJUS_FULL_8188696',
'NOVAJUS_FULL_8208183',
'NOVAJUS_FULL_8213282',
'InfolexOne_AR_8169096',
'NOVAJUS_FULL_8191928',
'NOVAJUS_FULL_8174799',
'NOVAJUS_FULL_8212609',
'NOVAJUS_FULL_8214776',
'NOVAJUS_FULL_8207673',
'NOVAJUS_FULL_8188986',
'NOVAJUS_FULL_8207865',
'NOVAJUS_FULL_8186273',
'NOVAJUS_FULL_8213291',
'NOVAJUS_FULL_8204078',
'NOVAJUS_FULL_8212671',
'NOVAJUS_FULL_8203859',
'NOVAJUS_FULL_8187632',
'NOVAJUS_FULL_8214787',
'NOVAJUS_FULL_8207437',
'NOVAJUS_FULL_8213753',
'NOVAJUS_FULL_8185666',
'InfolexOne_AR_8165917',
'NOVAJUS_FULL_8189688',
'NOVAJUS_FULL_8208138',
'NOVAJUS_FULL_8212130',
'NOVAJUS_FULL_8188094',
'NOVAJUS_FULL_8194813',
'NOVAJUS_FULL_8214771',
'InfolexOne_AR_8174781',
'NOVAJUS_FULL_8199641',
'NOVAJUS_FULL_8214522',
'NOVAJUS_FULL_8198300',
'NOVAJUS_FULL_8199656',
'NOVAJUS_FULL_8214854',
'InfolexOne_AR_8168404',
'NOVAJUS_FULL_8204457',
'NOVAJUS_FULL_8212229',
'NOVAJUS_FULL_8191342',
'InfolexOne_AR_8168982',
'NOVAJUS_FULL_8189766',
'InfolexOne_AR_8177589',
'NOVAJUS_FULL_8185421',
'NOVAJUS_FULL_8208161',
'NOVAJUS_FULL_8197160',
'NOVAJUS_FULL_8212694',
'NOVAJUS_FULL_8212400',
'NOVAJUS_FULL_8207666',
'NOVAJUS_FULL_8208348',
'NOVAJUS_FULL_8195485',
'NOVAJUS_FULL_8212697',
'NOVAJUS_FULL_8214756',
'InfolexOne_AR_8173651',
'NOVAJUS_FULL_8191358',
'NOVAJUS_FULL_8207522',
'NOVAJUS_FULL_8212850',
'NOVAJUS_FULL_8207738',
'NOVAJUS_FULL_8212549',
'NOVAJUS_FULL_8212430',
'InfolexOne_AR_8182303',
'NOVAJUS_FULL_8207788',
'InfolexOne_AR_8171962',
'InfolexOne_AR_8180002',
'NOVAJUS_FULL_8207578',
'InfolexOne_AR_8173003',
'InfolexOne_AR_8175383',
'NOVAJUS_FULL_8208631',
'NOVAJUS_FULL_8212702',
'InfolexOne_AR_8169353',
'NOVAJUS_FULL_8213074',
'NOVAJUS_FULL_8214754',
'NOVAJUS_FULL_8207535',
'NOVAJUS_FULL_8207719',
'NOVAJUS_FULL_8209030',
'InfolexOne_AR_8165666',
'NOVAJUS_FULL_8212395',
'InfolexOne_AR_8171863',
'InfolexOne_AR_8174424',
'InfolexOne_AR_8171216',
'NOVAJUS_FULL_8212467',
'InfolexOne_AR_8177454',
'InfolexOne_AR_8182369',
'NOVAJUS_FULL_8213009',
'InfolexOne_AR_8181114',
'InfolexOne_AR_8177071',
'NOVAJUS_FULL_8212501',
'NOVAJUS_FULL_8214846',
'NOVAJUS_FULL_8208928',
'NOVAJUS_FULL_8212093',
'InfolexOne_AR_8177642',
'NOVAJUS_FULL_8208969',
'NOVAJUS_FULL_8212667',
'NOVAJUS_FULL_8169650',
'NOVAJUS_FULL_8208356',
'NOVAJUS_FULL_8208581',
'NOVAJUS_FULL_8212623',
'NOVAJUS_FULL_8207750',
'NOVAJUS_FULL_8207901',
'NOVAJUS_FULL_8212241',
'NOVAJUS_FULL_8214779',
'NOVAJUS_FULL_8186284',
'NOVAJUS_FULL_8208112',
'NOVAJUS_FULL_8212297',
'NOVAJUS_FULL_8185942',
'NOVAJUS_FULL_8191254',
'NOVAJUS_FULL_8207587',
'InfolexOne_AR_8165748',
'InfolexOne_AR_8182786',
'InfolexOne_AR_8171021',
'InfolexOne_AR_8171601',
'NOVAJUS_FULL_8208965',
'InfolexOne_AR_8166344',
'NOVAJUS_FULL_8207863',
'NOVAJUS_FULL_8212415',
'InfolexOne_AR_8171319',
'InfolexOne_AR_8176863',
'NOVAJUS_FULL_8207496',
'NOVAJUS_FULL_8214781',
'InfolexOne_AR_8172122',
'InfolexOne_AR_8165522',
'NOVAJUS_FULL_8214768',
'InfolexOne_AR_8171312',
'InfolexOne_AR_8181794',
'NOVAJUS_FULL_8214761',
'InfolexOne_AR_8172896',
'InfolexOne_AR_8175626',
'InfolexOne_AR_8175956',
'InfolexOne_AR_8166467',
'InfolexOne_AR_8168639',
'NOVAJUS_FULL_8208902',
'NOVAJUS_FULL_8208937',
'InfolexOne_AR_8165082',
'InfolexOne_AR_8168993',
'InfolexOne_AR_8174788',
'NOVAJUS_FULL_8175933',
'NOVAJUS_FULL_8184784',
'l1_firm_ar_8096941',
'InfolexOne_AR_8165022',
'InfolexOne_AR_8165207',
'InfolexOne_AR_8166401',
'InfolexOne_AR_8168657',
'InfolexOne_AR_8169900',
'InfolexOne_AR_8172116',
'InfolexOne_AR_8172521',
'InfolexOne_AR_8174992',
'InfolexOne_AR_8176661',
'InfolexOne_AR_8178924',
'InfolexOne_AR_8179822',
'InfolexOne_AR_8180832',
'InfolexOne_AR_8181455',
'InfolexOne_AR_8181688',
'InfolexOne_AR_8182056',
'NOVAJUS_FULL_8175297',
'NOVAJUS_FULL_8184729',
'NOVAJUS_FULL_8186060',
'NOVAJUS_FULL_8214849',
'InfolexOne_AR_8168643',
'InfolexOne_AR_8171759',
'InfolexOne_AR_8172095',
'InfolexOne_AR_8174763',
'InfolexOne_AR_8176395',
'InfolexOne_AR_8178454',
'InfolexOne_AR_8179810',
'InfolexOne_AR_8180773',
'InfolexOne_AR_8182052',
'InfolexOne_AR_8182753',
'InfolexOne_AR_8182790',
'NOVAJUS_FULL_8169670',
'NOVAJUS_FULL_8170687',
'NOVAJUS_FULL_8170931',
'NOVAJUS_FULL_8173198',
'NOVAJUS_FULL_8175147',
'NOVAJUS_FULL_8175151',
'NOVAJUS_FULL_8176141',
'NOVAJUS_FULL_8180603',
'NOVAJUS_FULL_8184177',
'NOVAJUS_FULL_8184339',
'NOVAJUS_FULL_8184525',
'NOVAJUS_FULL_8184746',
'NOVAJUS_FULL_8184932',
'NOVAJUS_FULL_8185043'
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
