//adding new labels to nodes
MATCH (p:Person)
WHERE exists ((p)-[:ACTED_IN]-())
SET p:Actor

// turning properties into nodes

MATCH (m:Movie) //retrive the nodes you need to work with
UNWIND m.languages AS language // unwind
WITH  language, collect(m) AS movies
MERGE (l:Language {name:language})
WITH l, movies
UNWIND movies AS m
WITH l,m
MERGE (m)-[:IN_LANGUAGE]->(l);
MATCH (m:Movie)
SET m.languages = null

//creating relationships by retrieving nodes
MATCH (apollo:Movie {title: 'Apollo 13'})
MATCH (tom:Person {name: 'Tom Hanks'})
MATCH (meg:Person {name: 'Meg Ryan'})
MATCH (danny:Person {name: 'Danny DeVito'})
MATCH (sleep:Movie {title: 'Sleepless in Seattle'})
MATCH (hoffa:Movie {title: 'Hoffa'})
MATCH (jack:Person {name: 'Jack Nicholson'})

// create the relationships between nodes
MERGE (tom)-[:ACTED_IN {role: 'Jim Lovell'}]->(apollo)
MERGE (tom)-[:ACTED_IN {role: 'Sam Baldwin'}]->(sleep)
MERGE (meg)-[:ACTED_IN {role: 'Annie Reed'}]->(sleep)
MERGE (danny)-[:ACTED_IN {role: 'Bobby Ciaro'}]->(hoffa)
MERGE (danny)-[:DIRECTED]->(hoffa)
MERGE (jack)-[:ACTED_IN {role: 'Jimmy Hoffa'}]->(hoffa)

//specializing relationships - part 1
MATCH (n:Actor)-[:ACTED_IN]->(m:Movie)
CALL apoc.merge.relationship(n,
  'ACTED_IN_' + left(m.released,4),
  {},
  {},
  m ,
  {}
) YIELD rel
RETURN count(*) AS `Number of relationships merged`;

// specializing relationsips - part 2a: finding the right relationships
MATCH (u:User)-[r:RATED]->(m:Movie)
WHERE m.title = 'Apollo 13' AND
r.rating = 5
RETURN u.name as Reviewer

// specializing relationships - part 2b: using APOC call
MATCH (n:User)-[r:RATED]->(m:Movie)
CALL apoc.merge.relationship(n,
  'RATED_' + r.rating,
  {},
  {},
  m,
  {}
) YIELD rel
RETURN COUNT(*) AS `Number of relationships added`;


//using relationship conditionals in queries
MATCH (p:Person)-[:ACTED_IN_1995|DIRECTED_1995]->()
RETURN p.name as `Actor or Director`

//creating procedural event chains https://neo4j.com/labs/apoc/4.1/graph-updates/data-creation/
CREATE (:Event {name: "Event 1", date: datetime("2019-06-01")})
CREATE (:Event {name: "Event 2", date: datetime("2019-06-04")})
CREATE (:Event {name: "Event 3", date: datetime("2019-06-08")})

MATCH (e:Event)
WITH e ORDER BY e.date
WITH collect(e) AS events
CALL apoc.nodes.link(events, "NEXT")
RETURN count(*)


// modeling-fundamentals-adding-intermediate-nodes: adding a role exercise 👇

// step 0: apparently this works just fine
match (a:Actor)-[r:ACTED_IN]->(m:Movie)
merge (x:Role {name: r.role})
merge (a)-[p:PLAYED]->(x)
merge (x)-[i:IN_MOVIE]->(m)


// step 1: create Role nodes dynamically from the [ACTED_IN] role property

// 1a. retrieve the nodes you need
match (a:Actor)-[r:ACTED_IN]->(m:Movie)
// 1b. extract role property data from (Actor)->[ACTED_IN] relationship and pass it to merge clause to dynamically create nodes
merge (n:Role {name: r.role})
// 1c. check that everything looks good
match (a:Actor)-[r:ACTED_IN]-(m:Movie)
match (n:Role)
return a,r,m,n

// Step 2: dynamically create PLAYED relationship (Role)->(Actor) based on (Actor)->[ACTED_IN] relationship

// 2a. retrieve the nodes you'll need
match (a:Actor)-[r:ACTED_IN]-(m:Movie)
match (n:Role)
// 2b. find the alignment between (Role)-(Actor)-[ACTED_IN]
where n.name = r.role
// 2c. dynamically create (Role)-(Actor) relationships
call apoc.merge.relationship(a,'PLAYED',{},{},n,{}) yield rel
return rel;
// 2d. check that everything looks good
match (n) return n

// Step 3. dynamically create IN_MOVIE relationship: (Role)-(Movie)

// 3a. retrieve the nodes you'll need
match (a:Actor)-[p:PLAYED]-(n:Role)
match (a:Actor)-[r:ACTED_IN]-(m:Movie)
// 3b. find the alignment between (Role)-(Movie) based on (Role)-(Actor)-[ACTED_IN]
where r.role = n.name
call apoc.merge.relationship(n,"IN_MOVIE",{},{},m,{}) yield rel
return rel;
// 3c. check that everything looks good
match (n) return n

// Step 4. remove the role property for [ACTED_IN]

// 4a. retrieve the nodes you'll need
match (a:Actor)-[r:ACTED_IN]-()
// 4b. Clean up role property
SET r.role = null
// 4c. check that everything looks good
match (n) return n


