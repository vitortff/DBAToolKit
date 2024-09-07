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
'NOVAJUS_FULL_8190250'
'NOVAJUS_FULL_8192142'
'NOVAJUS_FULL_8193875'
'NOVAJUS_FULL_8194574'
'NOVAJUS_FULL_8193808'
'NOVAJUS_FULL_8202713'
'NOVAJUS_FULL_8208978'
'NOVAJUS_FULL_8199001'
'NOVAJUS_FULL_8196351'
'NOVAJUS_FULL_8188710'
'InfolexOne_AR_8168531'
'NOVAJUS_FULL_8193031'
'NOVAJUS_FULL_8178666'
'NOVAJUS_FULL_8201896'
'NOVAJUS_FULL_8206702'
'NOVAJUS_FULL_8183595'
'NOVAJUS_FULL_8185709'
'NOVAJUS_FULL_8191668'
'InfolexOne_AR_8178534'
'InfolexOne_AR_8190754'
'NOVAJUS_FULL_8180556'
'NOVAJUS_FULL_8190806'
'NOVAJUS_FULL_8184512'
'NOVAJUS_FULL_8180963'
'NOVAJUS_FULL_8197141'
'NOVAJUS_FULL_8204440'
'InfolexOne_AR_8171433'
'NOVAJUS_FULL_8202039'
'NOVAJUS_FULL_8194462'
'NOVAJUS_FULL_8211429'
'NOVAJUS_FULL_8186694'
'NOVAJUS_FULL_8200787'
'NOVAJUS_FULL_8195809'
'NOVAJUS_FULL_8199649'
'NOVAJUS_FULL_8201024'
'NOVAJUS_FULL_8189315'
'NOVAJUS_FULL_8196230'
'NOVAJUS_FULL_8178080'
'NOVAJUS_FULL_8178659'
'NOVAJUS_FULL_8177792'
'NOVAJUS_FULL_8204515'
'NOVAJUS_FULL_8190414'
'NOVAJUS_FULL_8181506'
'NOVAJUS_FULL_8206517'
'NOVAJUS_FULL_8185417'
'NOVAJUS_FULL_8207393'
'NOVAJUS_FULL_8166863'
'NOVAJUS_FULL_8201904'
'NOVAJUS_FULL_8205575'
'NOVAJUS_FULL_8202225'
'NOVAJUS_FULL_8185434'
'NOVAJUS_FULL_8198521'
'NOVAJUS_FULL_8207129'
'InfolexOne_AR_8178434'
'NOVAJUS_FULL_8211571'
'NOVAJUS_FULL_8180536'
'NOVAJUS_FULL_8205463'
'NOVAJUS_FULL_8179266'
'InfolexOne_AR_8184104'
'NOVAJUS_FULL_8203400'
'NOVAJUS_FULL_8186507'
'NOVAJUS_FULL_8207553'
'NOVAJUS_FULL_8196072'
'l1_firm_br_8126281'
'NOVAJUS_FULL_8178695'
'NOVAJUS_FULL_8201633'
'NOVAJUS_FULL_8211646'
'NOVAJUS_FULL_8205309'
'NOVAJUS_FULL_8204074'
'NOVAJUS_FULL_8209181'
'NOVAJUS_FULL_8196425'
'NOVAJUS_FULL_8185532'
'InfolexOne_AR_8184733'
'NOVAJUS_FULL_8201793'
'NOVAJUS_FULL_8210119'
'InfolexOne_AR_8178917'
'NOVAJUS_FULL_8182855'
'NOVAJUS_FULL_8207153'
'NOVAJUS_FULL_8200294'
'NOVAJUS_FULL_8174459'
'NOVAJUS_FULL_8211347'
'NOVAJUS_FULL_8197472'
'NOVAJUS_FULL_8211609'
'InfolexOne_AR_8165334'
'NOVAJUS_FULL_8211944'
'NOVAJUS_FULL_8179787'
'NOVAJUS_FULL_8200046'
'InfolexOne_AR_8166009'
'NOVAJUS_FULL_8183410'
'NOVAJUS_FULL_8178475'
'NOVAJUS_FULL_8183159'
'InfolexOne_AR_8169150'
'NOVAJUS_FULL_8203472'
'NOVAJUS_FULL_8184432'
'InfolexOne_AR_8187970'
'NOVAJUS_FULL_8185625'
'NOVAJUS_FULL_8195674'
'NOVAJUS_FULL_8211777'
'NOVAJUS_FULL_8205941'
'NOVAJUS_FULL_8209178'
'NOVAJUS_FULL_8209937'
'NOVAJUS_FULL_8202052'
'NOVAJUS_FULL_8195660'
'NOVAJUS_FULL_8211887'
'NOVAJUS_FULL_8211899'
'NOVAJUS_FULL_8205072'
'NOVAJUS_FULL_8195855'
'NOVAJUS_FULL_8210635'
'NOVAJUS_FULL_8202980'
'NOVAJUS_FULL_8209949'
'NOVAJUS_FULL_8177474'
'NOVAJUS_FULL_8202864'
'NOVAJUS_FULL_8205896'
'NOVAJUS_FULL_8211678'
'NOVAJUS_FULL_8211960'
'NOVAJUS_FULL_8211910'
'InfolexOne_AR_8185010'
'NOVAJUS_FULL_8185177'
'NOVAJUS_FULL_8198255'
'NOVAJUS_FULL_8176881'
'NOVAJUS_FULL_8185657'
'NOVAJUS_FULL_8176848'
'NOVAJUS_FULL_8198321'
'NOVAJUS_FULL_8209213'
'NOVAJUS_FULL_8181240'
'NOVAJUS_FULL_8179045'
'NOVAJUS_FULL_8213091'
'NOVAJUS_FULL_8197389'
'NOVAJUS_FULL_8209394'
'NOVAJUS_FULL_8211617'
'NOVAJUS_FULL_8209384'
'InfolexOne_AR_8186796'
'NOVAJUS_FULL_8171380'
'NOVAJUS_FULL_8178315'
'NOVAJUS_FULL_8178635'
'NOVAJUS_FULL_8209500'
'NOVAJUS_FULL_8210390'
'InfolexOne_AR_8184391'
'NOVAJUS_FULL_8183997'
'NOVAJUS_FULL_8195680'
'NOVAJUS_FULL_8179904'
'NOVAJUS_FULL_8184401'
'NOVAJUS_FULL_8211921'
'NOVAJUS_FULL_8195843'
'InfolexOne_AR_8185578'
'NOVAJUS_FULL_8209432'
'NOVAJUS_FULL_8209680'
'NOVAJUS_FULL_8204124'
'NOVAJUS_FULL_8211671'
'InfolexOne_AR_8185936'
'InfolexOne_AR_8189090'
'NOVAJUS_FULL_8209457'
'NOVAJUS_FULL_8201136'
'NOVAJUS_FULL_8175259'
'NOVAJUS_FULL_8179571'
'NOVAJUS_FULL_8178952'
'NOVAJUS_FULL_8208895'
'NOVAJUS_FULL_8209650'
'NOVAJUS_FULL_8195878'
'NOVAJUS_FULL_8196038'
'InfolexOne_AR_8185006'
'NOVAJUS_FULL_8178502'
'NOVAJUS_FULL_8175158'
'InfolexOne_AR_8187265'
'NOVAJUS_FULL_8212089'
'NOVAJUS_FULL_8211590'
'NOVAJUS_FULL_8211958'
'NOVAJUS_FULL_8195906'
'NOVAJUS_FULL_8211789'
'NOVAJUS_FULL_8181476'
'NOVAJUS_FULL_8196056'
'NOVAJUS_FULL_8195834'
'NOVAJUS_FULL_8211780'
'NOVAJUS_FULL_8212031'
'NOVAJUS_FULL_8211947'
'NOVAJUS_FULL_8195515'
'NOVAJUS_FULL_8195917'
'NOVAJUS_FULL_8211356'
'NOVAJUS_FULL_8211390'
'NOVAJUS_FULL_8176750'
'NOVAJUS_FULL_8195892'
'InfolexOne_AR_8189130'
'NOVAJUS_FULL_8180814'
'NOVAJUS_FULL_8211447'
'NOVAJUS_FULL_8212053'
'NOVAJUS_FULL_8175773'
'NOVAJUS_FULL_8195545'
'InfolexOne_AR_8185049'
'NOVAJUS_FULL_8212060'
'NOVAJUS_FULL_8196052'
'NOVAJUS_FULL_8195979'
'NOVAJUS_FULL_8211420'
'NOVAJUS_FULL_8211733'
'InfolexOne_AR_8184385'
'InfolexOne_AR_8191075'
'InfolexOne_AR_8185039'
'InfolexOne_AR_8191026'
'NOVAJUS_FULL_8196034'
'InfolexOne_AR_8185035'
'InfolexOne_AR_8188415'
'NOVAJUS_FULL_8211950'
'InfolexOne_AR_8188213'
'InfolexOne_AR_8185680'
'NOVAJUS_FULL_8195528'
'InfolexOne_AR_8184225'
'InfolexOne_AR_8184601'
'InfolexOne_AR_8184757'
'InfolexOne_AR_8184776'
'InfolexOne_AR_8185031'
'InfolexOne_AR_8185360'
'InfolexOne_AR_8186438'
'InfolexOne_AR_8187380'
'NOVAJUS_FULL_8195900'
'InfolexOne_AR_8186939'
'InfolexOne_AR_8191000'
'InfolexOne_AR_8191268'
'NOVAJUS_FULL_8195612'
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
