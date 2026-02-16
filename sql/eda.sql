-- Lateness rate across different discount type
SELECT
    p.DiscountType,
    COUNT(DISTINCT f.OrderID) AS TotalOrders,
    SUM(CASE WHEN f.IsLate = 1 THEN 1 ELSE 0 END) AS LateOrders,
    CAST(SUM(CASE WHEN f.IsLate = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT f.OrderID) AS DECIMAL(5,2)) AS LatenessRate
FROM vFactLogistics f
LEFT JOIN vDimPromotion p ON f.PromotionID = p.PromotionID
GROUP BY p.DiscountType
ORDER BY LatenessRate DESC;


-- Reasons for returns
SELECT
    s.ReasonCode,
    f.IsLate,
    COUNT(*) as ReturnCount
FROM vFactSales s
LEFT JOIN vFactLogistics f ON s.OrderID = f.OrderID
WHERE s.IsReturned = 1
GROUP BY
    s.ReasonCode,
    f.IsLate
ORDER BY ReasonCode;


-- Net Profit and Unprofitable sales by discount type
SELECT
    p.DiscountType,
    sum(LineRevenue$) AS Revenue,
    sum(NetProfit$) AS UnprofitableSales
FROM vFactSales s
LEFT JOIN vDimPromotion p on s.PromotionID = p.PromotionID
WHERE 1 = 1
--     AND NetProfit$ < 0
    AND IsReturned = 0
GROUP BY p.DiscountType
ORDER BY sum(NetProfit$);


-- Number of discounts by type (where profit is <0)
SELECT
    DiscountType,
    count(*) as cnt
FROM vFactSales s
LEFT JOIN vDimPromotion p on s.PromotionID = p.PromotionID
WHERE 1 = 1
--     AND NetProfit$ < 0
    AND IsReturned = 0
GROUP BY DiscountType
ORDER BY cnt DESC;

-- Why some percentage discount lose money (discount pct > margin pct)
SELECT TOP 30
    ProductID,
    Qty,
    LineRevenue$,
    LineCost$,
    LineDiscount$,
    AllocatedShipCost$,
    NetProfit$,
    IsReturned,
    cast(round(LineDiscount$ / (LineRevenue$ + LineDiscount$), 2) AS decimal(10,2)) AS DiscountPCT
FROM vFactSales
LEFT JOIN vDimPromotion on vFactSales.PromotionID = vDimPromotion.PromotionID
WHERE 1 = 1
    AND NetProfit$ < 0
    AND DiscountType = 'Percent'
    AND IsReturned = 0
    AND ProductID IN ('P002873', 'P002754', 'P003879')
ORDER BY NetProfit$ ASC;

SELECT
    p.ProductID,
    p.MSRP,
    p.StandardCost,
    (p.MSRP - p.StandardCost) AS TheoreticalMargin,
    (p.MSRP - p.StandardCost) / p.MSRP AS MarginPct
FROM product p
WHERE p.ProductID IN ('P002873', 'P002754', 'P003879');

-- Top 10 worst products in BOGO
SELECT TOP 10
    p.ProductID,
    p.Category,
    sum(s.Qty) AS qty,
    sum(s.LineCost$) as LineCost,
    sum(s.LineRevenue$) AS LineRevenue,
    sum(s.NetProfit$) AS NetProfit,
    (sum(s.NetProfit$) / sum(s.LineRevenue$)) AS ProfitMarginPCT
FROM vFactSales s
JOIN product p on s.ProductID = p.ProductID
JOIN promotion promo ON promo.PromotionID = s.PromotionID
WHERE
    promo.DiscountType = 'BOGO'
    AND s.IsReturned = 0
GROUP BY p.ProductID, p.Category
ORDER BY NetProfit

-- Sales units with BOGO discount where item quantity is odd
SELECT
    COUNT(*)
FROM vFactSales
JOIN promotion on vFactSales.PromotionID = promotion.PromotionID
WHERE DiscountType = 'BOGO' AND qty % 2 != 0

-- AVG ship cost by discount type
SELECT
    p.DiscountType,
    AVG(f.ShipCost$)
FROM orderheader oh
JOIN promotion p on oh.PromotionID = p.PromotionID
JOIN fulfillment f on f.OrderID = oh.OrderID
GROUP BY p.DiscountType;


-- Sales by campaign type
SELECT
    CampaignType,
    sum(NetProfit$) as NetProfit
FROM vFactSales
LEFT JOIN vDimPromotion on vFactSales.PromotionID = vDimPromotion.PromotionID
GROUP BY CampaignType
ORDER BY sum(NetProfit$) DESC;

-- Number of sales by campaign type for BOGO
-- Is BOGO used only for clearance?
SELECT
    CampaignType,
    DiscountType,
    count(*)
FROM vFactSales
LEFT JOIN vDimPromotion on vFactSales.PromotionID = vDimPromotion.PromotionID
WHERE DiscountType = 'BOGO'
GROUP BY CampaignType, DiscountType
ORDER BY count(*) DESC;


SELECT
    *
FROM vFactSales
join vDimPromotion on vFactSales.PromotionID = vDimPromotion.PromotionID
WHERE DiscountType = 'Percent'
ORDER BY OrderID


SELECT
    prd.PriceRange,
    sum(CASE WHEN IsReturned = 0 THEN Qty ELSE 0 END) AS UnitsSold,
    cast((sum(NetProfit$) / sum(LineRevenue$)) * 100 as decimal(10,2)) AS ProfitMarginPCT,
    sum(NetProfit$) as NetProfit
FROM vFactSales s
LEFT JOIN vDimProduct prd on s.ProductID = prd.ProductID
LEFT JOIN vDimPromotion prm on s.PromotionID = prm.PromotionID
WHERE prm.DiscountType = 'BOGO'
GROUP BY prd.PriceRange;