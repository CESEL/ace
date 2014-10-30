#just replace $1 with the project you're parsing, $2 with the location of the config file and $3 with your main/main_'name'.pl and away you go

echo "$3 db = $1 and Config = $2"

date

#creating the clt table
psql $1 -f create.sql

#get rid of indexes before inserts 
psql $1 -f drop_indexes.sql

#The first pass, getting the valid code elements
#./$3 $2 first > /tmp/$1_resolve1.out
echo "./$3 $2 first > /dev/null"
./$3 $2 first > /dev/null

psql $1 -f backup_clt.sql
date

#should make some indexes for variable resolution
#special case for hibernate in here
psql $1 -f post_first_pass.sql 
date

echo "create index du_pqn_idx on clt(du, pqn);"
psql $1 -c "create index du_pqn_idx on clt(du, pqn);"
psql $1 -c "ANALYZE clt;"
date

#for undefined variables that have methods or fields, what is the most commonly declared variable type that has the same fields and methods in the entire collection of documents.
echo "./var_resolver.pl $2"
./var_resolver.pl $2

date
psql $1 -c "drop index du_pqn_idx;"
date

#create the dictionary/index of valid code elements
#creates index on du for clt processing later
psql $1 -f dict_ce.sql
date

#find the ambiguous code elements that match a term in our collection-wide dictionary
#./$3 $2 second > /tmp/$1_resolve2.out
echo "./$3 $2 second > /dev/null"
./$3 $2 second > /dev/null

psql $1 -f backup_clt.sql
date

echo "save original trust sql: update clt set trust_original = trust, kind_original = kind where trust = 7;"
psql $1 -c "update clt set trust_original = trust, kind_original = kind where trust = 7;"
date

#vacuum and analyze and create indexes
echo "create indexes"
psql $1 -f create_index.sql
date

#create tmp tables of unresolved local terms
psql $1 -f du.sql
date

#Do the local context resolution
echo "./du_insert.pl $2"
psql $1 -f create_clt_temp_du.sql
./du_insert.pl $2
psql $1 -f after_du_insert.sql
date

#Attach the post's date to each code element
psql $1 -f date.sql 
#faster to do insert than update so need to recreate indexes
psql $1 -f create_index.sql
#Create tmp tables to resolve terms by thread/date
psql $1 -f thread.sql 
date

#Do the thread context resolution
psql $1 -f create_clt_temp_tid.sql
echo "./thread.pl $2"
./thread_insert.pl $2
psql $1 -f after_thread_insert.sql
date


echo "cleans up the db"
psql $1 -f final.sql
date

echo "you may want to run project specific quiries to include two camel classes, see src/project_specific/<project-name.sql>"

