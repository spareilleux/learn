package shop;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.tuple;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoMoreInteractions;
import static org.mockito.Mockito.when;

import java.time.Clock;
import java.time.ZoneOffset;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

/** Lesson 11 exercise solutions. */
@ExtendWith(MockitoExtension.class)
class ExercisesTest {

    @Mock
    Inventory inventory;

    @Mock
    PaymentGateway gateway;

    @Test
    void exercise1DeclinedPayment() {
        var service = new OrderService(inventory, gateway, Clock.fixed(OrderServiceTest.NOON, ZoneOffset.UTC));
        when(inventory.inStock(anyString(), anyInt())).thenReturn(true);
        when(gateway.charge(anyString(), anyLong())).thenReturn(new PaymentResult(false, null));

        assertThatThrownBy(() -> service.place("alan", List.of(new Item("pen", 3, 100)), null))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("payment declined for alan");
        verify(gateway, times(1)).charge("alan", 300);
        verifyNoMoreInteractions(gateway);
    }

    @Test
    void exercise2Receipts() {
        var receipts = List.of(
                new Receipt("ada", 300, "tx-1", OrderServiceTest.NOON),
                new Receipt("grace", 1800, "tx-2", OrderServiceTest.NOON));

        assertThat(receipts)
                .extracting(Receipt::customer, Receipt::totalCents)
                .containsExactly(tuple("ada", 300L), tuple("grace", 1800L));
        assertThat(receipts.get(0))
                .usingRecursiveComparison()
                .ignoringFields("transactionId")
                .isEqualTo(new Receipt("ada", 300, "tx-999", OrderServiceTest.NOON));
    }

    @Test
    void exercise3NullSafeDiscounts() {
        assertThat(SafeDiscounts.percentOrZero("TEN")).isEqualTo(10);
        assertThat(SafeDiscounts.percentOrZero("FREE")).isZero();
        assertThat(SafeDiscounts.describe("HALF")).isEqualTo("50% off");
        assertThat(SafeDiscounts.describe("FREE")).isEqualTo("no discount");
    }
}
