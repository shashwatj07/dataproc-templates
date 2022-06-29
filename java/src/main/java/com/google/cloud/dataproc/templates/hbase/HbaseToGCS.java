package com.google.cloud.dataproc.templates.hbase;

import com.google.cloud.dataproc.templates.BaseTemplate;
import com.google.cloud.dataproc.templates.util.TemplateConstants;

import org.apache.commons.lang3.StringUtils;
import org.apache.hadoop.hbase.spark.datasources.HBaseTableCatalog;
import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.SparkSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;


public class HbaseToGCS implements BaseTemplate, TemplateConstants {

    private static final Logger LOGGER = LoggerFactory.getLogger(HbaseToGCS.class);

    private String catalogue;
    private String projectId="anishks-poc";
    private String instanceId="demodataproc";
    private String outputFileFormat;
    private String gcsSaveMode;
    private String gcsWritePath;

    public HbaseToGCS() {

        //catalogue = getProperties().getProperty(HBASE_TO_BIG_TABLE_CATALOGUE);
        catalogue = "{" + "\"table\":{\"namespace\":\"default\", \"name\":\"my_table\"}," +
                "\"rowkey\":\"key\"," +
                "\"columns\":{" +
                "\"key\":{\"cf\":\"rowkey\", \"col\":\"key\", \"type\":\"string\"}," +
                "\"name\":{\"cf\":\"cf\", \"col\":\"name\", \"type\":\"string\"}" +
                "}" +
                "}";

        outputFileFormat = getProperties().getProperty(HBASE_TO_GCS_FILE_FORMAT);
        gcsSaveMode= getProperties().getProperty(HBASE_TO_GCS_SAVE_MODE);
        gcsWritePath=getProperties().getProperty(HBASE_TO_GCS_OUTPUT_PATH);
    }


    @Override
    public void runTemplate() {
        if (StringUtils.isAllBlank(outputFileFormat)
                || StringUtils.isAllBlank(gcsSaveMode)
                || StringUtils.isAllBlank(gcsWritePath)) {
            LOGGER.error(
                    "{},{} is required parameter. ",
                    HBASE_TO_GCS_OUTPUT_PATH,HBASE_TO_GCS_FILE_FORMAT,HBASE_TO_GCS_SAVE_MODE
            );
            throw new IllegalArgumentException(
                    "Required parameters for HbaseToGCS not passed. "
                            + "Set mandatory parameter for HbaseToGCS template "
                            + "in resources/conf/template.properties file.");
        }

        SparkSession spark =
                SparkSession.builder()
                        .appName("Spark HbaseToGCS Job")
                        .getOrCreate();


        Map<String, String> optionsMap = new HashMap<String, String>();
        optionsMap.put(HBaseTableCatalog.tableCatalog(), catalogue);


        // Read from HBase
        Dataset dataset = spark.read()
                .format("org.apache.hadoop.hbase.spark")
                .options(optionsMap)
                .option("hbase.spark.use.hbasecontext", "false")
                .load();

        //Write To GCS
        dataset.write().format(outputFileFormat).mode(gcsSaveMode).save(gcsWritePath);

    }

}