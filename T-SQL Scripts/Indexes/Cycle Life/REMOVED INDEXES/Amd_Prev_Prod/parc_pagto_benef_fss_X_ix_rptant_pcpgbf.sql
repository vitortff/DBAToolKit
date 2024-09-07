USE [Amd_Prev_Prod]
GO

/****** Object:  Index [ix_rptant_pcpgbf]    Script Date: 09/16/2013 13:52:26 ******/
CREATE NONCLUSTERED INDEX [ix_rptant_pcpgbf] ON [dbo].[parc_pagto_benef_fss] 
(
	[num_idntf_rptant] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO

