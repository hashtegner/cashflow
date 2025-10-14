import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import sum, avg, max, min, col, lag
from pyspark.sql.window import Window

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
raw_data_path = "s3://cashflow-data/raw/stocks"
refined_data_path = "s3://cashflow-data/refined/stocks"

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

database_name = "cashflow"
raw_table_name = "stocks_raw"
refined_table_name = "stocks_refined"

# # Read raw data from S3
df = glueContext.create_dynamic_frame.from_catalog(database=database_name, table_name=raw_table_name)
df = df.toDF()


# add calculations
df = df.groupBy("ticker", "reference_date") \
    .agg(
        avg("close").alias("average_price"),
        max("high").alias("max_high"),
        min("low").alias("min_low")
    )

df = df.withColumn("market", col("market"))

# moving average 7d
window_7d = Window.partitionBy("ticker").orderBy("reference_date").rowsBetween(-6, 0)
window_full = Window.partitionBy("ticker").orderBy("reference_date")

# add moving average 7d
df = df.withColumn("price_avg_7d", avg("avg_price").over(window_7d))

# add lag prices
df = df.withColumn("price_lag_1_month", lag("avg_price", 1).over(window_full))
df = df.withColumn("price_lag_2_month", lag("avg_price", 2).over(window_full))
df = df.withColumn("price_lag_3_month", lag("avg_price", 3).over(window_full))

df.write.mode("overwrite").partitionBy("reference_date", "ticker").parquet(refined_data_path)

job.commit()
