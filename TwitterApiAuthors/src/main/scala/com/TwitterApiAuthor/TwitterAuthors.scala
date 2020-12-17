package com.TwitterApiAuthor


import com.amazonaws.auth.{AWSStaticCredentialsProvider, DefaultAWSCredentialsProviderChain}
import org.apache.spark.SparkConf
import org.apache.spark.streaming.twitter.TwitterUtils
import org.apache.spark.streaming.{Seconds, StreamingContext}
import twitter4j.auth.OAuthAuthorization
import twitter4j.conf.ConfigurationBuilder
import com.amazonaws.services.kinesis.AmazonKinesisClientBuilder
import com.amazonaws.services.kinesis.model.PutRecordsRequest
import com.amazonaws.services.kinesis.model.PutRecordsRequestEntry
import com.amazonaws.services.kinesis.model.PutRecordsResult
import java.nio.ByteBuffer
import java.util

object TwitterAuthors {
  def main(args: Array[String]): Unit =  {

    // twitter credentials
    val twitterCredentials = new Array[String](4);
    twitterCredentials(0) = "7OC4H9doCOMQ0KiHWivCQiyh3";
    twitterCredentials(1) = "mD0aomzIQXIIsfbeNuiXqeKz5muo8vhbdgyNESJxm9G8lmZ9eJ";
    twitterCredentials(2) =  "1335636088724054022-oLy2k53Vv2rqcyBvAz5nJYw26z74i8";
    twitterCredentials(3) = "lwrK9NYeqsjoUZpZfdJcPFOtyw8QSFBpqhtvoaZqIrGqZ";

    val appName = "PopularTweeterAuthors"
    val conf = new SparkConf().setAppName(appName).setMaster("local[4]")
    val streaming = new StreamingContext(conf, Seconds(5))
    val Array(consumerKey, consumerSecret, accessToken, accessTokenSecret) = twitterCredentials.take(4)

    val filters = args.takeRight(args.length - 4)
    val config = new ConfigurationBuilder
    config.setDebugEnabled(true).setOAuthConsumerKey(consumerKey)
      .setOAuthConsumerSecret(consumerSecret)
      .setOAuthAccessToken(accessToken)
      .setOAuthAccessTokenSecret(accessTokenSecret)
      .setJSONStoreEnabled(true)

    val auth = new OAuthAuthorization(config.build)

    val tweets = TwitterUtils.createStream(streaming, Some(auth), filters)

    // Splitting the streams to Extracts all the authors who tweeted
    val authors = tweets.flatMap(status => status.getText.split(" ").filter(_.startsWith("@")))

    // In this variable, we count all the authors who have send tweets on the passed 60 seconds
    val recentAuthors = authors.map((_, 1)).reduceByKeyAndWindow(_ + _, Seconds(60))
      .map { case (topic, count) => (count, topic) }
      .transform(_.sortByKey(false))

    val credentials = new DefaultAWSCredentialsProviderChain
    val kinesisClient = AmazonKinesisClientBuilder.standard()
      .withCredentials(new AWSStaticCredentialsProvider(credentials.getCredentials))
      .withRegion("eu-central-1").build()
    val putRecordsRequest = new PutRecordsRequest
    putRecordsRequest.setStreamName("AppStreamData")
    val putRecordsRequestEntryList = new util.ArrayList[PutRecordsRequestEntry]

    recentAuthors.foreachRDD(rdd => {
      val topList = rdd.take(40)
      println("\nThis is the authors who tweeted the past 60 seconds : %s au total:".format(rdd.count()))
      topList.foreach { case (count, tag) => println("%s :%s tweets".format(tag, count))

        val tweeters: String = "%s :%s tweets ".format(tag, count) + "\n"
        val putRecordsRequestEntry = new PutRecordsRequestEntry
        putRecordsRequestEntry.setData(ByteBuffer.wrap(tweeters.getBytes))
        putRecordsRequestEntry.setPartitionKey(String.format("apiscalabucket"))
        putRecordsRequestEntryList.add(putRecordsRequestEntry)
        putRecordsRequest.setRecords(putRecordsRequestEntryList)
        val putRecordsResult: PutRecordsResult = kinesisClient.putRecords(putRecordsRequest)
        System.out.println("Put Result" + putRecordsResult)
      }
    })

    streaming.start()
    streaming.awaitTermination()
  }

}


