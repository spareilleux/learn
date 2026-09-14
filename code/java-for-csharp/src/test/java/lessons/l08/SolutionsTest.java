package lessons.l08;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.junit.jupiter.api.Test;

/** Lesson 8 exercise solutions. */
class SolutionsTest {

    sealed interface Expr permits Num, Add, Mul, Neg {}

    record Num(int value) implements Expr {}

    record Add(Expr left, Expr right) implements Expr {}

    record Mul(Expr left, Expr right) implements Expr {}

    record Neg(Expr operand) implements Expr {}

    static int eval(Expr expr) {
        return switch (expr) {
            case Num(int value) -> value;
            case Add(Expr l, Expr r) -> eval(l) + eval(r);
            case Mul(Expr l, Expr r) -> eval(l) * eval(r);
            case Neg(Expr e) -> -eval(e);
        };
    }

    static Expr simplify(Expr expr) {
        return switch (expr) {
            case Mul(Num(int one), Expr e) when one == 1 -> simplify(e);
            case Mul(Expr e, Num(int one)) when one == 1 -> simplify(e);
            case Add(Num(int zero), Expr e) when zero == 0 -> simplify(e);
            case Neg(Neg(Expr e)) -> simplify(e);
            case Add(Expr l, Expr r) -> new Add(simplify(l), simplify(r));
            case Mul(Expr l, Expr r) -> new Mul(simplify(l), simplify(r));
            case Neg(Expr e) -> new Neg(simplify(e));
            case Num n -> n;
        };
    }

    @Test
    void exercise1Expressions() {
        Expr expr = new Add(new Num(0), new Mul(new Num(1), new Neg(new Neg(new Num(7)))));
        assertEquals(7, eval(expr));
        assertEquals(new Num(7), simplify(expr));
    }

    record Order(String customer, double total, List<String> items) {}

    static String size(Order order) {
        return switch (order) {
            case Order(var _, var _, var items) when items.isEmpty() -> "empty";
            case Order(var _, var total, var _) when total > 1000 -> "large";
            case Order(var customer, var total, var _)
                    when (customer.equals("ada") || customer.equals("alan")) && total >= 100 && total <= 1000 ->
                "regular customer";
            case Order _ -> "normal";
        };
    }

    @Test
    void exercise2FromCSharpPatterns() {
        assertEquals("empty", size(new Order("ada", 50, List.of())));
        assertEquals("large", size(new Order("grace", 1500, List.of("gpu"))));
        assertEquals("regular customer", size(new Order("alan", 250, List.of("desk"))));
        assertEquals("normal", size(new Order("grace", 20, List.of("pen"))));
    }

    sealed interface Json permits JNull, JBool, JNumber, JString, JArray, JObject {}

    record JNull() implements Json {}

    record JBool(boolean value) implements Json {}

    record JNumber(double value) implements Json {}

    record JString(String value) implements Json {}

    record JArray(List<Json> items) implements Json {}

    record JObject(Map<String, Json> fields) implements Json {}

    static String render(Json json) {
        return switch (json) {
            case JNull _ -> "null";
            case JBool(boolean b) -> String.valueOf(b);
            case JNumber(double d) when d == Math.rint(d) -> String.valueOf((long) d);
            case JNumber(double d) -> String.valueOf(d);
            case JString(String s) -> '"' + s.replace("\"", "\\\"") + '"';
            case JArray(List<Json> items) -> items.stream().map(SolutionsTest::render).collect(Collectors.joining(",", "[", "]"));
            case JObject(Map<String, Json> fields) -> fields.entrySet().stream()
                    .map(e -> render(new JString(e.getKey())) + ":" + render(e.getValue()))
                    .collect(Collectors.joining(",", "{", "}"));
        };
    }

    @Test
    void exercise3Json() {
        Json doc = new JObject(new java.util.LinkedHashMap<>(Map.of("name", new JString("Ada \"Countess\""))));
        ((JObject) doc).fields().put("tags", new JArray(List.of(new JNumber(1), new JNumber(2.5), new JBool(true), new JNull())));
        assertEquals("{\"name\":\"Ada \\\"Countess\\\"\",\"tags\":[1,2.5,true,null]}", render(doc));
    }
}
