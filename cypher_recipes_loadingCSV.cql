cypher_recipes_loadingCSV

// basic recipes for loading CSV data with cypher
load csv with headers
from 'https://data.neo4j.com/importing/ratings.csv' as row
return count(row)

// how to check for all nodes
match (n) return count(n)

// how to check for all relationships
match ()-[r]->() return count r

// Viewing *node* property types in the graph
call apoc.meta.nodeTypeProperties()

// Viewing *relationship* property types in the graph
call apoc.meta.relTypeProperties()

//transforming imported properties into lists
match (m:Movie)
set m.countries = split(coalesce(m.countries,""), "|"),
m.languages = split(coalesce(m.languages,""), "|"),
m.genres = split(coalesce(m.genres,""),"|")

//adding labels conditionally to nodes
match (p:Person)-(r:ACTED_IN)->()
with distinct p set p:Actor

match (p:Director)-(r:DIRECTED)->()
with distinct p set p:Director

// REFACTORING PROPERTIES INTO NODES
// Step 1: define uniqueness constraint for name property in the Genre entity
create constraint Genre_name on (g:Genre) assert g.name is uniqueness

// Step 2. create Genre nodes from genres properties within the Movie nodes

// retrieves the data you need to work with
MATCH (m:Movie)

// expands the elements in genres list for each node as rows
UNWIND m.genres AS genre

// use movie nodes + unwound genre rows for each movie node
WITH m, genre

// creates the Genre node using MERGE if one does not already exist
MERGE (g:Genre {name:genre})

// creates the relationship between the Movie node and Genre node
MERGE (m)-[:IN_GENRE]->(g)

// Step 3. Remove the duplicate genres properties nested within the Movie nodes from the graph
match (m:Movie)
set m.genres = null