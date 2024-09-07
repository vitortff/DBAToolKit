--
-- Adicionando uma coluna em todas as tabelas do database
--
 
Use DB_Mundo_1;
exec sp_MSforeachtable 'Alter Table ? Add data_da_criacao Datetime Default  getdate(); '; 
