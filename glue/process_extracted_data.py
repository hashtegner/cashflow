import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import current_timestamp, format_date, col

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'INPUT_FILE', "BUCKET_NAME"])
input_path = args['INPUT_FILE']
bucket_name = args['BUCKET_NAME']
raw_data_path = f"s3://{bucket_name}/raw/market_data"

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)


df = spark.read \
            .option("header", "true") \
            .option("inferSchema", "true") \
            .csv(input_path) \
            .withColumn("processed_at", current_timestamp()) \
            .writeColumn("processed_date", format_date(col("processed_at"), "yyyy-MM-dd"))

df.write.mode("overwrite").partitionBy("processed_date").parquet(raw_data_path)

job.commit()
