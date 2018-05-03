/*
 * (c) Copyright 2018 codecentric AG
 */
package de.codecentric;

import com.amazonaws.auth.profile.ProfileCredentialsProvider;
import com.amazonaws.services.kinesis.producer.Attempt;
import com.amazonaws.services.kinesis.producer.KinesisProducer;
import com.amazonaws.services.kinesis.producer.KinesisProducerConfiguration;
import com.amazonaws.services.kinesis.producer.UserRecordResult;
import com.google.gson.Gson;
import io.codearte.jfairy.Fairy;
import io.codearte.jfairy.producer.person.Address;
import io.codearte.jfairy.producer.person.Person;
import org.jetbrains.annotations.NotNull;
import org.kohsuke.args4j.CmdLineException;
import org.kohsuke.args4j.CmdLineParser;
import org.kohsuke.args4j.Option;

import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.text.MessageFormat;
import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.stream.IntStream;
import java.util.stream.Stream;

/**
 * @author P.J. Meisch (peter-josef.meisch@codecentric.de)
 */
public class PersonsGenerator {

    private final Fairy fairy = Fairy.create();
    private final Gson gson = new Gson();

    @NotNull
    @Option(name = "-count", usage = "number of records to create")
    private Integer count = 10;

    @Option(name = "-kinesis", usage = "kinesis stream name")
    private String streamName;

    public static void main(String[] args) {
        try {
            new PersonsGenerator().run(args);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void run(@NotNull String[] args) {
        final CmdLineParser cmdLineParser = new CmdLineParser(this);

        try {
            cmdLineParser.parseArgument(args);
        } catch (CmdLineException e) {
            e.printStackTrace();
        }

        if (null != streamName) {
            sendToKinesis();
        } else {
            personsCsvs().forEach(System.out::println);
        }
    }

    private void sendToKinesis() {
        final KinesisProducer kinesis = setupKinesis();
        List<Future<UserRecordResult>> putFutures = new LinkedList<>();
        persons()
                .forEach(person -> {
                    try {
                        final ByteBuffer byteBuffer = ByteBuffer.wrap(gson.toJson(person).getBytes("UTF-8"));
                        putFutures.add(kinesis.addUserRecord(streamName, "person-" + person.getLastName(),
                                byteBuffer));
                    } catch (UnsupportedEncodingException e) {
                        e.printStackTrace();
                    }
                });
        // Wait for puts to finish and check the results
        for (Future<UserRecordResult> f : putFutures) {
            try {
                UserRecordResult result = f.get(); // this does block
                if (result.isSuccessful()) {
                    System.out.println("Put record into shard " +
                            result.getShardId());
                } else {
                    for (Attempt attempt : result.getAttempts()) {
                        System.err.println(attempt.getErrorMessage());
                    }
                }
            } catch (InterruptedException | ExecutionException e) {
                e.printStackTrace();
            }
        }

    }

    @NotNull
    private KinesisProducer setupKinesis() {
        final ProfileCredentialsProvider credentialsProvider = new ProfileCredentialsProvider("codecentric");
        final KinesisProducerConfiguration configuration = new KinesisProducerConfiguration();
        configuration.setCredentialsProvider(credentialsProvider);
        configuration.setRegion("eu-central-1");
        return new KinesisProducer(configuration);
    }


    @NotNull
    private String format(@NotNull Person person) {
        final Address address = person.getAddress();
        return MessageFormat.format("{0},{1},{2},{3},{4}", person.getFirstName(), person.getLastName(),
                address.getCity(), address.getStreet(), address.getStreetNumber());
    }

    @NotNull
    private Stream<String> personsCsvs() {
        return IntStream.rangeClosed(1, count).boxed().map(i -> format(fairy.person()));
    }

    @NotNull
    private Stream<Person> persons() {
        return IntStream.rangeClosed(1, count).boxed().map(i -> fairy.person());
    }
}
