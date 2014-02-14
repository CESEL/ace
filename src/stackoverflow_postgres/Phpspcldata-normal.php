<?php 

Echo "Hello, World!";

$db_handle = pg_pconnect("dbname=so_test");

if (!$db_handle) {
  echo "An error occurred.\n";
  exit;
}
   

#$result = pg_exec($db_handle);
$result = pg_query($db_handle);
$query1 = "SELECT id, body FROM posts1"; 
$result1 = pg_query( $query1);
$d1=pg_fetch_array($result1);
#$d1 = pg_fetch_row($result1);

while($d1['body'] != NULL)
	{  
		$finl1 = html_entity_decode($d1['body']);
		$finl = pg_escape_string($finl1);
		$query2 = "update posts1 set body ='$finl' where id = ('$d1[id]')";
		$chk=pg_query($db_handle,$query2);
		if(!$chk)
			 {
				printf ("\nERROR\n");
				exit;
			}
		$d1=pg_fetch_array($result1);
	}

echo" id is equal to " .$d1['id'];
#echo "Number of rows: " . $finl;   

#pg_freeresult($result);   
pg_close($db_handle); 
?> 
