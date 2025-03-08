----- Schema for psa tables --------------------------------------------------------------------------
CREATE SCHEMA db_environment;
USE db_environment;

----- psa tables --------------------------------------------------------------------------------------
CREATE TABLE psa_Co2_Emission (
     Land_Id INT,
     Land  VARCHAR(50),
     Year INT,
     Series VARCHAR(100), 
	 Value DECIMAL(15, 2),
     Footnotes VARCHAR(250),
     Source VARCHAR(250) 
 );
 CREATE TABLE psa_Land_Usage (
    Land_Id INT,
    Land VARCHAR(50),
    Year INT,
    Series VARCHAR(100), 
    Value DECIMAL(15, 2),
    Footnotes VARCHAR(250),
    Source VARCHAR(250)
 );
 CREATE TABLE psa_ThreatenedSpecies (
    Land_Id INT,
    Land VARCHAR(50),
    Year INT,
    Series VARCHAR(100), 
    Value INT,
    Footnotes VARCHAR(250),
    Source VARCHAR(250)
 );
 CREATE TABLE psa_WaterandSanitation (
    Land_Id INT,
    Land VARCHAR(50),
    Year INT,
    Series VARCHAR(100), 
    Value DECIMAL(15, 2),
    Footnotes VARCHAR(250),
    Source VARCHAR(250)
 );
 
----- Adding primary keys to psa tables ---------------------------------------------------------------
ALTER TABLE psa_Co2_Emission ADD COLUMN Fact_Id INT  AUTO_INCREMENT PRIMARY KEY FIRST;
ALTER TABLE psa_Land_Usage ADD COLUMN Fact_Id INT  AUTO_INCREMENT PRIMARY KEY FIRST;
ALTER TABLE psa_ThreatenedSpecies ADD COLUMN Fact_Id INT  AUTO_INCREMENT PRIMARY KEY FIRST;
ALTER TABLE psa_WaterandSanitation ADD COLUMN Fact_Id INT  AUTO_INCREMENT PRIMARY KEY FIRST;

----- Verifying if the data is inserted to psa tables -------------------------------------------------
SELECT * FROM psa_Co2_Emission;
SELECT count(*) FROM psa_Co2_Emission;
SELECT * FROM psa_Land_Usage;
SELECT count(*) FROM psa_Land_Usage;
SELECT * FROM psa_ThreatenedSpecies;
SELECT count(*) FROM psa_ThreatenedSpecies;
SELECT * FROM psa_WaterandSanitation;
SELECT count(*) FROM psa_WaterandSanitation;

-- Data Transformation---------------------------------------------------------------------------------------------------------
-- Transformation Area---------------------------------------------------------------------------------------------------------

CREATE SCHEMA trans_environment;
USE trans_environment;

CREATE TABLE trans_Co2_Emission (
     Fact_Id INT AUTO_INCREMENT PRIMARY KEY,
     Land_Id INT,
     Land  VARCHAR(50),
     Year INT,
     Series VARCHAR(100), 
     Value DECIMAL(15, 2),
     Footnotes VARCHAR(250),
     Source VARCHAR(250) 
);

CREATE TABLE trans_Land_Usage (
    Fact_Id INT AUTO_INCREMENT PRIMARY KEY,
    Land_Id INT,
    Land VARCHAR(50),
    Year INT,
    Series VARCHAR(100), 
    Value DECIMAL(15, 2),
    Footnotes VARCHAR(250),
    Source VARCHAR(250)
);

CREATE TABLE trans_ThreatenedSpecies (
    Fact_Id INT AUTO_INCREMENT PRIMARY KEY,
    Land_Id INT,
    Land VARCHAR(50),
    Year INT,
    Series VARCHAR(100), 
    Value INT,
    Footnotes VARCHAR(250),
    Source VARCHAR(250)
);

CREATE TABLE trans_WaterandSanitation (
    Fact_Id INT AUTO_INCREMENT PRIMARY KEY,
    Land_Id INT,
    Land VARCHAR(50),
    Year INT,
    Series VARCHAR(100), 
    Value DECIMAL(15, 2),
    Footnotes VARCHAR(250),
    Source VARCHAR(250)
);

-- Insert data from psa to trans tables-------------------------------------------------
INSERT INTO trans_co2_emission (Land_Id, Land, Year, Series, Value)
SELECT Land_Id, Land, Year, Series, Value
FROM db_environment.psa_co2_emission;

INSERT INTO trans_land_usage (Land_Id, Land, Year, Series, Value)
SELECT Land_Id, Land, Year, Series, Value
FROM db_environment.psa_land_usage;

INSERT INTO trans_threatenedspecies (Land_Id, Land, Year, Series, Value)
SELECT Land_Id, Land, Year, Series, Value
FROM db_environment.psa_threatenedspecies;

INSERT INTO trans_waterandsanitation (Land_Id, Land, Year, Series, Value)
SELECT Land_Id, Land, Year, Series, Value
FROM db_environment.psa_waterandsanitation;

-- Generate a complete list of years from all PSA tables-------------------------------------------------
CREATE TABLE all_years AS 
SELECT DISTINCT Year FROM db_environment.psa_co2_emission
UNION 
SELECT DISTINCT Year FROM db_environment.psa_land_usage
UNION 
SELECT DISTINCT Year FROM db_environment.psa_threatenedspecies
UNION 
SELECT DISTINCT Year FROM db_environment.psa_waterandsanitation;

-- Insert missing year records --------------------------------------------------------------------------
INSERT INTO trans_co2_emission (Land_Id, Land, Year, Series, Value)
SELECT DISTINCT t.Land_Id, t.Land, y.Year, t.Series, NULL 
FROM all_years y 
CROSS JOIN (SELECT DISTINCT Land_Id, Land, Series FROM db_environment.psa_co2_emission) t 
WHERE NOT EXISTS (
    SELECT 1 
    FROM trans_co2_emission tc 
    WHERE tc.Land_Id = t.Land_Id 
      AND tc.Year = y.Year
      AND tc.Series = t.Series
);

INSERT INTO trans_land_usage (Land_Id, Land, Year, Series, Value)
SELECT DISTINCT t.Land_Id, t.Land, y.Year, t.Series, NULL 
FROM all_years y 
CROSS JOIN (SELECT DISTINCT Land_Id, Land, Series FROM db_environment.psa_land_usage) t 
WHERE NOT EXISTS (
    SELECT 1 
    FROM trans_land_usage tlu 
    WHERE tlu.Land_Id = t.Land_Id 
      AND tlu.Year = y.Year
      AND tlu.Series = t.Series
);

INSERT INTO trans_threatenedspecies (Land_Id, Land, Year, Series, Value)
SELECT DISTINCT t.Land_Id, t.Land, y.Year, t.Series, NULL 
FROM all_years y 
CROSS JOIN (SELECT DISTINCT Land_Id, Land, Series FROM db_environment.psa_threatenedspecies) t 
WHERE NOT EXISTS (
    SELECT 1 
    FROM trans_threatenedspecies tts 
    WHERE tts.Land_Id = t.Land_Id 
      AND tts.Year = y.Year
      AND tts.Series = t.Series
);

INSERT INTO trans_waterandsanitation (Land_Id, Land, Year, Series, Value)
SELECT DISTINCT t.Land_Id, t.Land, y.Year, t.Series, NULL 
FROM all_years y 
CROSS JOIN (SELECT DISTINCT Land_Id, Land, Series FROM db_environment.psa_waterandsanitation) t 
WHERE NOT EXISTS (
    SELECT 1 
    FROM trans_waterandsanitation tws 
    WHERE tws.Land_Id = t.Land_Id 
      AND tws.Year = y.Year
      AND tws.Series = t.Series
);
-- Drop Unwanted Columns ------------------------------------------------------------------------
ALTER TABLE trans_Co2_Emission DROP COLUMN Footnotes, DROP COLUMN Source;
ALTER TABLE trans_Land_Usage DROP COLUMN Footnotes, DROP COLUMN Source;
ALTER TABLE trans_ThreatenedSpecies DROP COLUMN Footnotes, DROP COLUMN Source;
ALTER TABLE trans_WaterandSanitation DROP COLUMN Footnotes, DROP COLUMN Source;

----- datawarehouse schema -----------------------------------------------------------------------------
CREATE SCHEMA dwh_Environment;
USE dwh_Environment;

----- Dimension tables ---------------------------------------------------------------------------------
  CREATE TABLE Dim_Land (
    Land_Id INT PRIMARY KEY,
    Land_Name VARCHAR(100) NOT NULL
);
 CREATE TABLE dim_Year (
      Year_Id INT PRIMARY KEY AUTO_INCREMENT,
      Year INT NOT NULL
);
CREATE TABLE Dim_CO2_Series (
    Series_Id INT PRIMARY KEY AUTO_INCREMENT,
    Series_Name VARCHAR(100) NOT NULL
);
CREATE TABLE Dim_Land_Usage_Series (
    Series_Id INT PRIMARY KEY AUTO_INCREMENT,
    Series_Name VARCHAR(100) NOT NULL
);
CREATE TABLE Dim_Species_Series (
    Series_Id INT PRIMARY KEY AUTO_INCREMENT,
    Series_Name VARCHAR(100) NOT NULL
);
CREATE TABLE Dim_Water_and_Sanitation_Series (
    Series_Id INT PRIMARY KEY AUTO_INCREMENT,
    Series_Name VARCHAR(100) NOT NULL
);

----- Insert values from trans tables to dimension tables ------------------------------------------------
INSERT INTO dim_Land (Land_Id, Land_Name)
SELECT Land_Id, Land
FROM (
    SELECT DISTINCT Land_Id, Land FROM trans_environment.trans_co2_Emission
    UNION
    SELECT DISTINCT Land_Id, Land FROM trans_environment.trans_Land_Usage
    UNION
    SELECT DISTINCT Land_Id, Land FROM trans_environment.trans_ThreatenedSpecies
    UNION
    SELECT DISTINCT Land_Id, Land FROM trans_environment.trans_WaterandSanitation
) AS unique_Lands;

INSERT INTO dim_Year (Year)
SELECT Year FROM trans_environment.all_years;

INSERT INTO dim_CO2_Series (Series_Name)
SELECT DISTINCT Series
FROM trans_environment.trans_co2_Emission;

INSERT INTO dim_Land_Usage_Series (Series_Name)
SELECT DISTINCT Series
FROM trans_environment.trans_Land_Usage;

INSERT INTO dim_Species_Series (Series_Name)
SELECT DISTINCT Series
FROM trans_environment.trans_ThreatenedSpecies;

INSERT INTO dim_Water_and_Sanitation_Series (Series_Name)
SELECT DISTINCT Series
FROM trans_environment.trans_WaterandSanitation;

----- Verifying if the data is inserted to dimension tables ----------------------------------------------
SELECT * FROM dim_Land;
SELECT count(*) FROM dim_Land;
SELECT * FROM dim_Year;
SELECT count(*) FROM dim_Year;
SELECT * FROM dim_CO2_Series;
SELECT count(*) FROM dim_CO2_Series;
SELECT * FROM dim_Land_Usage_Series;
SELECT count(*) Dim_Land_Usage_Series;
SELECT * FROM dim_Species_Series;
SELECT count(*) dim_Species_Series;
SELECT * FROM dim_Water_and_Sanitation_Series;
SELECT count(*)dim_Water_and_Sanitation_Series ;

----- dwh tables ------------------------------------------------------------------------------------------
CREATE TABLE dwh_Co2_Emission (
    Fact_Id INT PRIMARY KEY,
    Land_Id INT,
    Year_Id INT,
    Series_Id INT,
    Emission_Value DECIMAL(15, 2),
    FOREIGN KEY (Land_Id) REFERENCES dwh_Environment.Dim_Land(Land_Id),
    FOREIGN KEY (Year_Id) REFERENCES dwh_Environment.dim_Year(Year_Id),
    FOREIGN KEY (Series_Id) REFERENCES dwh_Environment.Dim_CO2_Series(Series_Id)
);
 CREATE TABLE dwh_Land_Usage (
    Fact_Id INT PRIMARY KEY,
    Land_Id INT,
    Year_Id INT,
    Series_Id INT,
    Land_Metric_Value DECIMAL(15, 2),
    FOREIGN KEY (Land_Id) REFERENCES dwh_Environment.Dim_Land(Land_Id),
    FOREIGN KEY (Year_Id) REFERENCES dwh_Environment.dim_Year(Year_Id),
    FOREIGN KEY (Series_Id) REFERENCES dwh_Environment.Dim_Land_Usage_Series(Series_Id)
);
 CREATE TABLE dwh_Threatened_Species (
    Fact_Id INT PRIMARY KEY,
    Land_Id INT,
    Year_Id INT,
    Series_Id INT,
    Threatened_Species_Count INT,
    FOREIGN KEY (Land_Id) REFERENCES dwh_Environment.Dim_Land(Land_Id),
    FOREIGN KEY (Year_Id) REFERENCES dwh_Environment.dim_Year(Year_Id),
    FOREIGN KEY (Series_Id) REFERENCES dwh_Environment.Dim_Species_Series(Series_Id)
);
CREATE TABLE dwh_Water_and_Sanitation (
	Fact_Id INT PRIMARY KEY,
    Land_Id INT,
    Year_Id INT,
    Series_Id INT,
	Service_Coverage_Percentage DECIMAL(15, 2),
    FOREIGN KEY (Land_Id) REFERENCES dwh_Environment.Dim_Land(Land_Id),
    FOREIGN KEY (Year_Id) REFERENCES dwh_Environment.dim_Year(Year_Id),
    FOREIGN KEY (Series_Id) REFERENCES dwh_Environment.Dim_Water_and_Sanitation_Series(Series_Id)
);

----- Insert values from trans tables to datawarehouse tables --------------------------------------------------
INSERT INTO dwh_Co2_Emission (Fact_Id, Land_Id, Year_Id, Series_Id, Emission_Value)
SELECT 
    trans.Fact_Id,
    dim_L.Land_Id,
    dim_Y.Year_Id,
    dim_S.Series_Id,
    trans.Value
FROM 
    trans_environment.trans_Co2_Emission AS trans
JOIN 
    dwh_Environment.Dim_Land AS dim_L ON trans.Land_Id = dim_L.Land_Id
JOIN 
    dwh_Environment.dim_Year AS dim_Y ON trans.Year = dim_Y.Year
JOIN 
    dwh_Environment.Dim_CO2_Series AS dim_S ON trans.Series = dim_S.Series_Name;

INSERT INTO dwh_Land_Usage (Fact_Id, Land_Id, Year_Id, Series_Id, Land_Metric_Value)
SELECT 
    trans.Fact_Id,
    dim_L.Land_Id,
    dim_Y.Year_Id,
    dim_S.Series_Id,
    trans.Value
FROM 
    trans_environment.trans_Land_Usage AS trans
JOIN 
    dwh_Environment.Dim_Land AS dim_L ON trans.Land_Id = dim_L.Land_Id
JOIN 
    dwh_Environment.dim_Year AS dim_Y ON trans.Year = dim_Y.Year
JOIN 
    dwh_Environment.Dim_Land_Usage_Series AS dim_S ON trans.Series = dim_S.Series_Name;

INSERT INTO dwh_Threatened_Species (Fact_Id, Land_Id, Year_Id, Series_Id, Threatened_Species_Count)
SELECT 
    trans.Fact_Id,
    dim_L.Land_Id,
    dim_Y.Year_Id,
    dim_S.Series_Id,
    trans.Value
FROM 
    trans_environment.trans_ThreatenedSpecies AS trans
JOIN 
    dwh_Environment.Dim_Land AS dim_L ON trans.Land_Id = dim_L.Land_Id
JOIN 
    dwh_Environment.dim_Year AS dim_Y ON trans.Year = dim_Y.Year
JOIN 
    dwh_Environment.Dim_Species_Series AS dim_S ON trans.Series = dim_S.Series_Name;

INSERT INTO dwh_Water_and_Sanitation (Fact_Id, Land_Id, Year_Id, Series_Id, Service_Coverage_Percentage)
SELECT 
    trans.Fact_Id,
    dim_L.Land_Id,
    dim_Y.Year_Id,
    dim_S.Series_Id,
    trans.Value
FROM 
    trans_environment.trans_WaterandSanitation AS trans
JOIN 
    dwh_Environment.Dim_Land AS dim_L ON trans.Land_Id = dim_L.Land_Id
JOIN 
    dwh_Environment.dim_Year AS dim_Y ON trans.Year = dim_Y.Year
JOIN 
    dwh_Environment.Dim_Water_and_Sanitation_Series AS dim_S ON trans.Series = dim_S.Series_Name;

-- Verify the data inserted------------------------------------------------------------------------------------
SELECT COUNT(*) AS TotalRecords FROM dwh_Co2_Emission;
SELECT COUNT(*) AS TotalRecords FROM dwh_Land_Usage;
SELECT COUNT(*) AS TotalRecords FROM dwh_Threatened_Species;
SELECT COUNT(*) AS TotalRecords FROM dwh_Water_and_Sanitation;





