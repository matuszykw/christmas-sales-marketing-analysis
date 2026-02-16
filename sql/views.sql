CREATE OR ALTER VIEW vFactSales AS
WITH OrderTotals AS (
    SELECT
        OrderID,
        SUM(LineRevenue$) AS TotalOrderRevenue
    FROM OrderLine
    GROUP BY OrderID
)
SELECT
    ol.OrderLineID,
    ol.OrderID,
    ol.ProductID,
    ol.Qty,
    ol.UnitPrice,
    ol.LineDiscount$,
    ol.LineCost$,
    ol.LineRevenue$,
    CAST(
        ISNULL((ol.LineRevenue$ / NULLIF(ot.TotalOrderRevenue, 0)) * f.ShipCost$, 0)
    AS DECIMAL(18,2)) AS AllocatedShipCost$,
    CAST(
        (ol.LineRevenue$ - ISNULL(r.Refund$, 0))
        - CASE
            WHEN r.Disposition = 'Resell' THEN 0
            ELSE ol.LineCost$
          END
        + ISNULL(r.RestockFee$, 0)
        - ISNULL(r.ReturnShipCost$, 0)
        - ISNULL((ol.LineRevenue$ / NULLIF(ot.TotalOrderRevenue, 0)) * f.ShipCost$, 0)
    AS DECIMAL(18,2)) AS NetProfit$,
    oh.OrderDateTime,
    oh.OrderDate,
    oh.CustomerID,
    oh.ChannelID,
    ISNULL(oh.StoreID, 'Online Store') AS StoreName,
    ISNULL(oh.PromotionID, 'NOPROMO') AS PromotionID,
    oh.CouponCode,
    oh.PaymentType,
    CASE
        WHEN r.ReturnID IS NOT NULL THEN 1 ELSE 0
    END AS IsReturned,
    r.ReturnDate,
    ISNULL(r.ReasonCode, 'Not Returned') AS ReasonCode,
    r.Condition,
    ISNULL(r.Refund$, 0) AS Refund$,
    ISNULL(r.RestockFee$, 0) AS RestockFee$,
    ISNULL(r.ReturnShipCost$, 0) AS ReturnShipCost$,
    r.Disposition
FROM orderline ol
LEFT JOIN orderheader oh ON ol.OrderID = oh.OrderID
LEFT JOIN OrderTotals ot on ol.OrderID = ot.OrderID
LEFT JOIN fulfillment f on ol.OrderID = f.OrderID
LEFT JOIN returns r ON ol.OrderLineID = r.OrderLineID;


CREATE OR ALTER VIEW vFactLogistics AS
SELECT
    f.OrderID,
    WarehouseID,
    Carrier,
    ServiceLevel,
    PromisedDate,
    ShipDate,
    DeliveryDate,
    datediff(day, ShipDate, DeliveryDate) AS DeliveryTime,
    CASE
        WHEN DeliveryStatus = 'Late' THEN 1 ELSE 0
    END AS IsLate,
    datediff(day, PromisedDate, DeliveryDate) AS DaysOffset,
    ShipCost$,
    DeliveryStatus,
    ISNULL(oh.PromotionID, 'NOPROMO') AS PromotionID
FROM fulfillment f
LEFT JOIN orderheader oh ON f.OrderID = oh.OrderID;


CREATE OR ALTER VIEW vDimProduct AS
SELECT
    ProductID,
    Category,
    Subcategory,
    StandardCost,
    MSRP,
    (MSRP - StandardCost) AS TheoreticalMargin$,
    CAST((MSRP - StandardCost) / NULLIF(MSRP, 0) AS DECIMAL(18,2)) AS TheoreticalMarginPct,
    Vendor,
    SeasonalityTag,
    CASE
        WHEN MSRP < 30 THEN '$0-30'
        WHEN MSRP < 60 THEN '$30-60'
        WHEN MSRP < 90 THEN '$60-90'
        WHEN MSRP < 120 THEN '$90-120'
        WHEN MSRP < 150 THEN '$120-150'
        WHEN MSRP < 180 THEN '$150-180'
        WHEN MSRP < 210 THEN '$180-210'
        WHEN MSRP < 240 THEN '$210-240'
        WHEN MSRP < 270 THEN '$240-270'
        WHEN MSRP < 300 THEN '$270-300'
        WHEN MSRP < 330 THEN '$300-330'
        WHEN MSRP < 360 THEN '$330-360'
        WHEN MSRP < 400 THEN '$360-400'
        ELSE '$400+'
    END AS PriceRange
FROM product;


CREATE OR ALTER VIEW vDimPromotion AS
SELECT
    PromotionID,
    Name,
    CampaignType,
    StartDate,
    EndDate,
    datediff(day, StartDate, EndDate) AS PromotionDurationDays,
    TargetSegment,
    ISNULL(DiscountType, 'No Discount') AS DiscountType,
    [PlannedLift%] AS PlannedLiftPct,
    PlannedBudget
FROM promotion
UNION ALL
SELECT
    'NOPROMO',
    'No Promotion',
    'None',
    cast('1900-01-01' AS DATE),
    cast('2099-12-31' AS DATE),
    0,
    'None',
    'None',
    0.0,
    0.0