// LadybugDB course, lesson 8: transactions
// Run from code/ladybugdb: lbug < cypher/08-transactions.cypher
CREATE NODE TABLE Project(path STRING PRIMARY KEY, name STRING, language STRING, sdk STRING, frameworks STRING, in_solution BOOLEAN);
COPY Project FROM 'data/ga/projects.csv' (HEADER = true);

// Auto-commit: each statement is a transaction, and a statement that fails changes nothing
UNWIND ['New/Zero.csproj', 'Common/GA.Core/GA.Core.csproj'] AS path
CREATE (:Project {path: path, name: 'Zero'});
MATCH (p:Project) RETURN count(*) AS projects;

// A manual transaction sees its own changes; ROLLBACK undoes them
BEGIN TRANSACTION;
CREATE (:Project {path: 'New/One.csproj', name: 'One'});
MATCH (p:Project) RETURN count(*) AS inside;
ROLLBACK;
MATCH (p:Project) RETURN count(*) AS after_rollback;

// Creating a table and loading it are part of the transaction too
BEGIN TRANSACTION;
CREATE NODE TABLE Package(name STRING PRIMARY KEY);
COPY Package FROM (LOAD FROM 'data/ga/package_refs.csv' (HEADER = true) RETURN DISTINCT package);
MATCH (k:Package) RETURN count(*) AS packages_inside;
ROLLBACK;
CALL show_tables() RETURN name ORDER BY name;

// An error ends the transaction: the statements after it run in auto-commit, and ROLLBACK finds nothing to undo
BEGIN TRANSACTION;
CREATE (:Project {path: 'New/Two.csproj', name: 'Two'});
CREATE (:Project {path: 'Common/GA.Core/GA.Core.csproj', name: 'Duplicate'});
CREATE (:Project {path: 'New/Three.csproj', name: 'Three'});
ROLLBACK;
MATCH (p:Project) WHERE p.path STARTS WITH 'New/' RETURN p.name;

// So does a BEGIN inside a transaction
BEGIN TRANSACTION;
MATCH (p:Project {name: 'Three'}) DELETE p;
BEGIN TRANSACTION;
COMMIT;
MATCH (p:Project) WHERE p.path STARTS WITH 'New/' RETURN p.name;

// A read-only transaction refuses writes, and this error doesn't end it: COMMIT succeeds
BEGIN TRANSACTION READ ONLY;
MATCH (p:Project) RETURN count(*) AS read_only;
CREATE (:Project {path: 'New/Four.csproj', name: 'Four'});
COMMIT;

// CHECKPOINT can't run inside a transaction, and ends it
BEGIN TRANSACTION;
CREATE (:Project {path: 'New/Five.csproj', name: 'Five'});
CHECKPOINT;
COMMIT;
MATCH (p:Project) WHERE p.path STARTS WITH 'New/' RETURN p.name;
CALL current_setting('checkpoint_threshold') RETURN *;
