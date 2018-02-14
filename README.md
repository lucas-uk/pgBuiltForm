
# pgBuiltForm

Example routines for extracting metrics from a PostGIS database of building polygons.

## Description
This repository contains example SQL queries for extracting metrics about buildings from a PostGIS database. It aims to show how a database can be used to determining attributes on the form and geometry of 2D building footprints. It as been tested on OS MasterMap Topography Layer data.

Journal article :
`Beck, A., Long, G., Boyd, D.S., Rosser, J.F., Morley, J., Duffield, R., Robinson, D. And Sanderson, M. 2018. Automated classification metrics for
energy modelling of residential
buildings in the UK with open
algorithms. Environment and Planning B: Urban Analytics and City Science`


### Built form extraction and exterior wall ratio
In the code, a PostGIS schema.table `derivedinfo.buildingsandheights` contains the building footprints (MasterMap) footprints which have been spatially joined to  a dataset of address points (AddressBase). A PostGIS topology has been defined over `derivedinfo.buildingsandheights`. 

 - The query `built_form_classification.sql` shows adding a field `form_based_on_addressgeometry` defining the built form (i.e. detached | semi-detached | mid-terrace | end-terrace | complex).
 
 - The query `compute_exterior_wall_ratio_normal_tables.sql` shows creation of a table `derivedinfo.external_wall_ratio_test`  containing the length of exterior edges, the length of shared edges and the external wall ratio.



![built form and wall metrics](https://upload.wikimedia.org/wikipedia/commons/thumb/9/9b/House_Classification_By_Form_-_Conceptual_Approach_01.svg/640px-House_Classification_By_Form_-_Conceptual_Approach_01.svg.png "Built form and metrics")



## Licence
This work is licensed under a Creative Commons Attribution 4.0 License.


## Acknowledgements
![Leverhulme Trust](images/Leverhulme_Trust_small.jpg "Leverhulme Trust logo")



