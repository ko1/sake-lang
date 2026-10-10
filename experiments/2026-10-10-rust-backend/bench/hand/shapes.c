/* The "shapes" micro benchmark by hand in C: a tagged pointer and a switch (what ceec generates). */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
typedef struct { int64_t r; } Circle;
typedef struct { int64_t w, h; } Rect;
typedef struct { int64_t b, h; } Tri;
typedef struct { int tag; void *p; } Shape;
static int64_t area(Shape s) {
    switch (s.tag) {
    case 0: { Circle *c = s.p; return 3 * c->r * c->r; }
    case 1: { Rect *x = s.p; return x->w * x->h; }
    default: { Tri *t = s.p; return t->b * t->h / 2; }
    }
}
static const char *name(Shape s) { return s.tag == 0 ? "circle" : s.tag == 1 ? "rect" : "tri"; }
int main(int argc, char **argv) {
    (void)argc;
    int64_t rounds = atoll(argv[1]);
    Shape *shapes = malloc(sizeof(Shape) * 1000);
    for (int64_t i = 0; i < 1000; i++) {
        switch (i % 3) {
        case 0: { Circle *c = malloc(sizeof *c); c->r = i; shapes[i] = (Shape){0, c}; break; }
        case 1: { Rect *x = malloc(sizeof *x); x->w = i; x->h = 2; shapes[i] = (Shape){1, x}; break; }
        default: { Tri *t = malloc(sizeof *t); t->b = i; t->h = 4; shapes[i] = (Shape){2, t}; }
        }
    }
    int64_t total = 0;
    for (int64_t k = 0; k < rounds; k++)
        for (int64_t i = 0; i < 1000; i++) total += area(shapes[i]);
    printf("%lld\n%s: %lld\n", (long long)total, name(shapes[1]), (long long)area(shapes[1]));
    return 0;
}
