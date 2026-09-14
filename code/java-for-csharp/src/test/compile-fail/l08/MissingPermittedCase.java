sealed interface Payment permits Card, Transfer, Voucher {}

record Card(String number) implements Payment {}

record Transfer(String iban) implements Payment {}

record Voucher(String code) implements Payment {}

class Fees {
    static double fee(Payment payment) {
        return switch (payment) {
            case Card c -> 0.30;
            case Transfer t -> 0.0;
        };
    }
}
// expect: compiler.err.not.exhaustive
