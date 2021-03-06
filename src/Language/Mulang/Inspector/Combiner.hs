module Language.Mulang.Inspector.Combiner (
  detect,
  negative,
  alternative,
  scoped,
  scopedList,
  transitive,
  transitiveList) where

import Language.Mulang
import Language.Mulang.Binding
import Language.Mulang.Inspector
import Language.Mulang.Explorer

detect :: Inspection -> Expression -> [Binding]
detect i expression = filter (`inspection` expression) $ declaredBindingsOf expression
                  where inspection = scoped i

alternative :: Inspection -> Inspection -> Inspection
alternative i1 i2 expression = i1 expression || i2 expression

negative :: Inspection -> Inspection
negative f = not . f

scoped :: Inspection -> Binding -> Inspection
scoped inspection scope expression =  any inspection (expression // scope)

scopedList :: Inspection -> [Binding] -> Inspection
scopedList i =  foldl scoped i . reverse

transitive :: Inspection -> Binding -> Inspection
transitive inspection binding code = any (`scopedInspection` code) . transitiveReferencedBindingsOf binding $ code
  where scopedInspection = scoped inspection

transitiveList :: Inspection -> [Binding] -> Inspection
transitiveList i bindings = transitive (scopedList i (init bindings)) (last bindings)
