import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import current_date, date_format, col

args = getResolvedOptions(sys.argv, ['JOB_NAME', 'INPUT_FILE'])

# input file is the csv file with the exttracted stocks data
input_path = args['INPUT_FILE']
raw_data_path = "s3://cashflow-data/raw/stocks"

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)


df = spark.read \
            .option("header", "true") \
            .option("inferSchema", "true") \
            .csv(input_path) \

# add column to be used as partition key
df = df.withColumn("process_date", date_format(current_date(), "yyyyMMdd").cast("int")) \
    .withColumn("date", date_format(col("date"), "yyyyMMdd").cast("int")) \
    .withColumn("retrieve_at", date_format(col("retrieved_at"), "yyyyMMdd").cast("int"))


# rename columns to proper names
df = df.withColumnRenamed("name", "company_name") \
    .withColumnRenamed("sector", "company_sector") \
    .withColumnRenamed("retrieved_at", "retrieve_date") \
    .withColumnRenamed("date", "reference_date")

df.write.mode("overwrite").partitionBy("process_date").parquet(raw_data_path)


job.commit()
