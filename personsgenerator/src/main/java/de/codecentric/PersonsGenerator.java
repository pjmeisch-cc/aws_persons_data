/*
 * (c) Copyright 2018 codecentric AG
 */
package de.codecentric;

import io.codearte.jfairy.Fairy;
import io.codearte.jfairy.producer.person.Address;
import io.codearte.jfairy.producer.person.Person;

import java.text.MessageFormat;

/**
 * @author P.J. Meisch (peter-josef.meisch@codecentric.de)
 */
public class PersonsGenerator {
    public static void main(String[] args) {
        final Fairy fairy = Fairy.create();
        int count = 500;
        while (count-- > 0) {
            System.out.println(format(fairy.person()));
        }
    }

    private static String format(Person person) {
        final Address address = person.getAddress();
        return MessageFormat.format("{0},{1},{2},{3},{4}", person.getFirstName(), person.getLastName(), address
                        .getCity(),
                address.getStreet(), address.getStreetNumber());
    }
}
