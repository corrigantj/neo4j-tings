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
// STEP 1: define uniqueness constraint for name property in the Genre entity (This also creates Genre Node)
create constraint Genre_name on (g:Genre) assert g.name is unique

// STEP 2. create Genre nodes from genres properties within the Movie nodes

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

// STEP 3. Remove the duplicate genres properties nested within the Movie nodes from the graph
match (m:Movie)
set m.genres = null

// STEP 4. Confirm the final schema of the graph
call db.schema.visualization




/// IMPORT USING CYPHER EXERCISE

// Step 1: Delete all nodes and relationships in the graph
MATCH (u:User) DETACH DELETE u;
MATCH (p:Person) DETACH DELETE p;
MATCH (m:Movie) DETACH DELETE m;
MATCH (n) DETACH DELETE n

// Step 2: Ensure all constraints exist in the graph
show constraints

// Step 3: Import Movie and Genre data

//Verify the data
LOAD CSV WITH HEADERS
FROM 'https://data.neo4j.com/importing/2-movieData.csv'
AS row
//process only Movie rows
WITH row WHERE row.Entity = "Movie"
RETURN
row.tmdbId,
row.imdbId,
toFloat(row.imdbRating),
row.released,
row.title,
toInteger(row.year),
row.poster,
toInteger(row.runtime),
split(coalesce(row.countries,""), "|"),
toInteger(row.imdbVotes),
toInteger(row.revenue),
row.plot,
row.url,
toInteger(row.budget),
split(coalesce(row.languages,""), "|"),
split(coalesce(row.genres,""), "|")
LIMIT 10

//Import the data
:auto USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'https://data.neo4j.com/importing/2-movieData.csv'
AS row
//process only Movie rows
WITH row WHERE row.Entity = "Movie"
MERGE (m:Movie {movieId: toInteger(row.movieId)})
ON CREATE SET
m.tmdbId = toInteger(row.tmdbId),
m.imdbId = toInteger(row.imdbId),
m.imdbRating = toFloat(row.imdbRating),
m.released = row.released,
m.title = row.title,
m.year = toInteger(row.year),
m.poster = row.poster,
m.runtime = toInteger(row.runtime),
m.countries = split(coalesce(row.countries,""), "|"),
m.imdbVotes = toInteger(row.imdbVotes),
m.revenue = toInteger(row.revenue),
m.plot = row.plot,
m.url = row.url,
m.budget = toInteger(row.budget),
m.languages = split(coalesce(row.languages,""), "|")
WITH m,split(coalesce(row.genres,""), "|") AS genres
UNWIND genres AS genre
WITH m, genre
MERGE (g:Genre {name:genre})
MERGE (m)-[:IN_GENRE]->(g)

// import person data
LOAD CSV WITH HEADERS
FROM 'https://data.neo4j.com/importing/2-movieData.csv'
AS row
WITH row WHERE row.Entity = "Person"
RETURN
row.tmdbId,
row.imdbId,
row.bornIn,
row.name,
row.bio,
row.poster,
row.url,
CASE row.born WHEN "" THEN null ELSE date(row.born) END,
CASE row.died WHEN "" THEN null ELSE date(row.died) END
LIMIT 10


:auto USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'https://data.neo4j.com/importing/2-movieData.csv'
AS row
WITH row WHERE row.Entity = "Person"
MERGE (p:Person {tmdbId: toInteger(row.tmdbId)})
ON CREATE SET
p.imdbId = toInteger(row.imdbId),
p.bornIn = row.bornIn,
p.name = row.name,
p.bio = row.bio,
p.poster = row.poster,
p.url = row.url,
p.born = CASE row.born WHEN "" THEN null ELSE date(row.born) END,
p.died = CASE row.died WHEN "" THEN null ELSE date(row.died) END

// import acted_in
LOAD CSV WITH HEADERS
FROM 'https://data.neo4j.com/importing/2-movieData.csv'
AS row
WITH row WHERE row.Entity = "Join" AND row.Work = "Acting"
RETURN
row.tmdbId,
row.movieId,
row.role
LIMIT 10

:auto USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'https://data.neo4j.com/importing/2-movieData.csv'
AS row
WITH row WHERE row.Entity = "Join" AND row.Work = "Acting"
MATCH (p:Person {tmdbId: toInteger(row.tmdbId)})
MATCH (m:Movie {movieId: toInteger(row.movieId)})
MERGE (p)-[r:ACTED_IN]->(m)
ON CREATE
SET r.role = row.role
SET p:Actor

// Step 6: Import the DIRECTED relationships
LOAD CSV WITH HEADERS
FROM 'https://data.neo4j.com/importing/2-movieData.csv'
AS row
WITH row WHERE row.Entity = "Join" AND row.Work = "Directing"
RETURN
row.tmdbId,
row.movieId,
row.role
LIMIT 10

:auto USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'https://data.neo4j.com/importing/2-movieData.csv'
AS row
WITH row WHERE row.Entity = "Join" AND row.Work = "Directing" AND exists(row.role)
MATCH (p:Person {tmdbId: toInteger(row.tmdbId)})
MATCH (m:Movie {movieId: toInteger(row.movieId)})
MERGE (p)-[r:DIRECTED]->(m)
ON CREATE
SET r.role = row.role
SET p:Director

// Step 7: Import the User data
LOAD CSV WITH HEADERS
FROM 'https://data.neo4j.com/importing/2-ratingData.csv'
AS row
RETURN
row.movieId,
row.userId,
row.name,
toInteger(row.rating),
toInteger(row.timestamp)
LIMIT 100

:auto USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'https://data.neo4j.com/importing/2-ratingData.csv'
AS row
MATCH (m:Movie {movieId: toInteger(row.movieId)})
MERGE (u:User {userId: toInteger(row.userId)})
ON CREATE SET u.name = row.name
MERGE (u)-[r:RATED]->(m)
ON CREATE SET r.rating = toInteger(row.rating),
r.timestamp = toInteger(row.timestamp)

