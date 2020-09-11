#!/bin/bash

#get timer and retries from env

if ["$HOOK_RETRIES" = "" ]; then
  HOOK_RETRIES=1
fi
if ["$HOOK_SLEEP" = "" ]; then
  HOOK_RETRIES=2
fi

echo "=========================================="
echo $HOOK_RETRIES
echo $MYSQL_SERVICE_HOST
echo $MYSQL_USER
echo $MYSQL_PASSWORD
echo $MYSQL_DATABASE
echo "=========================================="

cd /tmp

sql_scripts='CREATE TABLE IF NOT EXISTS users (
    user_id int(10) unsigned NOT NULL AUTO_INCREMENT,
    name varchar(100) NOT NULL,
    email varchar(100) NOT NULL,
    PRIMARY KEY (user_id) ENGINE=InnoDB DEFAULT CHARSET=utf8;

insert into users(name,email) values ('user1','user1@example.com');
insert into users(name,email) values ('user2','user2@example.com');
insert into users(name,email) values ('user3','user3@example.com');'

echo "Trying $HOOK_RETRIES times, sleeping $HOOK_SLEEP sec between tries:"
while ["$HOOK_RETRIES" != 0 ]; do
  echo -n 'Checking if MySQL is up...'
  if mysqlshow -h$MYSQL_SERVICE_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD -P3306 $MYSQL_DATABASE &>/dev/null
  then 
    echo 'Database is up'
	break
  else
    echo 'Database is down'
	# Sleep to wait for the MySql pod to be ready
    sleep $HOOK_SLEEP
  fi
  
  let HOOK_RETRIES=HOOK_RETRIES-1
done

if ["$HOOK_RETRIES" = 0 ]; then
  echo 'Too many tries, giving up'
  exit 1
fi

#Run the SQL script
if mysql -h$MYSQL_SERVICE_HOST -U $MYSQL_USER -p$MYSQL_PASSWORD -p3306 $MYSQL_DATABASE < echo sql_scripts
then  
  echo 'Database initialized successfully'
else 
  echo 'Failed to initialize database'
  exit 2
fi
