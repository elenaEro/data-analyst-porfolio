SELECT COUNT(*) #all rows 8000
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.mql`;

SELECT mql_id, COUNT(*) #are there any duplicates? no
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.mql`
GROUP BY mql_id
HAVING COUNT(*) >1; 

# check table for null values 60 in origin_nulls
SELECT
  SUM(CASE WHEN mql_id IS NULL THEN 1 ELSE 0 END) as mql_nulls,
  SUM(CASE WHEN first_contact_date IS NULL THEN 1 ELSE 0 END) as first_contact_date_nulls,
  SUM(CASE WHEN landing_page_id IS NULL THEN 1 ELSE 0 END) as landing_page_id_nulls,
  SUM(CASE WHEN origin IS NULL THEN 1 ELSE 0 END) as origin_nulls
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.mql`;
 
SELECT DISTINCT(origin) #check all the values, they include unknown, other, other_publicities, direct, etc
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.mql`;

#replace nulls with unknown and other with other_publicities
UPDATE `project-f1e6afa5-5311-4b6e-94e.ecom.mql`
SET origin = CASE 
      WHEN origin IS NULL THEN 'unknown'
      WHEN origin = 'other' THEN 'other_publicities'
      ELSE origin
END
WHERE TRUE;

SELECT DISTINCT(origin)
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.mql`;

#save a new version of table with casting date clumn from string to date
CREATE or REPLACE TABLE `project-f1e6afa5-5311-4b6e-94e.ecom.mql` as
SELECT * EXCEPT(first_contact_date),
PARSE_DATE('%Y-%m-%d', first_contact_date) AS first_contact_date
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.mql`;

SELECT first_contact_date
FROM `project-f1e6afa5-5311-4b6e-94e.ecom.mql`
LIMIT 5;

