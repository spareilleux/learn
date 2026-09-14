package shop;

public interface PaymentGateway {

    PaymentResult charge(String customer, long amountCents);
}
