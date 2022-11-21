# scv_challenge

Para la realización de los ejercicios, decidí crear una base de datos de postgreSQL utilizando AWS para que este hosteada en la nube.

## Ejercicio 1:

La carga de los csv a la base de datos utilicé un jupyter notebook que elimina los caracteres especiales de los nombres de las columnas, modifica los nulls, tira las filas sin data relevante y modifica los tipos de datos. Luego de esto generó los strings para las queries en SQL, me conecto a postgreSQL usando psycopg2 y levanto la data.

El código tiene muchísimo lugar para mejorarse y se podría terminar armando un script que lo haga todo automáticamente ya que ahora esta bastante "hardcodeado". También me dí cuenta que fue contraproducente rellenar los nulls con "-1" en el dataset de calidad_aire ya que me complicó algunos cálculos.

## Ejercicio 2:

1) Obtuve los promedios de las mediciones de cada contaminante en cada ubicación por fecha, ya que había días con varias mediciones.  
2) Saqué la relación entre la medición de cada contaminante en cada ubicación y el límite de concentración de ese contaminante a partir del cual empieza a haber impactos en la salud. Cuanto más cercano a 0 sea este número, menor contaminación, si el número es 1, el valor está en el límite y si es mayor a 1, hay efector adversos para las personas. El código para crear la tabla con los valores límites fue el siguiente:

                                       create table vo_lkp_calidad_aire as
                                       select
                                          7.3 as co_contamination_limit,
                                          200 as no2_contamination_limit,
                                          150 as pm10_contamination_limit;

4) Uní las columnas de los distintos contaminantes, que estaban discriminadas por ubicación, en una sola para luego promediar las mediciones de las distintas ubicaciones por fecha. De esta manera me quedó una sola columna por cada contaminante con una sola fila por fecha.
5) En el último paso cree el indice general de calidad del aire, para cada fecha, ponderando los valores de los distintos contaminantes. Usando información de la OMS y del gobierno uruguayo, definí atribuirle pesos a los distintos contaminantes de la siguiente manera:
          pm10: 1,25
          no2: 1,1
          co: 1
La idea es tratar de llevar a una misma escala el impacto en la salud a cada contaminante para poder combinarlos y compararlos en su conjunto. 
En este punto también cree unos indicadores para saber si en cada fecha hubo o no mediciones de cada contaminante, ya que había muchas fechas que no tenían medición de pm10 por ejemplo y considero que estas muestras son de peor calidad. Siendo el contaminante pm10 el más relevante para la salud, para los siguientes ejercicios sólo tuve en cuenta muestras donde se haya medido estos elementos.

Links:
      https://www.who.int/es/news-room/fact-sheets/detail/ambient-(outdoor)-air-quality-and-health  \
      https://montevideo.gub.uy/areas-tematicas/ambiente/calidad-del-aire/principales-contaminantes-del-aire

## Ejercicio 3:

Hago un select a la view creada en el ejercicio anterior ordenando de manera ascendente el índice construído (0 - sin contaminación) dejando afuera los registros donde no hubiera mediciones de pm10.

## Ejercicio 4:

Para obtener los 3 mejores días por mes, hizo un rank de mediciones para cada mes ordenándolo según el índice y me quede con las 3 mediciones (menos si es que no existen 3) que tengan mejor índice.

## Ejercicio 5:

1) Eliminé duplicados del dataset de viajes, ya que noté que existían, y luego sumé por fecha la cantidad de pasajeros totales. 
2) Uní la view con el índice de calidad de aire diario y la de pasajeros totales por día y cree el indicador de impacto en la gente multiplicando el índice de calidad con la cantidad de pasajeros dividida por 100.000. De esta manera, cuanto menor la contaminación o menor la cantidad de gente, menor el valor del indicador de impacto. 

A partir de este punto hago un select ordenador por el indicador de impacto y/o el índice de calidad de aire para definir los días con mayor o menor impacto. 
