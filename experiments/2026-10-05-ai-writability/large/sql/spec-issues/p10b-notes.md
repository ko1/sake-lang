# Spec issues reported by the P10b builders (Java, Scheme, Steep, Haskell); the spec is not changed during the runs

- 2.3 BETWEEN bounds (p10-java-2 stage 2): "parsed at the level just tighter than 6" is level 5, which holds
  `<` `<=` `>` `>=`, but the parenthetical says the bounds "cannot contain a comparison". The two disagree
  for `<`-family comparisons; tests do not depend on it.
