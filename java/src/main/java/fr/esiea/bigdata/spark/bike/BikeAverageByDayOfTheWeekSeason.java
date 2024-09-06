package fr.esiea.bigdata.spark.bike;

import org.apache.spark.SparkConf;
import org.apache.spark.api.java.JavaPairRDD;
import org.apache.spark.api.java.JavaRDD;
import org.apache.spark.api.java.JavaSparkContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import scala.Tuple2;

import java.io.Serializable;
import java.text.SimpleDateFormat;

import static org.sparkproject.guava.base.Preconditions.checkArgument;

public class BikeAverageByDayOfTheWeekSeason implements Serializable {
    private static final Logger LOGGER = LoggerFactory.getLogger(BikeAverageByDayOfTheWeekSeason.class);

    public static void main(String[] args) {
        checkArgument(args.length > 1, "Please provide the path of input file and output dir as parameters.");
        new BikeAverageByDayOfTheWeekSeason().run(args[0], args[1]);
    }

    public void run(String inputFilePath, String outputDir) {

        SparkConf conf = new SparkConf()
                .setAppName(BikeAverageByDayOfTheWeekSeason.class.getName())
                .setMaster("local[*]");

        JavaSparkContext sc = new JavaSparkContext(conf);

        JavaRDD<String> textFile = sc.textFile(inputFilePath);

        // Skip the header row
        JavaRDD<String> data = textFile.filter(line -> !line.startsWith("timestamp"));

        // Map each line to a pair of ((dayOfWeek, season), count)
        JavaPairRDD<Tuple2<String, String>, Tuple2<Integer, Integer>> counts = data
                .mapToPair(line -> {
                    String[] parts = line.split(",");
                    String timestamp = parts[0];
                    String dayOfWeek = new SimpleDateFormat("EEEE").format(new SimpleDateFormat("yyyy-MM-dd").parse(timestamp));
                    String season = getSeasonName(parts[9]);
                    int count = Integer.parseInt(parts[1]);
                    return new Tuple2<>(new Tuple2<>(dayOfWeek, season), new Tuple2<>(count, 1));
                })
                .reduceByKey((a, b) -> new Tuple2<>(a._1 + b._1, a._2 + b._2));

        // Calculate the average bike count for each category
        JavaPairRDD<Tuple2<String, String>, Double> averages = counts.mapToPair(
                tuple -> new Tuple2<>(tuple._1, (double) tuple._2._1 / tuple._2._2)
        );

        // Save the results to a single output file
        averages.coalesce(1).saveAsTextFile(outputDir);
    }

    private String getSeasonName(String seasonCode) {
        double seasonCodeDouble = Double.parseDouble(seasonCode);
        int seasonCodeInt = (int) seasonCodeDouble;
        switch (seasonCodeInt) {
            case 0: return "spring";
            case 1: return "summer";
            case 2: return "fall";
            case 3: return "winter";
            default: throw new IllegalArgumentException("Invalid season code: " + seasonCode);
        }
    }
}