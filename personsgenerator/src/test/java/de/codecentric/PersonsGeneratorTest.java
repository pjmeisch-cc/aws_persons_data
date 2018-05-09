package de.codecentric;

import io.codearte.jfairy.Fairy;
import io.codearte.jfairy.producer.person.Person;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * @author P.J. Meisch (peter-josef.meisch@codecentric.de)
 */
class PersonsGeneratorTest {

    @Test
    @DisplayName("a person is converted to json")
    void personToJson() {
        final Person person = Fairy.create().person();
        final String json = new PersonsGenerator().json(person);
        System.out.println(json);
    }
}
