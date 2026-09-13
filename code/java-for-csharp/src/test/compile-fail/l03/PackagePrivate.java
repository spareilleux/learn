package other;

import lessons.l03.Accounts;

class PackagePrivate {
    void run() {
        var account = new Accounts.Account("Ada", 100);
    }
}
// expect: compiler.err.not.def.public.cant.access
