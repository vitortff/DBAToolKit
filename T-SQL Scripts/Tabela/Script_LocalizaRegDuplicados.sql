*/ Este script permite localizar e excluir registros duplicados em uma tabela

-- Passo1: Verifica os registros duplicados
select unico,count(*)as vezes from TTT group by unico having count(unico)>1

--Passo 5: Pega o id máximo para cada registro duplicado
select max(id)as idmaximo,unico from TTT group by unico having count(unico)>1

--Passo 6: Exclui os registros duplicadfos
DELETE FROM
	p1
--SELECT * 
FROM
	TTT	 p1
INNER JOIN
	(
		SELECT
			max(id)as id,unico
		FROM
			TTT
		GROUP BY
			unico
		HAVING
			COUNT(*) > 1
	) p2
	ON(p1.unico = p2.unico
	AND p1.id <> p2.id)






