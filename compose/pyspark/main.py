import pyspark

sc = pyspark.SparkContext('local[*]')

# do something
sc.parallelize(range(1000))
rdd.takeSample(False, 5)

