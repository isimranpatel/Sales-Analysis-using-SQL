-- Total number of sales and total quantity sold
SELECT 
    COUNT(*) AS Total_Sales, 
    SUM(s.quant) AS Total_Sold_Quantity 
FROM 
    sales s;

-- Customer-wise sold product and quantity
SELECT 
    s.cust, 
    s.prod, 
    SUM(s.quant) AS total_quantity
FROM 
    sales s 
GROUP BY 
    s.cust, s.prod;

-- Customer and product partitioned row numbers, total, and average quantities
SELECT 
    s.cust, 
    s.prod, 
    s.state,
    ROW_NUMBER() OVER (PARTITION BY s.cust, s.prod) AS row_num,
    SUM(s.quant) OVER (PARTITION BY s.cust, s.prod) AS total_quantity,
    AVG(s.quant) OVER (PARTITION BY s.cust, s.prod) AS avg_quantity
FROM 
    sales s;

-- Maximum, minimum, and average sales quantities by product
WITH S_DATA AS (
    SELECT 
        s.prod, 
        MAX(s.quant) AS max_quantity, 
        MIN(s.quant) AS min_quantity, 
        AVG(s.quant) AS avg_quantity 
    FROM 
        sales s 
    GROUP BY 
        s.prod
),
MAX_DATA AS (
    SELECT 
        sd.prod, 
        sd.max_quantity, 
        s1.cust AS max_cust,  
        s1.date AS max_date,  
        s1.state AS state, 
        sd.avg_quantity
    FROM 
        sales s1
    JOIN 
        S_DATA sd ON s1.prod = sd.prod AND s1.quant = sd.max_quantity
),
MIN_DATA AS (
    SELECT 
        sd.prod, 
        sd.min_quantity, 
        s1.cust AS min_cust,  
        s1.date AS min_date,  
        s1.state AS state 
    FROM 
        sales s1
    JOIN 
        S_DATA sd ON s1.prod = sd.prod AND s1.quant = sd.min_quantity
)
SELECT 
    m1.prod AS product, 
    m1.max_quantity, 
    m1.max_cust, 
    m1.max_date, 
    m1.state, 
    m2.min_quantity, 
    m2.min_cust, 
    m2.min_date, 
    m2.state, 
    m1.avg_quantity 
FROM 
    MAX_DATA m1
JOIN 
    MIN_DATA m2 ON m1.prod = m2.prod;

-- Quarterly sales quantities and yearly statistics by customer and product
WITH SQ1_DATA AS (
    SELECT  
        s.cust, 
        s.prod, 
        s.month, 
        SUM(s.quant) AS total_q1 
    FROM 
        sales s 
    GROUP BY 
        s.cust, s.prod, s.month 
    HAVING s.month IN (1, 2, 3)
),
SQ2_DATA AS (
    SELECT  
        s.cust, 
        s.prod, 
        s.month, 
        SUM(s.quant) AS total_q2 
    FROM 
        sales s 
    GROUP BY 
        s.cust, s.prod, s.month 
    HAVING s.month IN (4, 5, 6)
),
SQ3_DATA AS (
    SELECT  
        s.cust, 
        s.prod, 
        s.month, 
        SUM(s.quant) AS total_q3 
    FROM 
        sales s 
    GROUP BY 
        s.cust, s.prod, s.month 
    HAVING s.month IN (7, 8, 9)
),
SQ4_DATA AS (
    SELECT  
        s.cust, 
        s.prod, 
        s.month, 
        SUM(s.quant) AS total_q4 
    FROM 
        sales s 
    GROUP BY 
        s.cust, s.prod, s.month 
    HAVING s.month IN (10, 11, 12)
),
Q1 AS (
    SELECT 
        cust, 
        prod, 
        SUM(total_q1) AS q1_quantity 
    FROM 
        SQ1_DATA 
    GROUP BY 
        cust, prod
),
Q2 AS (
    SELECT 
        cust, 
        prod, 
        SUM(total_q2) AS q2_quantity 
    FROM 
        SQ2_DATA 
    GROUP BY 
        cust, prod
),
Q3 AS (
    SELECT 
        cust, 
        prod, 
        SUM(total_q3) AS q3_quantity 
    FROM 
        SQ3_DATA 
    GROUP BY 
        cust, prod
),
Q4 AS (
    SELECT 
        cust, 
        prod, 
        SUM(total_q4) AS q4_quantity 
    FROM 
        SQ4_DATA 
    GROUP BY 
        cust, prod
),
S_DATA AS (
    SELECT 
        s.cust, 
        s.prod, 
        SUM(s.quant) AS total_quantity, 
        AVG(s.quant) AS avg_quantity, 
        COUNT(s.quant) AS count_quantity  
    FROM 
        sales s 
    GROUP BY 
        s.cust, s.prod
)
SELECT 
    q1.cust AS customer, 
    q1.prod AS product, 
    q1.q1_quantity AS q1_total, 
    q2.q2_quantity AS q2_total, 
    q3.q3_quantity AS q3_total, 
    q4.q4_quantity AS q4_total, 
    sd.avg_quantity, 
    sd.total_quantity, 
    sd.count_quantity 
FROM 
    Q1 q1
JOIN 
    Q2 q2 ON q1.cust = q2.cust AND q1.prod = q2.prod
JOIN 
    Q3 q3 ON q2.cust = q3.cust AND q2.prod = q3.prod
JOIN 
    Q4 q4 ON q3.cust = q4.cust AND q3.prod = q4.prod
JOIN 
    S_DATA sd ON q4.cust = sd.cust AND q4.prod = sd.prod;

-- Calculate percentage contribution and identify 75% purchase month
WITH TOT_DATA AS (
    SELECT 
        s.cust, 
        s.prod,  
        SUM(s.quant) AS total_quantity 
    FROM 
        sales s
    GROUP BY 
        s.cust, prod
),
MONTHLY_DATA AS (
    SELECT 
        s.cust, 
        s.prod, 
        s.month, 
        SUM(s.quant) AS monthly_total 
    FROM 
        sales s	
    GROUP BY 
        s.cust, s.prod, s.month
),
PER_DATA AS (
    SELECT 
        m1.cust, 
        m1.prod, 
        m1.month, 
        (m1.monthly_total * 100) / t1.total_quantity AS percentage 
    FROM 
        MONTHLY_DATA m1
    JOIN 
        TOT_DATA t1 ON m1.cust = t1.cust AND m1.prod = t1.prod
),
UPPER_DATA AS (
    SELECT 
        p1.cust, 
        p1.prod, 
        p1.month, 
        SUM(p2.percentage) AS cumulative_percentage
    FROM 
        PER_DATA p1
    JOIN 
        PER_DATA p2 ON p1.cust = p2.cust AND p1.prod = p2.prod AND p1.month >= p2.month
    GROUP BY 
        p1.cust, p1.prod, p1.month
    HAVING 
        SUM(p2.percentage) >= 75
)
SELECT 
    u.cust AS customer, 
    u.prod AS product, 
    MIN(u.month) AS "75% Purchased by Month"
FROM 
    UPPER_DATA u
GROUP BY 
    u.cust, u.prod;
