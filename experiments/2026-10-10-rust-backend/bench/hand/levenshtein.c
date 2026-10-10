/* The "levenshtein" micro benchmark by hand in C. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
static int64_t lev(const char *s, const char *t) {
    int64_t m = (int64_t)strlen(s), n = (int64_t)strlen(t);
    if (m == 0) return n;
    if (n == 0) return m;
    int64_t *prev = malloc(sizeof(int64_t) * (size_t)(n + 1)), *curr = malloc(sizeof(int64_t) * (size_t)(n + 1));
    for (int64_t j = 0; j <= n; j++) prev[j] = j;
    for (int64_t i = 1; i <= m; i++) {
        curr[0] = i;
        for (int64_t j = 1; j <= n; j++) {
            int64_t cost = s[i - 1] == t[j - 1] ? 0 : 1;
            int64_t del = prev[j] + 1, ins = curr[j - 1] + 1, sub = prev[j - 1] + cost, best = del;
            if (ins < best) best = ins;
            if (sub < best) best = sub;
            curr[j] = best;
        }
        int64_t *tmp = prev; prev = curr; curr = tmp;
    }
    int64_t r = prev[n];
    free(prev); free(curr);
    return r;
}
int main(int argc, char **argv) {
    int64_t min = -1, times = 0;
    for (int i = 1; i < argc; i++)
        for (int j = 1; j < argc; j++)
            if (i != j) { int64_t d = lev(argv[i], argv[j]); if (min == -1 || d < min) min = d; times++; }
    printf("times: %lld\nmin_distance: %lld\n", (long long)times, (long long)min);
    return 0;
}
