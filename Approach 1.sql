WITH customerHistory AS (
    SELECT customer_id, YEAR(invoice_date) AS year, MONTH(invoice_date) AS month, MIN(invoice_date) OVER (PARTITION BY customer_id) AS firstPurchaseDate
    FROM customer_invoice_data
),
-- Calculate the number of customers at the end of a given period (E)
eValue AS (
    SELECT year, month, COUNT(DISTINCT customer_id) AS E
    FROM customerHistory
    GROUP BY year, month
),
-- Calculate the number of customers added within the time period (N)
nValue AS (
    SELECT YEAR(firstPurchaseDate) AS year, MONTH(firstPurchaseDate) AS month, COUNT(DISTINCT customer_id) AS N,
        LAG(COUNT(DISTINCT customer_id)) OVER (ORDER BY YEAR(firstPurchaseDate), MONTH(firstPurchaseDate)) AS N1
    FROM customerHistory
    GROUP BY YEAR(firstPurchaseDate), MONTH(firstPurchaseDate)
),
-- Calculate the number of customers at the start of a given period (S)
sValue AS (
    SELECT eValue.year, eValue.month, COALESCE(nValue.N, 0) AS N, eValue.E,
        SUM(N1) OVER (ORDER BY eValue.year, eValue.month) AS S -- Use N1 from the lagged value to calculate S
    FROM  eValue
    LEFT JOIN nValue  ON eValue.year = nValue.year AND eValue.month = nValue.month
)
SELECT sValue.*, 
    ROUND(((E - N) * 100.0) / NULLIF(S, 0), 2) AS CRR, -- Customer Retention Rate (Handle potential divide by zero)
    ROUND(100 - ((E - N) * 100.0) / NULLIF(S, 0), 2) AS CCR -- Customer Churn Rate (Handle potential divide by zero)
FROM sValue 
ORDER BY year, month;





