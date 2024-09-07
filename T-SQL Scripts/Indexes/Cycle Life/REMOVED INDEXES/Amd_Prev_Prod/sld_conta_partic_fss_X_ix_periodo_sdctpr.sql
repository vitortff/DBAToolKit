USE [Amd_Prev_Prod]
GO

/****** Object:  Index [ix_periodo_sdctpr]    Script Date: 09/10/2013 10:16:33 ******/
CREATE NONCLUSTERED INDEX [ix_periodo_sdctpr] ON [dbo].[sld_conta_partic_fss] 
(
	[ano_movim_sdctpr] ASC,
	[mes_movim_sdctpr] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO

