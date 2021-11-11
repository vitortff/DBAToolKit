SELECT TOP 100 A.Name,
               L.[ItemPath],
  MAX(l.TimeStart) AS [LastRun],
               AVG(l.TimeDataRetrieval + l.TimeProcessing + l.TimeRendering) / 1000.0 [AverageExecutionTimeSeconds],
               SUM(l.TimeDataRetrieval + l.TimeProcessing + l.TimeRendering) / 1000.0 [TotalExecutionTimeSeconds],
               SUM(l.TimeDataRetrieval + l.TimeProcessing + l.TimeRendering) / 1000.0 / 60 [TotalExecutionTimeMinutes],
               COUNT(*) TimesRun
FROM [Catalog] A
    LEFT JOIN ExecutionLog3 L ON A.[Path] = L.ItemPath AND L.RequestType = 'Interactive' AND L.ItemAction LIKE 'Render%'

WHERE
    RequestType = 'Interactive'
    AND ItemAction LIKE 'Render%'
GROUP BY A.Name,
         A.[Path],
         l.InstanceName,
l.ItemPath
HAVING AVG(l.TimeDataRetrieval + l.TimeProcessing + l.TimeRendering) / 1000.0 > 1
ORDER BY AVG(l.TimeDataRetrieval + l.TimeProcessing + l.TimeRendering) DESC;