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

