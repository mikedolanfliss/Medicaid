--Generate data for U01 prediction model

DROP TABLE #A_2014
DROP TABLE #A1_2014
DROP TABLE #A1_2015
DROP TABLE #ID2014

--1. select children with asthma and age 3-17 (born between 1997-2011) in 2014
--#A_2014. Select needed baseline fields, age, and sequence the entries by eligiblity dates
SELECT CAL_YEAR AS YEAR, MEDICAID_RECIPIENT_ID AS ID2014, GENDER, RACE1, HISPANIC_ORIGIN_NAME AS HISP, BIRTH_DATE AS DOB,
CTZNSHP_STATUS_NAME AS CTZNSHP, INS_STATUS_NAME AS INS_STATUS, SPOKEN_LNG_NAME AS LANG, FPL_PRCNTG AS FPL, RAC_CODE AS RAC_CODE1,
FROM_DATE, TO_DATE, END_REASON, COVERAGE_TYPE_IND AS COVERAGE, POSTAL_CODE AS ZIPCODE,
ROW_NUMBER() OVER(PARTITION BY MEDICAID_RECIPIENT_ID ORDER BY MEDICAID_RECIPIENT_ID, FROM_DATE DESC, TO_DATE DESC) AS ROW
INTO #A_2014
FROM PHClaims.dbo.vEligibility
WHERE CAL_YEAR=2014 AND BIRTH_DATE BETWEEN '1997-01-01' AND '2011-12-31';

--#A1_2015. Select children in 2015 to be matched with baseline
SELECT DISTINCT MEDICAID_RECIPIENT_ID AS ID2015
INTO #A1_2015
FROM PHClaims.dbo.vEligibility
WHERE CAL_YEAR=2015 AND BIRTH_DATE BETWEEN '1997-01-01' AND '2011-12-31'
GROUP BY MEDICAID_RECIPIENT_ID;

--Match baseline with the following year (only include cases present in both years)
SELECT * INTO #A1_2014
FROM #A_2014
INNER JOIN #A1_2015
ON #A_2014.ID2014=#A1_2015.ID2015
WHERE ROW=1;

ALTER TABLE #A1_2014
DROP COLUMN ID2015

SELECT ID2014 INTO #ID2014 FROM #A1_2014;

--#T1=number of baseline total hospitalizations
SELECT DISTINCT MEDICAID_RECIPIENT_ID AS ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS T1 INTO #T1
FROM PHClaims.dbo.vClaims
WHERE CAL_YEAR=2014 AND CLM_TYPE_CID=31
GROUP BY MEDICAID_RECIPIENT_ID;

--#T2=number of baseline total ED visits
SELECT DISTINCT MEDICAID_RECIPIENT_ID AS ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS T2 INTO #T2
FROM PHClaims.dbo.vClaims
WHERE CAL_YEAR=2014 AND REVENUE_CODE IN ('0450','0456','0459','0981')
GROUP BY MEDICAID_RECIPIENT_ID;

--#B. SELECT 2014 BASELINE CLAIMS DATA FOR PATIENTS WITH ASTHMA
SELECT * INTO #B
FROM PHClaims.dbo.vClaims
INNER JOIN #ID2014
ON PHClaims.dbo.vClaims.MEDICAID_RECIPIENT_ID=#ID2014.ID2014
WHERE CAL_YEAR=2014
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%'
OR DIAGNOSIS_CODE_2 LIKE '493%' OR DIAGNOSIS_CODE_2 LIKE 'J45%'
OR DIAGNOSIS_CODE_3 LIKE '493%' OR DIAGNOSIS_CODE_3 LIKE 'J45%'
OR DIAGNOSIS_CODE_4 LIKE '493%' OR DIAGNOSIS_CODE_4 LIKE 'J45%'
OR DIAGNOSIS_CODE_5 LIKE '493%' OR DIAGNOSIS_CODE_5 LIKE 'J45%');

SELECT MEDICAID_RECIPIENT_ID AS ID493 INTO #B1
FROM #B
;
--Generate predictors from #B, such as hospitalization, ED visit, urgent care visit, other visit type? comorbidity?
--#H1=number of baseline hospitalizations for asthma, any diagnosis
SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS H1 INTO #H1
FROM #B
WHERE CAL_YEAR=2014 AND CLM_TYPE_CID=31
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%'
OR DIAGNOSIS_CODE_2 LIKE '493%' OR DIAGNOSIS_CODE_2 LIKE 'J45%'
OR DIAGNOSIS_CODE_3 LIKE '493%' OR DIAGNOSIS_CODE_3 LIKE 'J45%'
OR DIAGNOSIS_CODE_4 LIKE '493%' OR DIAGNOSIS_CODE_4 LIKE 'J45%'
OR DIAGNOSIS_CODE_5 LIKE '493%' OR DIAGNOSIS_CODE_5 LIKE 'J45%')
GROUP BY ID2014;

--#H2=number of baseline hospitalizations for asthma, primary diagnosis
SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS H2 INTO #H2
FROM #B
WHERE CAL_YEAR=2014 AND CLM_TYPE_CID=31
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%')
GROUP BY ID2014;

--#E1=number of ER visit for asthma, any diagnosis
SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS E1 INTO #E1
FROM #B
WHERE CAL_YEAR=2014 AND REVENUE_CODE IN ('0450','0456','0459','0981')
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%'
OR DIAGNOSIS_CODE_2 LIKE '493%' OR DIAGNOSIS_CODE_2 LIKE 'J45%'
OR DIAGNOSIS_CODE_3 LIKE '493%' OR DIAGNOSIS_CODE_3 LIKE 'J45%'
OR DIAGNOSIS_CODE_4 LIKE '493%' OR DIAGNOSIS_CODE_4 LIKE 'J45%'
OR DIAGNOSIS_CODE_5 LIKE '493%' OR DIAGNOSIS_CODE_5 LIKE 'J45%')
GROUP BY ID2014;

--#E2=number of ER visit for asthma, primary diagnosis
SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS E2 INTO #E2	
FROM #B
WHERE CAL_YEAR=2014 AND REVENUE_CODE IN ('0450','0456','0459','0981')
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%')
GROUP BY ID2014;

--#C1=well child check up visit for asthma, any diagnosis
SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS C1 INTO #C1
FROM #B
WHERE CAL_YEAR=2014 AND CLM_TYPE_CID=27
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%'
OR DIAGNOSIS_CODE_2 LIKE '493%' OR DIAGNOSIS_CODE_2 LIKE 'J45%'
OR DIAGNOSIS_CODE_3 LIKE '493%' OR DIAGNOSIS_CODE_3 LIKE 'J45%'
OR DIAGNOSIS_CODE_4 LIKE '493%' OR DIAGNOSIS_CODE_4 LIKE 'J45%'
OR DIAGNOSIS_CODE_5 LIKE '493%' OR DIAGNOSIS_CODE_5 LIKE 'J45%')
GROUP BY ID2014;

--#C2=number of well child checkup visit for asthma, primary diagnosis
SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS C2 INTO #C2	
FROM #B
WHERE CAL_YEAR=2014 AND CLM_TYPE_CID=27
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%')
GROUP BY ID2014;


--#U1=number of asthma-related urgent care based on place of service
SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS U1 INTO #U1
FROM #B
WHERE CAL_YEAR=2014 AND PLACE_OF_SERVICE='20 URGENT CARE FAC' 
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%'
OR DIAGNOSIS_CODE_2 LIKE '493%' OR DIAGNOSIS_CODE_2 LIKE 'J45%'
OR DIAGNOSIS_CODE_3 LIKE '493%' OR DIAGNOSIS_CODE_3 LIKE 'J45%'
OR DIAGNOSIS_CODE_4 LIKE '493%' OR DIAGNOSIS_CODE_4 LIKE 'J45%'
OR DIAGNOSIS_CODE_5 LIKE '493%' OR DIAGNOSIS_CODE_5 LIKE 'J45%')
GROUP BY ID2014;

SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS U2 INTO #U2
FROM #B
WHERE CAL_YEAR=2014 AND PLACE_OF_SERVICE='20 URGENT CARE FAC' 
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%')
GROUP BY ID2014;

SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS E1B INTO #E1B
FROM #B
WHERE CAL_YEAR=2014 AND PLACE_OF_SERVICE='23 EMERGENCY ROOM2' 
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%'
OR DIAGNOSIS_CODE_2 LIKE '493%' OR DIAGNOSIS_CODE_2 LIKE 'J45%'
OR DIAGNOSIS_CODE_3 LIKE '493%' OR DIAGNOSIS_CODE_3 LIKE 'J45%'
OR DIAGNOSIS_CODE_4 LIKE '493%' OR DIAGNOSIS_CODE_4 LIKE 'J45%'
OR DIAGNOSIS_CODE_5 LIKE '493%' OR DIAGNOSIS_CODE_5 LIKE 'J45%')
GROUP BY ID2014;

SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS E2B INTO #E2B
FROM #B
WHERE CAL_YEAR=2014 AND PLACE_OF_SERVICE='23 EMERGENCY ROOM2' 
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%')
GROUP BY ID2014;

---------------------------
--#C. SELECT 2015 (SUBSEQUENT YEAR) CLAIMS DATA FOR PATIENTS WITH ASTHMA
SELECT * INTO #C
FROM PHClaims.dbo.vClaims
INNER JOIN #ID2014
ON PHClaims.dbo.vClaims.MEDICAID_RECIPIENT_ID=#ID2014.ID2014
WHERE CAL_YEAR=2015
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%'
OR DIAGNOSIS_CODE_2 LIKE '493%' OR DIAGNOSIS_CODE_2 LIKE 'J45%'
OR DIAGNOSIS_CODE_3 LIKE '493%' OR DIAGNOSIS_CODE_3 LIKE 'J45%'
OR DIAGNOSIS_CODE_4 LIKE '493%' OR DIAGNOSIS_CODE_4 LIKE 'J45%'
OR DIAGNOSIS_CODE_5 LIKE '493%' OR DIAGNOSIS_CODE_5 LIKE 'J45%');

--Generate outcome variables from #C, such as hospitalization, ED visit, 
--#C1=number of hospitalizations for asthma, any diagnosis, OUTCOME VARIABLE
SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS EX_H1 INTO #EX_H1
FROM #C
WHERE CAL_YEAR=2015 AND CLM_TYPE_CID=31
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%'
OR DIAGNOSIS_CODE_2 LIKE '493%' OR DIAGNOSIS_CODE_2 LIKE 'J45%'
OR DIAGNOSIS_CODE_3 LIKE '493%' OR DIAGNOSIS_CODE_3 LIKE 'J45%'
OR DIAGNOSIS_CODE_4 LIKE '493%' OR DIAGNOSIS_CODE_4 LIKE 'J45%'
OR DIAGNOSIS_CODE_5 LIKE '493%' OR DIAGNOSIS_CODE_5 LIKE 'J45%')
GROUP BY ID2014;

--#C2=number of EXIT hospitalizations for asthma, primary diagnosis
SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS EX_H2 INTO #EX_H2
FROM #C
WHERE CAL_YEAR=2015 AND CLM_TYPE_CID=31
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%')
GROUP BY ID2014;

--#C3=number of EXIT ER visit for asthma, any diagnosis
SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS EX_E1 INTO #EX_E1	
FROM #C
WHERE CAL_YEAR=2015 AND REVENUE_CODE IN ('0450','0456','0459','0981')
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%'
OR DIAGNOSIS_CODE_2 LIKE '493%' OR DIAGNOSIS_CODE_2 LIKE 'J45%'
OR DIAGNOSIS_CODE_3 LIKE '493%' OR DIAGNOSIS_CODE_3 LIKE 'J45%'
OR DIAGNOSIS_CODE_4 LIKE '493%' OR DIAGNOSIS_CODE_4 LIKE 'J45%'
OR DIAGNOSIS_CODE_5 LIKE '493%' OR DIAGNOSIS_CODE_5 LIKE 'J45%')
GROUP BY ID2014;

--#C4=number of EXIT ER visit for asthma, primary diagnosis
SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS EX_E2 INTO #EX_E2
FROM #C
WHERE CAL_YEAR=2015 AND REVENUE_CODE IN ('0450','0456','0459','0981')
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%')
GROUP BY ID2014;

SELECT * FROM #C
--#U1=number of asthma-related urgent care based on place of service
SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS EX_U1 INTO #EX_U1
FROM #C
WHERE CAL_YEAR=2015 AND PLACE_OF_SERVICE='20 URGENT CARE FAC' 
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%'
OR DIAGNOSIS_CODE_2 LIKE '493%' OR DIAGNOSIS_CODE_2 LIKE 'J45%'
OR DIAGNOSIS_CODE_3 LIKE '493%' OR DIAGNOSIS_CODE_3 LIKE 'J45%'
OR DIAGNOSIS_CODE_4 LIKE '493%' OR DIAGNOSIS_CODE_4 LIKE 'J45%'
OR DIAGNOSIS_CODE_5 LIKE '493%' OR DIAGNOSIS_CODE_5 LIKE 'J45%')
GROUP BY ID2014;

SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS EX_U2 INTO #EX_U2
FROM #C
WHERE CAL_YEAR=2015 AND PLACE_OF_SERVICE='20 URGENT CARE FAC' 
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%')
GROUP BY ID2014;

SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS EX_E1B INTO #EX_E1B
FROM #C
WHERE CAL_YEAR=2015 AND PLACE_OF_SERVICE='23 EMERGENCY ROOM2' 
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%'
OR DIAGNOSIS_CODE_2 LIKE '493%' OR DIAGNOSIS_CODE_2 LIKE 'J45%'
OR DIAGNOSIS_CODE_3 LIKE '493%' OR DIAGNOSIS_CODE_3 LIKE 'J45%'
OR DIAGNOSIS_CODE_4 LIKE '493%' OR DIAGNOSIS_CODE_4 LIKE 'J45%'
OR DIAGNOSIS_CODE_5 LIKE '493%' OR DIAGNOSIS_CODE_5 LIKE 'J45%')
GROUP BY ID2014;

SELECT DISTINCT ID2014, COUNT(DISTINCT FROM_SRVC_DATE) AS EX_E2B INTO #EX_E2B
FROM #C
WHERE CAL_YEAR=2015 AND PLACE_OF_SERVICE='23 EMERGENCY ROOM2' 
AND (PRIMARY_DIAGNOSIS_CODE LIKE '493%' OR PRIMARY_DIAGNOSIS_CODE LIKE 'J45%')
GROUP BY ID2014;

SELECT * FROM #EX_U1
----xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
/*Join files */
SELECT *
FROM #A1_2014
INNER JOIN #B1
ON #A1_2014.ID2014=#B1.ID493
LEFT JOIN #H1
ON #A1_2014.ID2014=#H1.ID2014
LEFT JOIN #H2
ON #A1_2014.ID2014=#H2.ID2014
LEFT JOIN #E1
ON #A1_2014.ID2014=#E1.ID2014
LEFT JOIN #E2
ON #A1_2014.ID2014=#E2.ID2014
LEFT JOIN #C1
ON #A1_2014.ID2014=#C1.ID2014
LEFT JOIN #C2
ON #A1_2014.ID2014=#C2.ID2014
LEFT JOIN #T1
ON #A1_2014.ID2014=#T1.ID2014
LEFT JOIN #T2
ON #A1_2014.ID2014=#T2.ID2014
LEFT JOIN #U1
ON #A1_2014.ID2014=#U1.ID2014
LEFT JOIN #U2
ON #A1_2014.ID2014=#U2.ID2014
LEFT JOIN #E1B
ON #A1_2014.ID2014=#E1B.ID2014
LEFT JOIN #E2B
ON #A1_2014.ID2014=#E2B.ID2014
LEFT JOIN #EX_H1
ON #A1_2014.ID2014=#EX_H1.ID2014
LEFT JOIN #EX_H2
ON #A1_2014.ID2014=#EX_H2.ID2014
LEFT JOIN #EX_E1
ON #A1_2014.ID2014=#EX_E1.ID2014
LEFT JOIN #EX_E2
ON #A1_2014.ID2014=#EX_E2.ID2014
LEFT JOIN #EX_U1
ON #A1_2014.ID2014=#EX_U1.ID2014
LEFT JOIN #EX_U2
ON #A1_2014.ID2014=#EX_U2.ID2014
LEFT JOIN #EX_E1B
ON #A1_2014.ID2014=#EX_E1B.ID2014
LEFT JOIN #EX_E2B
ON #A1_2014.ID2014=#EX_E2B.ID2014;