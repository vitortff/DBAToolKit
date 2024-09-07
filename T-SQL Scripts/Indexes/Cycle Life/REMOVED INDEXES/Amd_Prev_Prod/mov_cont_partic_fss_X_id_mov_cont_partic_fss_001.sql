USE [Amd_Prev_Prod]
GO

/****** Object:  Index [id_mov_cont_partic_fss_001]    Script Date: 11/08/2013 13:11:58 ******/
CREATE NONCLUSTERED INDEX [id_mov_cont_partic_fss_001] ON [dbo].[mov_cont_partic_fss] 
(
	[ano_cicloctb_mvcpr] ASC,
	[mes_cicloctb_mvcpr] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO

