package sqlengine.exec;

/**
 * The row of one query level as seen by the subqueries inside it: a subquery node sets it before
 * running, and outer-column references in the subquery read it (4.3 correlated subqueries).
 */
final class Frame {
    Object[] row;
}
