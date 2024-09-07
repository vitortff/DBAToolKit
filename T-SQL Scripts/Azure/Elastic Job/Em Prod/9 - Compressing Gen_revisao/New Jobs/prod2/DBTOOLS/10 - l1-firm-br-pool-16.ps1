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
$ExportToCsvPath = "$PSScriptRoot\DBTOOLS10.csv"
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
'NOVAJUS_FULL_8201548',
'NOVAJUS_FULL_8194766',
'NOVAJUS_FULL_8207442',
'NOVAJUS_FULL_8197308',
'NOVAJUS_FULL_8201602',
'NOVAJUS_FULL_8205474',
'NOVAJUS_FULL_8201519',
'NOVAJUS_FULL_8203499',
'NOVAJUS_FULL_8181546',
'NOVAJUS_FULL_8202565',
'NOVAJUS_FULL_8179506',
'NOVAJUS_FULL_8175286',
'NOVAJUS_FULL_8180538',
'NOVAJUS_FULL_8187030',
'NOVAJUS_FULL_8181880',
'NOVAJUS_FULL_8182027',
'NOVAJUS_FULL_8179727',
'NOVAJUS_FULL_8174189',
'NOVAJUS_FULL_8179672',
'NOVAJUS_FULL_8177278',
'NOVAJUS_FULL_8181973',
'NOVAJUS_FULL_8181471',
'NOVAJUS_FULL_8177305',
'NOVAJUS_FULL_8184037',
'NOVAJUS_FULL_8185059',
'NOVAJUS_FULL_8183640',
'NOVAJUS_FULL_8201877',
'NOVAJUS_FULL_8178570',
'NOVAJUS_FULL_8181664',
'NOVAJUS_FULL_8178087',
'NOVAJUS_FULL_8178936',
'NOVAJUS_FULL_8182326',
'NOVAJUS_FULL_8187127',
'NOVAJUS_FULL_8208149',
'NOVAJUS_FULL_8202568',
'NOVAJUS_FULL_8178574',
'NOVAJUS_FULL_8203590',
'NOVAJUS_FULL_8177694',
'NOVAJUS_FULL_8208195',
'NOVAJUS_FULL_8183824',
'NOVAJUS_FULL_8175240',
'NOVAJUS_FULL_8178346',
'NOVAJUS_FULL_8201582',
'NOVAJUS_FULL_8206137',
'NOVAJUS_FULL_8186958',
'NOVAJUS_FULL_8204243',
'NOVAJUS_FULL_8176754',
'NOVAJUS_FULL_8176768',
'NOVAJUS_FULL_8178451',
'NOVAJUS_FULL_8175469',
'NOVAJUS_FULL_8180250',
'NOVAJUS_FULL_8176026',
'NOVAJUS_FULL_8211523',
'NOVAJUS_FULL_8176414',
'NOVAJUS_FULL_8201429',
'NOVAJUS_FULL_8202951',
'NOVAJUS_FULL_8184352',
'NOVAJUS_FULL_8201692',
'l1_firm_br_8138776',
'NOVAJUS_FULL_8201669',
'NOVAJUS_FULL_8201079',
'NOVAJUS_FULL_8187446',
'NOVAJUS_FULL_8175292',
'NOVAJUS_FULL_8211440',
'NOVAJUS_FULL_8204113',
'NOVAJUS_FULL_8202886',
'NOVAJUS_FULL_8201959',
'NOVAJUS_FULL_8205165',
'NOVAJUS_FULL_8200205',
'NOVAJUS_FULL_8207082',
'NOVAJUS_FULL_8207166',
'NOVAJUS_FULL_8201556',
'NOVAJUS_FULL_8186710',
'NOVAJUS_FULL_8206885',
'NOVAJUS_FULL_8207197',
'NOVAJUS_FULL_8205965',
'NOVAJUS_FULL_8201699',
'NOVAJUS_FULL_8207156',
'NOVAJUS_FULL_8210352',
'NOVAJUS_FULL_8202517',
'NOVAJUS_FULL_8202855',
'NOVAJUS_FULL_8196184',
'NOVAJUS_FULL_8195013',
'NOVAJUS_FULL_8201382',
'NOVAJUS_FULL_8201087',
'NOVAJUS_FULL_8199975',
'NOVAJUS_FULL_8201082',
'NOVAJUS_FULL_8186682',
'NOVAJUS_FULL_8187078',
'NOVAJUS_FULL_8202847',
'NOVAJUS_FULL_8202334',
'NOVAJUS_FULL_8206925',
'NOVAJUS_FULL_8186941',
'NOVAJUS_FULL_8201507',
'NOVAJUS_FULL_8202653',
'NOVAJUS_FULL_8207093',
'NOVAJUS_FULL_8202386',
'NOVAJUS_FULL_8207049',
'NOVAJUS_FULL_8206131',
'NOVAJUS_FULL_8186723',
'NOVAJUS_FULL_8201472',
'NOVAJUS_FULL_8201968',
'NOVAJUS_FULL_8202201',
'NOVAJUS_FULL_8206645',
'NOVAJUS_FULL_8207078',
'NOVAJUS_FULL_8202280',
'NOVAJUS_FULL_8208463',
'NOVAJUS_FULL_8189997',
'NOVAJUS_FULL_8202833',
'NOVAJUS_FULL_8201063',
'NOVAJUS_FULL_8201494',
'NOVAJUS_FULL_8203146',
'NOVAJUS_FULL_8212232',
'NOVAJUS_FULL_8201940',
'NOVAJUS_FULL_8209260',
'NOVAJUS_FULL_8187135',
'NOVAJUS_FULL_8206878',
'NOVAJUS_FULL_8201683',
'NOVAJUS_FULL_8205862',
'NOVAJUS_FULL_8202319',
'NOVAJUS_FULL_8202884',
'NOVAJUS_FULL_8214970',
'NOVAJUS_FULL_8201993',
'NOVAJUS_FULL_8187334',
'NOVAJUS_FULL_8207347',
'NOVAJUS_FULL_8202860',
'NOVAJUS_FULL_8207249',
'NOVAJUS_FULL_8201576',
'NOVAJUS_FULL_8207264',
'NOVAJUS_FULL_8186928',
'NOVAJUS_FULL_8191338',
'NOVAJUS_FULL_8188005',
'NOVAJUS_FULL_8187018',
'NOVAJUS_FULL_8206417',
'NOVAJUS_FULL_8201533',
'NOVAJUS_FULL_8206710',
'NOVAJUS_FULL_8189254',
'NOVAJUS_FULL_8189869',
'NOVAJUS_FULL_8201841',
'NOVAJUS_FULL_8201674',
'NOVAJUS_FULL_8201605',
'NOVAJUS_FULL_8206718',
'NOVAJUS_FULL_8201597',
'NOVAJUS_FULL_8202291',
'NOVAJUS_FULL_8206521',
'NOVAJUS_FULL_8215989',
'NOVAJUS_FULL_8201204',
'NOVAJUS_FULL_8206882',
'NOVAJUS_FULL_8195215',
'NOVAJUS_FULL_8206699',
'NOVAJUS_FULL_8201531',
'NOVAJUS_FULL_8201617',
'NOVAJUS_FULL_8206288',
'NOVAJUS_FULL_8206548',
'NOVAJUS_FULL_8206796',
'NOVAJUS_FULL_8206124',
'NOVAJUS_FULL_8199733',
'NOVAJUS_FULL_8206927',
'NOVAJUS_FULL_8201093',
'NOVAJUS_FULL_8202522',
'NOVAJUS_FULL_8200603',
'NOVAJUS_FULL_8206903',
'NOVAJUS_FULL_8199918',
'NOVAJUS_FULL_8195011',
'NOVAJUS_FULL_8201364',
'NOVAJUS_FULL_8201772',
'NOVAJUS_FULL_8202858',
'NOVAJUS_FULL_8207283',
'NOVAJUS_FULL_8201375',
'NOVAJUS_FULL_8207256',
'NOVAJUS_FULL_8201380',
'NOVAJUS_FULL_8201479',
'NOVAJUS_FULL_8213285',
'NOVAJUS_FULL_8201423',
'NOVAJUS_FULL_8207426',
'NOVAJUS_FULL_8206225',
'NOVAJUS_FULL_8201112',
'NOVAJUS_FULL_8201787',
'NOVAJUS_FULL_8202821',
'NOVAJUS_FULL_8201411',
'NOVAJUS_FULL_8201415',
'NOVAJUS_FULL_8202205',
'NOVAJUS_FULL_8206533',
'NOVAJUS_FULL_8206713',
'NOVAJUS_FULL_8186740',
'NOVAJUS_FULL_8202845',
'NOVAJUS_FULL_8211971',
'NOVAJUS_FULL_8205923',
'NOVAJUS_FULL_8207086',
'NOVAJUS_FULL_8207133',
'NOVAJUS_FULL_8213835',
'NOVAJUS_FULL_8206686',
'NOVAJUS_FULL_8207322',
'NOVAJUS_FULL_8201114',
'NOVAJUS_FULL_8201972',
'NOVAJUS_FULL_8207070',
'NOVAJUS_FULL_8201525',
'NOVAJUS_FULL_8202277',
'NOVAJUS_FULL_8207160',
'NOVAJUS_FULL_8201426',
'NOVAJUS_FULL_8205858',
'NOVAJUS_FULL_8201133',
'NOVAJUS_FULL_8206198',
'NOVAJUS_FULL_8207344',
'NOVAJUS_FULL_8202227',
'NOVAJUS_FULL_8206419',
'NOVAJUS_FULL_8206929',
'NOVAJUS_FULL_8202485',
'NOVAJUS_FULL_8202756',
'NOVAJUS_FULL_8203089',
'NOVAJUS_FULL_8206716',
'NOVAJUS_FULL_8202542',
'NOVAJUS_FULL_8202146',
'NOVAJUS_FULL_8205910',
'NOVAJUS_FULL_8206075',
'NOVAJUS_FULL_8202247',
'NOVAJUS_FULL_8206629',
'NOVAJUS_FULL_8215609',
'NOVAJUS_FULL_8205878',
'NOVAJUS_FULL_8206815',
'NOVAJUS_FULL_8206835',
'NOVAJUS_FULL_8207170',
'NOVAJUS_FULL_8201418',
'NOVAJUS_FULL_8202868',
'NOVAJUS_FULL_8206641',
'NOVAJUS_FULL_8170521',
'NOVAJUS_FULL_8206023',
'NOVAJUS_FULL_8206056',
'NOVAJUS_FULL_8207178',
'NOVAJUS_FULL_8215599',
'NOVAJUS_FULL_8201356',
'NOVAJUS_FULL_8205939',
'NOVAJUS_FULL_8206003',
'NOVAJUS_FULL_8206550',
'NOVAJUS_FULL_8207269'
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
