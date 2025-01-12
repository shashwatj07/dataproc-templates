# 1. JDBC To JDBC

Template for reading data from JDBC table and writing them to a JDBC table. It supports reading partition tabels and write into partitioned or non-partitioned tables.

## Arguments

* `jdbctojdbc.input.url`: JDBC input URL
* `jdbctojdbc.input.driver`: JDBC input driver name
* `jdbctojdbc.input.table`: JDBC input table name
* `jdbctojdbc.input.partitioncolumn` (Optional): JDBC input table partition column name
* `jdbctojdbc.input.lowerbound` (Optional): JDBC input table partition column lower bound which is used to decide the partition stride
* `jdbctojdbc.input.upperbound` (Optional): JDBC input table partition column upper bound which is used to decide the partition stride
* `jdbctojdbc.numpartitions` (Optional): The maximum number of partitions that can be used for parallelism in table reading and writing. Same value will be used for both input and output jdbc connection. Default set to 10
* `jdbctojdbc.output.url`: JDBC output url
* `jdbctojdbc.output.driver`: JDBC output driver name
* `jdbctojdbc.output.table`: JDBC output table name
* `jdbctojdbc.output.create_table.option` (Optional): This option allows setting of database-specific table and partition options when creating a output table
* `jdbctojdbc.output.mode` (Optional): Output write mode (one of: append,overwrite,ignore,errorifexists)(Defaults to append)
* `jdbctojdbc.output.batch.size` (Optional): JDBC output batch size. Default set to 1000

## Usage

```
$ python main.py --template JDBCTOJDBC --help

usage: main.py --template JDBCTOJDBC \
    --jdbctojdbc.input.url JDBCTOJDBC.INPUT.URL \
    --jdbctojdbc.input.driver JDBCTOJDBC.INPUT.DRIVER \
    --jdbctojdbc.input.table JDBCTOJDBC.INPUT.TABLE \
    --jdbctojdbc.output.url JDBCTOJDBC.OUTPUT.URL \
    --jdbctojdbc.output.driver JDBCTOJDBC.OUTPUT.DRIVER \
    --jdbctojdbc.output.table JDBCTOJDBC.OUTPUT.TABLE \

optional arguments:
    -h, --help            show this help message and exit
    --jdbctojdbc.input.partitioncolumn JDBCTOJDBC.INPUT.PARTITIONCOLUMN \
    --jdbctojdbc.input.lowerbound JDBCTOJDBC.INPUT.LOWERBOUND \
    --jdbctojdbc.input.upperbound JDBCTOJDBC.INPUT.UPPERBOUND \
    --jdbctojdbc.numpartitions JDBCTOJDBC.NUMPARTITIONS \
    --jdbctojdbc.output.create_table.option JDBCTOJDBC.OUTPUT.CREATE_TABLE.OPTION \
    --jdbctojdbc.output.mode {overwrite,append,ignore,errorifexists} \
    --jdbctojdbc.output.batch.size JDBCTOJDBC.OUTPUT.BATCH.SIZE \
```

## Required JAR files

This template requires the JDBC jar file to be available in the Dataproc cluster.
User has to download the required jar file and host it inside a GCS Bucket, so that it could be referred during the execution of code.

wget command to download JDBC jar file is as follows :-

* MySQL
```
wget http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.30.tar.gz
```
* PostgreSQL
```
wget https://jdbc.postgresql.org/download/postgresql-42.2.6.jar
```
* Microsoft SQL Server
```
wget https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/6.4.0.jre8/mssql-jdbc-6.4.0.jre8.jar
```

Once the jar file gets downloaded, please upload the file into a GCS Bucket and export the below variable

```
export JARS=<gcs-bucket-location-containing-jar-file> 
```

## JDBC URL syntax

* MySQL
```
jdbc:mysql://<hostname>:<port>/<dbname>?user=<username>&password=<password>
```
* PostgreSQL
```
jdbc:postgresql://<hostname>:<port>/<dbname>?user=<username>&password=<password>
```
* Microsoft SQL Server
```
jdbc:sqlserver://<hostname>:<port>;databaseName=<dbname>;user=<username>;password=<password>
```

## Other important properties

* Driver Class

    * MySQL
    ```
    jdbctojdbc.input.driver="com.mysql.cj.jdbc.Driver" 
    ```
    * PostgreSQL
    ```
    jdbctojdbc.input.driver="org.postgresql.Driver"
    ```
    * Microsoft SQL Server
    ```
    jdbctojdbc.input.driver="com.microsoft.sqlserver.jdbc.SQLServerDriver"
    ```

* You can either specify the source table name or have SQL query within double quotes. Example,

```
jdbctojdbc.input.table="employees"
jdbctojdbc.input.table="(select * from employees where dept_id>10) as employees"
```

* partitionColumn, lowerBound, upperBound and numPartitions must be used together. If one is specified then all needs to be specified.

* You can specify the target table properties such as partition column using below property. This is useful when target table is not present or when write mode=overwrite and you need the target table to be created as partitioned table.

    * MySQL
    ```
    jdbctojdbc.output.create_table.option="PARTITION BY RANGE(id)  (PARTITION p0 VALUES LESS THAN (5),PARTITION p1 VALUES LESS THAN (10),PARTITION p2 VALUES LESS THAN (15),PARTITION p3 VALUES LESS THAN MAXVALUE)"
    ```
    * PostgreSQL
    ```
    jdbctojdbc.output.create_table.option="PARTITION BY RANGE(id);CREATE TABLE po0 PARTITION OF <table_name> FOR VALUES FROM (MINVALUE) TO (5);CREATE TABLE po1 PARTITION OF <table_name> FOR VALUES FROM (5) TO (10);CREATE TABLE po2 PARTITION OF <table_name> FOR VALUES FROM (10) TO (15);CREATE TABLE po3 PARTITION OF <table_name> FOR VALUES FROM (15) TO (MAXVALUE);"
    ```

* Additional execution details [refer spark jdbc doc](https://spark.apache.org/docs/latest/sql-data-sources-jdbc.html)

## General execution: 

```
export GCP_PROJECT=<gcp-project-id> 
export REGION=<region>  
export GCS_STAGING_LOCATION=<gcs staging location> 
export SUBNET=<subnet>   
export JARS="<gcs_path_to_jdbc_jar_files>/mysql-connector-java-8.0.29.jar,<gcs_path_to_jdbc_jar_files>/postgresql-42.2.6.jar,<gcs_path_to_jdbc_jar_files>/mssql-jdbc-6.4.0.jre8.jar"

./bin/start.sh \
-- --template=JDBCTOJDBC \
--jdbctojdbc.input.url="jdbc:mysql://<hostname>:<port>/<dbname>?user=<username>&password=<password>" \
--jdbctojdbc.input.driver=<jdbc-driver-class-name> \
--jdbctojdbc.input.table=<input table name or subquery with where clause filter> \
--jdbctojdbc.input.partitioncolumn=<optional-partition-column-name> \
--jdbctojdbc.input.lowerbound=<optional-partition-start-value>  \
--jdbctojdbc.input.upperbound=<optional-partition-end-value>  \
--jdbctojdbc.numpartitions=<optional-partition-number> \
--jdbctojdbc.output.url="jdbc:mysql://<hostname>:<port>/<dbname>?user=<username>&password=<password>" \
--jdbctojdbc.output.driver=<jdbc-driver-class-name> \
--jdbctojdbc.output.table=<output table name> \
--jdbctojdbc.output.create_table.option=<optional_output-table-properties> \
--jdbctojdbc.output.mode="<optional_write-mode> \
--jdbctojdbc.output.batch.size=<optional_batch-size>
```

## Example execution: 

```
export GCP_PROJECT=my-gcp-proj
export REGION=us-central1 
export GCS_STAGING_LOCATION=gs://my-gcp-proj/staging
export SUBNET=projects/my-gcp-proj/regions/us-central1/subnetworks/default   
export JARS="gs://my-gcp-proj/jars/mysql-connector-java-8.0.29.jar,gs://my-gcp-proj/jars/postgresql-42.2.6.jar,gs://my-gcp-proj/jars/mssql-jdbc-6.4.0.jre8.jar"
```
* MySQL to MySQL
```
./bin/start.sh \
-- --template=JDBCTOJDBC \
--jdbctojdbc.input.url="jdbc:mysql://1.1.1.1:3306/mydb?user=root&password=password123" \
--jdbctojdbc.input.driver="com.mysql.cj.jdbc.Driver" \
--jdbctojdbc.input.table="(select * from employees where id <10) as employees" \
--jdbctojdbc.input.partitioncolumn=id \
--jdbctojdbc.input.lowerbound="1" \
--jdbctojdbc.input.upperbound="10" \
--jdbctojdbc.numpartitions="4" \
--jdbctojdbc.output.url="jdbc:mysql://1.1.1.1:3306/mydb?user=root&password=password123" \
--jdbctojdbc.output.driver="com.mysql.cj.jdbc.Driver" \
--jdbctojdbc.output.table="employees_out" \
--jdbctojdbc.output.create_table.option="PARTITION BY RANGE(id)  (PARTITION p0 VALUES LESS THAN (5),PARTITION p1 VALUES LESS THAN (10),PARTITION p2 VALUES LESS THAN (15),PARTITION p3 VALUES LESS THAN MAXVALUE)" \
--jdbctojdbc.output.mode="overwrite" \
--jdbctojdbc.output.batch.size="1000"
```

* PostgreSQL to PostgreSQL
```
./bin/start.sh \
-- --template=JDBCTOJDBC \
--jdbctojdbc.input.url="jdbc:postgresql://1.1.1.1:5432/postgres?user=postgres&password=password123" \
--jdbctojdbc.input.driver="org.postgresql.Driver" \
--jdbctojdbc.input.table="(select * from employees) as employees" \
--jdbctojdbc.input.partitioncolumn=id \
--jdbctojdbc.input.lowerbound="11" \
--jdbctojdbc.input.upperbound="20" \
--jdbctojdbc.numpartitions="4" \
--jdbctojdbc.output.url="jdbc:postgresql://1.1.1.1:5432/postgres?user=postgres&password=password123" \
--jdbctojdbc.output.driver="org.postgresql.Driver" \
--jdbctojdbc.output.table="employees_out" \
--jdbctojdbc.output.create_table.option="PARTITION BY RANGE(id);CREATE TABLE po0 PARTITION OF employees_out FOR VALUES FROM (MINVALUE) TO (5);CREATE TABLE po1 PARTITION OF employees_out FOR VALUES FROM (5) TO (10);CREATE TABLE po2 PARTITION OF employees_out FOR VALUES FROM (10) TO (15);CREATE TABLE po3 PARTITION OF employees_out FOR VALUES FROM (15) TO (MAXVALUE);" \
--jdbctojdbc.output.mode="overwrite" \
--jdbctojdbc.output.batch.size="1000"
```

* Microsoft SQL Server to Microsoft SQL Server
```
./bin/start.sh \
-- --template=JDBCTOJDBC \
--jdbctojdbc.input.url="jdbc:sqlserver://1.1.1.1:1433;databaseName=mydb;user=sqlserver;password=password123" \
--jdbctojdbc.input.driver="com.microsoft.sqlserver.jdbc.SQLServerDriver" \
--jdbctojdbc.input.table="employees" \
--jdbctojdbc.input.partitioncolumn=id \
--jdbctojdbc.input.lowerbound="11" \
--jdbctojdbc.input.upperbound="20" \
--jdbctojdbc.numpartitions="4" \
--jdbctojdbc.output.url="jdbc:sqlserver://1.1.1.1:1433;databaseName=mydb;user=sqlserver;password=password123" \
--jdbctojdbc.output.driver="com.microsoft.sqlserver.jdbc.SQLServerDriver" \
--jdbctojdbc.output.table="employees_out" \
--jdbctojdbc.output.mode="overwrite" \
--jdbctojdbc.output.batch.size="1000"
```

* MySQL to PostgreSQL

```
./bin/start.sh \
-- --template=JDBCTOJDBC \
--jdbctojdbc.input.url="jdbc:mysql://1.1.1.1:3306/mydb?user=root&password=password123" \
--jdbctojdbc.input.driver="com.mysql.cj.jdbc.Driver" \
--jdbctojdbc.input.table="employees" \
--jdbctojdbc.input.partitioncolumn=id \
--jdbctojdbc.input.lowerbound="11" \
--jdbctojdbc.input.upperbound="20" \
--jdbctojdbc.numpartitions="4" \
--jdbctojdbc.output.url="jdbc:postgresql://1.1.1.1:5432/postgres?user=postgres&password=password123" \
--jdbctojdbc.output.driver="org.postgresql.Driver" \
--jdbctojdbc.output.table="employees_out" \
--jdbctojdbc.output.mode="overwrite" \
--jdbctojdbc.output.batch.size="1000"
```

* MySQL to Microsoft SQL Server

```
./bin/start.sh \
-- --template=JDBCTOJDBC \
--jdbctojdbc.input.url="jdbc:mysql://1.1.1.1:3306/mydb?user=root&password=password123" \
--jdbctojdbc.input.driver="com.mysql.cj.jdbc.Driver" \
--jdbctojdbc.input.table="employees" \
--jdbctojdbc.input.partitioncolumn=id \
--jdbctojdbc.input.lowerbound="11" \
--jdbctojdbc.input.upperbound="20" \
--jdbctojdbc.numpartitions="4" \
--jdbctojdbc.output.url="jdbc:sqlserver://1.1.1.1:1433;databaseName=mydb;user=sqlserver;password=password123" \
--jdbctojdbc.output.driver="com.microsoft.sqlserver.jdbc.SQLServerDriver" \
--jdbctojdbc.output.table="employees_out" \
--jdbctojdbc.output.mode="overwrite" \
--jdbctojdbc.output.batch.size="1000"
```