package sqlengine.exec;

/** What a window call computes for the rows of one partition (6.3). */
interface WindowFunction {
    /** Sets out[pos] to the result for the row at each position of p. */
    void compute(Partition p, WindowFrame frame, Object[] out);
}
