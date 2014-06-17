#just replace hadoop with the project you're parsing and away you go

echo "db = hadoop and Config = config/hadoop.conf"

date

#creating the clt table
psql hadoop -f create.sql

#get rid of indexes before inserts 
psql hadoop -f drop_indexes.sql

#The first pass, getting the valid code elements
echo "./resolve.pl config/hadoop.conf first > /tmp/hadoop_resolve1.out"
./resolve.pl config/hadoop.conf first > /tmp/hadoop_resolve1.out
date

#should make some indexes for variable resolution
#special case for hibernate in here
psql hadoop -f post_first_pass.sql 
date

echo "create index du_pqn_idx on clt(du, pqn);"
psql hadoop -c "create index du_pqn_idx on clt(du, pqn);"
psql hadoop -c "ANALYZE clt;"
date

#for undefined variables that have methods or fields, what is the most commonly declared variable type that has the same fields and methods in the entire collection of documents.
echo "./var_resolver.pl config/hadoop.conf"
./var_resolver.pl config/hadoop.conf

date
psql hadoop -c "drop index du_pqn_idx;"
date

#create the dictionary/index of valid code elements
#creates index on du for clt processing later
psql hadoop -f dict_ce.sql
date

#find the ambiguous code elements that match a term in our collection-wide dictionary
echo "./resolve.pl config/hadoop.conf second > /tmp/hadoop_resolve2.out"
./resolve.pl config/hadoop.conf second > /tmp/hadoop_resolve2.out
date

echo "save original trust sql: update clt set trust_original = trust, kind_original = kind where trust = 7;"
psql hadoop -c "update clt set trust_original = trust, kind_original = kind where trust = 7;"
date

#vacuum and analyze and create indexes
echo "create indexes"
psql hadoop -f create_index.sql
date

#create tmp tables of unresolved local terms
psql hadoop -f du.sql
date

#Do the local context resolution
echo "./du_insert.pl config/hadoop.conf"
psql hadoop -f create_clt_temp_du.sql
./du_insert.pl config/hadoop.conf
psql hadoop -f after_du_insert.sql
date

#Attach the post's date to each code element
psql hadoop -f date.sql 
#faster to do insert than update so need to recreate indexes
psql hadoop -f create_index.sql
#Create tmp tables to resolve terms by thread/date
psql hadoop -f thread.sql 
date

#Do the thread context resolution
psql hadoop -f create_clt_temp_tid.sql
echo "./thread.pl config/hadoop.conf"
./thread_insert.pl config/hadoop.conf
psql hadoop -f after_thread_insert.sql
date


echo "cleans up the db"
psql hadoop -f final.sql
date

echo "you may want to run project specific quiries to include two camel classes, see src/project_specific/<project-name.sql>"

