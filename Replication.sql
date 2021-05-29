--Check und commands
USE DISTRIBUTION
GO
EXECUTE sp_replmonitorsubscriptionpendingcmds  
  @publisher ='publisher', -- Put publisher server name here
  @publisher_db = 'publisher_db', -- Put publisher database name here
  @publication ='publication',  -- Put publication name here
  @subscriber ='subscriber', -- Put subscriber server name here
  @subscriber_db ='subscriber_db', -- Put subscriber database name here
  @subscription_type ='1' -- 0 = push and 1 = pull

--REINITIALIZE ONE ARTICLE
1. First, we turn off @allow_anonymous and @immediate_sync on the publication by doing the following:
EXEC sp_changepublication
@publication = ‘testpublication’,
@property = N’allow_anonymous’,
@value = ‘false’
GO

EXEC sp_changepublication
@publication = ‘testpublication’,
@property = N’immediate_sync’,
@value = ‘false’
GO

2. Then, we drop the article from the subscription.
EXEC sp_dropsubscription
@publication = ‘testpublication’,
@subscriber = ‘subscriber_name’,
@article = ‘article_we_want_to_change’

3. Next, we want to force an invalidate of the snapshot.
EXEC sp_droparticle
@publication = ‘testpublication’,
@article = ‘article_we_want_to_change’,
@force_invalidate_snapshot = 1

4. Now we can change the schema of the article we just removed from the subscription.

5. Then, we add the article we want to change back to the publication.
EXEC sp_addarticle
@publication = ‘testpublication’,
@article = ‘article_we_want_to_change’,
@source_object = ‘article_we_want_to_change’,
@force_invalidate_snapshot = 1

6. We will then want to refresh the subscription.
EXEC sp_refreshsubscriptions @publication = ‘testpublication’

7. Next we can start our snapshot agent which will snapshot only the article that we made changes to.

8. Next re-add the @immediate_sync and @allow_anonymous.
EXEC sp_changepublication
@publication = ‘testpublication’,
@property = N’immediate_sync’,
@value = ‘true’
GO

EXEC sp_changepublication
@publication = ‘testpublication’,
@property = N’allow_anonymous’,
@value = ‘true’
GO



--Check unsubscriber commands
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
GO 

SELECT
    a.publisher_db,
    a.article,
    ds.article_id,
    ds.UndelivCmdsInDistDB,
    ds.DelivCmdsInDistDB,
    CASE WHEN md.[status] = 1 THEN 'Started'
         WHEN md.[status] = 2 THEN 'Succeeded'
         WHEN md.[status] = 3 THEN 'In Progress'
         WHEN md.[status] = 4 THEN 'Idle'
         WHEN md.[status] = 5 THEN 'Retrying'
         WHEN md.[status] = 6 THEN 'Failed'
         ELSE 'Other'
    END [Status],
    CASE WHEN md.warning = 0 THEN 'OK'
         WHEN md.warning = 1 THEN 'Expired'
         WHEN md.warning = 2 THEN 'Latency'
         ELSE 'OTHER'
    END [Warnings],
    md.cur_latency / 60.0 / 60.0 [Latency (min.)] FROM
    Distribution.dbo.MSdistribution_status ds JOIN 
    Distribution.dbo.MSarticles a
    ON a.article_id = ds.article_id
JOIN 
    Distribution.dbo.MSreplication_monitordata md
    ON md.agent_id = ds.agent_id
WHERE
    UndelivCmdsInDistDB > 0
    AND a.publisher_db = 'YOUR PUBLISHED DATABASE'

ORDER BY
    a.publisher_db,
    UndelivCmdsInDistDB DESC

--Check Article List
SELECT 
  msp.publication AS PublicationName,
  msa.publisher_db AS DatabaseName,
  msa.article AS ArticleName,
  msa.source_owner AS SchemaName,
  msa.source_object AS TableName
FROM distribution.dbo.MSarticles msa
JOIN distribution.dbo.MSpublications msp ON msa.publication_id = msp.publication_id
ORDER BY 
  msp.publication, 
  msa.article