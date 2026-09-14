package lessons.l12;

import java.time.DateTimeException;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.OffsetDateTime;
import java.time.Period;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Calendar;
import java.util.Locale;

/** Lesson 12: java.time, where C# has DateTime, DateTimeOffset, DateOnly and TimeZoneInfo. */
public class Dates {

    public static void main(String[] args) {
        // Instant is a point on the timeline, like a DateTimeOffset in UTC.
        Instant noon = Instant.parse("2026-09-13T12:00:00Z");
        ZoneId paris = ZoneId.of("Europe/Paris");
        System.out.println("in Paris: " + noon.atZone(paris));
        System.out.println("in Toronto: " + noon.atZone(ZoneId.of("America/Toronto")));

        // LocalDate is DateOnly. Months count from 1, and an invalid date throws.
        LocalDate endOfJanuary = LocalDate.of(2026, 1, 31);
        System.out.println("a month after January 31: " + endOfJanuary.plusMonths(1));
        System.out.println("from January 31 to March 1: " + Period.between(endOfJanuary, LocalDate.of(2026, 3, 1)));
        try {
            LocalDate.of(2026, 2, 30);
        } catch (DateTimeException e) {
            System.out.println("DateTimeException: " + e.getMessage());
        }
        // The API it replaces counted months from 0.
        System.out.println("Calendar.SEPTEMBER: " + Calendar.SEPTEMBER);

        // ZonedDateTime applies the zone's rules: Paris moves to summer time on March 29, 2026.
        ZonedDateTime saturdayNoon = ZonedDateTime.of(2026, 3, 28, 12, 0, 0, 0, paris);
        System.out.println("plusDays(1): " + saturdayNoon.plusDays(1));
        System.out.println("plusHours(24): " + saturdayNoon.plusHours(24));
        System.out.println("that day lasted " + Duration.between(saturdayNoon, saturdayNoon.plusDays(1)));

        // A local time that doesn't exist is moved forward; one that happens twice takes the earlier offset.
        System.out.println("02:30 on March 29: " + ZonedDateTime.of(2026, 3, 29, 2, 30, 0, 0, paris));
        ZonedDateTime twice = ZonedDateTime.of(2026, 10, 25, 2, 30, 0, 0, paris);
        System.out.println("02:30 on October 25: " + twice + ", or " + twice.withLaterOffsetAtOverlap());

        // Each type parses only its own format.
        System.out.println("OffsetDateTime.parse: " + OffsetDateTime.parse("2026-09-13T14:00:00+02:00").toInstant());
        try {
            LocalDateTime.parse("2026-09-13T12:00:00Z");
        } catch (DateTimeParseException e) {
            System.out.println("DateTimeParseException: " + e.getMessage());
        }

        // Y is the week-based year, and weeks depend on the locale.
        LocalDate newYearsEve = LocalDate.of(2026, 12, 31);
        System.out.println("yyyy: " + newYearsEve.format(DateTimeFormatter.ofPattern("yyyy-MM-dd")));
        System.out.println("YYYY, US: " + newYearsEve.format(DateTimeFormatter.ofPattern("YYYY-MM-dd", Locale.US)));
        System.out.println("YYYY, France: " + newYearsEve.format(DateTimeFormatter.ofPattern("YYYY-MM-dd", Locale.FRANCE)));
    }
}
