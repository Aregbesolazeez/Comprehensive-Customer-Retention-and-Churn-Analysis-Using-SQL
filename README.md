# Customer Retention and Churn Analysis Using SQL

## Project Overview
This project explores customer retention and churn analysis using SQL, showcasing two distinct methods to calculate **Customer Retention Rate (CRR)** and **Customer Churn Rate (CCR)**. The goal is to understand customer behavior, verify consistency across different approaches, and derive actionable insights for business strategy.

## Dataset
The dataset consists of customer transaction data, including:
- `customer_id`
- `invoice_date`
- Transactional details like quantity and price

The dataset spans multiple months, allowing for a detailed, time-based analysis of customer behavior.

## Methodology

### Approach 1: Window Functions
- **Description**: This method uses SQL window function (`LAG`) to calculate new customers and track cumulative totals over time.
- **Strengths**: Efficient and straightforward, leveraging SQL’s windowing capabilities for clear and concise calculations.
- **Limitations**: Requires careful handling of cumulative values when calculating starting customers to ensure accuracy.

### Approach 2: Subquery-Based
- **Description**: This approach uses a subquery to count distinct customers up to the start of each month, ensuring precise calculation by avoiding duplicate counts across periods.
- **Strengths**: Provides a precise and direct method for calculating starting customers.
- **Limitations**: Slightly more computationally intensive due to the subquery.

## SQL Queries

### Query 1: Window Function Approach
```sql
WITH customerHistory AS (
    SELECT 
        customer_id,
        YEAR(invoice_date) AS year,
        MONTH(invoice_date) AS month,
        MIN(invoice_date) OVER (PARTITION BY customer_id) AS firstPurchaseDate
    FROM 
        customer_invoice_data
),
eValue AS (
    SELECT 
        year,
        month,
        COUNT(DISTINCT customer_id) AS E
    FROM 
        customerHistory
    GROUP BY 
        year, month
),
nValue AS (
    SELECT
        YEAR(firstPurchaseDate) AS year,
        MONTH(firstPurchaseDate) AS month,
        COUNT(DISTINCT customer_id) AS N,
        LAG(COUNT(DISTINCT customer_id)) OVER (ORDER BY YEAR(firstPurchaseDate), MONTH(firstPurchaseDate)) AS N1
    FROM 
        customerHistory
    GROUP BY
        YEAR(firstPurchaseDate),
        MONTH(firstPurchaseDate)
),
sValue AS (
    SELECT 
        eValue.year,
        eValue.month,
        COALESCE(nValue.N, 0) AS N,
        eValue.E,
        SUM(N1) OVER (ORDER BY eValue.year, eValue.month) AS S -- Using lagged value to calculate S
    FROM 
        eValue
    LEFT JOIN
        nValue 
        ON eValue.year = nValue.year AND eValue.month = nValue.month
)
SELECT 
    sValue.*, 
    ROUND(((E - N) * 100.0) / NULLIF(S, 0), 2) AS CRR, -- Customer Retention Rate
    ROUND(100 - ((E - N) * 100.0) / NULLIF(S, 0), 2) AS CCR -- Customer Churn Rate
FROM 
    sValue 
ORDER BY 
    year, month;
```


### Query 2: Subquery-Based Approach
```sql
WITH distinctCustomers AS (
    SELECT 
        customer_id,
        MIN(invoice_date) AS firstPurchaseDate
    FROM 
        customer_invoice_data
    GROUP BY 
        customer_id
),
nValue AS (
    SELECT 
        YEAR(firstPurchaseDate) AS year,
        MONTH(firstPurchaseDate) AS month,
        COUNT(DISTINCT customer_id) AS N 
    FROM 
        distinctCustomers
    GROUP BY 
        YEAR(firstPurchaseDate), MONTH(firstPurchaseDate)
),
eValue AS (
    SELECT 
        YEAR(invoice_date) AS year,
        MONTH(invoice_date) AS month,
        COUNT(DISTINCT customer_id) AS E 
    FROM 
        customer_invoice_data
    GROUP BY 
        YEAR(invoice_date), MONTH(invoice_date)
),
sValue AS (
    SELECT 
        me.year,
        me.month,
        COALESCE(mn.N, 0) AS N,
        me.E,
        (SELECT COUNT(DISTINCT customer_id) 
         FROM customer_invoice_data AS ci 
         WHERE 
             YEAR(ci.invoice_date) < me.year OR 
             (YEAR(ci.invoice_date) = me.year AND MONTH(ci.invoice_date) < me.month)) AS S
    FROM 
        eValue me
    LEFT JOIN 
        nValue mn ON me.year = mn.year AND me.month = mn.month
)
SELECT 
    year,
    month,
    E,
    N,
    S,
    CASE 
        WHEN S > 0 THEN ROUND(((E - N) * 100.0) / S, 2) -- Customer Retention Rate
        ELSE NULL -- Prevent division by zero
    END AS CRR,
    CASE 
        WHEN S > 0 THEN ROUND(100 - ((E - N) * 100.0) / S, 2) -- Customer Churn Rate
        ELSE NULL -- Prevent division by zero
    END AS CCR
FROM 
    sValue 
ORDER BY 
    year, month;
```

### Key Insights:
- Retention rates varied, with a notable dip in some months, indicating opportunities for further investigation and strategy refinement.

![image](https://github.com/user-attachments/assets/da019025-804a-48c5-89a0-4ab31e1ca5ce)

![image](https://github.com/user-attachments/assets/d252809c-0918-437b-9c05-2bc792ba081d)



