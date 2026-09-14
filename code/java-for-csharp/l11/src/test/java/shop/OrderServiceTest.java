package shop;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    static final Instant NOON = Instant.parse("2026-09-13T12:00:00Z");

    @Mock
    Inventory inventory;

    @Mock
    PaymentGateway gateway;

    OrderService service;

    @BeforeEach
    void setUp() {
        // A fixed clock needs no mock, like FakeTimeProvider.
        service = new OrderService(inventory, gateway, Clock.fixed(NOON, ZoneOffset.UTC));
    }

    @Test
    void chargesTheTotalAndReturnsAReceipt() {
        when(inventory.inStock("pen", 2)).thenReturn(true);
        when(gateway.charge("ada", 300)).thenReturn(new PaymentResult(true, "tx-42"));

        Receipt receipt = service.place("ada", List.of(new Item("pen", 2, 150)), null);

        assertThat(receipt).isEqualTo(new Receipt("ada", 300, "tx-42", NOON));
        verify(gateway).charge("ada", 300);
    }

    @Test
    void outOfStockNeverCharges() {
        when(inventory.inStock(anyString(), org.mockito.ArgumentMatchers.anyInt())).thenReturn(false);

        assertThatThrownBy(() -> service.place("ada", List.of(new Item("pen", 1, 150)), null))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage("out of stock: pen");
        verify(gateway, never()).charge(anyString(), anyLong());
    }

    @Test
    void theCouponIsAppliedBeforeCharging() {
        when(inventory.inStock(anyString(), org.mockito.ArgumentMatchers.anyInt())).thenReturn(true);
        when(gateway.charge(anyString(), anyLong())).thenReturn(new PaymentResult(true, "tx-7"));

        service.place("grace", List.of(new Item("book", 1, 2000)), "TEN");

        ArgumentCaptor<Long> amount = ArgumentCaptor.forClass(Long.class);
        verify(gateway).charge(org.mockito.ArgumentMatchers.eq("grace"), amount.capture());
        assertThat(amount.getValue()).isEqualTo(1800L);
    }

    @Test
    void recordsAreFinalButCanStillBeMocked() {
        // Moq can only mock interfaces and virtual members; Mockito 5 also mocks final classes.
        PaymentResult result = org.mockito.Mockito.mock(PaymentResult.class);
        when(result.approved()).thenReturn(true);
        assertThat(result.approved()).isTrue();
    }
}
