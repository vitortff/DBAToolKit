USE [Amd_Prev_Prod]
GO

/****** Object:  Index [id_lancto_emprest_fss_001x2]    Script Date: 09/16/2013 13:50:25 ******/
CREATE NONCLUSTERED INDEX [id_lancto_emprest_fss_001x2] ON [dbo].[lancto_emprest_fss] 
(
	[sgdcodseguradora] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
GO

