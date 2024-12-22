----- schema for psa tables --------------------------------------------------------------------------
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
 
----- adding primary keys to psa tables ---------------------------------------------------------------
ALTER TABLE psa_Co2_Emission ADD COLUMN Fact_Id INT  AUTO_INCREMENT PRIMARY KEY FIRST;
ALTER TABLE psa_Land_Usage ADD COLUMN Fact_Id INT  AUTO_INCREMENT PRIMARY KEY FIRST;
ALTER TABLE psa_ThreatenedSpecies ADD COLUMN Fact_Id INT  AUTO_INCREMENT PRIMARY KEY FIRST;
ALTER TABLE psa_WaterandSanitation ADD COLUMN Fact_Id INT  AUTO_INCREMENT PRIMARY KEY FIRST;

----- verifying if the data is inserted to psa tables -------------------------------------------------
SELECT * FROM psa_Co2_Emission;
SELECT count(*) FROM psa_Co2_Emission;
SELECT * FROM psa_Land_Usage;
SELECT count(*) FROM psa_Land_Usage;
SELECT * FROM psa_ThreatenedSpecies;
SELECT count(*) FROM psa_ThreatenedSpecies;
SELECT * FROM psa_WaterandSanitation;
SELECT count(*) FROM psa_WaterandSanitation;

----- datawarehouse schema -----------------------------------------------------------------------------
CREATE SCHEMA dwh_Environment;
USE dwh_Environment;

----- dimension tables ---------------------------------------------------------------------------------
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

----- insert values from psa tables to dimension tables ------------------------------------------------
INSERT INTO dim_Land (Land_Id, Land_Name)
SELECT Land_Id, Land
FROM (
    SELECT DISTINCT Land_Id, Land FROM db_Environment.psa_Co2_Emission
    UNION
    SELECT DISTINCT Land_Id, Land FROM db_Environment.psa_Land_Usage
    UNION
    SELECT DISTINCT Land_Id, Land FROM db_Environment.psa_ThreatenedSpecies
    UNION
    SELECT DISTINCT Land_Id, Land FROM db_Environment.psa_WaterandSanitation
) AS unique_Lands;

INSERT INTO dim_Year (Year)
SELECT DISTINCT Year 
FROM (
    SELECT Year FROM db_Environment.psa_Co2_Emission
    UNION
    SELECT Year FROM db_Environment.psa_Land_Usage
    UNION
    SELECT Year FROM db_Environment.psa_ThreatenedSpecies
    UNION
    SELECT Year FROM db_Environment.psa_WaterandSanitation
) AS unique_Years;

INSERT INTO dim_CO2_Series (Series_Name)
SELECT DISTINCT Series
FROM db_Environment.psa_Co2_Emission;

INSERT INTO dim_Land_Usage_Series (Series_Name)
SELECT DISTINCT Series
FROM db_Environment.psa_Land_Usage;

INSERT INTO dim_Species_Series (Series_Name)
SELECT DISTINCT Series
FROM db_Environment.psa_ThreatenedSpecies;

INSERT INTO dim_Water_and_Sanitation_Series (Series_Name)
SELECT DISTINCT Series
FROM db_Environment.psa_WaterandSanitation;

----- verifying if the data is inserted to dimension tables ----------------------------------------------
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

----- insert values from psa tables to datawarehouse tables --------------------------------------------------
INSERT INTO dwh_Co2_Emission (Fact_Id, Land_Id, Year_Id, Series_Id, Emission_Value)
SELECT 
    psa.Fact_Id,
    dim_L.Land_Id,
    dim_Y.Year_Id,
    dim_S.Series_Id,
    psa.Value
FROM 
    db_Environment.psa_Co2_Emission AS psa
JOIN 
    dwh_Environment.Dim_Land AS dim_L ON psa.Land_Id = dim_L.Land_Id
JOIN 
    dwh_Environment.dim_Year AS dim_Y ON psa.Year = dim_Y.Year
JOIN 
    dwh_Environment.Dim_CO2_Series AS dim_S ON psa.Series = dim_S.Series_Name;

 SELECT COUNT(*) AS TotalRecords FROM dwh_Co2_Emission;

INSERT INTO dwh_Land_Usage (Fact_Id, Land_Id, Year_Id, Series_Id, Land_Metric_Value)
SELECT 
    psa.Fact_Id,
    dim_L.Land_Id,
    dim_Y.Year_Id,
    dim_S.Series_Id,
    psa.Value
FROM 
    db_Environment.psa_Land_Usage AS psa
JOIN 
    dwh_Environment.Dim_Land AS dim_L ON psa.Land_Id = dim_L.Land_Id
JOIN 
    dwh_Environment.dim_Year AS dim_Y ON psa.Year = dim_Y.Year
JOIN 
    dwh_Environment.Dim_Land_Usage_Series AS dim_S ON psa.Series = dim_S.Series_Name;
    
SELECT COUNT(*) AS TotalRecords FROM dwh_Land_Usage;

INSERT INTO dwh_Threatened_Species (Fact_Id, Land_Id, Year_Id, Series_Id, Threatened_Species_Count)
SELECT 
    psa.Fact_Id,
    dim_L.Land_Id,
    dim_Y.Year_Id,
    dim_S.Series_Id,
    psa.Value
FROM 
    db_Environment.psa_ThreatenedSpecies AS psa
JOIN 
    dwh_Environment.Dim_Land AS dim_L ON psa.Land_Id = dim_L.Land_Id
JOIN 
    dwh_Environment.dim_Year AS dim_Y ON psa.Year = dim_Y.Year
JOIN 
    dwh_Environment.Dim_Species_Series AS dim_S ON psa.Series = dim_S.Series_Name;

SELECT COUNT(*) AS TotalRecords FROM dwh_Threatened_Species;

INSERT INTO dwh_Water_and_Sanitation (Fact_Id, Land_Id, Year_Id, Series_Id, Service_Coverage_Percentage)
SELECT 
    psa.Fact_Id,
    dim_L.Land_Id,
    dim_Y.Year_Id,
    dim_S.Series_Id,
    psa.Value
FROM 
    db_Environment.psa_WaterandSanitation AS psa
JOIN 
    dwh_Environment.Dim_Land AS dim_L ON psa.Land_Id = dim_L.Land_Id
JOIN 
    dwh_Environment.dim_Year AS dim_Y ON psa.Year = dim_Y.Year
JOIN 
    dwh_Environment.Dim_Water_and_Sanitation_Series AS dim_S ON psa.Series = dim_S.Series_Name;

-- Verify the data inserted------------------------------------------------------------------------------------
SELECT COUNT(*) AS TotalRecords FROM dwh_Co2_Emission;
SELECT COUNT(*) AS TotalRecords FROM dwh_Land_Usage;
SELECT COUNT(*) AS TotalRecords FROM dwh_Threatened_Species;
SELECT COUNT(*) AS TotalRecords FROM dwh_Water_and_Sanitation;

-- KPIs---------------------------------------------------------------------------------------------------------
-- to be continued----------------------------------------------------------------------------------------------

  




 











 








 
 
 
 
 
 



