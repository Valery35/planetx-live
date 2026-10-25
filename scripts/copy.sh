#!/usr/bin/env bash
# PlanetX Lite - глобус PlanetX без QGIS.
# Copyright (C) 2026 ООО «Информ++». Лицензия Apache 2.0.
# SPDX-License-Identifier: Apache-2.0
#
# Копии данных для страницы PlanetX Lite. Службы ниже не отдают браузеру
# заголовок CORS, страница читает их копии отсюда, программа на компьютере
# ходит к службам сама. Копии кладутся в папку $1:
#   currents/<ГГГГ-ММ-ДД>.nc, currents/latest.nc - течения NOAA CoastWatch,
#     последние 7 суток, сетка 0.5°, как CURRENTS_URL в data::flow;
#   fires/J1_VIIRS_C2_Global_24h.csv - пожары NASA FIRMS за сутки;
#   volcanoes/holocene.csv - вулканы GVP;
#   static/ - постоянные файлы: контуры горных разработок, CRUST1.0,
#     томография SEISGLOB2, модель поля gufm1. Скачиваются один раз.
# Неудачная загрузка не портит прежнюю копию: файл пишется рядом
# и подменяет прежний, только если пришёл целиком.
set -u
out="$1"
agent="PlanetX-Lite copy (+https://github.com/Valery35/planetx-live)"
mkdir -p "$out/currents" "$out/fires" "$out/volcanoes" "$out/static"

# Скачать $1 в файл $2, если пришло не меньше $3 байт.
get() {
  local url="$1" file="$2" least="${3:-1}"
  local tmp="$file.part"
  if curl -fsSL --retry 3 --retry-delay 10 --max-time 900 -A "$agent" -o "$tmp" "$url"; then
    local size
    size=$(stat -c %s "$tmp")
    if [ "$size" -ge "$least" ]; then
      mv "$tmp" "$file"
      echo "ok $file $size"
      return 0
    fi
  fi
  rm -f "$tmp"
  echo "fail $url"
  return 1
}

erddap="https://coastwatch.pfeg.noaa.gov/erddap/griddap/nesdisSSH1day"
grid='%5B(-89.875):2:(89.875)%5D%5B(-179.875):2:(179.875)%5D'
currents_url() {
  echo "$erddap.nc?ugos%5B($1)%5D$grid,vgos%5B($1)%5D$grid"
}

# Последние готовые сутки течений.
last=$(curl -fsSL --max-time 120 -A "$agent" "$erddap.csv?time%5B(last)%5D" | sed -n '3p' | cut -c1-10)
if [ -n "$last" ]; then
  for back in 0 1 2 3 4 5 6; do
    day=$(date -u -d "$last -$back day" +%F)
    file="$out/currents/$day.nc"
    [ -s "$file" ] || get "$(currents_url "${day}T00:00:00Z")" "$file" 100000 || true
  done
  [ -s "$out/currents/$last.nc" ] && cp "$out/currents/$last.nc" "$out/currents/latest.nc"
  # Старше 7 суток - вон.
  keep=$(date -u -d "$last -6 day" +%F)
  for f in "$out"/currents/????-??-??.nc; do
    [ -e "$f" ] || continue
    name=$(basename "$f" .nc)
    [[ "$name" < "$keep" ]] && rm -f "$f"
  done
  echo "$last" > "$out/currents/last.txt"
fi

get "https://firms.modaps.eosdis.nasa.gov/data/active_fire/noaa-20-viirs-c2/csv/J1_VIIRS_C2_Global_24h.csv" "$out/fires/J1_VIIRS_C2_Global_24h.csv" 1000 || true
get "https://webservices.volcano.si.edu/geoserver/GVP-VOTW/ows?service=WFS&version=2.0.0&request=GetFeature&typeName=GVP-VOTW:Smithsonian_VOTW_Holocene_Volcanoes&outputFormat=csv" "$out/volcanoes/holocene.csv" 100000 || true

[ -s "$out/static/global_mining_polygons_v2.gpkg" ] || get "https://download.pangaea.de/dataset/942325/files/global_mining_polygons_v2.gpkg" "$out/static/global_mining_polygons_v2.gpkg" 20000000 || true
[ -s "$out/static/crust1.0.tar.gz" ] || get "https://igppweb.ucsd.edu/~gabi/crust1/crust1.0.tar.gz" "$out/static/crust1.0.tar.gz" 1000000 || true
[ -s "$out/static/SEISGLOB2_percent.r0.0-n4c.nc" ] || get "https://data.earthscope.org/archive/seismology/products/emc/netcdf/SEISGLOB2_percent.r0.0-n4c.nc" "$out/static/SEISGLOB2_percent.r0.0-n4c.nc" 20000000 || true
[ -s "$out/static/gufm1.txt" ] || get "https://geomag.colorado.edu/images/GUFM/gufm1.txt" "$out/static/gufm1.txt" 500000 || true
exit 0
