/* shapes_mono by hand in C: one struct, a direct call. */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
typedef struct { int64_t r; } Circle;
static int64_t area(Circle *c) { return 3 * c->r * c->r; }
int main(int argc, char **argv) {
    (void)argc;
    int64_t rounds = atoll(argv[1]);
    Circle **shapes = malloc(sizeof(Circle *) * 1000);
    for (int64_t i = 0; i < 1000; i++) { shapes[i] = malloc(sizeof(Circle)); shapes[i]->r = i; }
    int64_t total = 0;
    for (int64_t k = 0; k < rounds; k++)
        for (int64_t i = 0; i < 1000; i++) total += area(shapes[i]);
    printf("%lld\ncircle: %lld\n", (long long)total, (long long)area(shapes[1]));
    return 0;
}
