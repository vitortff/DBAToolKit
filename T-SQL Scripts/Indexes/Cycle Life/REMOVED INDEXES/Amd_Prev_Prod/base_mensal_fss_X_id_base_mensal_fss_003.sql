USE [Amd_Prev_Prod]
GO

/****** Object:  Index [id_base_mensal_fss_003]    Script Date: 09/10/2013 10:30:32 ******/
CREATE NONCLUSTERED INDEX [id_base_mensal_fss_003] ON [dbo].[base_mensal_fss] 
(
	[num_cpf_bsmens] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO

