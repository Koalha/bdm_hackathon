#!/bin/bash
# Konsta Happonen, 2015

# Tämä skripti ajetaan GRASS 7:n sisältä.
# Se laskee syötetiedostolle lidar-johteisia metsämuuttujia
# Syötetiedoston on tarkoitus olla georeferoitu .las -tiedosto.

# utm5-karttalehtijako on pitänyt tuoda GRASSIIN PERMANENT-karttaan nimellä utm5

# ASCIINAME:n kansio on oltava olemassa.

# Tämän skriptin ongelma on, että se interpoloi neliön muotoisilla
# alueilla, ts. reuna-alueille voi tulla vääristymiä.

# Pitäisi laittaa testaukset alkuun varmistamaan, että tiedostot on
# olemassa.

LASFILE=$1
BASEFILE=${LASFILE##*/}
BASEFILE=${BASEFILE%.las}
DEMPATH="/mnt/grassdata/EPSG:3067/PERMANENT/laserkeilaus/demit/"
DEMBASEFILE=${BASEFILE%?}
DEM=${DEMPATH}${DEMBASEFILE}".asc"
ASCIINAME="/mnt/grassdata/EPSG:3067/PERMANENT/laserkeilaus/ascii/${BASEFILE}.txt" 
POINT_MAP="${BASEFILE}_points"
INT_RASTER="${BASEFILE}_intensity_2m"
MAXH_RASTER="${BASEFILE}_max_height_6m"
DEM_RASTER="${BASEFILE}_DEM_2m"
NONGROUND_RASTER="${BASEFILE}_nonground_n_6m"
N_RASTER="${BASEFILE}_n_6m"
COVER_RASTER="${BASEFILE}_canopycover_6m"


# Tämä tarkastaa skripin muuttujat
echo "LASFILE: $LASFILE"
echo "BASEFILE: $BASEFILE"
echo "DEMPATH: $DEMPATH"
echo "DEMBASEFILE: $DEMBASEFILE"
echo "DEM: $DEM"
echo "ASCIINAME: $ASCIINAME"
echo "POINT_MAP: $POINT_MAP"
echo "INT_RASTER: $INT_RASTER"
echo "MAXH_RASTER: $MAXH_RASTER"
echo "DEM_RASTER: $DEM_RASTER"
echo "NONGROUND_RASTER: $NONGROUND_RASTER"
echo "N_RASTER: $N_RASTER"
echo "COVER_RASTER: $COVER_RASTER"


# Tarkasta, että LAS-tiedosto ja DEM ovat olemassa.
if [ -f $LASFILE ];
then
    echo "$LASFILE exists"
else
    echo "$LASFILE doesn't exist."
    echo "Exiting..."
    exit 1
fi

if [ -f $DEM ];
then
    echo "$DEM exists"
else
    echo "$DEM doesn't exist."
    echo "Exiting..."
    exit 1
fi

# Muutetaan las-tiedosto pistevektoritiedostoksi – sitä on helpompi käsitellä GRASSISSA
echo "Muutetaan las-tiedostoa pistevektoritiedostoksi"
v.in.lidar -o --overwrite input=$LASFILE output=$POINT_MAP class_filter=1,2,3
echo "Valmis."

# Luodaan pistekartan tietokantaan uudet sarakkeet: DEM (maanpinnan korkeus) & normalisoitu DSM (eli "latvuskorkeus").
echo "Lisätään pistetietokantaan uusia sarakkeita DEM:ä ja NDSM:ä varten."
v.db.addcolumn map=$POINT_MAP columns="dem_value double precision,ndsm_value double precision"
echo "Valmis."

# Asetetaan laskenta-alue LAS-tiedoston karttalehden perusteella
echo "Asetetaan laskenta-aluetta..."
v.extract --overwrite input=utm5@keskisuomi output=$BASEFILE where="LEHTITUNNU = \"$BASEFILE\""
g.region vector=$BASEFILE res=2 -ap
echo "Valmis."

# Intensiteetin interpolointi 2 m rasteriksi etäisyyden käänteisluvulla painotetulla tasoitusfunktiolla
echo "Luodaan intensiteettirasteri..."
v.surf.idw --overwrite input=$POINT_MAP column=intensity output=$INT_RASTER npoints=12 power=12
echo "Valmis."

# Ladataan korkeusrasteri GRASSIIN. Asciissa ei CRS-tietoa, joten käytetään -o flägiä. Oltava siis ETRS-TM35FIN.
echo "Tuodaan korkeusrasteri GRASSIIN..."
r.in.gdal --overwrite -o input=$DEM output=$DEM_RASTER
echo "Valmis"

# Haetaan pistekartalle korkeusmallin korkeudet oikeaan sarakkeeseen
echo "Poimitaan DEMin tiedot pistetietokantaan..."
v.what.rast map=$POINT_MAP column=dem_value raster=$DEM_RASTER
echo "Valmis."

# Lasketaan NDSM-arvot pisteille
echo "Lasketaan NDSM-arvot pisteille..."
v.db.update map=$POINT_MAP column=ndsm_value query_column="z_coord-dem_value"
echo "Valmis."

# ote tiedostosta:
# cat|x_coord|y_coord|z_coord|intensity|return|n_returns|scan_dir|edge|cl_type|class|gps_time|angle|src_id|usr_data|red|green|blue|GRASSRGB|dem_value|ndsm_value
# 1|377499.94|6897012.98|106.37|11|1|1|0|0|Synthetic|Water|51464675.258683|-9|7|1|0|0|0|000:000:000|106.394|-0.0240000000000009


# r.in.xyz:aa varten pistekartta on exportoitava ASCII-tiedostoksi. Hmm.
echo "Viedään pistekartta tekstitiedostoon rasterointia varten..."
v.out.ascii --overwrite input=$POINT_MAP type=point output=$ASCIINAME columns="ndsm_value"
echo "Valmis."

# Lasketaan 6 m resoluutiolla maksimikorkeusrasteri normalisoidusta pintamallista (ndsm_value)
# Monesko sarake ASCII-tiedostossa on NDSM?
# 377499.94|6897012.98|106.37|1|-0.02400000
# 5. sarake.
# Se laitetaan z-arvoksi.
echo "Asetetaan resoluutio maksimikorkeusrasteria varten"
g.region vector=$BASEFILE res=6 -ap

echo "Lasketaan maksimikorkeusrasteri..."
r.in.xyz --overwrite input=$ASCIINAME output=$MAXH_RASTER method=max type=FCELL z=5
echo "Valmis"

echo "Luodaan rasteri maaluokitelluista lidar-palautumista..."
r.in.lidar --overwrite -o input=$LASFILE output=$NONGROUND_RASTER method=n resolution=6 type=CELL class_filter=1,3
echo "Valmis."

echo "Luodaan rasteri maaksi luokittelemattomista lidar-palautumista..."
r.in.lidar --overwrite -o input=$LASFILE output=$N_RASTER method=n resolution=6 type=CELL class_filter=1,2,3
echo "Valmis."

echo "Lasketaan peittävyysmuuttujaa..."
r.mapcalc --overwrite expression="$COVER_RASTER = float(${NONGROUND_RASTER})/${N_RASTER}"
echo "Valmis."

echo "Poistetaan väliaikaistiedostot..."
echo "Muista koodata poistot kun jaksat."

exit 0
