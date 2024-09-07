
/*****************************************************************************************
Script......: Desbloqueia_Agente_Travado.sql
Criado em...: 05/10/2015      
Tabela......: AGENTESLOGADOS        
        
        Esse script deve ser utilizado quando ao tentar realizar login na toolbar e 
        apresentar a mensagem de que o agente já está logado.
        Primeiro tentar reiniciar a máquina. Caso não resolva deve-se executar o script.        
       
--****************************************************************************************/




--select * from HardWare where NumeroAssociado = '3816'



use VSYSUnique
select DATAHORALOGON, * from AGENTESLOGADOS

--delete AGENTESLOGADOS where NumeroAssociado = '3816' -- vanessa
--delete AGENTESLOGADOS where NumeroAssociado = '3863' -- laila
--delete AGENTESLOGADOS where NumeroAssociado = '3862' -- patricia
--delete AGENTESLOGADOS where NumeroAssociado = '3853' -- sirleide
--delete AGENTESLOGADOS where NumeroAssociado = '3828' -- gisele
--delete AGENTESLOGADOS where NumeroAssociado = '3864' -- roseli