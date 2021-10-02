//
// Download data as needed from various sites
//
// Suggestions:
// https://download.bbbike.org/osm/bbbike/NewYork/
// https://download.bbbike.org/osm/bbbike/SanFrancisco/
// https://download.geofabrik.de/europe.html
// https://download.geofabrik.de/europe/sweden-latest.osm.bz2
// https://download.geofabrik.de/australia-oceania/australia-latest.osm.bz2

//
// Import data
//

mvn clean package
cp target/osm-0.2.3-neo4j-4.1.3-procedures.jar ~/Downloads/neo4j-community-4.1.3/plugins/
cp ~/Downloads/apoc-4.1.0.2-core.jar ~/Downloads/neo4j-community-4.1.3/plugins/

mvn dependency:copy-dependencies

// For NewYork

java -Xms1024m -Xmx1024m \
-cp "target/osm-0.2.2-neo4j-3.4.9.jar:target/dependency/*" org.neo4j.gis.osm.OSMImportTool \
--skip-duplicate-nodes --delete --into target/databases --database NewYork samples/NewYork.osm.gz

//IMPORT DONE in 1m 40s 810ms. (was 29s in Neo4j 3.4.9)
//Imported:
//21401587 nodes  (over 3x nodes from 3.4.9)
//22647165 relationships (over 3x)
//53854869 properties (over 3x)
//Peak memory usage: 1.240GiB (was 1.10 GB)
// I think the 3.4.9 numbers are incorrect because later numbers match.

rm -Rf ~/Downloads/neo4j-community-4.0.0/data/databases/NewYork
cp -a target/databases/data/databases/NewYork ~/Downloads/neo4j-community-4.0.0/data/databases/
cp -a target/databases/data/transactions/NewYork ~/Downloads/neo4j-community-4.0.0/data/transactions/

// For SanFransisco

java -Xms1024m -Xmx1024m \
-cp "target/osm-0.2.2-neo4j-3.4.9.jar:target/dependency/*" org.neo4j.gis.osm.OSMImportTool \
--skip-duplicate-nodes --delete --into target/databases/SanFrancisco samples/SanFrancisco.osm.gz

// For sweden

java -Xms1024m -Xmx1024m \
-cp "target/osm-0.2.2-neo4j-3.5.1.jar:target/dependency/*" org.neo4j.gis.osm.OSMImportTool \
--skip-duplicate-nodes --delete --into target/databases/sweden samples/sweden.osm.gz

//IMPORT DONE in 35m 29s 970ms.
//Imported:
//  121722375 nodes
//  128018052 relationships
//  400011864 properties
//Peak memory usage: 2.36 GB
//There were bad entries which were skipped and logged into /data/craig/dev/neo4j/osm/target/databases/sweden/bad.log
//real	35m34,169s
//user	94m52,946s
//sys	16m4,122s


// For sweden and Neo4j 4.1.3 (freshly downloaded on 2020-10-04)

java -Xms1024m -Xmx1024m \
-cp "target/osm-0.2.3-neo4j-4.1.3.jar:target/dependency/*" org.neo4j.gis.osm.OSMImportTool \
--skip-duplicate-nodes --delete --into target/neo4j --database sweden samples/2020/sweden-latest.osm.bz2

//IMPORT DONE in 54m 18s 735ms.
//Imported:
//  152740897 nodes
//  162199801 relationships
//  427791894 properties
//Peak memory usage: 2.705GiB
//There were bad entries which were skipped and logged into /data/craig/dev/neo4j/osm/target/neo4j/bad.log

// For sweden and Neo4j 4.2.6 (freshly downloaded from geofabrik 2021-05-13)

//IMPORT DONE in 1h 44s 376ms.
//Imported:
//  165422570 nodes
//  175761332 relationships
//  463144959 properties
//Peak memory usage: 2.319GiB

// For australia and Neo4j 4.2.6 (freshly downloaded from geofabrik 2021-05-13)

java -Xms1024m -Xmx1024m \
-cp "target/osm-0.2.4-neo4j-4.2.6.jar:target/dependency/*" org.neo4j.gis.osm.OSMImportTool \
--skip-duplicate-nodes --delete --into target/neo4j --database australia samples/2021/australia-latest.osm.bz2

//IMPORT DONE in 54m 52s 275ms.
//Imported:
//  166066215 nodes
//  169138399 relationships
//  490590540 properties
//Peak memory usage: 2.159GiB

rm -Rf ~/Downloads/neo4j-enterprise-4.1.3/data/databases/sweden
rm -Rf ~/Downloads/neo4j-enterprise-4.1.3/data/transactions/sweden
#cp -a target/neo4j/data/databases/sweden ~/Downloads/neo4j-enterprise-4.1.3/data/databases/
#cp -a target/neo4j/data/transactions/sweden ~/Downloads/neo4j-enterprise-4.1.3/data/transactions/

// 2021 Sweden and Australia COMMUNITY
for dir in databases transactions ; do for db in sweden australia ; do echo "$dir/$db" ; cp -a target/neo4j/data/$dir/$db ~/Downloads/neo4j-community-4.2.3/data/$dir/ ; done ; done
// Then edit neo4j-conf to set default_database=sweden (or australia)

// 2021 Sweden and Australia ENTERPRISE
for dir in databases transactions ; do for db in sweden australia ; do echo "$dir/$db" ; cp -a target/neo4j/data/$dir/$db ~/Downloads/neo4j-community-4.2.3/data/$dir/ ; done ; done
// Then run Neo4j and `CREATE DATABASE sweden` (and repeat for australia)
neo4j$ MATCH (n) RETURN count(n)
--> 0
neo4j$ :use system
system$ CREATE DATABASE sweden
system$ CREATE DATABASE autralia
system$ :use sweden
sweden MATCH (n) RETURN count(n)
--> 165422570
sweden$ :use australia
australia$ MATCH (n) RETURN count(n)
--> 166066215
australia$ :use sweden
sweden$

// Start Neo4j
// If using community edition, first edit conf/neo4j.conf to point to the default_database of choice

cd ~/Downloads/neo4j-enterprise-4.1.3/
bin/neo4j start

//
// Make indexes on :OSMTags
//

CREATE INDEX ON :OSMTags(amenity);
CREATE INDEX ON :OSMTags(building);
CREATE INDEX ON :OSMTags(capital);
CREATE INDEX ON :OSMTags(description);
CREATE INDEX ON :OSMWay(distance);
CREATE INDEX ON :OSMRelation(distance);
CREATE INDEX ON :OSMTags(food);
CREATE INDEX ON :OSMTags(highway);
CREATE INDEX ON :OSMTags(information);
CREATE INDEX ON :OSMTags(kiosk);
CREATE INDEX ON :Intersection(location);
CREATE INDEX ON :Routable(location);
CREATE INDEX ON :PointOfInterest(location);
CREATE INDEX ON :OSMTags(location);
CREATE INDEX ON :OSMNode(location);
CREATE INDEX ON :PointOfInterest(name);
CREATE INDEX ON :OSMTags(office);
CREATE INDEX ON :OSMTags(place);
CREATE INDEX ON :OSMTags(restaurant);
CREATE INDEX ON :OSMTags(shop);
CREATE INDEX ON :OSMTags(station);
CREATE INDEX ON :OSMTags(type);

// For sweden on 4.1.3 This can be achieved using:
cat indexes.txt | ~/Downloads/neo4j-community-4.1.3/bin/cypher-shell -u neo4j -p abc -d sweden

// For sweden and australia on 4.2.6 This can be achieved using:
cat demo/indexes.txt | ~/Downloads/neo4j-enterprise-4.2.6/bin/cypher-shell -u neo4j -p abc -d sweden
cat demo/indexes.txt | ~/Downloads/neo4j-enterprise-4.2.6/bin/cypher-shell -u neo4j -p abc -d australias

// Status of index building can be observed
sweden$ SHOW INDEXES
australia$ SHOW INDEXES
╒════╤════════════════╤════════════╤═══════════════════╤════════════╤═══════╤════════════╤═══════════════════╤═══════════════╤══════════════════╕
│"id"│"name"          │"state"     │"populationPercent"│"uniqueness"│"type" │"entityType"│"labelsOrTypes"    │"properties"   │"indexProvider"   │
╞════╪════════════════╪════════════╪═══════════════════╪════════════╪═══════╪════════════╪═══════════════════╪═══════════════╪══════════════════╡
│11  │"index_2e4dcaae"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["Intersection"]   │["location"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│18  │"index_547d1975"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["place"]      │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│21  │"index_572fab50"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["station"]    │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│22  │"index_5c3df2da"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["type"]       │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│19  │"index_6e7fabd8"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["restaurant"] │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│12  │"index_83cf2557"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["Routable"]       │["location"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│3   │"index_85197e1e"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["capital"]    │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│5   │"index_879671ef"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMWay"]         │["distance"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│8   │"index_9126305a"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["highway"]    │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│1   │"index_9191603f"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["amenity"]    │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│7   │"index_91de7dce"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["food"]       │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│6   │"index_ab4569b" │"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMRelation"]    │["distance"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│9   │"index_ad384e1b"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["information"]│"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│4   │"index_bc3670c7"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["description"]│"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│15  │"index_bfc331e9"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMNode"]        │["location"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│16  │"index_c17a3934"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["PointOfInterest"]│["name"]       │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│20  │"index_c219af3d"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["shop"]       │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│13  │"index_c6d8e26b"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["PointOfInterest"]│["location"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│2   │"index_d3c993f9"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["building"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│17  │"index_d4dfdf4f"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["office"]     │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│14  │"index_e1e9298e"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["location"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│10  │"index_f759b847"│"POPULATING"│0.0                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["kiosk"]      │"native-btree-1.0"│
└────┴────────────────┴────────────┴───────────────────┴────────────┴───────┴────────────┴───────────────────┴───────────────┴──────────────────┘

// Once POPULATING changes to ONLINE, the indexes are ready to be used
╒════╤════════════════╤════════════╤═══════════════════╤════════════╤═══════╤════════════╤═══════════════════╤═══════════════╤══════════════════╕
│"id"│"name"          │"state"     │"populationPercent"│"uniqueness"│"type" │"entityType"│"labelsOrTypes"    │"properties"   │"indexProvider"   │
╞════╪════════════════╪════════════╪═══════════════════╪════════════╪═══════╪════════════╪═══════════════════╪═══════════════╪══════════════════╡
│11  │"index_2e4dcaae"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["Intersection"]   │["location"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│18  │"index_547d1975"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["place"]      │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│21  │"index_572fab50"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["station"]    │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│22  │"index_5c3df2da"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["type"]       │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│19  │"index_6e7fabd8"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["restaurant"] │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│12  │"index_83cf2557"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["Routable"]       │["location"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│3   │"index_85197e1e"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["capital"]    │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│5   │"index_879671ef"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMWay"]         │["distance"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│8   │"index_9126305a"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["highway"]    │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│1   │"index_9191603f"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["amenity"]    │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│7   │"index_91de7dce"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["food"]       │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│6   │"index_ab4569b" │"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMRelation"]    │["distance"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│9   │"index_ad384e1b"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["information"]│"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│4   │"index_bc3670c7"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["description"]│"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│15  │"index_bfc331e9"│"POPULATING"│8.5                │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMNode"]        │["location"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│16  │"index_c17a3934"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["PointOfInterest"]│["name"]       │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│20  │"index_c219af3d"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["shop"]       │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│13  │"index_c6d8e26b"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["PointOfInterest"]│["location"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│2   │"index_d3c993f9"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["building"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│17  │"index_d4dfdf4f"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["office"]     │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│14  │"index_e1e9298e"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["location"]   │"native-btree-1.0"│
├────┼────────────────┼────────────┼───────────────────┼────────────┼───────┼────────────┼───────────────────┼───────────────┼──────────────────┤
│10  │"index_f759b847"│"ONLINE"    │100.0              │"NONUNIQUE" │"BTREE"│"NODE"      │["OSMTags"]        │["kiosk"]      │"native-btree-1.0"│
└────┴────────────────┴────────────┴───────────────────┴────────────┴───────┴────────────┴───────────────────┴───────────────┴──────────────────┘