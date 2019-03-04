SELECT "ToView"."CountryCODE"              AS "CounryCODE",
       "ToView"."Year"                     AS "Year",
	   "ToView"."Entering"                 AS "Entering",
	 "FromView"."Leaving"                  AS "Leaving"
FROM
(SELECT "WBMOutput"."Discharge_CRUTSv401+Dist_FAOGAULCrossing_06min_Annual"."SampleID"        AS "CountryCODE",
        "WBMOutput"."Discharge_CRUTSv401+Dist_FAOGAULCrossing_06min_Annual"."Year"            AS "Year",
        SUM ("WBMOutput"."Discharge_CRUTSv401+Dist_FAOGAULCrossing_06min_Annual"."Discharge") AS "Entering"
 FROM "FAO-GAUL2014"."Global_CountryCrossing_FAO-GAUL2014_06min",
      "WBMOutput"."Discharge_CRUTSv401+Dist_FAOGAULCrossing_06min_Annual"
 WHERE "FAO-GAUL2014"."Global_CountryCrossing_FAO-GAUL2014_06min"."ToCountryCODE" = 2
 AND   "FAO-GAUL2014"."Global_CountryCrossing_FAO-GAUL2014_06min"."ToCountryCODE" = 
       "WBMOutput"."Discharge_CRUTSv401+Dist_FAOGAULCrossing_06min_Annual"."SampleID"
 GROUP BY "WBMOutput"."Discharge_CRUTSv401+Dist_FAOGAULCrossing_06min_Annual"."SampleID",
          "WBMOutput"."Discharge_CRUTSv401+Dist_FAOGAULCrossing_06min_Annual"."Year") AS "ToView"
NATURAL LEFT JOIN (SELECT "WBMOutput"."Discharge_CRUTSv401+Dist_FAOGAULCrossing_06min_Annual"."SampleID"        AS "CountryCODE",
        "WBMOutput"."Discharge_CRUTSv401+Dist_FAOGAULCrossing_06min_Annual"."Year"            AS "Year",
        SUM ("WBMOutput"."Discharge_CRUTSv401+Dist_FAOGAULCrossing_06min_Annual"."Discharge") AS "Leaving"
 FROM "FAO-GAUL2014"."Global_CountryCrossing_FAO-GAUL2014_06min",
      "WBMOutput"."Discharge_CRUTSv401+Dist_FAOGAULCrossing_06min_Annual"
 WHERE "FAO-GAUL2014"."Global_CountryCrossing_FAO-GAUL2014_06min"."CountryCODE" = 2
 AND   "FAO-GAUL2014"."Global_CountryCrossing_FAO-GAUL2014_06min"."CountryCODE" = 
       "WBMOutput"."Discharge_CRUTSv401+Dist_FAOGAULCrossing_06min_Annual"."SampleID"
 GROUP BY "WBMOutput"."Discharge_CRUTSv401+Dist_FAOGAULCrossing_06min_Annual"."SampleID",
          "WBMOutput"."Discharge_CRUTSv401+Dist_FAOGAULCrossing_06min_Annual"."Year") AS "FromView";