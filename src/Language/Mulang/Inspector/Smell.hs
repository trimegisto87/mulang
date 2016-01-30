module Language.Mulang.Inspector.Smell (
  hasRedundantBooleanComparison,
  hasRedundantIf,
  hasRedundantGuards,
  hasRedundantLambda,
  hasRedundantParameter,
  doesNullTest,
  doesTypeTest,
  returnsNull) where

import Language.Mulang
import Language.Mulang.Explorer
import Language.Mulang.Inspector


-- | Inspection that tells whether a binding has expressions like 'x == True'
hasRedundantBooleanComparison :: Inspection
hasRedundantBooleanComparison = hasExpression f
  where f (InfixApplication x c y) = any isBooleanLiteral [x, y] && isComp c
        f _ = False

doesNullTest :: Inspection
doesNullTest = hasExpression f
  where f (InfixApplication _ c MuNull)  = isComp c
        f (InfixApplication MuNull c _) = isComp c
        f _ = False

doesTypeTest :: Inspection
doesTypeTest = hasExpression f
  where f (InfixApplication _ c (MuString _))  = isComp c
        f (InfixApplication (MuString _) c _) = isComp c
        f _ = False

isComp c = c == "==" || c == "/="

-- | Inspection that tells whether a binding has an if expression where both branches return
-- boolean literals
hasRedundantIf :: Inspection
hasRedundantIf = hasExpression f
  where f (If _ (Return x) (Return y)) = all isBooleanLiteral [x, y]
        f (If _ x y)                   = all isBooleanLiteral [x, y]
        f _                            = False

returnsNull :: Inspection
returnsNull = hasExpression f
  where f (Return MuNull) = True
        f _               = False


-- | Inspection that tells whether a binding has guards where both branches return
-- boolean literals
hasRedundantGuards :: Inspection
hasRedundantGuards = hasBody f -- TODO not true when condition is a pattern
  where f (GuardedBodies [
            GuardedBody _ (Return x),
            GuardedBody (Variable "otherwise") (Return y)]) = all isBooleanLiteral [x, y]
        f _ = False


-- | Inspection that tells whether a binding has lambda expressions like '\x -> g x'
hasRedundantLambda :: Inspection
hasRedundantLambda = hasExpression f
  where f (Lambda [VariablePattern (x)] (Return (Application _ [Variable (y)]))) = x == y
        f _ = False -- TODO consider parenthesis and symbols

-- | Inspection that tells whether a binding has parameters that
-- can be avoided using point-free
hasRedundantParameter :: Inspection
hasRedundantParameter binding = any f . declarationsBindedTo binding
  where f (FunctionDeclaration _ [Equation params (UnguardedBody (Return (Application _ args)))])
                                                            | (VariablePattern param) <- last params,
                                                              (Variable arg) <- last args = param == arg
        f _ = False

isBooleanLiteral (MuBool _) = True
isBooleanLiteral _          = False

