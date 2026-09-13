import java.math.BigDecimal;

class Invoice {
    BigDecimal total(BigDecimal net, BigDecimal tax) {
        return net + tax;
    }
}
// expect: compiler.err.operator.cant.be.applied.1
