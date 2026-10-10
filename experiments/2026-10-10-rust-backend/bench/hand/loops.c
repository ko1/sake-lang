/* The "loops" micro benchmark by hand in C (the ceiling for ceec with the same compiler). */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
int main(int argc, char **argv) {
    (void)argc;
    int64_t u = atoll(argv[1]);
    int64_t r = (int64_t)(time(NULL) % 10000);
    int64_t *a = calloc(10000, sizeof *a);
    for (int64_t i = 0; i < 10000; i++) {
        for (int64_t j = 0; j < 100000; j++) a[i] = a[i] + j % u;
        a[i] = a[i] + r;
    }
    printf("%lld\n", (long long)a[r]);
    return 0;
}
