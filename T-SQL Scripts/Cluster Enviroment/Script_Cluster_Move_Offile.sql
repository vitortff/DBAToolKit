-- Move os recuros de um nó para outro
master..xp_cmdshell 'c:\WINNT\system32\cluster group <Virtual name> /moveto'

-- Coloca os recursos Offline
master..xp_cmdshell 'c:\WINNT\system32\cluster group <Virtual name> /offline'

-- Coloca os recursos Online
master..xp_cmdshell 'c:\WINNT\system32\cluster group <Virtual name> /online'

--XP_CMDSHELL 'c:\WINNT\system32\cluster.exe /?'

-- Verifica Status do Grupo
XP_CMDSHELL 'c:\WINNT\system32\cluster.exe /CLUSTER:<Cluster name> GROUP <virtual name>'
go
--Mostra o Status do Cluster
XP_CMDSHELL 'c:\WINNT\system32\cluster.exe /CLUSTER:<Cluster name> GROUP'

-- Verifica Status do Nó (Nome Físico)
XP_CMDSHELL 'c:\WINNT\system32\cluster.exe /CLUSTER:<Cluster name> NODE < nome fisico>'
go
XP_CMDSHELL 'c:\WINNT\system32\cluster.exe /CLUSTER:<Cluster name> NODE  < nome fisico>'