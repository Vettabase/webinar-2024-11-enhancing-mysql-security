# Description

This repositories contains example for the webinar "Enhancing MySQL Security: 
More on Data-at-Rest Encryption", by Mike Rykmas, 2024/11/27.

We're making the examples publicly available not just as helper material for the webinar, but also for future reference. Even if you didn't attend the webinar, hopefully you'll find some useful examples and explanations here.

# Create custom sysbench image

- Version: 1.1.0 (with SSL support)

```
cd sysbench
docker build -t custom-sysbench:1.1.0 .
```

# (Re)-Build Stack

## Clean up
```
docker-compose down --remove-orphans
rm -rf volumes/
```

## Build
```
docker-compose up -d
```

# Apply aliases

The aliases helping you to simplify access to the current stack. 

```
source config/bash_aliases
```

## Example

```
$ encrypton -e "select @@hostname;"
+------------+
| @@hostname |
+------------+
| encrypton  |
+------------+
```

# Nodes Info

- Hostname: `encrypton`
	- Docker IP: `172.20.1.11`
	- Docker Image: `mysql:8.0.40-debian`
	- Role: `DB host with encryption enabled by default`
	- Port: `0.0.0.0:3311->3306/tcp`
	- DB Credentials: `root/root`
- Hostname: `encryptoff`
	- Docker IP: `172.20.1.12`
	- Docker Image: `mysql:8.0.40-debian`
	- Role: `DB host with encryption enabled by default`
	- Port: `0.0.0.0:3312->3306/tcp`
	- DB Credentials: `root/root`
- Hostname: `sysbench`
	- Docker IP: `172.20.1.13`
	- Docker Image: `custom-sysbench:1.1.0`
	- Role: `Sysbench host (for benchmarks)`

# Read data from tablespaces

## hexdump
```
hexdump -C volumes/encryptoff_data/sakila/category.ibd | head -500
hexdump -C volumes/encrypton_data/sakila/category.ibd | head -500
```

## strings
```
strings volumes/encryptoff_data/sakila/category.ibd | head -c 256
strings volumes/encrypton_data/sakila/category.ibd | head -c 256
```

# Check if data encrypted

## MySQL Query
```
SELECT TABLE_SCHEMA, TABLE_NAME, CREATE_OPTIONS FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='sakila' AND TABLE_TYPE='BASE TABLE';
```

### Output
```
+--------------+---------------+----------------+
| TABLE_SCHEMA | TABLE_NAME    | CREATE_OPTIONS |
+--------------+---------------+----------------+
| sakila       | actor         | ENCRYPTION='Y' |
| sakila       | address       | ENCRYPTION='Y' |
| sakila       | category      | ENCRYPTION='Y' |
| sakila       | city          | ENCRYPTION='Y' |
| sakila       | country       | ENCRYPTION='Y' |
| sakila       | customer      | ENCRYPTION='Y' |
| sakila       | film          | ENCRYPTION='Y' |
| sakila       | film_actor    | ENCRYPTION='Y' |
| sakila       | film_category | ENCRYPTION='Y' |
| sakila       | film_text     | ENCRYPTION='Y' |
| sakila       | inventory     | ENCRYPTION='Y' |
| sakila       | language      | ENCRYPTION='Y' |
| sakila       | payment       | ENCRYPTION='Y' |
| sakila       | rental        | ENCRYPTION='Y' |
| sakila       | staff         | ENCRYPTION='Y' |
| sakila       | store         | ENCRYPTION='Y' |
+--------------+---------------+----------------+
16 rows in set (0.0115 sec)
```

# Sysbench (from sysbench container)

## Prepare

### Encrypted Host
```
sysbench /usr/local/share/sysbench/oltp_read_write.lua \
  --mysql-host=172.20.1.11 \
  --mysql-port=3306 \
  --mysql-user=root \
  --mysql-password=root \
  --mysql-db=sakila \
  --mysql-ssl=on \
  --mysql-ssl-ca=/tmp/encrypton_data/ca.pem \
  --mysql-ssl-cert=/tmp/encrypton_data/client-cert.pem \
  --mysql-ssl-key=/tmp/encrypton_data/client-key.pem \
  --tables=5 \
  --table-size=100000 \
  prepare
```

### Non-Encrypted Host

```
sysbench /usr/local/share/sysbench/oltp_read_write.lua \
  --mysql-host=172.20.1.12 \
  --mysql-port=3306 \
  --mysql-user=root \
  --mysql-password=root \
  --mysql-db=sakila \
  --mysql-ssl=on \
  --mysql-ssl-ca=/tmp/encryptoff_data/ca.pem \
  --mysql-ssl-cert=/tmp/encryptoff_data/client-cert.pem \
  --mysql-ssl-key=/tmp/encryptoff_data/client-key.pem \
  --tables=5 \
  --table-size=100000 \
  prepare
```

## Run benchmarking

### Encrypted Host
```
sysbench /usr/local/share/sysbench/oltp_read_write.lua \
  --mysql-host=172.20.1.11 \
  --mysql-port=3306 \
  --mysql-user=root \
  --mysql-password=root \
  --mysql-db=sakila \
  --mysql-ssl=on \
  --mysql-ssl-ca=/tmp/encrypton_data/ca.pem \
  --mysql-ssl-cert=/tmp/encrypton_data/client-cert.pem \
  --mysql-ssl-key=/tmp/encrypton_data/client-key.pem \
  --tables=5 \
  --table-size=100000 \
  --threads=2 \
  --time=60 \
  run
```

### Non-Encrypted Host
```
sysbench /usr/local/share/sysbench/oltp_read_write.lua \
  --mysql-host=172.20.1.12 \
  --mysql-port=3306 \
  --mysql-user=root \
  --mysql-password=root \
  --mysql-db=sakila \
  --mysql-ssl=on \
  --mysql-ssl-ca=/tmp/encryptoff_data/ca.pem \
  --mysql-ssl-cert=/tmp/encryptoff_data/client-cert.pem \
  --mysql-ssl-key=/tmp/encryptoff_data/client-key.pem \
  --tables=5 \
  --table-size=100000 \
  --threads=2 \
  --time=60 \
  run
```

## Results

### Encrypted Host
```
SQL statistics:
    queries performed:
        read:                            1020096
        write:                           291456
        other:                           145728
        total:                           1457280
    transactions:                        72864  (1214.35 per sec.)
    queries:                             1457280 (24286.90 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

Throughput:
    events/s (eps):                      1214.3451
    time elapsed:                        60.0027s
    total number of events:              72864

Latency (ms):
         min:                                    1.78
         avg:                                    3.29
         max:                                   28.39
         95th percentile:                        4.91
         sum:                               239933.69

Threads fairness:
    events (avg/stddev):           18216.0000/182.55
    execution time (avg/stddev):   59.9834/0.00
```

### Non-Encrypted Host
```
SQL statistics:
    queries performed:
        read:                            1130836
        write:                           323096
        other:                           161548
        total:                           1615480
    transactions:                        80774  (1346.21 per sec.)
    queries:                             1615480 (26924.18 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

Throughput:
    events/s (eps):                      1346.2088
    time elapsed:                        60.0011s
    total number of events:              80774

Latency (ms):
         min:                                    1.27
         avg:                                    2.97
         max:                                   19.91
         95th percentile:                        4.49
         sum:                               239936.30

Threads fairness:
    events (avg/stddev):           20193.5000/46.10
    execution time (avg/stddev):   59.9841/0.00
```
