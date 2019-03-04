#!/bin/bash
if [ "${GHAASDIR}" == "" ]; then GHAASDIR="/usr/local/share/ghaas"; fi
source "${GHAASDIR}/Scripts/pgFunctions.sh"

if [ "${0%/*}" != "." ]; then PROJECTDIR="${0%/*}"; PROJECTDIR="${PROJECTDIR%/Scripts}"; else PROJECTDIR=".."; fi

RGISARCHIVE="/asrc/RGISarchive2"
  RGISLOCAL="/asrc/COMPASS/Core/Analysis/RGISlocal"
RGISRESULTS="/asrc/COMPASS/Core/ModelRuns/RGISresults"

function PrintUsage ()
{
	echo "Usage ${0##*/} [domain] [CRUTSv401|GPCCv7] [dist|prist] [resolution] [case]"
	exit 1
}

if [[ "${5}" == "" ]]; then PrintUsage; fi

         DOMAIN="${1}"; shift
        PRODUCT="${1}"; shift
     EXPERIMENT="${1}"; shift
     RESOLUTION="${1}"; shift
        CASEVAL="${1}"; shift

function Sample_ModelOutput ()
{
	local      caseVal="${1}"; shift
	local       dbName="${1}"; shift
	local       schema="${1}"; shift
	local  globArchive="${1}"; shift
	local modelArchive="${1}"; shift
	local       domain="${1}"; shift
	local   resolution="${1}"; shift
	local  samplerType="${1}"; shift
	local      product="${1}"; shift
	local     variable="${1}"; shift

	case "${samplerType}" in
	(confluence)
		local  samplerFile="$(RGISfile "${globArchive}" "${domain}" "confluence" "HydroSTN30" "${resolution}" "static")"
		local samplingMode="point"
		local      tblName="$(RGISlookupSubject "${variable}")_Conf_${resolution}"
	;;
	(crossing-countries)
		local  samplerFile="${globArchive}/${domain}/Crossing-Countries/HydroSTN30/${resolution}/Static/${domain}_Crossing-Countries_HydroSTN30_${resolution}_Static.gdbp.gz"
		local samplingMode="point"
		local      tblName="$(RGISlookupSubject "${variable}")_Countries_${resolution}"
	;;
	(crossing-states)
		local  samplerFile="${globArchive}/${domain}/Crossing-States/HydroSTN30/${resolution}/Static/${domain}_Crossing-States_HydroSTN30_${resolution}_Static.gdbp.gz"
		local samplingMode="point"
		local      tblName="$(RGISlookupSubject "${variable}")_States_${resolution}"
	;;
	(crossing-counties)
		local  samplerFile="${globArchive}/${domain}/Counties/HydroSTN30/${resolution}/Static/${domain}_Crossing-Counties_HydroSTN30_${resolution}_Static.gdbp.gz"
		local samplingMode="point"
		local      tblName="$(RGISlookupSubject "${variable}")_Counties_${resolution}"
	;;
	(countries)
		local  samplerFile="$(RGISfile "${globArchive}" "${domain}" "countries"  "FAO-GAUL2014" "${resolution}" "TS" "annual" "2013")"
		local samplingMode="grid"
		local     tblName="$(RGISlookupSubject "${variable}")_Countries_${resolution}"
	;;
	(states)
		local  samplerFile="$(RGISfile "${globArchive}" "${domain}" "states"  "FAO-GAUL2014" "${resolution}" "TS" "annual" "2013")"
		local samplingMode="grid"
		local      tblName="$(RGISlookupSubject "${variable}")_States_${resolution}"
	;;
	(counties)
		local  samplerFile="$(RGISfile "${globArchive}" "${domain}" "counties"  "FAO-GAUL2014" "${resolution}" "TS" "annual" "2013")"
		local samplingMode="grid"
		local      tblName="$(RGISlookupSubject "${variable}")_Counties_${resolution}"
	;;
	(subbasin)
		local  samplerFile="$(RGISfile "${globArchive}" "${domain}" "subbasin"    "HydroSTN30" "${resolution}" "static")"
		local samplingMode="grid"
		local      tblName="$(RGISlookupSubject "${variable}")_Subbasin_${resolution}"
	;;
	(*)
		return 1
	;;
	esac
	 dbName="$(RGIScase "${caseVal}" "${dbName}")"
	tblName="$(RGIScase "${caseVal}" "${tblName}")"

	case "${product}" in
	(CRUTSv401+Prist|CRUTSv401+Dist)
		local startYear="1901"
		local   endYear="2016"
	;;
	(GPCCv7+Prist|GPCCv7+Dist)
		local startYear="1901"
		local   endYear="2013"
	;;
	(GPCCfullDailyV1+Prist|GPCCfullDailyV1+Dist)
		local startYear="1989"
		local   endYear="2013"
	;;
	(GPCCmonV5+Prist|GPCCmonV5+Dist)
 		local startYear="1989"
		local   endYear="2017"
	;;
	(GPCCfirstDaily+Prist|GPCCfirstDaily+Dist)
 		local startYear="2017"
		local   endYear="2018"
	;;
	(*)
		echo "${product}"
		PrintUsage
	esac

	local     sqlMode="copy"
	local   tmpAnnual="Logs/$(RGIScase "${caseVal}" "${domain}_${product}_${tblName}")_annual.log"
	local  tmpMonthly="Logs/$(RGIScase "${caseVal}" "${domain}_${product}_${tblName}")_monthly.log"
	if [[ -e  "${tmpAnnual}"  ]]; then rm "${tmpAnnual}";  fi
	if [[ -e  "${tmpMonthly}" ]]; then rm "${tmpMonthly}"; fi
	for ((year = ${startYear}; year <= ${endYear}; ++year))
	do
		local  annualGrid="$(RGISfile "${modelArchive}" "${domain}" "$(RGISlookupSubject "${variable}")" "${product}" "${resolution}" "TS" "annual"  "${year}")"
		local monthlyGrid="$(RGISfile "${modelArchive}" "${domain}" "$(RGISlookupSubject "${variable}")" "${product}" "${resolution}" "TS" "monthly" "${year}")"
		case "${samplingMode}" in
		(point)
			pntGridSampling -s "${samplerFile}" -m "table" -t "Sampled Model Output" -d "${domain}" -u "$(RGISlookupSubject "${variable}")" "${annualGrid}" - |\
			tblDeleteField -f "LayerID"                     - - |\
			tblRedefField  -f "GHAASSampleID" -r "SampleID" - - |\
			tblRedefField  -f "LayerName" -r "Year"  -y int -w 4  - - |\
			rgis2sql -c "${caseVal}" -a "DBItems" -m "${sqlMode}" -s "${schema}" -q "${tblName}_annual"  | psql "$(PGdbName "${dbName}")" >> "${tmpAnnual}" 2>&1 &

			pntGridSampling -s "${samplerFile}" -m "table" -t "Sampled Model Output" -d "${domain}" -u "$(RGISlookupSubject "${variable}")" "${monthlyGrid}" - |\
			tblDeleteField -f "LayerID"                      - - |\
			tblRedefField  -f "GHAASSampleID" -r "SampleID"  - - |\
			tblRedefField  -f "LayerName" -r "Date"  -y date - - |\
			tblSplitDate   -f "Date" -y "Year" -m "Month"    - - |\
			rgis2sql -c "${caseVal}" -a "DBItems" -m "${sqlMode}" -s "${schema}" -q "${tblName}_monthly" | psql "$(PGdbName "${dbName}")" >> "${tmpMonthly}" 2>&1 &
		;;
		(grid)
			grdZoneStats -z "${samplerFile}" -t "Zonal averaged Model Output" -d "${domain}" -u "$(RGISlookupSubject "${variable}")"  "${annualGrid}" - |\
			tblDeleteField -f "ZoneLayerID" -f "ZoneLayerName" -f "ZoneGridName" -f "WeightLayerID" -f "ZonalStdDev" - - |\
			tblRedefField  -f "ZoneGridID"  -r "SampleID"  - - |\
			tblRedefField  -f "WeightLayerName" -r "Year" -y int -w 4 - - |\
			rgis2sql -c "${caseVal}" -a "DBItems" -m "${sqlMode}" -s "${schema}" -q "${tblName}_annual"  | psql "$(PGdbName "${dbName}")" >> "${tmpAnnual}" 2>&1 &

			grdZoneStats -z "${samplerFile}" -t "Zonal averaged Model Output" -d "${domain}" -u "$(RGISlookupSubject "${variable}")"  "${monthlyGrid}" - |\
			tblDeleteField -f "ZoneLayerID" -f "ZoneLayerName" -f "ZoneGridName" -f "WeightLayerID" -f "ZonalStdDev" - - |\
			tblRedefField  -f "ZoneGridID"  -r "SampleID"         - - |\
			tblRedefField  -f "WeightLayerName" -r "Date" -y date - - |\
			tblSplitDate   -f "Date" -y "Year" -m "Month"         - - |\
			rgis2sql -c "${caseVal}" -a "DBItems" -m "${sqlMode}" -s "${schema}" -q "${tblName}_monthly" | psql "$(PGdbName "${dbName}")" >> "${tmpMonthly}" 2>&1 &
		;;
		esac
		wait
		local sqlMode="append"
	done
	echo "ALTER TABLE \"$(RGIScase "${caseVal}"  "${schema}")\".\"${tblName}_annual\"  DROP COLUMN \"$(RGIScase "${caseVal}" "RecordName")\";" | psql "$(PGdbName "${dbName}")" >> "${tmpAnnual}"  2>&1
	echo "ALTER TABLE \"$(RGIScase "${caseVal}"  "${schema}")\".\"${tblName}_monthly\" DROP COLUMN \"$(RGIScase "${caseVal}" "RecordName")\";" | psql "$(PGdbName "${dbName}")" >> "${tmpMonthly}" 2>&1
	echo "${tblName} completed"	
#	rm "${tmpAnnual}" "${tmpMonthly}"
}


case ${RESOLUTION} in
	(3m45s|03min|2m30s|1m30s|01min|45dec|30sec|15sec)
		ADMINUNITS="countries states"
	;;
	(06min|05min)
		ADMINUNITS="countries states"
	;;
	(*)
		ADMINUNITS="countries"
	;;
esac

case ${EXPERIMENT} in
	(prist)
		SCHEMA="WBM_${PRODUCT}_Prist"
		echo "CREATE SCHEMA IF NOT EXISTS \"$(RGIScase "${CASEVAL}" "${SCHEMA}")\";" | psql "$(PGdbName "$(RGIScase "${CASEVAL}" "${DOMAIN}")")"
		Sample_ModelOutput "${CASEVAL}" "${DOMAIN}" "${SCHEMA}" "${RGISARCHIVE}" "${RGISRESULTS}" "${DOMAIN}" "${RESOLUTION}" "confluence" "${PRODUCT}+Prist" "Discharge"          &
		Sample_ModelOutput "${CASEVAL}" "${DOMAIN}" "${SCHEMA}" "${RGISARCHIVE}" "${RGISRESULTS}" "${DOMAIN}" "${RESOLUTION}" "subbasin"   "${PRODUCT}+Prist" "Evapotranspiration" &
		Sample_ModelOutput "${CASEVAL}" "${DOMAIN}" "${SCHEMA}" "${RGISARCHIVE}" "${RGISRESULTS}" "${DOMAIN}" "${RESOLUTION}" "subbasin"   "${PRODUCT}+Prist" "Runoff"             &
		wait
		for ADMIN in ${ADMINUNITS}
		do
			Sample_ModelOutput "${CASEVAL}" "${DOMAIN}" "${SCHEMA}" "${RGISARCHIVE}" "${RGISRESULTS}" "${DOMAIN}" "${RESOLUTION}" "crossing-${ADMIN}" "${PRODUCT}+Prist" "Discharge"          &
			Sample_ModelOutput "${CASEVAL}" "${DOMAIN}" "${SCHEMA}" "${RGISARCHIVE}" "${RGISRESULTS}" "${DOMAIN}" "${RESOLUTION}" "${ADMIN}"          "${PRODUCT}+Prist" "Evapotranspiration" &
			Sample_ModelOutput "${CASEVAL}" "${DOMAIN}" "${SCHEMA}" "${RGISARCHIVE}" "${RGISRESULTS}" "${DOMAIN}" "${RESOLUTION}" "${ADMIN}"          "${PRODUCT}+Prist" "Runoff"             &
			wait
		done
	;;
	(dist)
		SCHEMA="WBM_${PRODUCT}_Dist"
		echo "CREATE SCHEMA IF NOT EXISTS \"$(RGIScase "${CASEVAL}" "${SCHEMA}")\";" | psql "$(PGdbName "$(RGIScase "${CASEVAL}" "${DOMAIN}")")"
		Sample_ModelOutput "${CASEVAL}" "${DOMAIN}" "${SCHEMA}"  "${RGISARCHIVE}" "${RGISRESULTS}" "${DOMAIN}" "${RESOLUTION}" "confluence" "${PRODUCT}+Dist"  "Discharge"          &
		Sample_ModelOutput "${CASEVAL}" "${DOMAIN}" "${SCHEMA}"  "${RGISARCHIVE}" "${RGISRESULTS}" "${DOMAIN}" "${RESOLUTION}" "subbasin"   "${PRODUCT}+Dist"  "Evapotranspiration" &
		Sample_ModelOutput "${CASEVAL}" "${DOMAIN}" "${SCHEMA}"  "${RGISARCHIVE}" "${RGISRESULTS}" "${DOMAIN}" "${RESOLUTION}" "subbasin"   "${PRODUCT}+Dist"  "Runoff"             &
		Sample_ModelOutput "${CASEVAL}" "${DOMAIN}" "${SCHEMA}"  "${RGISARCHIVE}" "${RGISRESULTS}" "${DOMAIN}" "${RESOLUTION}" "subbasin"   "${PRODUCT}+Dist"  "Irrgrossdemand"     &
		wait
		for ADMIN in ${ADMINUNITS}
		do
			Sample_ModelOutput "${CASEVAL}" "${DOMAIN}" "${SCHEMA}"  "${RGISARCHIVE}" "${RGISRESULTS}" "${DOMAIN}" "${RESOLUTION}" "crossing-${ADMIN}" "${PRODUCT}+Dist"  "Discharge"          &
			Sample_ModelOutput "${CASEVAL}" "${DOMAIN}" "${SCHEMA}"  "${RGISARCHIVE}" "${RGISRESULTS}" "${DOMAIN}" "${RESOLUTION}" "${ADMIN}"          "${PRODUCT}+Dist"  "Evapotranspiration" &
			Sample_ModelOutput "${CASEVAL}" "${DOMAIN}" "${SCHEMA}"  "${RGISARCHIVE}" "${RGISRESULTS}" "${DOMAIN}" "${RESOLUTION}" "${ADMIN}"          "${PRODUCT}+Dist"  "Runoff"             &
		    Sample_ModelOutput "${CASEVAL}" "${DOMAIN}" "${SCHEMA}"  "${RGISARCHIVE}" "${RGISRESULTS}" "${DOMAIN}" "${RESOLUTION}" "${ADMIN}"          "${PRODUCT}+Dist"  "Irrgrossdemand"     &
			wait
		done
	;;
	(*)
		PrintUsage
	;;
esac