package lessons.l03;

import java.util.EnumMap;

/** Lesson 3: Java enums are classes with a fixed set of instances. */
public class Enums {

    enum Planet {
        MERCURY(3.303e+23, 2.4397e6),
        EARTH(5.976e+24, 6.37814e6);

        private static final double G = 6.67300E-11;
        private final double mass;
        private final double radius;

        Planet(double mass, double radius) {
            this.mass = mass;
            this.radius = radius;
        }

        double surfaceGravity() {
            return G * mass / (radius * radius);
        }
    }

    enum Operation {
        PLUS {
            @Override
            int apply(int a, int b) {
                return a + b;
            }
        },
        TIMES {
            @Override
            int apply(int a, int b) {
                return a * b;
            }
        };

        abstract int apply(int a, int b);
    }

    public static void main(String[] args) {
        for (Planet planet : Planet.values()) {
            System.out.printf("%s %.2f%n", planet, planet.surfaceGravity());
        }
        System.out.println(Planet.valueOf("EARTH").ordinal());
        System.out.println(Operation.TIMES.apply(6, 7));

        var counts = new EnumMap<Planet, Integer>(Planet.class);
        counts.put(Planet.EARTH, 8);
        System.out.println(counts);

        try {
            Planet.valueOf("PLUTO");
        } catch (IllegalArgumentException e) {
            System.out.println(e.getMessage());
        }
    }
}
