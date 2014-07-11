#just replace hibernate with the project you're parsing, config/hibernate.conf with the location of the config file and main/main_email.pl with your main/main_'name'.pl and away you go

echo "main_email.pl db = hibernate and Config = config/hibernate.conf"

date

#creating the clt table
psql hibernate -f create.sql

#get rid of indexes before inserts 
psql hibernate -f drop_indexes.sql

#The first pass, getting the valid code elements
echo "./main_email.pl config/hibernate.conf first > /tmp/hibernate_resolve1.out"
./main_email.pl config/hibernate.conf first > /tmp/hibernate_resolve1.out
date

#should make some indexes for variable resolution
#special case for hibernate in here
psql hibernate -f post_first_pass.sql 
date

echo "create index du_pqn_idx on clt(du, pqn);"
psql hibernate -c "create index du_pqn_idx on clt(du, pqn);"
psql hibernate -c "ANALYZE clt;"
date

#for undefined variables that have methods or fields, what is the most commonly declared variable type that has the same fields and methods in the entire collection of documents.
echo "./var_resolver.pl config/hibernate.conf"
./var_resolver.pl config/hibernate.conf

date
psql hibernate -c "drop index du_pqn_idx;"
date

#create the dictionary/index of valid code elements
#creates index on du for clt processing later
psql hibernate -f dict_ce.sql
date

#find the ambiguous code elements that match a term in our collection-wide dictionary
echo "./main_email.pl config/hibernate.conf second > /tmp/hibernate_resolve2.out"
./main_email.pl config/hibernate.conf second > /tmp/hibernate_resolve2.out
date

echo "save original trust sql: update clt set trust_original = trust, kind_original = kind where trust = 7;"
psql hibernate -c "update clt set trust_original = trust, kind_original = kind where trust = 7;"
date

#vacuum and analyze and create indexes
echo "create indexes"
psql hibernate -f create_index.sql
date

#create tmp tables of unresolved local terms
psql hibernate -f du.sql
date

#Do the local context resolution
echo "./du_insert.pl config/hibernate.conf"
psql hibernate -f create_clt_temp_du.sql
./du_insert.pl config/hibernate.conf
psql hibernate -f after_du_insert.sql
date

#Attach the post's date to each code element
psql hibernate -f date.sql 
#faster to do insert than update so need to recreate indexes
psql hibernate -f create_index.sql
#Create tmp tables to resolve terms by thread/date
psql hibernate -f thread.sql 
date

#Do the thread context resolution
psql hibernate -f create_clt_temp_tid.sql
echo "./thread.pl config/hibernate.conf"
./thread_insert.pl config/hibernate.conf
psql hibernate -f after_thread_insert.sql
date


echo "cleans up the db"
psql hibernate -f final.sql
date

echo "you may want to run project specific quiries to include two camel classes, see src/project_specific/<project-name.sql>"

