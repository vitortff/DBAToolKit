--Para poder realizar o shrink em um banco de dados que está sendo replicado
EXEC sp_repldone @xactid = NULL, @xact_segno = NULL, @numtrans = 0,     @time = 0, @reset = 1

--BACKUP LOG ABACOS TO DISK='X:\ABACOS.trn' WITH COMPRESSION
DBCC SQLPERF(LOGSPACE)
