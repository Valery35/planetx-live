# planetx-live

Copies of live and large data for the web page of
[PlanetX Lite](https://github.com/Valery35/planetx-lite).

The services below send no CORS header, so a browser page cannot read
them directly. The desktop program reads the services itself, and the
page reads these copies.

Every 3 hours the workflow `.github/workflows/copy.yml` runs
`scripts/copy.sh` and replaces the `data` branch with a single commit, so
the old copies do not pile up in history.

| Path in `data` | Source | Terms |
|---|---|---|
| `currents/<day>.nc`, `currents/latest.nc` | NOAA CoastWatch ERDDAP `nesdisSSH1day`, geostrophic currents, 0.5° grid, last 7 days | NOAA, public domain |
| `fires/J1_VIIRS_C2_Global_24h.csv` | NASA FIRMS, VIIRS NOAA-20, last 24 hours | NASA FIRMS |
| `volcanoes/holocene.csv` | Smithsonian Global Volcanism Program | GVP, cite the source |
| `static/global_mining_polygons_v2.gpkg` | Maus et al. 2022, PANGAEA 942325 | CC BY-SA 4.0 |
| `static/crust1.0.tar.gz` | CRUST1.0, Laske et al. | free for research |
| `static/SEISGLOB2_percent.r0.0-n4c.nc` | SEISGLOB2, EarthScope EMC | see EMC |
| `static/gufm1.txt` | gufm1, Jackson et al. 2000 | free for research |

The rights to the data stay with their sources. Each copy keeps the
source's credit in PlanetX Lite.
