package shop;

import java.time.Instant;

public record Receipt(String customer, long totalCents, String transactionId, Instant placedAt) {}
