-- AdditionalViews.sql
-- This file contains additional views for analyzing crime data in CRMS

-- View 4: Officer Performance Statistics
CREATE OR REPLACE VIEW Officer_Performance_Statistics AS
SELECT 
    o.Officer_ID,
    o.Firstname || ' ' || o.Lastname AS Officer_Name,
    o.Nationality,
    COUNT(c.C_ID) AS Total_Cases_Assigned,
    COUNT(CASE WHEN cs.Date_closed IS NOT NULL THEN 1 END) AS Cases_Closed,
    COUNT(CASE WHEN cs.Date_closed IS NULL THEN 1 END) AS Open_Cases,
    ROUND(AVG(NVL(cs.Date_closed - cs.Date_assigned, SYSDATE - cs.Date_assigned)), 2) AS Avg_Resolution_Days,
    ROUND(COUNT(CASE WHEN cs.Date_closed IS NOT NULL THEN 1 END) / 
          NULLIF(COUNT(c.C_ID), 0) * 100, 2) AS Closure_Rate,
    MAX(cs.Date_assigned) AS Last_Case_Assigned
FROM 
    Officer o
LEFT JOIN 
    Crime c ON o.Officer_ID = c.Officer_ID
LEFT JOIN 
    Crime_Status cs ON c.C_ID = cs.C_ID
GROUP BY 
    o.Officer_ID, o.Firstname, o.Lastname, o.Nationality
ORDER BY 
    Closure_Rate DESC;

-- View 5: Detailed Crime Report
CREATE OR REPLACE VIEW Detailed_Crime_Report AS
SELECT 
    c.C_ID AS Crime_ID,
    cat.Category_name AS Crime_Category,
    c.Crime_desc AS Description,
    c.Date_reported,
    cs.Crime_Status AS Status,
    cs.Date_assigned,
    cs.Date_closed,
    CASE WHEN cs.Date_closed IS NOT NULL 
         THEN cs.Date_closed - cs.Date_assigned 
         ELSE SYSDATE - cs.Date_assigned 
    END AS Days_Open,
    o.Firstname || ' ' || o.Lastname AS Assigned_Officer,
    u.Firstname || ' ' || u.Lastname AS Reported_By,
    (SELECT COUNT(*) FROM Victim_Crime vc WHERE vc.C_ID = c.C_ID) AS Victim_Count,
    (SELECT COUNT(*) FROM Crime_Criminal cc WHERE cc.C_ID = c.C_ID) AS Criminal_Count,
    (SELECT LISTAGG(v.Firstname || ' ' || v.Lastname, ', ') WITHIN GROUP (ORDER BY v.Firstname)
     FROM Victim v
     JOIN Victim_Crime vc ON v.V_ID = vc.V_ID
     WHERE vc.C_ID = c.C_ID) AS Victims,
    (SELECT LISTAGG(cr.Firstname || ' ' || cr.Lastname, ', ') WITHIN GROUP (ORDER BY cr.Firstname)
     FROM Criminal cr
     JOIN Crime_Criminal cc ON cr.CR_ID = cc.CR_ID
     WHERE cc.C_ID = c.C_ID) AS Criminals
FROM 
    Crime c
JOIN 
    Category cat ON c.Category_ID = cat.Category_ID
JOIN 
    Crime_Status cs ON c.C_ID = cs.C_ID
JOIN 
    Officer o ON c.Officer_ID = o.Officer_ID
JOIN 
    Users u ON c.Created_by = u.User_ID
ORDER BY 
    c.Date_reported DESC;

-- View 6: Criminal History
CREATE OR REPLACE VIEW Criminal_History AS
SELECT 
    cr.CR_ID,
    cr.Firstname || ' ' || cr.Lastname AS Criminal_Name,
    cr.Date_of_Birth,
    TRUNC(MONTHS_BETWEEN(SYSDATE, cr.Date_of_Birth)/12) AS Age,
    c.C_ID AS Crime_ID,
    cat.Category_name AS Crime_Category,
    c.Crime_desc AS Description,
    c.Date_reported,
    cs.Crime_Status AS Status,
    cs.Date_closed,
    o.Firstname || ' ' || o.Lastname AS Assigned_Officer
FROM 
    Criminal cr
JOIN 
    Crime_Criminal cc ON cr.CR_ID = cc.CR_ID
JOIN 
    Crime c ON cc.C_ID = c.C_ID
JOIN 
    Category cat ON c.Category_ID = cat.Category_ID
JOIN 
    Crime_Status cs ON c.C_ID = cs.C_ID
JOIN 
    Officer o ON c.Officer_ID = o.Officer_ID
ORDER BY 
    cr.CR_ID, c.Date_reported DESC;

-- View 7: High-Priority Cases
CREATE OR REPLACE VIEW High_Priority_Cases AS
SELECT 
    c.C_ID AS Crime_ID,
    cat.Category_name AS Crime_Category,
    c.Crime_desc AS Description,
    c.Date_reported,
    cs.Crime_Status AS Status,
    cs.Date_assigned,
    SYSDATE - cs.Date_assigned AS Days_Open,
    o.Firstname || ' ' || o.Lastname AS Assigned_Officer,
    CASE 
        WHEN cat.Category_name IN ('Murder', 'Assault', 'Robbery') THEN 'High'
        WHEN SYSDATE - cs.Date_assigned > 30 THEN 'High'
        WHEN cat.Category_name = 'Fraud' AND SYSDATE - cs.Date_assigned > 15 THEN 'Medium'
        ELSE 'Normal'
    END AS Priority
FROM 
    Crime c
JOIN 
    Category cat ON c.Category_ID = cat.Category_ID
JOIN 
    Crime_Status cs ON c.C_ID = cs.C_ID
JOIN 
    Officer o ON c.Officer_ID = o.Officer_ID
WHERE 
    cs.Date_closed IS NULL
AND 
    (cat.Category_name IN ('Murder', 'Assault', 'Robbery') 
     OR SYSDATE - cs.Date_assigned > 30
     OR (cat.Category_name = 'Fraud' AND SYSDATE - cs.Date_assigned > 15))
ORDER BY 
    Priority, SYSDATE - cs.Date_assigned DESC;

-- View 8: Geographical Crime Distribution (Assuming city/location data is available)
CREATE OR REPLACE VIEW Victim_Distribution_Report AS
SELECT 
    TRUNC(MONTHS_BETWEEN(SYSDATE, v.Date_of_Birth)/12) AS Age_Group,
    CASE 
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, v.Date_of_Birth)/12) < 18 THEN 'Under 18'
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, v.Date_of_Birth)/12) BETWEEN 18 AND 30 THEN '18-30'
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, v.Date_of_Birth)/12) BETWEEN 31 AND 45 THEN '31-45'
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, v.Date_of_Birth)/12) BETWEEN 46 AND 60 THEN '46-60'
        ELSE 'Over 60'
    END AS Age_Range,
    COUNT(DISTINCT v.V_ID) AS Victim_Count,
    LISTAGG(DISTINCT cat.Category_name, ', ') WITHIN GROUP (ORDER BY cat.Category_name) AS Crime_Categories
FROM 
    Victim v
JOIN 
    Victim_Crime vc ON v.V_ID = vc.V_ID
JOIN 
    Crime c ON vc.C_ID = c.C_ID
JOIN 
    Category cat ON c.Category_ID = cat.Category_ID
GROUP BY 
    TRUNC(MONTHS_BETWEEN(SYSDATE, v.Date_of_Birth)/12),
    CASE 
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, v.Date_of_Birth)/12) < 18 THEN 'Under 18'
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, v.Date_of_Birth)/12) BETWEEN 18 AND 30 THEN '18-30'
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, v.Date_of_Birth)/12) BETWEEN 31 AND 45 THEN '31-45'
        WHEN TRUNC(MONTHS_BETWEEN(SYSDATE, v.Date_of_Birth)/12) BETWEEN 46 AND 60 THEN '46-60'
        ELSE 'Over 60'
    END
ORDER BY 
    Age_Group;

-- View 9: Case Aging Analysis
CREATE OR REPLACE VIEW Case_Aging_Analysis AS
SELECT 
    cat.Category_name AS Crime_Category,
    cs.Crime_Status AS Status,
    COUNT(c.C_ID) AS Case_Count,
    MIN(SYSDATE - cs.Date_assigned) AS Min_Days_Open,
    MAX(SYSDATE - cs.Date_assigned) AS Max_Days_Open,
    ROUND(AVG(SYSDATE - cs.Date_assigned), 2) AS Avg_Days_Open,
    CASE 
        WHEN AVG(SYSDATE - cs.Date_assigned) < 7 THEN 'Less than a week'
        WHEN AVG(SYSDATE - cs.Date_assigned) BETWEEN 7 AND 30 THEN '1-4 weeks'
        WHEN AVG(SYSDATE - cs.Date_assigned) BETWEEN 31 AND 90 THEN '1-3 months'
        WHEN AVG(SYSDATE - cs.Date_assigned) BETWEEN 91 AND 180 THEN '3-6 months'
        ELSE 'Over 6 months'
    END AS Aging_Category
FROM 
    Crime c
JOIN 
    Category cat ON c.Category_ID = cat.Category_ID
JOIN 
    Crime_Status cs ON c.C_ID = cs.C_ID
WHERE 
    cs.Date_closed IS NULL
GROUP BY 
    cat.Category_name, cs.Crime_Status
ORDER BY 
    Avg_Days_Open DESC;

-- View 10: System User Activity
CREATE OR REPLACE VIEW User_Activity_Report AS
SELECT 
    u.User_ID,
    u.Username,
    u.Firstname || ' ' || u.Lastname AS User_Name,
    u.Role,
    (SELECT COUNT(*) FROM Crime WHERE Created_by = u.User_ID) AS Crimes_Reported,
    (SELECT COUNT(*) FROM Victim WHERE Created_by = u.User_ID) AS Victims_Registered,
    (SELECT COUNT(*) FROM Crime_Status WHERE Created_by = u.User_ID) AS Status_Updates,
    (SELECT COUNT(*) FROM Officer WHERE Created_by = u.User_ID) AS Officers_Added,
    (SELECT MAX(Created_at) FROM Crime WHERE Created_by = u.User_ID) AS Last_Crime_Report,
    (SELECT MAX(Created_at) FROM Victim WHERE Created_by = u.User_ID) AS Last_Victim_Registration
FROM 
    Users u
ORDER BY 
    Crimes_Reported DESC, Victims_Registered DESC;