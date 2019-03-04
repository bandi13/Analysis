#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
  countryCode=1
  countryName="Afganistan"
} else if (length(args)==2) {
  countryCode=args[1]
  countryName=args[2]
} else  {
  stop ("Incomplete argument list",call.= TRUE)
}

require("RPostgreSQL")
setwd("/Users/balazs/Desktop/Analysis")

# create a connection
# save the password that we can "hide" it as best as we can by collapsing it

DrawCountryRunoff = function (countryCode, countryName,resolution,pageWidth,pageHeight,pointSize) {

  dbDrv <- dbDriver("PostgreSQL")
  dbCon <- dbConnect(dbDrv, dbname = "PostGIS_COMPASS", host = "10.16.12.60", port = 5432)
  schema='"WBMOutput"'
  tblName=paste('"Runoff_CRUTSv401+Prist_FAOGAULCountry_',resolution,'_Annual"',sep="")
  selectStatement=paste('SELECT * FROM ',schema,'.',tblName,'WHERE "SampleID" = ',countryCode,sep="")
  df <- dbGetQuery(dbCon, selectStatement)

  fileName=paste("Figures/Fig_",countryName,'_Runoff_',resolution,'_Annual.pdf',sep="")
  pdf(file=fileName,paper="special", width=pageWidth, height=pageHeight, pointsize = pointSize)
  par(mar=c(5,7,4,2))
  plot (df$Year,df$ZonalMean,
        main="Annual Runoff",
        xlab="Time [year]",ylab="Runoff [mm/yr]",type="l", col="black", lwd=2.5,
        cex.main=2.5, cex.lab = 2, cex.axis=1.5)
#  schema='"WBMOutput"'
#  tblName=paste('"Runoff_GPCCv7+Prist_FAOGAULCountry_',resolution,'_Annual"',sep="")
#  selectStatement=paste('SELECT * FROM ',schema,'.',tblName,'WHERE "SampleID" = ',countryCode,sep="")
#  df <- dbGetQuery(dbCon, selectStatement)
#  lines(df$Year,df$ZonalMean, col="green", lwd=2.5)
  dev.off ()
  dbDisconnect(dbCon)
  dbUnloadDriver(dbDrv)
}

DrawCountryRunoff (1,'Afganistan','06min',15,8,15)
