#!/bin/bash
if [ "${GHAASDIR}" == "" ]; then GHAASDIR="/usr/local/share/ghaas"; fi
source "${GHAASDIR}/Scripts/RGISfunctions.sh"

if [ "${0%/*}" != "." ]; then PROJECTDIR="${0%/*}"; PROJECTDIR="${PROJECTDIR%/Scripts}"; else PROJECTDIR=".."; fi

IFS='	'
MAXCOUNT=500
COUNT=0

CURDIR=$(pwd)

cd "${PROJECTDIR}/LaTeX"

cat "COMPASS Preamble.tex" > "COMPASS Main.tex"

  cat "../ASCII/FAO_GAUL2FAOSTAT.txt" | sed "1d" |\
  (while read line
   do
	COUNT=$(echo "${COUNT} + 1" | bc)
	columns=(${line})
	CNTRYNAME="${columns[0]}"
	FAOSTATID="${columns[1]}"
	FAOGAULID="${columns[2]}"
	echo ${CNTRYNAME} > /dev/stderr
	echo "\include{CountryPages/CountryPage_${FAOGAULID}} \pagebreak" >> "COMPASS Main.tex"

	 POPQUERY="SELECT to_char(\"value\" * 1000,'9,999,999,999') FROM \"country_statistics_fao2\".\"population_e_all_data\"   WHERE \"areacode\" = ${FAOSTATID} AND \"year\" = 2017 AND \"element\" = 'Total Population - Both sexes';"
	 CNTRYPOP=$(echo ${POPQUERY}  | psql -h 10.16.12.60 "PostGIS_Global" | sed "1,2d" | sed "2,3d")
	AREAQUERY="SELECT to_char(\"value\" * 10,'9,999,999,999') FROM \"country_statistics_fao2\".\"inputs_landuse_e_all_data\" WHERE \"areacode\" = ${FAOSTATID} AND \"year\" = 2015 AND \"item\"    = 'Country area';"
	CNTRYAREA=$(echo ${AREAQUERY} | psql -h 10.16.12.60 "PostGIS_Global" | sed "1,2d" | sed "2,3d")
	CNTRYDENS=$(printf "%5.1f" $(echo "${CNTRYPOP} / ${CNTRYAREA}" | sed "s:,::g" | bc -l))

	$(cat "CountryPageTEMPLATE.tex"    |\
	  sed "s:CNTRYCODE:${FAOGAULID}:g" |\
	  sed "s:CNTRYNAME:${CNTRYNAME}:g" |\
	  sed "s:CNTRYPOP:${CNTRYPOP}:g"   |\
	  sed "s:CNTRYAREA:${CNTRYAREA}:g" |\
	  sed "s:CNTRYDENS:${CNTRYDENS}:g" |\
	  cat > "CountryPages/CountryPage_${FAOGAULID}.tex")

#	Rscript "../Rscripts/COMPASS_Graphics.R" "${FAOSTATID}" "${FAOGAULID}" "${CNTRYNAME}"

	if (( "${COUNT}" >= "${MAXCOUNT}" )); then break; fi
	done)

cat "COMPASS Conclude.tex" >> "COMPASS Main.tex"

pdflatex "COMPASS Main.tex"
