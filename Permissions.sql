-- Permissions.sql
-- This file contains the necessary grants for users to execute the CRMS stored procedures, functions, and packages

-- Grant permissions for all packages
GRANT EXECUTE ON user_mgmt_pkg TO PUBLIC;
GRANT EXECUTE ON crime_mgmt_pkg TO PUBLIC;
GRANT EXECUTE ON officer_mgmt_pkg TO PUBLIC;

-- Grant permissions for standalone procedures
GRANT EXECUTE ON register_criminal TO PUBLIC;
GRANT EXECUTE ON register_victim TO PUBLIC;
GRANT EXECUTE ON assign_crime_to_officer TO PUBLIC;
GRANT EXECUTE ON update_crime_status TO PUBLIC;

-- Grant permissions for functions
GRANT EXECUTE ON get_officer_caseload TO PUBLIC;
GRANT EXECUTE ON get_crime_status TO PUBLIC;

-- Grant permissions for specific roles
-- For Admin role
CREATE ROLE crms_admin;
GRANT EXECUTE ON user_mgmt_pkg TO crms_admin;
GRANT EXECUTE ON crime_mgmt_pkg TO crms_admin;
GRANT EXECUTE ON officer_mgmt_pkg TO crms_admin;
GRANT EXECUTE ON register_criminal TO crms_admin;
GRANT EXECUTE ON register_victim TO crms_admin;
GRANT EXECUTE ON assign_crime_to_officer TO crms_admin;
GRANT EXECUTE ON update_crime_status TO crms_admin;
GRANT EXECUTE ON get_officer_caseload TO crms_admin;
GRANT EXECUTE ON get_crime_status TO crms_admin;

-- For Officer role
CREATE ROLE crms_officer;
GRANT EXECUTE ON crime_mgmt_pkg TO crms_officer;
GRANT EXECUTE ON register_criminal TO crms_officer;
GRANT EXECUTE ON register_victim TO crms_officer;
GRANT EXECUTE ON update_crime_status TO crms_officer;
GRANT EXECUTE ON get_officer_caseload TO crms_officer;
GRANT EXECUTE ON get_crime_status TO crms_officer;

-- For User role
CREATE ROLE crms_user;
GRANT EXECUTE ON get_crime_status TO crms_user;

-- Grant SELECT permissions on views
GRANT SELECT ON Crime_Category_Statistics TO PUBLIC;
GRANT SELECT ON Criminal_Activity_Report TO PUBLIC;
GRANT SELECT ON Monthly_Crime_Trends TO PUBLIC;
GRANT SELECT ON Officer_Performance_Statistics TO PUBLIC;
GRANT SELECT ON Detailed_Crime_Report TO PUBLIC;
GRANT SELECT ON Criminal_History TO PUBLIC;
GRANT SELECT ON High_Priority_Cases TO PUBLIC;
GRANT SELECT ON Victim_Distribution_Report TO PUBLIC;
GRANT SELECT ON Case_Aging_Analysis TO PUBLIC;
GRANT SELECT ON User_Activity_Report TO PUBLIC;

-- Role-specific view permissions
GRANT SELECT ON Officer_Performance_Statistics TO crms_admin;
GRANT SELECT ON User_Activity_Report TO crms_admin;

COMMIT;