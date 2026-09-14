package shop;

import org.jspecify.annotations.Nullable;

public record PaymentResult(boolean approved, @Nullable String transactionId) {}
