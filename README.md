# Mercado Aéreo Argentino - Data Analytics Project

El presente proyecto tiene como objetivo evaluar la situación del mercado aeronáutico aergentino y la actuación de sus aeropuertos en los últimos 4 años: 2019 - 2023.

 - Utilizamos los datasets provistos por la ANAC, disponibles en el portal de [datos.gob.ar](https://datos.gob.ar/dataset/transporte-aterrizajes-despegues-procesados-por-administracion-nacional-aviacion-civil-anac). Se encuentran disponibles los años 2019, 2020, 2021, 2022 y 2023. 

 - Se realizó un proceso de EDA (Exploratory Data Analysis) mediante MySQL. Si bien el mismo podría realizarse en Python con las librerías Pandas y Numpy, el trabajo de limpíeza se realizó mediante lenguaje SQL con ingesta de los datasets vía disco local.

- Para la integración con Looker Studio, se utilizó Google Cloud. Se cargaron tablas intermedias en la nube y luego utilizando Big Query, se crearon sentencias específicas para la creación de gráficos.

- El tablero se encuentra disponible en el siguiente link: [Dashboard Mercado Aeronáutico](https://lookerstudio.google.com/reporting/3e9043de-2bea-4144-b39e-042104fe9919)

- En la presente carpeta encontrarán los códigos en MySQL para el análisis exploratorio y limpieza del dataset, como así tambien las consultas para tablas utilizadas. A su vez, se anexan las tablas externas utilizadas.
