WITH distinctCustomers AS (
    SELECT customer_id, MIN(invoice_date) AS firstPurchaseDate
    FROM customer_invoice_data
    GROUP BY customer_id
),
-- New customers in the current month
nValue AS (
    SELECT YEAR(firstPurchaseDate) AS year, MONTH(firstPurchaseDate) AS month, COUNT(DISTINCT customer_id) AS N 
    FROM distinctCustomers
    GROUP BY YEAR(firstPurchaseDate), MONTH(firstPurchaseDate)
),
-- Customers at the end of the month
eValue AS (
    SELECT YEAR(invoice_date) AS year, MONTH(invoice_date) AS month, COUNT(DISTINCT customer_id) AS E 
    FROM customer_invoice_data
    GROUP BY YEAR(invoice_date), MONTH(invoice_date)
),
-- Calculate S as total distinct customers before the current month
sValue AS (
    SELECT me.year, me.month, COALESCE(mn.N, 0) AS N, me.E,
        (SELECT COUNT(DISTINCT customer_id) 
         FROM customer_invoice_data AS ci 
         WHERE YEAR(ci.invoice_date) < me.year OR 
             (YEAR(ci.invoice_date) = me.year AND MONTH(ci.invoice_date) < me.month)) AS S
    FROM eValue me
    LEFT JOIN nValue mn ON me.year = mn.year AND me.month = mn.month
)
SELECT year, month, E, N, S,
    CASE 
        WHEN S > 0 THEN ROUND(((E - N) * 100.0) / S, 2) -- Customer Retention Rate
        ELSE NULL -- Prevent division by zero
    END AS CRR,
    CASE 
        WHEN S > 0 THEN ROUND(100 - ((E - N) * 100.0) / S, 2) -- Customer Churn Rate
        ELSE NULL -- Prevent division by zero
    END AS CCR
FROM sValue 
ORDER BY year, month;



