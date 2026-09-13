package lessons.l03;

import java.util.ArrayList;
import java.util.List;

/** Lesson 3: a class with a constructor, a getter instead of a property, and virtual-by-default methods. */
public class Accounts {

    static class Account {
        private final String owner;
        private long balanceCents;

        Account(String owner, long openingCents) {
            if (openingCents < 0) {
                throw new IllegalArgumentException("opening balance must not be negative");
            }
            this.owner = owner;
            this.balanceCents = openingCents;
        }

        String getOwner() {
            return owner;
        }

        long getBalanceCents() {
            return balanceCents;
        }

        void deposit(long cents) {
            balanceCents += cents;
        }

        String describe() {
            return owner + ": " + balanceCents + " cents";
        }
    }

    static class SavingsAccount extends Account {
        private final int ratePerMille;

        SavingsAccount(String owner, long openingCents, int ratePerMille) {
            super(owner, openingCents);
            this.ratePerMille = ratePerMille;
        }

        @Override
        String describe() {
            return super.describe() + " (savings, " + ratePerMille + " per mille)";
        }
    }

    public static void main(String[] args) {
        List<Account> accounts = new ArrayList<>();
        accounts.add(new Account("Ada", 10_000));
        accounts.add(new SavingsAccount("Grace", 25_000, 15));

        for (Account account : accounts) {
            account.deposit(500);
            System.out.println(account.describe());
        }
        System.out.println(accounts.getFirst().getOwner());
    }
}
