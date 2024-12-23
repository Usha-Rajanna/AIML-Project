use orders;

-- 1********************************************

SELECT CUSTOMER_ID, 
      CASE 
          when CUSTOMER_GENDER = 'F'
           THEN CONCAT('Mrs',' ', upper(CONCAT(CUSTOMER_FNAME ,' ',CUSTOMER_LNAME )))
           ELSE CONCAT('Mr',' ', upper(CONCAT(CUSTOMER_FNAME ,' ',CUSTOMER_LNAME )))
	 end AS FULL_NAME, CUSTOMER_EMAIL,CUSTOMER_CREATION_DATE,
     case
        when YEAR(CUSTOMER_CREATION_DATE) < 2005 
        THEN 'category A'
		when YEAR(CUSTOMER_CREATION_DATE)  >=2005 and YEAR(CUSTOMER_CREATION_DATE) < 2011
        THEN 'category B'
        when YEAR(CUSTOMER_CREATION_DATE) >= 2011 
        THEN 'category C'
	 end AS CUSTOMER’s_CATEGORY
     From online_customer;
  
  -- 2

	SELECT p.PRODUCT_ID, p.PRODUCT_DESC, p.PRODUCT_QUANTITY_AVAIL, p.PRODUCT_PRICE, 
      (p.PRODUCT_QUANTITY_AVAIL * p.PRODUCT_PRICE) AS INVENTRY,
      CASE
       when PRODUCT_PRICE > 20000 
       THEN  (PRODUCT_PRICE-(PRODUCT_PRICE*0.20))
	   when PRODUCT_PRICE > 10000 
       then (PRODUCT_PRICE-(PRODUCT_PRICE*0.15))
	   when PRODUCT_PRICE <= 10000 
       then (PRODUCT_PRICE-(PRODUCT_PRICE*0.10))
       end AS NEW_PRICE
	  FROM product AS p
    LEFT JOIN order_items AS ot ON ot.PRODUCT_ID = p.PRODUCT_ID  
	WHERE ot.PRODUCT_ID IS NULL;
  
  -- 3

SELECT  PC.PRODUCT_CLASS_CODE, PC.PRODUCT_CLASS_DESC,
COUNT(PC.PRODUCT_CLASS_DESC),
SUM((P.PRODUCT_QUANTITY_AVAIL * P.PRODUCT_PRICE)) AS INVENTORY_VALUE
FROM   product P
   INNER JOIN
product_class PC ON P.PRODUCT_CLASS_CODE = PC.PRODUCT_CLASS_CODE
GROUP BY PC.PRODUCT_CLASS_DESC , PC.PRODUCT_CLASS_CODE
HAVING INVENTORY_VALUE > 100000
Order by inventory_value DESC;

-- 4

SELECT c.CUSTOMER_ID, c.CUSTOMER_EMAIL, concat(c.CUSTOMER_FNAME,' ',c.CUSTOMER_LNAME) AS FULL_NAME, 
   c.CUSTOMER_PHONE,a.COUNTRY
FROM   online_customer c ,address a
WHERE  EXISTS (SELECT CUSTOMER_ID
               FROM   order_header oh
               WHERE  c.CUSTOMER_ID = oh.CUSTOMER_ID
                 AND  oh.ORDER_STATUS = 'Cancelled')
  AND  NOT EXISTS (SELECT  CUSTOMER_ID
               FROM   order_header oh
               WHERE  c.CUSTOMER_ID = oh.CUSTOMER_ID
                     AND  oh.ORDER_STATUS <> 'Cancelled')
                     AND c.ADDRESS_ID=a.ADDRESS_ID;

-- 5

SELECT
    s.SHIPPER_NAME,
    a.CITY AS catering_city,
    COUNT(DISTINCT oc.CUSTOMER_ID) AS num_customers,
    COUNT(DISTINCT oi.ORDER_ID) AS num_consignments
FROM
    shipper s
JOIN
    order_header oh ON s.SHIPPER_ID = oh.SHIPPER_ID
JOIN
   online_customer oc on oh.CUSTOMER_ID=oc.CUSTOMER_ID
JOIN
    address a ON oc.ADDRESS_ID = a.ADDRESS_ID
JOIN
    order_items oi ON oh.ORDER_ID = oi.ORDER_ID
WHERE
    s.SHIPPER_NAME = 'DHL'
GROUP BY
    s.SHIPPER_NAME, a.CITY
ORDER BY
    catering_city;

-- 6
SELECT
    p.PRODUCT_ID,
    p.PRODUCT_DESC,
    p.PRODUCT_QUANTITY_AVAIL,
    COALESCE(oi.quantity_sold, 0) AS quantity_sold,
    CASE
        WHEN pc.PRODUCT_CLASS_DESC IN ('Electronics', 'Computer') THEN
            CASE
                WHEN COALESCE(oi.quantity_sold, 0) = 0 THEN 'No Sales in past, give discount to reduce inventory'
                WHEN p.PRODUCT_QUANTITY_AVAIL < 0.1 * COALESCE(oi.quantity_sold, 0) THEN 'Low inventory, need to add inventory'
                WHEN p.PRODUCT_QUANTITY_AVAIL < 0.5 * COALESCE(oi.quantity_sold, 0) THEN 'Medium inventory, need to add some inventory'
                ELSE 'Sufficient inventory'
            END
        WHEN pc.PRODUCT_CLASS_DESC IN ('Mobiles', 'Watches') THEN
            CASE
                WHEN COALESCE(oi.quantity_sold, 0) = 0 THEN 'No Sales in past, give discount to reduce inventory'
                WHEN p.PRODUCT_QUANTITY_AVAIL < 0.2 * COALESCE(oi.quantity_sold, 0) THEN 'Low inventory, need to add inventory'
                WHEN p.PRODUCT_QUANTITY_AVAIL < 0.6 * COALESCE(oi.quantity_sold, 0) THEN 'Medium inventory, need to add some inventory'
                ELSE 'Sufficient inventory'
            END
        ELSE
            CASE
                WHEN COALESCE(oi.quantity_sold, 0) = 0 THEN 'No Sales in past, give discount to reduce inventory'
                WHEN p.PRODUCT_QUANTITY_AVAIL < 0.3 * COALESCE(oi.quantity_sold, 0) THEN 'Low inventory, need to add inventory'
                WHEN p.PRODUCT_QUANTITY_AVAIL < 0.7 * COALESCE(oi.quantity_sold, 0) THEN 'Medium inventory, need to add some inventory'
                ELSE 'Sufficient inventory'
            END
    END AS inventory_status
FROM
    product p
JOIN
    product_class pc ON p.PRODUCT_CLASS_CODE = pc.PRODUCT_CLASS_CODE
LEFT JOIN (
    SELECT
        PRODUCT_ID,
        SUM(PRODUCT_QUANTITY) AS quantity_sold
    FROM
        order_items
    GROUP BY
        PRODUCT_ID
) oi ON p.PRODUCT_ID = oi.PRODUCT_ID;


-- 7

SELECT o.ORDER_ID, MAX(total_order_volume) AS max_order_volume
FROM (
    SELECT oi.ORDER_ID, SUM(p.PRODUCT_QUANTITY_AVAIL * oi.PRODUCT_QUANTITY) AS total_order_volume
    FROM order_items oi
    JOIN product p ON oi.PRODUCT_ID = p.PRODUCT_ID
    WHERE oi.ORDER_ID IN (
        SELECT ORDER_ID
        FROM carton c
        WHERE c.CARTON_ID = 10
    )
    GROUP BY oi.ORDER_ID
) AS o
GROUP BY o.ORDER_ID
ORDER BY max_order_volume DESC
LIMIT 1;

-- 8

SELECT 
    oc.CUSTOMER_ID,
    CONCAT(oc.CUSTOMER_FNAME, ' ', oc.CUSTOMER_LNAME) AS customer_full_name,
    SUM(oi.PRODUCT_QUANTITY) AS total_quantity,
    SUM(oi.PRODUCT_QUANTITY * p.PRODUCT_PRICE) AS total_value
FROM 
    online_customer oc
JOIN 
    order_header oh ON oc.CUSTOMER_ID = oh.CUSTOMER_ID
JOIN 
    order_items oi ON oh.ORDER_ID = oi.ORDER_ID
JOIN 
    product p ON oi.PRODUCT_ID = p.PRODUCT_ID
WHERE 
    oh.PAYMENT_MODE = 'Cash'
    AND oc.CUSTOMER_LNAME LIKE 'G%'
GROUP BY 
    oc.CUSTOMER_ID, oc.CUSTOMER_FNAME, oc.CUSTOMER_LNAME
ORDER BY 
    oc.CUSTOMER_ID;
    
-- 9th question
    
SELECT
    p.PRODUCT_ID,
    p.PRODUCT_DESC,
    SUM(oi.PRODUCT_QUANTITY) AS tot_qty
FROM
    product p
JOIN
    order_items oi ON p.PRODUCT_ID = oi.PRODUCT_ID
JOIN (
    SELECT DISTINCT oh.ORDER_ID
    FROM
        order_header oh
    JOIN
        online_customer oc ON oh.CUSTOMER_ID = oc.CUSTOMER_ID
	join
      address a on oc.ADDRESS_ID=a.ADDRESS_ID
    WHERE
        a.CITY NOT IN ('Bangalore', 'New Delhi')
) subq ON oi.ORDER_ID = subq.ORDER_ID
WHERE
    p.PRODUCT_ID != 201  
GROUP BY
    p.PRODUCT_ID, p.PRODUCT_DESC
ORDER BY
    tot_qty DESC;
    
    
    
   -- 10 answer
   
   SELECT
    distinct oh.ORDER_ID,
    oh.CUSTOMER_ID,
    CONCAT(oc.CUSTOMER_FNAME, ' ', oc.CUSTOMER_LNAME) AS customer_fullname,
    SUM(oi.PRODUCT_QUANTITY) AS total_quantity
FROM
    order_header oh
JOIN
    online_customer oc ON oh.CUSTOMER_ID = oc.CUSTOMER_ID
JOIN
    order_items oi ON oh.ORDER_ID = oi.ORDER_ID
JOIN
    address a ON oc.ADDRESS_ID = a.ADDRESS_ID
WHERE
    oh.ORDER_ID % 2 = 0  
    AND LEFT(a.PINCODE, 1) <> '5' 
GROUP BY
    oh.ORDER_ID, oh.CUSTOMER_ID, oc.CUSTOMER_FNAME, oc.CUSTOMER_LNAME
ORDER BY
    oh.ORDER_ID;

 
 

 


 

 
 




