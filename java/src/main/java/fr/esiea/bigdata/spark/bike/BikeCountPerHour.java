package fr.esiea.bigdata.spark.bike;

import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaPairRDD;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import scala.Tuple2;

import static org.sparkproject.guava.base.Preconditions.checkArgument;

public class BikeCountPerHour {
    private static final Logger LOGGER = LoggerFactory.getLogger(BikeCountPerHour.class);

    public static void main(String[] args) {
        checkArgument(args.length > 1, "Please provide the path of input file and output dir as parameters.");
        new BikeCountPerHour().run(args[0], args[1]);
    }

    public void run(String inputFilePath, String outputDir) {

        SparkConf conf = new SparkConf()
                .setAppName(BikeCountPerHour.class.getName())
                .setMaster("local[*]");

        JavaSparkContext sc = new JavaSparkContext(conf);

        JavaRDD<String> textFile = sc.textFile(inputFilePath);

        // Skip the header row
        JavaRDD<String> data = textFile.filter(line -> !line.startsWith("timestamp"));

        // Map each line to a pair of (hour, count)
        JavaPairRDD<String, Integer> counts = data
                .mapToPair(line -> {
                    String[] parts = line.split(",");
                    String timestamp = parts[0];
                    int count = Integer.parseInt(parts[1]);
                    String hour = timestamp.split(" ")[1].split(":")[0];
                    return new Tuple2<>(hour, count);
                })
                .reduceByKey(Integer::sum);

        // Sort the results by hour
        JavaPairRDD<String, Integer> sortedCounts = counts.sortByKey();

        // Save the sorted results to a single output file
        sortedCounts.coalesce(1).saveAsTextFile(outputDir);
    }
}