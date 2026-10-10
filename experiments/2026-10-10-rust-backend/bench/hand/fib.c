/* The "fibonacci" micro benchmark by hand in C. */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
static int64_t fib(int64_t n) { return n < 2 ? n : fib(n - 1) + fib(n - 2); }
int main(int argc, char **argv) {
    (void)argc;
    int64_t u = atoll(argv[1]), r = 0;
    for (int64_t i = 1; i < u; i++) r += fib(i);
    printf("%lld\n", (long long)r);
    return 0;
}
