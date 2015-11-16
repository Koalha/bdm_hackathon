# Poimitaan Keski-Suomen ELY-keskuksen alueelta vanhojen metsien suojelualueet
options(stringsAsFactors = FALSE)
library(rgdal)
library(rgeos)
keskisuomi <- readOGR("./kuntajako/kunnat.shp", "kunnat")
plot(keskisuomi)
polygonsLabel(keskisuomi, labels = keskisuomi@data$text1, method = "centroid")

# Ladataan valtion mailla olevat suojelualueet
# Poimitaan niistä vanhoja metsiä suojelevat alueet
# Poimitaan niistä Keski-Suomessa olevat suojelualueet
valtiosa <- readOGR("nature_reserve/NatureReserveOldgrowthState.shp", "NatureReserveOldgrowthState")
plot(keskisuomi)
plot(valtiosa, col = "red", border = NA, add = TRUE)
title(main = "Vanhojen metsien suojelualueet valtion mailla")

# Ladataan suojeluohjelmat
# Poimitaan niistä vanhoja metsiä suojelevat alueet
# Poimitaan niistä Keski-Suomessa olevat suojelualueet
ohjelmasa <- readOGR("nature_reserve/NatureReserveOldgrowthProgrammeState.shp", "NatureReserveOldgrowthProgrammeState")

plot(keskisuomi)
plot(ohjelmasa, col = "red", border = NA, add = TRUE)
title(main = "Vanhojen metsien suojeluohjelmat valtion mailla")


# Ladataan vanhojen metsien suojelualueet, jotka ovat yksityismailla
yksitvasa <- readOGR("nature_reserve/NatureReserveOldgrowthProgrammePrivate.shp", "NatureReserveOldgrowthProgrammePrivate")
plot(keskisuomi)
plot(yksitvasa, col="red", border = NA, add = TRUE)
title(main = "Vanhojen metsien suojeluohjelmat yksityisillä mailla")

# Ladataan yksityisten mailla olevat suojelualueet
# Näitä on paljon, ja nämä pitää vielä rikastaa
# METSO-datalla (/suojelualueet/runsaslahopuustoiset_ysta.csv)
yksitsa <- readOGR("nature_reserve/NatureReservePrivate.shp", "NatureReservePrivate")
plot(keskisuomi)
plot(yksitsa, col = "red", border = NA, add = TRUE)


# Kaikki suojelualueemme
plot(keskisuomi)
plot(yksitsa, col = "red", border = NA, add = TRUE)
plot(yksitvasa, col = "red", border = NA, add = TRUE)
plot(ohjelmasa, col = "red", border = NA, add = TRUE)
plot(valtiosa, col = "red", border = NA, add = TRUE)
title("Vanhan metsän suojelualueet + yksityiset")
