#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
     statCode=2
     gaulCode=1
  countryName="Afghanistan"
  setwd("/Users/balazs/Desktop/Analysis/LaTeX")
} else if (length(args)==3) {
     statCode=args[1]
     gaulCode=args[2]
  countryName=args[3]
} else  {
  stop ("Incomplete argument list",call.= TRUE)
}

require("RPostgreSQL")
require("ggplot2")
require("sf")

dbDrv <- dbDriver("PostgreSQL")

DrawCountryMap <- function (pageWidth, pageHeight, pointSize, statCode, gaulCode, countryName, resolution) {
  dbCon <- dbConnect(dbDrv, dbname = "PostGIS_COMPASS", host = "10.16.12.60", port = 5432)
  
  schema  <- '"FAO-GAUL2014"'
  tblName <- paste ('"Global_Countries_FAO-GAUL2014_',resolution,'"',sep="")
  selectStatement=paste('SELECT "adm0_code", "adm0_name", ST_AsText("geom") AS "wkt_geom", "Color" ','FROM ',schema,'.',tblName,' WHERE "adm0_code" = ',gaulCode,sep="")
  df <- dbGetQuery(dbCon, selectStatement)
  dbDisconnect(dbCon)

  sfPolygons <- st_as_sf (df, wkt="wkt_geom") %>% st_set_crs(4326)

  #Requires development version of ggplot2: devtools::install_github("tidyverse/ggplot2")
  fileName <- paste("Figures/Fig_",gaulCode,'_CountryMap.pdf',sep="")
  pdf(file=fileName,paper="special", width=pageWidth, height=pageHeight, pointsize = pointSize)
  countryMap = ggplot(sfPolygons) + geom_sf(data=sfPolygons,aes(colour="red",fill = "red")) +
               ggtitle(countryName) +
               theme(plot.title = element_text(hjust = 0.5)) +
               theme(legend.position="none")
  print (countryMap)
  dev.off()
}

DrawCountryAnnualPopulation <- function (pageWidth, pageHeight, pointSize, statCode, gaulCode, countryName, resolution) {
  dbCon <- dbConnect(dbDrv, dbname = "PostGIS_Global", host = "10.16.12.60", port = 5432)
  
  schema  <- '"country_statistics_fao2"'
  tblName <- '"population_e_all_data"'
  selectStatement=paste('SELECT "year", "value" / 1000 AS "Total" FROM ',schema,'.',tblName,
                        'WHERE "areacode" = ',statCode,
                        " AND element = 'Total Population - Both sexes'",' AND "year" < 2019 ORDER BY "year"',sep="")
  df <- dbGetQuery(dbCon, selectStatement)
  popMin <- min(df$Total)*0.95/2
  popMax <- max(df$Total)*1.1
  legendPos <- popMin+(popMax-popMin)*0.95
  
  fileName <- paste("Figures/Fig_",gaulCode,'_Population_Annual.pdf',sep="")
  pdf(file=fileName,paper="special", width=pageWidth, height=pageHeight, pointsize = pointSize)
  par(mar=c(5,7,4,2))
  plot (df$year,df$Total,
        main="FAO Statistics",
        xlim=c(1950,2020),
        ylim=c(popMin,popMax),
        xlab="Time [year]",ylab="Population [million ppl.]",type="l", col="black", lwd=2.5,
        cex.main=2.5, cex.lab = 2, cex.axis=1.5)
  selectStatement <- paste('SELECT "year", "value" / 1000 AS "Total" FROM ',schema,'.',tblName,
                           'WHERE "areacode" = ',statCode,
                           " AND element = 'Total Population - Male'",' AND "year" < 2019 ORDER BY "year"',sep="")
  df <- dbGetQuery(dbCon, selectStatement)
  lines(df$year,df$Total, col="red", lwd=2.5)
  selectStatement=paste('SELECT "year", "value" / 1000 AS "Total" FROM ',schema,'.',tblName,
                        'WHERE "areacode" = ',statCode,
                        " AND element = 'Total Population - Female'",' AND "year" < 2019 ORDER BY "year"',sep="")
  df <- dbGetQuery(dbCon, selectStatement)
  lines(df$year,df$Total, col="green", lwd=2.5)
  legend(1950,legendPos, # places a legend at the appropriate place (upper corner of legend box)
         legend = c("Total", "Male", "Female"), # puts text in the legend
         lty    = c(1,      1,     1),   # gives the legend appropriate symbols (lines)
         lwd    = c(2.5,    2.5,   2.5),
         col    = c('black','red', 'green')) # gives the legend lines the correct color and width
  dev.off()
  dbDisconnect(dbCon)
}

DrawCountryAnnualRunoff <- function (pageWidth, pageHeight, pointSize, statCode, gaulCode, countryName, resolution) {
  dbCon <- dbConnect(dbDrv, dbname = "PostGIS_COMPASS", host = "10.16.12.60", port = 5432)
  
  schema    <- '"WBMOutput"'
  tblName   <- paste('"Runoff_CRUTSv401+Dist_FAOGAULCountry_',resolution,'_Annual"',sep="")
  selectStatement <- paste('SELECT * FROM ',schema,'.',tblName,'WHERE "SampleID" = ',gaulCode,' ORDER BY "Year"',sep="")
  dfCRUTS   <- dbGetQuery(dbCon, selectStatement)
  tblName   <- paste('"Runoff_GPCCv7+Dist_FAOGAULCountry_',resolution,'_Annual"',sep="")
  selectStatement <- paste('SELECT * FROM ',schema,'.',tblName,'WHERE "SampleID" = ',gaulCode,' ORDER BY "Year"',sep="")
  dfGPCC    <- dbGetQuery(dbCon, selectStatement)
  tblName   <- paste('"Runoff_GPCCmonV5+Dist_FAOGAULCountry_',resolution,'_Annual"',sep="")
  selectStatement <- paste('SELECT * FROM ',schema,'.',tblName,'WHERE "SampleID" = ',gaulCode,' ORDER BY "Year"',sep="")
  dfGPCCmon <- dbGetQuery(dbCon, selectStatement)
  tblName   <- paste('"Runoff_GPCCfirstDaily+Dist_FAOGAULCountry_',resolution,'_Annual"',sep="")
  selectStatement <- paste('SELECT * FROM ',schema,'.',tblName,'WHERE "SampleID" = ',gaulCode,' ORDER BY "Year"',sep="")
  dfFirst   <- dbGetQuery(dbCon, selectStatement)
  
  runoffMin <- min(dfCRUTS$ZonalMean,dfGPCC$ZonalMean,dfGPCCmon$ZonalMean,dfFirst$ZonalMean)*0.9
  runoffMax <- max(dfCRUTS$ZonalMean,dfGPCC$ZonalMean,dfGPCCmon$ZonalMean,dfFirst$ZonalMean)*1.2
  legendPos <- runoffMin+(runoffMax-runoffMin)*0.95
  fileName  <- paste("Figures/Fig_",gaulCode,'_Runoff_',resolution,'_Annual.pdf',sep="")
  pdf(file=fileName,paper="special", width=pageWidth, height=pageHeight, pointsize = pointSize)
  par(mar=c(5,7,4,2))
  plot (dfCRUTS$Year,dfCRUTS$ZonalMean,
        main="Annual Runoff",
        xlim=c(1900,2020),
        ylim=c(runoffMin,runoffMax),
        xlab="Time [year]",ylab="Runoff [mm/yr]",type="l", col="black", lwd=2.5,
        cex.main=2.5, cex.lab = 2, cex.axis=1.5)
  lines(dfGPCC$Year,    dfGPCC$ZonalMean,    col="red",   lwd=2.5)
  lines(dfGPCCmon$Year, dfGPCCmon$ZonalMean, col="green", lwd=2.5)
  lines(dfFirst$Year,   dfFirst$ZonalMean,   col="blue",  lwd=2.5)
  legend(1900,legendPos, # places a legend at the appropriate place (upper corner of legend box)
         legend = c("CRUTSv401",  "GPCCv7", "GPCCmonV5", "GPCCfirstGuess"), # puts text in the legend
         lty    = c(1,      1,     1,       1),   # gives the legend appropriate symbols (lines)
         lwd    = c(2.5,    2.5,   2.5,     2.5),
         col    = c('black','red', 'green', 'blue')) # gives the legend lines the correct color and width
  dev.off ()
  dbDisconnect(dbCon)
}

DrawCountryMonthlyRunoff <- function (pageWidth, pageHeight, pointSize, statCode, gaulCode, countryName, resolution, modelRun) {
  dbCon <- dbConnect(dbDrv, dbname = "PostGIS_COMPASS", host = "10.16.12.60", port = 5432)
  
  schema    <- '"WBMOutput"'
  tblName   <- paste('"Runoff_',modelRun,'_FAOGAULCountry_',resolution,'_Monthly"',sep="")
  selectStatement=paste('SELECT "Month", AVG ("ZonalMean") AS "MeanRunoff", MIN ("ZonalMean") AS "MinRunoff", MAX ("ZonalMean") AS "MaxRunoff"
                         FROM ',schema,'.',tblName,'WHERE "SampleID" = ',gaulCode,'GROUP BY "Month" ORDER BY "Month"',sep="")
  df <- dbGetQuery(dbCon, selectStatement)

  runoffMin <- min(df$MinRunoff)*0.9
  runoffMax <- max(df$MaxRunoff)*1.2
  legendPos <- runoffMin+(runoffMax-runoffMin)*0.95
  fileName  <- paste("Figures/Fig_",gaulCode,'_Runoff_',modelRun,"_",resolution,'_Monthly.pdf',sep="")
  pdf(file=fileName,paper="special", width=pageWidth, height=pageHeight, pointsize = pointSize)
  par(mar=c(5,7,4,2))
  plot (df$Month,df$MeanRunoff,
        main=modelRun,
        xlim=c(1,12),
        ylim=c(runoffMin,runoffMax),
        xlab="Time [month]",ylab="Runoff [mm/yr]",type="l", col="black", lwd=2.5,
        cex.main=2.5, cex.lab = 2, cex.axis=1.5)
  lines(df$Month,df$MinRunoff, col="red",   lwd=2.5)
  lines(df$Month,df$MaxRunoff, col="green", lwd=2.5)
  legend(1,legendPos, # places a legend at the appropriate place (upper corner of legend box)
         legend = c("Mean", "Minimum", "Maximum"), # puts text in the legend
         lty    = c(1,      1,         1),         # gives the legend appropriate symbols (lines)
         lwd    = c(2.5,    2.5,       2.5),
         col    = c('black','red',     'green'))   # gives the legend lines the correct color and width
  dev.off ()
  dbDisconnect(dbCon)
}

DrawCountryAnnualDischarge <- function (pageWidth, pageHeight, pointSize, statCode, gaulCode, countryName, resolution, modelRun)
{
   dbCon <- dbConnect(dbDrv, dbname = "PostGIS_COMPASS", host = "10.16.12.60", port = 5432)
  
   faoSchema <- '"FAO-GAUL2014"'
   faoTable  <- '"Global_CountryCrossing_FAO-GAUL2014_06min"'
  wbmSchema  <- '"WBMOutput"'
   wbmTable  <- paste ('"Discharge_',modelRun,'_FAOGAULCrossing_06min_Annual"',sep="")
  selectStatement <- paste('SELECT "ToView"."CountryCODE"                       AS "CounryCODE",
                                  "ToView"."Year"                                AS "Year",
                                  "ToView"."Entering" - "NextView"."Re-entering" AS "Entering",
                                "FromView"."Leaving"  - "NextView"."Re-entering" AS "Leaving",
                                "FromView"."Leaving"  -   "ToView"."Entering"    AS "Difference"
                          FROM
                          (SELECT   ',faoSchema,".",faoTable,'."ToCountryCODE"    AS "CountryCODE",
                                    ',wbmSchema,".",wbmTable,'."Year"             AS "Year",
                               SUM (',wbmSchema,".",wbmTable,'."Discharge")       AS "Entering"
                           FROM     ',faoSchema,".",faoTable,',',wbmSchema,".",wbmTable,'
                           WHERE    ',faoSchema,".",faoTable,'."ToCountryCODE" = ', gaulCode,'
                           AND      ',faoSchema,".",faoTable,'."ID" = ',wbmSchema,".",wbmTable,'."SampleID" 
                           GROUP BY ',faoSchema,".",faoTable,'."ToCountryCODE", ',wbmSchema,".",wbmTable,'."Year")',' AS "ToView"
                          NATURAL LEFT JOIN
                          (SELECT  ',faoSchema,".",faoTable,'."CountryCODE"       AS "CountryCODE",
                                   ',wbmSchema,".",wbmTable,'."Year"              AS "Year",
                              SUM (',wbmSchema,".",wbmTable,'."Discharge")        AS "Leaving"
                           FROM    ',faoSchema,".",faoTable,',',wbmSchema,".",wbmTable,'
                           WHERE   ',faoSchema,".",faoTable,'."CountryCODE" = ', gaulCode,'
                           AND     ',faoSchema,".",faoTable,'."ID" = ',wbmSchema,".",wbmTable,'."SampleID" 
                           GROUP BY ',faoSchema,".",faoTable,'."CountryCODE", ',wbmSchema,".",wbmTable,'."Year")',' AS "FromView"
                          NATURAL LEFT JOIN
                          (SELECT  ',faoSchema,".",faoTable,'."NextCountryCODE"   AS "CountryCODE",
                                   ',wbmSchema,".",wbmTable,'."Year"              AS "Year",
                              SUM (',wbmSchema,".",wbmTable,'."Discharge")        AS "Re-entering"
                           FROM    ',faoSchema,".",faoTable,',',wbmSchema,".",wbmTable,'
                           WHERE    ',faoSchema,".",faoTable,'."NextCountryCODE" = ', gaulCode,'
                           AND      ',faoSchema,".",faoTable,'."ID" = ',wbmSchema,".",wbmTable,'."SampleID" 
                          GROUP BY  ',faoSchema,".",faoTable,'."NextCountryCODE", ',wbmSchema,".",wbmTable,'."Year")',' AS "NextView"
                          ORDER BY  "Year";',sep="")
   df <- dbGetQuery(dbCon, selectStatement)
   
   dischMin <- min(df$Entering,df$Leaving)*0.9
   dischMax <- max(df$Entering,df$Leaving)*1.2
   if (abs (dischMin) > 1000.0) {
     multiplyer = 0.001;
     yLabel='Discharge [" ~ 10^{3}~m^{3}~s^{-1} ~ "]'
     dischMax = dischMax * multiplyer
     dischMin = dischMin * multiplyer
   }
   else {
     multiplyer = 1.0; yLabel="Discharge [" ~ m^{3}~s^{-1} ~ "]"
   }
   legendPos <- dischMin+(dischMax-dischMin)*0.95
   fileName <- paste("Figures/Fig_",gaulCode,'_Discharge_',modelRun,'_06min_Annual.pdf',sep="")
   pdf(file=fileName,paper="special", width=pageWidth, height=pageHeight, pointsize = pointSize)
   par(mar=c(5,7,4,2))
   plot (df$Year,df$Leaving * multiplyer,
         main=modelRun,
         xlim=c(1900,2020),
         ylim=c(dischMin,dischMax),
         xlab="Time [year]", ylab=yLabel, type="l", col="black", lwd=2.5,
         cex.main=2.5, cex.lab = 2, cex.axis=1.5)
   lines(df$Year,df$Entering, col="red", lwd=2.5)
   legend(1900,legendPos, # places a legend at the appropriate place (upper corner of legend box)
          legend = c("Leaving", "Entering"), # puts text in the legend
          lty    = c(1,      1),             # gives the legend appropriate symbols (lines)
          lwd    = c(2.5,    2.5),
          col    = c('black','red'))         # gives the legend lines the correct color and width
   dev.off ()
   dbDisconnect(dbCon)
}

DrawCountryMonthlyDischarge <- function (pageWidth, pageHeight, pointSize, statCode, gaulCode, countryName, resolution, modelRun)
{
  dbCon <- dbConnect(dbDrv, dbname = "PostGIS_COMPASS", host = "10.16.12.60", port = 5432)
  
  faoSchema <- '"FAO-GAUL2014"'
  faoTable  <- '"Global_CountryCrossing_FAO-GAUL2014_06min"'
  wbmSchema  <- '"WBMOutput"'
  wbmTable  <- paste ('"Discharge_',modelRun,'_FAOGAULCrossing_06min_Monthly"',sep="")
  selectStatement <- paste('SELECT "ToView"."CountryCODE"                        AS "CounryCODE",
                           "ToView"."Year"                                       AS "Year",
                           "ToView"."Month"                                      AS "Month",
                           "ToView"."Entering" - "NextView"."Re-entering"        AS "Entering",
                           "FromView"."Leaving"  - "NextView"."Re-entering"      AS "Leaving",
                           "FromView"."Leaving"  -   "ToView"."Entering"         AS "Difference"
                           FROM
                           (SELECT   ',faoSchema,".",faoTable,'."ToCountryCODE"  AS "CountryCODE",
                           ',wbmSchema,".",wbmTable,'."Year"                     AS "Year",
                           ',wbmSchema,".",wbmTable,'."Month"                    AS "Month",
                           SUM (',wbmSchema,".",wbmTable,'."Discharge")          AS "Entering"
                           FROM     ',faoSchema,".",faoTable,',',wbmSchema,".",wbmTable,'
                           WHERE    ',faoSchema,".",faoTable,'."ToCountryCODE" = ', gaulCode,'
                           AND      ',faoSchema,".",faoTable,'."ID" = ',wbmSchema,".",wbmTable,'."SampleID" 
                           GROUP BY ',faoSchema,".",faoTable,'."ToCountryCODE", ',wbmSchema,".",wbmTable,'."Year", ',wbmTable,'."Month")',' AS "ToView"
                           NATURAL LEFT JOIN
                           (SELECT  ',faoSchema,".",faoTable,'."CountryCODE"     AS "CountryCODE",
                           ',wbmSchema,".",wbmTable,'."Year"                     AS "Year",
                           ',wbmSchema,".",wbmTable,'."Month"                    AS "Month",
                           SUM (',wbmSchema,".",wbmTable,'."Discharge")          AS "Leaving"
                           FROM    ',faoSchema,".",faoTable,',',wbmSchema,".",wbmTable,'
                           WHERE   ',faoSchema,".",faoTable,'."CountryCODE" = ', gaulCode,'
                           AND     ',faoSchema,".",faoTable,'."ID" = ',wbmSchema,".",wbmTable,'."SampleID" 
                           GROUP BY ',faoSchema,".",faoTable,'."CountryCODE", ',wbmSchema,".",wbmTable,'."Year", ',wbmTable,'."Month")',' AS "FromView"
                           NATURAL LEFT JOIN
                           (SELECT  ',faoSchema,".",faoTable,'."NextCountryCODE" AS "CountryCODE",
                           ',wbmSchema,".",wbmTable,'."Year"                     AS "Year",
                           ',wbmSchema,".",wbmTable,'."Month"                    AS "Month",
                           SUM (',wbmSchema,".",wbmTable,'."Discharge")          AS "Re-entering"
                           FROM    ',faoSchema,".",faoTable,',',wbmSchema,".",wbmTable,'
                           WHERE    ',faoSchema,".",faoTable,'."NextCountryCODE" = ', gaulCode,'
                           AND      ',faoSchema,".",faoTable,'."ID" = ',wbmSchema,".",wbmTable,'."SampleID" 
                           GROUP BY  ',faoSchema,".",faoTable,'."NextCountryCODE", ',wbmSchema,".",wbmTable,'."Year", ',wbmTable,'."Month")',' AS "NextView"
                           ORDER BY  "Year";',sep="")
  df <- dbGetQuery(dbCon, selectStatement)
  
  dischMin <- min(df$Entering,df$Leaving)*0.9
  dischMax <- max(df$Entering,df$Leaving)*1.2
  if (abs (dischMin) > 1000.0) {
    multiplyer = 0.001;
    yLabel='Discharge [" ~10^3~m^3~s^{-1}~ "]'
    dischMax = dischMax * multiplyer
    dischMin = dischMin * multiplyer
  }
  else {
    multiplyer = 1.0; yLabel="Discharge [" ~ m^3~s^{-1}~ "]"
  }
  legendPos <- dischMin+(dischMax-dischMin)*0.95
  fileName <- paste("Figures/Fig_",gaulCode,'_Discharge_',modelRun,'_06min_Monthly.pdf',sep="")
  pdf(file=fileName,paper="special", width=pageWidth, height=pageHeight, pointsize = pointSize)
  par(mar=c(5,7,4,2))
  plot (df$Year + (df$Month - 1) / 12,df$Leaving * multiplyer,
        main=modelRun,
        xlim=c(2000,2020),
        ylim=c(dischMin,dischMax),
        xlab="Time [year]", ylab=yLabel, type="l", col="black", lwd=2.5,
        cex.main=2.5, cex.lab = 2, cex.axis=1.5)
  lines(df$Year + (df$Month - 1) / 12,df$Entering, col="red", lwd=2.5)
  legend(2000,legendPos, # places a legend at the appropriate place (upper corner of legend box)
         legend = c("Leaving", "Entering"), # puts text in the legend
         lty    = c(1,      1),             # gives the legend appropriate symbols (lines)
         lwd    = c(2.5,    2.5),
         col    = c('black','red'))         # gives the legend lines the correct color and width
  dev.off ()
  dbDisconnect(dbCon)
}

DrawCountryMap               ( 4, 4, 1, statCode, gaulCode, countryName, '06min')
DrawCountryAnnualPopulation (15, 8,15, statCode, gaulCode, countryName, '06min')
DrawCountryAnnualRunoff     (15, 8,15, statCode, gaulCode, countryName, '06min')
DrawCountryMonthlyRunoff    (15, 8,15, statCode, gaulCode, countryName, '06min', 'CRUTSv401+Dist')
DrawCountryMonthlyRunoff    (15, 8,15, statCode, gaulCode, countryName, '06min', 'GPCCv7+Dist')
DrawCountryMonthlyRunoff    (15, 8,15, statCode, gaulCode, countryName, '06min', 'GPCCmonV5+Dist')
DrawCountryMonthlyRunoff    (15, 8,15, statCode, gaulCode, countryName, '06min', 'GPCCfirstDaily+Dist')
DrawCountryAnnualDischarge  (15, 8,15, statCode, gaulCode, countryName, '06min', 'CRUTSv401+Dist')
DrawCountryAnnualDischarge  (15, 8,15, statCode, gaulCode, countryName, '06min', 'GPCCv7+Dist')
DrawCountryMonthlyDischarge (15, 8,15, statCode, gaulCode, countryName, '06min', 'GPCCmonV5+Dist')
DrawCountryMonthlyDischarge (15, 8,15, statCode, gaulCode, countryName, '06min', 'GPCCfirstDaily+Dist')

dbUnloadDriver(dbDrv)