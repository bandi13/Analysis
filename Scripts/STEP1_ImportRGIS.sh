#!/bin/bash
if [ "${GHAASDIR}" == "" ]; then GHAASDIR="/usr/local/share/ghaas"; fi
source "${GHAASDIR}/Scripts/pgFunctions.sh"

if [ "${0%/*}" != "." ]; then PROJECTDIR="${0%/*}"; PROJECTDIR="${PROJECTDIR%/Scripts}"; else PROJECTDIR=".."; fi

RGISARCHIVE="/asrc/RGISarchive2"

if [ "${3}" == "" ]
then
	echo "Usage ${0##*/} [domain] [resolution] [sensitive|lower|upper]"
	exit 1
fi

         DOMAIN="${1}"; shift
     RESOLUTION="${1}"; shift
        CASEVAL="${1}"; shift

function Import_Streamline ()
{
	local    archive="${1}"
	local     domain="${2}"
	local resolution="${3}"
	local     dbName="${4}"
	local    caseVal="${5}"

	local rgisFile="$(RGISfile "${archive}" "${domain}" "streamline" "HydroSTN30" "${resolution}" "static")"
	rgis2PostGIS -c "${caseVal}" -d "$(PGdbName ${dbName})" -s "HydroSTN30"  -t "Streamline_${resolution}" "${rgisFile}"
}

function Import_Confluence
{
	local    archive="${1}"
	local     domain="${2}"
	local resolution="${3}"
	local     dbName="${4}"
	local    caseVal="${5}"

	local rgisFile="$(RGISfile "${archive}" "${domain}" "confluence" "HydroSTN30" "${resolution}" "static")"
	rgis2PostGIS -c "${caseVal}" -d "$(PGdbName ${dbName})" -s "HydroSTN30"  -t "Confluence_${resolution}" "${rgisFile}"
}

function Import_Subbasin ()
{
	local    archive="${1}"
	local     domain="${2}"
	local resolution="${3}"
	local     dbName="${4}"
	local    caseVal="${5}"

	local rgisFile="$(RGISfile "${archive}" "${domain}" "subbasin"   "HydroSTN30"  "${resolution}" "static")"
	rgis2PostGIS -c "${caseVal}" -d "$(PGdbName ${dbName})" -s "HydroSTN30"  -t "Subbasin_${resolution}" "${rgisFile}"
	PGpolygonColorizeSQL "sensitive" "HydroSTN30" "Subbasin_06min" "geom" "BasinID" "myCOLOR" | psql "$(PGdbName "${domain}")"
}

function Import_AdminUnits ()
{
	local    archive="${1}"
	local     domain="${2}"
	local resolution="${3}"
	local adminUnits="${4}"
	local     dbName="${5}"
	local    caseVal="${6}"

	case ${adminUnits} in
		(Countries)
			local admCode="adm0_code"
		;;
		(States)
			local admCode="adm1_code"
		;;
		(Counties)
			local admCode="adm2_code"
		;;
	esac	
	local rgisFile="$(RGISfile "${archive}" "${domain}" "$(RGIScase "lower" "${adminUnits}")"  "FAO-GAUL2014" "${resolution}" "TS" "annual" "2013")"
	rgis2PostGIS -c "${caseVal}" -d "$(PGdbName ${dbName})" -s "FAO-GAUL2014"  -t "${adminUnits}_${resolution}" "${rgisFile}"
	PGpolygonColorizeSQL "sensitive" "FAO-GAUL2014" "${adminUnits}_${resolution}" "geom" "ID" "Color" | psql "$(PGdbName "${domain}")"
}

function Import_Crossings ()
{
	local    archive="${1}"
	local     domain="${2}"
	local resolution="${3}"
	local adminUnits="${4}"
	local     dbName="${5}"
	local    caseVal="${6}"

	case ${adminUnits} in
		(Countries)
			local crossings="Crossing-Countries"
		;;
		(States)
			local crossings="Crossing-States"
		;;
		(Counties)
			local crossings="Crossing-Counties"
		;;
	esac

	local rgisFile="${archive}/${domain}/${crossings}/HydroSTN30/${resolution}/Static/${domain}_${crossings}_HydroSTN30_${resolution}_Static.gdbp.gz"
	rgis2PostGIS -c "${caseVal}" -d "$(PGdbName "${dbName}")" -s "FAO-GAUL2014"  -t "${crossings}_${resolution}" "${rgisFile}"
}

Import_Streamline "${RGISARCHIVE}" "${DOMAIN}" "${RESOLUTION}"             "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_Streamline_${RESOLUTION}").log       2>&1
Import_Confluence "${RGISARCHIVE}" "${DOMAIN}" "${RESOLUTION}"             "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_Confluence_${RESOLUTION}").log       2>&1
Import_Subbasin   "${RGISARCHIVE}" "${DOMAIN}" "${RESOLUTION}"             "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_Subbasin_${RESOLUTION}").log         2>&1

case ${RESOLUTION} in
	(3m45s|03min|1m30s|01min|45dec|30sec|15sec)
		Import_AdminUnits "${RGISARCHIVE}" "${DOMAIN}" "${RESOLUTION}" "Countries" "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_Countries_${RESOLUTION}").log        2>&1
		Import_AdminUnits "${RGISARCHIVE}" "${DOMAIN}" "${RESOLUTION}" "States"    "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_States_${RESOLUTION}").log           2>&1
		Import_AdminUnits "${RGISARCHIVE}" "${DOMAIN}" "${RESOLUTION}" "Counties"  "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_Counties_${RESOLUTION}").log         2>&1
		Import_Crossings  "${RGISARCHIVE}"   "${DOMAIN}" "${RESOLUTION}" "Countries" "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_CountryCrossings_${RESOLUTION}").log 2>&1
		Import_Crossings  "${RGISARCHIVE}"   "${DOMAIN}" "${RESOLUTION}" "States"    "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_StateCrossings_${RESOLUTION}").log   2>&1
		Import_Crossings  "${RGISARCHIVE}"   "${DOMAIN}" "${RESOLUTION}" "Counties"  "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_CountyCrossings_${RESOLUTION}").log  2>&1
	;;
	(06min|05min)
		Import_AdminUnits "${RGISARCHIVE}" "${DOMAIN}" "${RESOLUTION}" "Countries" "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_Countries_${RESOLUTION}").log        2>&1
		Import_AdminUnits "${RGISARCHIVE}" "${DOMAIN}" "${RESOLUTION}" "States"    "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_States_${RESOLUTION}").log           2>&1
		Import_Crossings  "${RGISARCHIVE}"   "${DOMAIN}" "${RESOLUTION}" "Countries" "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_CountryCrossings_${RESOLUTION}").log 2>&1
		Import_Crossings  "${RGISARCHIVE}"   "${DOMAIN}" "${RESOLUTION}" "States"    "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_StateCrossings_${RESOLUTION}").log   2>&1
	;;
	(*)
		Import_AdminUnits "${RGISARCHIVE}" "${DOMAIN}" "${RESOLUTION}" "Countries" "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_Countries_${RESOLUTION}").log        2>&1
		Import_Crossings  "${RGISARCHIVE}"   "${DOMAIN}" "${RESOLUTION}" "Countries" "$(RGIScase "${CASEVAL}" "${DOMAIN}")" "${CASEVAL}" > Logs/Import_$(RGIScase "${CASEVAL}" "${DOMAIN}_CountryCrossings_${RESOLUTION}").log 2>&1
	;;
esac
