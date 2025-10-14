import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import current_date, date_format

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'INPUT_FILE', "BUCKET_NAME"])
input_path = args['INPUT_FILE']
bucket_name = args['BUCKET_NAME']
raw_data_path = f"s3://{bucket_name}/raw/stocks"

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
df = df.withColumn("process_date", date_format(current_date(), "yyyyMMdd") \
        .cast("int"))


# rename columns to proper names
df = df.withColumn("name", "company_name") \
    .withColumn("sector", "company_sector") \
    .withColumn("retrieved_at", "retrieve_date")

df.write.mode("overwrite").partitionBy("processed_date").parquet(raw_data_path)

# repair table to ensure all partitions are created
spark.sql("MSCK REPAIR TABLE cashflow.stocks_raw")

job.commit()
