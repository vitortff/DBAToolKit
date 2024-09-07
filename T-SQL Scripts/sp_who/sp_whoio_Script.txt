use master
go
if exists (select * from master.dbo.sysobjects where id = object_id('dbo.sp_whoio') )
 Drop Procedure dbo.sp_whoio
go

/*====================================================================
-- Mircea Anton Nita - 2010
-- https://www.mcpvirtualbusinesscard.com/VBCServer/Mircea/card
======================================================================*/
Create Procedure dbo.sp_whoio
 @dbname sysname = null,
 @loginame sysname = null
as

set nocount on

declare
  @retcode int
 ,@sidlow varbinary(85)
 ,@sidhigh varbinary(85)
 ,@sid1 varbinary(85)
 ,@spidlow int
 ,@spidhigh int
 ,@seldbid varchar(10)
 ,@charMaxLenLoginName varchar(24)
 ,@charMaxLenDBName varchar(24)
 ,@charMaxLenCPUTime varchar(10)
 ,@charMaxLenDiskIODelta varchar(10)
 ,@charMaxLenDiskIO varchar(10)
 ,@charMaxLenHostName varchar(24)
 ,@charMaxLenProgramName varchar(10)
 ,@charMaxLenLastBatch varchar(10)
 ,@charMaxLenCommand varchar(10)
 ,@charsidlow varchar(85)
 ,@charsidhigh varchar(85)
 ,@charspidlow varchar(11)
 ,@charspidhigh varchar(11)
 ,@command varchar(8000)

-- set defaults
set @retcode = 0
set @sidlow = convert(varbinary(85), (replicate(char(0), 85)))
set @sidhigh = convert(varbinary(85), (replicate(char(1), 85)))
set @spidlow = 0
set @spidhigh = 32767

if (@dbname is not null)
 set @seldbid = cast((select top 1 dbid from master.dbo.sysdatabases where name like '%'+@dbname+'%') as varchar(10))
else
 set @seldbid = '0'

if (@loginame is null) -- Simple default to all LoginNames.
 GOTO LABEL_PARAM

select @sid1 = null
if exists(select * from sys.syslogins where loginname = @loginame)
 select @sid1 = sid from sys.syslogins where loginname = @loginame

if (@sid1 IS NOT NULL) -- The parameter is a recognized login name.
 begin
 select @sidlow = suser_sid(@loginame)
 ,@sidhigh = suser_sid(@loginame)
 GOTO LABEL_PARAM
 end

if (lower(@loginame collate Latin1_General_CI_AS) IN ('active')) -- Special action, not sleeping.
 begin
 select @loginame = lower(@loginame collate Latin1_General_CI_AS)
 GOTO LABEL_PARAM
 end

if (patindex ('%[^0-9]%' , isnull(@loginame,'z')) = 0) -- Is a number.
 begin
 select
 @spidlow = convert(int, @loginame)
 ,@spidhigh = convert(int, @loginame)
 GOTO LABEL_PARAM
 end

raiserror(15007,-1,-1,@loginame)
select @retcode = 1
GOTO LABEL_RETURN


LABEL_PARAM:

-- Getting data over a time window to allow the io_delta metric calculation
if object_id('tempdb.dbo.#io1') is not null drop table #io1
if object_id('tempdb.dbo.#io2') is not null drop table #io2
select spid, physical_io into #io1 from master.dbo.sysprocesses with (nolock) order by physical_io desc
waitfor delay '00:00:03'
select spid, physical_io into #io2 from master.dbo.sysprocesses with (nolock) order by physical_io desc

-------------------- Capture consistent sysprocesses. -------------------

select
 sp.spid
,status
,sid
,hostname
,program_name
,cmd
,cpu
,sp.physical_io
,i2.physical_io-i1.physical_io as 'io_delta'
,blocked
,dbid
,convert(sysname, rtrim(loginame)) as loginname
,sp.spid as 'spid_sort'
, substring( convert(varchar,last_batch,111) ,6 ,5 ) + ' '
 + substring( convert(varchar,last_batch,113) ,13 ,8 ) as 'last_batch_char'

 into #tb1_sysprocesses
 from #io2 i2 join #io1 i1 on i2.spid = i1.spid join master.dbo.sysprocesses sp with (nolock) on sp.spid = i2.spid
 where i2.physical_io-i1.physical_io > 0 

if @@error <> 0
 begin
 select @retcode = @@error
 GOTO LABEL_RETURN
 end

if (@loginame in ('active'))
 delete #tb1_sysprocesses
 where lower(status) = 'sleeping'
 and upper(cmd) in (
 'AWAITING COMMAND'
 ,'LAZY WRITER'
 ,'CHECKPOINT SLEEP'
 )
 and blocked = 0
 and dbid <> @seldbid

-- Prepare to dynamically optimize column widths.
select
 @charsidlow = convert(varchar(85),@sidlow)
 ,@charsidhigh = convert(varchar(85),@sidhigh)
 ,@charspidlow = convert(varchar,@spidlow)
 ,@charspidhigh = convert(varchar,@spidhigh)

select
 @charMaxLenLoginName =
 convert( varchar
 ,isnull( max( datalength(loginname)) ,16)
 )

 ,@charMaxLenDBName =
 convert( varchar
 ,isnull( max( datalength( rtrim(convert(varchar(128),db_name(dbid))))) ,20)
 )

 ,@charMaxLenCPUTime =
 convert( varchar
 ,isnull( max( datalength( rtrim(convert(varchar(128),cpu)))) ,10)
 )

 ,@charMaxLenDiskIO =
 convert( varchar
 ,isnull( max( datalength( rtrim(convert(varchar(128),physical_io)))) ,6)
 )

 ,@charMaxLenDiskIODelta =
 convert( varchar
 ,isnull( max( datalength( rtrim(convert(varchar(128),io_delta)))) ,6)
 )

 ,@charMaxLenCommand =
 convert( varchar
 ,isnull( max( datalength( rtrim(convert(varchar(128),cmd)))) ,7)
 )

 ,@charMaxLenHostName =
 convert( varchar
 ,isnull( max( datalength( rtrim(convert(varchar(128),hostname)))) ,16)
 )

 ,@charMaxLenProgramName =
 convert( varchar
 ,isnull( max( datalength( rtrim(convert(varchar(128),program_name)))) ,11)
 )

 ,@charMaxLenLastBatch =
 convert( varchar
 ,isnull( max( datalength( rtrim(convert(varchar(128),last_batch_char)))) ,9)
 )
 from
 #tb1_sysprocesses
 where
 spid >= @spidlow
 and spid <= @spidhigh


-- Output the report.
set @command = '
SET nocount off

select
 SPID = convert(char(5),spid)

 ,Status =
 CASE lower(status)
 When ''sleeping'' Then lower(status)
 Else upper(status)
 END

 ,Login = substring(loginname,1,' + @charMaxLenLoginName + ')

 ,HostName =
 CASE hostname
 When Null Then '' .''
 When '' '' Then '' .''
 Else substring(hostname,1,' + @charMaxLenHostName + ')
 END

 ,BlkBy =
 CASE isnull(convert(char(5),blocked),''0'')
 When ''0'' Then '' .''
 Else isnull(convert(char(5),blocked),''0'')
 END

 ,DBName = substring(case when dbid = 0 then null when dbid <> 0 then db_name(dbid) end,1,' + @charMaxLenDBName + ')
 ,Command = substring(cmd,1,' + @charMaxLenCommand + ')

 ,CPUTime = substring(convert(varchar,cpu),1,' + @charMaxLenCPUTime + ')
 ,DiskIO_Total = substring(convert(varchar,physical_io),1,' + @charMaxLenDiskIO + ')
 ,DiskIO_Delta = substring(convert(varchar,io_delta),1,' + @charMaxLenDiskIODelta + ')

 ,LastBatch = substring(last_batch_char,1,' + @charMaxLenLastBatch + ')

 ,ProgramName = substring(program_name,1,' + @charMaxLenProgramName + ')
 ,SPID = convert(char(5),spid) -- Handy extra for right-scrolling users.
 from
 #tb1_sysprocesses 
 where spid > 50 -- filter out system spids
 and spid <> @@spid -- and current process spid
 and spid >= ' + @charspidlow + '
 and spid <= ' + @charspidhigh + '
'
if @seldbid > 0
 set @command = @command +
'
 and dbid = ' + @seldbid + '
'

 set @command = @command +
' order by cast(io_delta as int) desc, cast(physical_io as int) desc


SET nocount on
'
 exec (@command)


LABEL_RETURN:


if object_id('tempdb..#tb1_sysprocesses') is not null drop table #tb1_sysprocesses
if object_id('tempdb.dbo.#io1') is not null drop table #io1
if object_id('tempdb.dbo.#io2') is not null drop table #io2


return @retcode -- sp_whoio
go


if exists (select * from sysobjects 
 where id = object_id('dbo.sp_whoio') 
 and sysstat & 0xf = 4)
 grant exec on dbo.sp_whoio to public
go






