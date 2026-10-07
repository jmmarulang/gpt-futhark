{-# OPTIONS --guardedness #-}
--{-# OPTIONS --warn=noUserWarning #-}
module ToFile where

open import Extraction
open Extract
open import Data.String
open import Lang
open import IO
open import Data.Bool
open import Relation.Binary.PropositionalEquality

main : Main
-- main = run (putStrLn Extract.bgpt-forward-s)
main = run (putStrLn Extract.bgpt-loss-s)
-- main = run (putStrLn Extract.mgpt-forward-s)
-- main = run (putStrLn Extract.mgpt-loss-s)
-- main = run (putStrLn grad-gpt-loss-s)
-- main = run (putStrLn grad-mgpt-loss-pp)