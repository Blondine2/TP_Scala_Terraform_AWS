name := "TwitterAuthors"

version := "0.1"

scalaVersion := "2.11.12"
libraryDependencies += "com.amazonaws" % "aws-java-sdk-kinesis" % "1.11.880"
libraryDependencies += "com.amazonaws" % "aws-java-sdk-core" % "1.11.880"
libraryDependencies += "org.apache.bahir" %% "spark-streaming-twitter" % "2.3.2"
libraryDependencies += "org.apache.spark" %% "spark-core" % "2.2.0"
libraryDependencies += "org.apache.spark" %% "spark-sql" % "2.2.0"


libraryDependencies ++= Seq(

  "org.apache.spark" %% "spark-core" % "1.6.2",
  "org.apache.spark" %% "spark-streaming" % "2.4.0",
  "org.apache.spark" %% "spark-sql" % "1.6.2",
  "org.apache.spark" %% "spark-mllib" % "1.6.2",
  "org.apache.spark" %% "spark-streaming" % "0.8.0-incubating",
  "org.twitter4j" % "twitter4j-core" % "3.0.3"
)
