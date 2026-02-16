ALTER TABLE calendar ADD hday_flag BIT;
UPDATE calendar SET hday_flag = CASE WHEN HolidayFlag = 'Y' THEN 1 ELSE 0 END;

ALTER TABLE calendar DROP COLUMN HolidayFlag;
EXEC sp_rename 'calendar.hday_flag', 'HolidayFlag', 'COLUMN';


ALTER TABLE orderheader ADD OrderDate DATE;
UPDATE orderheader SET OrderDate = cast(OrderDateTime AS DATE);