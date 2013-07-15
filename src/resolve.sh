#just replace $1 with the project you're parsing and away you go

echo "db = $1 and Config = $2"

date

#creating the clt table
psql $1 -f create.sql

#The first pass, getting the valid code elements
echo "./resolve.pl $2 first > /tmp/$1_resolve1.out"
./resolve.pl $2 first > /tmp/$1_resolve1.out
date

#should make some indexes for variable resolution
#special case for hibernate in here
psql $1 -f post_first_pass.sql 
date

#for undefined variables that have methods or fields, what is the most commonly declared variable type that has the same fields and methods in the entire collection of documents.
echo "./var_resolver.pl $2"
./var_resolver.pl $2
date

#create the dictionary/index of valid code elements
psql $1 -f dict_ce.sql
date

#find the ambiguous code elements that match a term in our collection-wide dictionary
echo "./resolve.pl $2 second > /tmp/$1_resolve2.out"
./resolve.pl $2 second > /tmp/$1_resolve2.out
date

#vacuum and analyze and create indexes
echo "create indexes"
psql $1 -f create_index.sql
date

#create tmp tables of unresolved local terms
psql $1 -f du.sql
date

#Do the local context resolution
echo "./du.pl $2"
./du.pl $2
date


#Attach the post's date to each code element
psql $1 -f date.sql 
#Create tmp tables to resolve terms by thread/date
psql $1 -f thread.sql 
date

#Do the thread context resolution
echo "./thread.pl $2"
./thread.pl $2
#./thread_freq.pl $2
date


#Includes unresolved two camel classes, but must exclude classes that have same name as project
echo "run final.sql including your own list of \"bad words\""
#psql $1 -f final.sql
#date

