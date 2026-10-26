{-# OPTIONS --backtracking-instance-search #-}
{-# OPTIONS --allow-unsolved-metas #-}
-- {-# OPTIONS --warn=noUserWarning #-}
open import Data.Product
open import Data.Unit
open import Data.Empty
open import Data.Nat using (ℕ; zero; suc)
open import Data.List as L using (List; []; _∷_)
open import Data.List.Relation.Unary.All as All using (All; []; _∷_)
open import Relation.Binary.PropositionalEquality hiding ([_])
open import Relation.Nullary
open import Function
open import Data.Nat.Properties using (_≟_)
open import Data.Product.Properties

open import Ar
open import Lang as La
open import LangEq
open import Real

-- Jairo Made
open import Data.Product as Prod hiding (_<*>_)
open import Data.List.Properties

module Opt (r : Real) (rp : RealProp r) where

  open Real.Real r
  open RealProp rp

  open import Eval r rp
  open ZeroBut
  open WkSub hiding (_∙ˢ_)
  open import Data.Maybe
  open Syntax
  open Primitives

  ∷-inj₂ : (n ∷ s ≡ n ∷ p) → s ≡ p
  ∷-inj₂ refl = refl

  ++-inj₂ : (s L.++ p ≡ s L.++ q) → p ≡ q
  ++-inj₂ {[]} eq = eq
  ++-inj₂ {x ∷ s} eq = ++-inj₂ (∷-inj₂ eq)

  module _ where
    opt : (e : E Γ is) → ∃ λ e′ → (e ≈ᵉ e′)
-- var
    opt (var x) = var x
      , reflᵉ (var x)
-- kop
    opt (kop x) = (kop x)
      , reflᵉ (kop x)
-- uop
    opt (uop x e) with x  | opt e
    ... | ⊟ₒ    | ⊟ a , ap = a
      , λ ρ i → (cong -_ (ap _ _)) ∙ minus-invʳ
    ... | ⊟ₒ    | zero-but i j a , ap = (zero-but i j (⊟ a))
      , go where
        go : _
        go ρ k with eval i ρ ≟ₚ eval j ρ | (cong -_ (ap ρ k))
        ... | yes b | eq = eq
        ... | no b | eq = eq ∙ minus-idʳ
    -- default
    ... | ⊟ₒ    | a , ap = ⊟ a
      , λ ρ j → cong -_ (ap ρ j)
    -- default
    ... | reluₒ | a , ap = relu a
      , λ ρ j → cong (_∨_ 0ᵣ) (ap ρ j)
    -- default
    ... | √ₒ    | a , ap = (La.√ a)
      , λ ρ j → cong √_ (ap ρ j)
    -- default
    ... | 𝟙/ₒ   | a , ap = 𝟙/ a
      , λ ρ j → cong 1/_ (ap ρ j)
    -- default
    ... | 𝕚+ₒ   | a , ap = 𝕚+ a
      , λ ρ j → cong I+ (ap ρ j)
    -- default
    ... | lnₒ   | a , ap = ln a
      , λ ρ j → cong log (ap ρ j)
    ... | scₒ n | imap′ {s = s} {p = p} refl a , ap = imap′ {s = s} {p = p} refl (scaledown n a)
      , λ ρ i → cong (_÷ fromℕ n) (ap ρ i)
    ... | scₒ n | zero-but {s = s} {p = p} i j a , ap = go where
      go : _
      go with (Data.Nat._≟_ n 0)
      ... | yes _ = (scaledown n (zero-but i j a)) , λ ρ j → cong (_÷ fromℕ n) (ap ρ j)
      ... | no b = (zero-but i j (scaledown n a)) , go₁ where
        go₁ : _
        go₁ ρ k with eval i ρ ≟ₚ eval j ρ | (cong (_÷ fromℕ n) (ap ρ k))
        ... | yes b | q' = q'
        ... | no _ | q' rewrite q' = ÷-nul λ tt → b (fromℕ-inj tt)
    -- default
    ... | scₒ n | a , ap = scaledown n a
      , λ ρ j → cong (_÷ fromℕ n) (ap ρ j)
    -- default
    ... | ℙₒ    | a , ap = ℙ a
      , λ ρ i → cong₂ _÷_ (cong e^_ (ap _ _)) (sum-cong _+_ _ {e^_ ∘ (eval e ρ)}
        λ j → cong e^_ (ap _ _))
-- bop
    opt (bop x e e₁) with x | opt e | opt e₁
    ... | ⊞ₒ | 𝟘 , ap | b , bp = b
      , λ ρ j → cong₂ _+_ (ap ρ j) (bp ρ j) ∙ +-neutˡ
    ... | ⊞ₒ | a , ap | 𝟘 , bp = a
      , λ ρ j → cong₂ _+_ (ap ρ j) (bp ρ j) ∙ +-neutʳ
    ... | ⊞ₒ | imaps a′ , ap | b , bp = imaps (a′ ⊞ sels (b ↑) (var here))
      , λ ρ j → cong₂ _+_ (ap ρ j)
                (sym (eval-wk (skip ⊆-eq) b (ρ , j) j
                      ∙ eval-cong b (wk-env-id) j
                      ∙ (sym (bp ρ j))))
    ... | ⊞ₒ | a , ap | imaps b′ , bp = imaps (sels (a ↑) (var here) ⊞ b′)
      , λ ρ j → cong₂ _+_ (ap ρ j
                ∙ sym (eval-wk (skip ⊆-eq) a (ρ , j) j
                      ∙ eval-cong a (wk-env-id) j)) (bp ρ j)
    ... | ⊞ₒ | imap′ {s} {r} refl a′ , ap | b , bp = imap (a′ ⊞ sel (b ↑) (var v₀))
      , λ ρ j → cong₂ _+_ (ap _ _) (sym ((eval-wk (skip ⊆-eq) b _ _)
        ∙ eval-cong b wk-env-id _
        ∙ cong (eval b _) (sym (splitP-eq {s = s} j))
        ∙ sym (bp ρ j)))
    ... | ⊞ₒ | a , ap | imap′ {s} {r} refl b′ , bp = imap (sel (a ↑) (var v₀) ⊞ b′)
      , λ ρ j → cong₂ _+_ ((ap _ _)
      ∙ sym (eval-wk (skip ⊆-eq) a _ _
      ∙ eval-cong a (wk-env-id) _
      ∙ cong (eval a _) (sym (splitP-eq {s = s} j)))) (bp _ _)
    ... | ⊞ₒ | zero-but (var i) (var j) x , ap | zero-but (var i′) (var j′) x′ , bp = go where
      go : _
      go with eq? i i′ | eq? j j′
      ... | veq | veq = zero-but (var i) (var j) (x ⊞ x′) , go₁ where
        go₁ : _
        go₁ ρ k rewrite ap ρ k | bp ρ k with lookup i ρ ≟ₚ lookup j ρ
        ... | yes _ = refl
        ... | no _ = +-neutʳ
      ... | _ | _ = zero-but (var i) (var j) x ⊞ zero-but (var i′) (var j′) x′
        , λ ρ k → cong₂ _+_ (ap ρ k) (bp ρ k)
    -- default
    ... | ⊞ₒ | a , ap | b , bp = a ⊞ b
      , λ ρ j → cong₂ _+_ (ap ρ j) (bp ρ j)
    ... | ⊠ₒ | ⊟ a , ap | b , bp = ⊟ (a ⊠ b)
      , λ ρ i → cong₂ _*_ (ap ρ i) (bp ρ i) ∙ minus-*-pushˡ
    ... | ⊠ₒ | 𝟙 , ap | b , bp = b
      , λ ρ j → cong₂ _*_ (ap ρ j) (bp ρ j) ∙ *-neutˡ
    ... | ⊠ₒ | zero-but i j a , ap | b , bp = zero-but i j (a ⊠ b)
      , go where
        go : _
        go ρ k with eval i ρ ≟ₚ eval j ρ | (ap ρ k) | (bp ρ k)
        ... | yes _ | p′ | q′ rewrite p′ | q′ = refl
        ... | no _ | p′ | q′ rewrite p′ = *-nulˡ
    ... | ⊠ₒ | a , ap | imaps b′ , bp = imaps (sels (a ↑) (var here) ⊠ b′)
      , λ ρ j → cong₂ _*_ (ap ρ j
                ∙ sym (eval-wk (skip ⊆-eq) a (ρ , j) j
                  ∙ eval-cong a (wk-env-id) j)) (bp ρ j)
    ... | ⊠ₒ | imaps a′ , ap | b , bp = (imaps (a′ ⊠ sels (b ↑) (var here)))
      , λ ρ j → cong₂ _*_ (ap ρ j)
                (sym (eval-wk (skip ⊆-eq) b (ρ , j) j
                      ∙ eval-cong b (wk-env-id) j
                      ∙ (sym (bp ρ j))))
    ... | ⊠ₒ | a , ap | ⊟ c , bp = ⊟ (a ⊠ c)
      , λ ρ i → (cong₂ _*_ (ap ρ i) (bp ρ i)) ∙ minus-*-pushʳ
    ... | ⊠ₒ | a , ap | zero-but i j c , bp = zero-but i j (a ⊠ c)
      , go where
        go : _
        go ρ k with eval i ρ ≟ₚ eval j ρ | (ap ρ k) | (bp ρ k)
        ... | yes _ | p′ | q′ rewrite p′ | q′ = refl
        ... | no _ | p′ | q′ rewrite q′ = *-nulʳ
    -- default
    ... | ⊠ₒ | a , ap | b , bp = a ⊠ b
      , λ ρ j → cong₂ _*_ (ap ρ j) (bp ρ j)
-- mop
    opt (mop x e) with x  | opt e
  -- imaps
    -- default
    ... | imapsₒ     | a , ap = imaps a
      , λ ρ i → ap (ρ , i) []
  -- imap
    ... | imapₒ {s = s} {p = p} refl | e@(let′ {r} a b) , ap = go where
      go : _
      go with (stren-∃ a v₀)
      ... | just (c , eq) = let′ c (imap (sub b sub-swap))
        , go₁ where
          go₁ : _
          go₁ ρ i = let j , k = splitP {s} i .proj₁ , splitP {s} i .proj₂ in
            (ap _ k)
            ∙ sym (eval-sub b _ _ _
            ∙ eval-cong b
              (sub-env-wks (sdrop sub-id) (skip ⊆-eq) _ ▹ refl ▹ λ _ → refl) k
            ∙ eval-cong b (sub-env-sdrop sub-id ▹ refl ▹ λ _ → refl) k
            ∙ eval-cong b (sub-env-id ▹ refl ▹ λ _ → refl) k
            ∙ eval-cong b (wk-env-id ▹ refl ▹ λ _ → refl) k
            ∙ sym (eval-cong b
              (reflᶜ ▹ refl ▹ λ l → cong (λ x → eval x _ _) eq) k
            ∙ eval-cong b
                (reflᶜ ▹ refl ▹ λ l → eval-wk (skip ⊆-eq) c (ρ , j) l) k
            ∙ eval-cong b (reflᶜ ▹ refl ▹ eval-cong c wk-env-id) k
            ))
      ... | nothing = imap e
        , λ ρ i → ap (ρ , splitP i .proj₁) (splitP i .proj₂)
    -- default
    ... | imapₒ refl | a , ap = imap a
      , λ ρ i → ap (ρ , splitP i .proj₁) (splitP i .proj₂)
  -- imapb
    -- default
    ... | imapbₒ eq  | a , ap = La.imapb eq a
      , λ ρ j → ap (ρ , ix-div j eq) (ix-mod j eq)
  -- sum
    ... | sumₒ {s = s} | e'@(a ⊠ b) , ap = go where
      go : _
      go with (stren-∃ a v₀) | (stren-∃ b v₀)
      ... | just (c , ceq) | _ = c ⊠ La.sum b
        , λ ρ i → let w = skip ⊆-eq in
        sum-inv _+_ (fromℕ 0) {λ j → eval e (ρ , j)} i
        ∙ sum-cong _+_ (fromℕ 0) (λ j →
          ap (ρ , j) i
          ∙ flip (cong₂ _*_) refl (
              cong (λ y → eval y (ρ , j) i) ceq
              ∙ eval-wk w c _ _))
        ∙ sum-const-out
          {a = eval c (wk-env ⊆-eq ρ) i}
          {b = λ j → eval b (ρ , j) i} (fromℕ 0)
          +-neutˡ
          (λ {x} → sym (*-nulʳ {x}))
          (λ {_ _ z} → dist {_} {_} {z})
        ∙ cong₂ _*_ (eval-cong c wk-env-id i)
          (sym (sum-inv _+_ (fromℕ 0) {a = λ j → eval b (ρ , j)} i))

      ... | _ | just (d , deq) = (La.sum a) ⊠ d , {!   !}
      ... | _ | _ = La.sum (a ⊠ b) , {!   !}
    ... | sumₒ {s = s} | ⊟ a , ap = ⊟ (La.sum a) , {!   !}
    ... | sumₒ {s = s} | let′ {s = q} a b , ap = let′ (imap a) (La.sum {s = s} $ sub b $
      skeep (sdrop sub-id) ▹ sel (var v₁) (var v₀))
        , go where
          go : _
          go ρ i =
            let aux = skeep (sdrop sub-id) ▹ sel (var v₁) (var v₀) in
            let aux0 = λ k → eval a (ρ , splitP k .proj₁) (splitP k .proj₂) in
            let aux1 = λ j → (((ρ , aux0) , j )) in
            sum-inv {s = s} _+_ (fromℕ 0) i
            ∙ sum-cong {s = s} _+_ (fromℕ 0) (λ k → ap _ _)
            ∙ sym ( sum-inv {s = s} _+_ (fromℕ 0) i
            ∙ sum-cong {s = s} _+_ (fromℕ 0) {λ j → eval (sub b _) (aux1 j) i}
              (λ k →
              (eval-sub b _ aux i)
              ∙ eval-cong b
                (sub-env-wks (sdrop sub-id) (skip ⊆-eq) _ ▹ refl ▹ λ _ → refl) i
              ∙ eval-cong b (sub-env-sdrop sub-id ▹ refl ▹ λ _ → refl) i
              ∙ eval-cong b (sub-env-id ▹ refl ▹ λ _ → refl) i
              ∙ eval-cong b (wk-env-id ▹ refl ▹ λ _ → refl) i
              ∙ eval-cong b (reflᶜ ▹ refl ▹ λ z →
                (cong (eval a _) (splitP-proj₂ {i = k}))
                ∙ cong (λ x → eval a (_ , x) _) (splitP-proj₁ {i = k})) i
              ))
    ... | sumₒ {s = s} | 𝟘 , ap = 𝟘
      , λ ρ j → sum-inv _+_ (fromℕ 0) {λ i → eval e (ρ , i)} j
        ∙ sum-cong _+_ (fromℕ 0) {λ i → eval e (ρ , i) j} (λ i → ap (ρ , i) j)
        ∙ sum-zero {s}
    ... | sumₒ {s = s} | imaps a′ , ap = imaps (La.sum $ sub a′ sub-swap)
      , λ ρ j →
        let ss = (wks (wks sub-id (skip ⊆-eq))
                      (skip (keep ⊆-eq)) ▹ var v₀) ▹ var v₁ in
        sym (sum-inv _+_ (fromℕ 0)
                      {(λ i → eval (sub a′ ss) ((ρ , j) , i))} []
              ∙ sum-cong _+_ (fromℕ 0)
                {(λ j₁ → eval (sub a′ ss) ((ρ , j) , j₁) [])}
                (λ k → eval-sub a′ ((ρ , j) , k) ss []
                  ∙ eval-cong a′ ((sub-env-wks _ _ ((ρ , j) , k)
                    ∙ᶜ sub-env-wks _ _ (wk-env ⊆-eq ρ , j)
                    ∙ᶜ sub-env-id ∙ᶜ wk-env-id ∙ᶜ wk-env-id) ▹ refl ▹ refl) [])
              ∙ sum-cong _+_ (fromℕ 0) {λ z → eval a′ ((ρ , z) , j) []}
                (λ i → sym (ap (ρ , i) j))
              ∙ sym (sum-inv _+_ (fromℕ 0) {λ z → eval e (ρ , z)} j))
    ... | sumₒ {s = s} | imap′ refl a′ , ap = imap (La.sum $ sub a′ sub-swap)
      , λ ρ j →
        let ss = ((wks (wks sub-id (skip ⊆-eq)) (skip (keep ⊆-eq)) ▹ var v₀)
                  ▹ var v₁)
        in sym (sum-inv _+_ (fromℕ 0)
          {λ i → eval (sub a′ ss) ((ρ , splitP j .proj₁) , i)} (splitP j .proj₂)
          ∙ sum-cong _+_ (fromℕ 0)
            {λ j₁ → eval (sub a′ ss) ((ρ , splitP j .proj₁) , j₁)
              (splitP j .proj₂)}
            (λ k → eval-sub a′ ((ρ , splitP j .proj₁) , k) ss (splitP j .proj₂)
                    ∙ eval-cong a′ ((sub-env-wks _ _ ((ρ , splitP j .proj₁) , k)
                      ∙ᶜ sub-env-wks _ _ (wk-env ⊆-eq ρ , splitP j .proj₁)
                      ∙ᶜ sub-env-id ∙ᶜ wk-env-id ∙ᶜ wk-env-id) ▹ refl ▹ refl)
                    (splitP j .proj₂))
          ∙ sum-cong _+_ (fromℕ 0)  (λ i → sym (ap (ρ , i) j))
          ∙ sym (sum-inv _+_ (fromℕ 0) {λ z → eval e (ρ , z)} j))
    ... | sumₒ {s = s} | imapb m a′ , ap = La.imapb m (La.sum $ sub a′ sub-swap)
      , λ ρ j →
      let ss = (wks (wks sub-id (skip ⊆-eq)) (skip (keep ⊆-eq)) ▹ var v₀) ▹ _
      in sym (sum-inv _+_ (fromℕ 0) {λ i → eval (sub a′ ss)
        ((ρ , ix-div j m) , i)} (ix-mod j m)
        ∙ sum-cong _+_ (fromℕ 0)
          {λ j₁ → eval (sub a′ ss) ((ρ , ix-div j m) , j₁) (ix-mod j m)}
          (λ k → eval-sub a′ ((ρ , ix-div j m) , k) ss (ix-mod j m)
          ∙ eval-cong a′ ((sub-env-wks _ _ ((ρ , ix-div j m) , k)
            ∙ᶜ sub-env-wks _ _ (wk-env ⊆-eq ρ , ix-div j m)
            ∙ᶜ sub-env-id ∙ᶜ wk-env-id ∙ᶜ wk-env-id) ▹ refl ▹ refl)
            (ix-mod j m))
        ∙ sum-cong _+_ (fromℕ 0)  (λ i → sym (ap (ρ , i) j))
        ∙ sym (sum-inv _+_ (fromℕ 0) {λ z → eval e (ρ , z)} j))
    ... | sumₒ | zero-but (var i) (var j) a , ap = go where
      go : _
      go with eq? v₀ i | eq? v₀ j
      ... | veq  | veq = La.sum a , go₁ where
        go₁ : _
        go₁ ρ j = sum-inv _+_ (fromℕ 0) {(λ i₂ → eval e (ρ , i₂))} j
          ∙ sum-cong _+_ (fromℕ 0) {λ j₂ → eval e (ρ , j₂) j}
                        (λ k → ap (ρ , k) j ∙ eval-zb a (var v₀) (ρ , k) j)
          ∙ sym (sum-inv _+_ (fromℕ 0) {(λ z → eval a (ρ , z))} j)
      ... | neq _ i′ | veq = sub a (sub-id ▹ var i′)
        , λ ρ j → sum-inv _+_ (fromℕ 0) {(λ i₁ → eval e (ρ , i₁))} j
          ∙ sum-cong _+_ (fromℕ 0) {λ j₂ → eval e (ρ , j₂) j}
            (λ k → ap (ρ , k) j
            ∙ zb-zbs (lookup i′ ρ) k j (λ k → eval a (ρ , k)))
          ∙ zbs-sum-s (lookup i′ ρ) _
          ∙ (sym (eval-sub a ρ (sub-id ▹ var i′) j
                  ∙ eval-cong a (sub-env-id ▹ refl) j))
      ... | veq | neq _ j′ = sub a (sub-id ▹ var j′)
        , λ ρ j → sum-inv _+_ (fromℕ 0) {(λ i₁ → eval e (ρ , i₁))} j
          ∙ sum-cong _+_ (fromℕ 0) {(λ j₂ → eval e (ρ , j₂) j)}
                        (λ k → ap (ρ , k) j
                                ∙ zb-sym k _ j (λ k → eval a (ρ , k))
                                ∙ zb-zbs (lookup j′ ρ) k j (λ k → eval a (ρ , k)))
          ∙ zbs-sum-s (lookup j′ ρ) _
          ∙ (sym (eval-sub a ρ (sub-id ▹ var j′) j
                  ∙ eval-cong a (sub-env-id ▹ refl) j))
      ... | neq _ i′ | neq _ j′ = zero-but (var i′) (var j′) (La.sum a)
        , λ ρ j → sum-inv _+_ (fromℕ 0) {(λ i₁ → eval e (ρ , i₁))} j
          ∙ sum-cong _+_ (fromℕ 0) {(λ j₂ → eval e (ρ , j₂) j)}
            (λ k → ap (ρ , k) j ∙ zb-zbs (lookup i′ ρ) _ j λ _ → eval a (ρ , k))
          ∙ zbs-ext (lookup i′ ρ) (lookup j′ ρ) (λ z → eval a (ρ , z) j)
          ∙ sym (zb-zbs-k (lookup i′ ρ) _ j
            (Ar.sum (Ar.zipWith _+_) (K (fromℕ 0)) (λ i₁ → eval a (ρ , i₁)))
            ∙ zbs-cong _ _ (λ _ → sum-inv _+_ (fromℕ 0)
                {(λ i₂ → eval a (ρ , i₂))} j) (lookup i′ ρ) (lookup j′ ρ))

    -- default
    ... | sumₒ | a , ap = La.sum a
      , λ ρ j → sum-inv _+_ (fromℕ 0) {(λ i₁ → eval e (ρ , i₁))} j
        ∙ sum-cong _+_ (fromℕ 0) {λ j₁ → eval e (ρ , j₁) j} (λ i → ap (ρ , i) j)
        ∙ (sym (sum-inv _+_ (fromℕ 0) {λ i → eval a (ρ , i)} j))
-- sop
    opt (sop x e e₁) with x | opt e | opt e₁
  -- sels
    ... | selsₒ | 𝟘 , ap | i , ip = 𝟘
      , λ ρ i → ap ρ _
    ... | selsₒ | 𝟙 , ap | i , ip = 𝟙
      , λ ρ i → ap ρ _
    ... | selsₒ | imaps a , ap | i , ip = sub a (sub-id ▹ i)
      , λ {ρ [] → ap ρ (eval e₁ ρ)
          ∙ cong (λ t → eval a (ρ , t) []) (ip ρ)
          ∙ sym (eval-sub a ρ (sub-id ▹ i) []
                  ∙ eval-cong a (sub-env-id ▹ refl) [])}
    ... | selsₒ | a ⊞ b , ap | i , ip = sels a i ⊞ sels b i
      , λ ρ j → ap ρ (eval e₁ ρ)
        ∙ cong₂ _+_ (cong (eval a ρ) (ip ρ)) (cong (eval b ρ) (ip ρ))
    ... | selsₒ | a ⊠ b , ap | i , ip = sels a i ⊠ sels b i
      , λ ρ j → ap ρ (eval e₁ ρ)
        ∙ cong₂ _*_ (cong (eval a ρ) (ip ρ)) (cong (eval b ρ) (ip ρ))
    ... | selsₒ | sum a , ap | i , ip = (La.sum (sels a (i ↑)))
      , λ {ρ [] → ap ρ (eval e₁ ρ)
        ∙ sum-inv _+_ (fromℕ 0) {eval a ∘ (ρ ,_)} (eval e₁ ρ)
        ∙ sym (sum-inv _+_ (fromℕ 0)
                        {λ i₁ i₂ → eval a (ρ , i₁)
                                          (eval (wk (skip ⊆-eq) i)
                                                (ρ , i₁))} []
                ∙ Ar.sum-cong _+_ (fromℕ 0)
                  {λ j → eval a (ρ , j) (eval (wk (skip ⊆-eq) i) (ρ , j))}
                  λ j → cong (eval a (ρ , j))
                        (eval-wk (skip ⊆-eq) i (ρ , j)
                        ∙ eval-cong i wk-env-id
                        ∙ sym (ip ρ) ))  }
    ... | selsₒ | zero-but i j a , ap | k , kp = (zero-but i j (sels a k))
      , go where
        go : _
        go ρ u with eval i ρ ≟ₚ eval j ρ | ap ρ (eval e₁ ρ)
        ... | yes _ | p′ = p′ ∙ cong (eval a ρ) (kp ρ)
        ... | no _ | p′ = p′
    ... | selsₒ | ⊟ a , ap | i , ip = (⊟ sels a i)
      , λ ρ j → (ap _ _) ∙ cong (λ x → - (eval a ρ x)) (ip _)
    ... | selsₒ | 𝟙/ a , ap | i , ip = (𝟙/ $ sels a i)
      , λ ρ j → (ap _ _) ∙ cong (λ x → fromℕ 1 ÷  (eval a ρ x)) (ip _)
    -- default
    ... | selsₒ | a , ap | i , ip = sels a i ,
      λ ρ j → ap ρ (eval e₁ ρ) ∙ cong (eval a ρ) (ip ρ)
  -- sel
    ... | selₒ {q = q} refl | zero-but i j a , ap | k , kp = zero-but i j (sel a k) , {!   !}
    ... | selₒ refl | 𝟘 , ap | i , ip = 𝟘
      , λ ρ j → ap ρ (eval e₁ ρ ++ j)
    ... | selₒ refl | 𝟙 , ap | i , ip = 𝟙
      , λ ρ j → ap ρ (eval e₁ ρ ++ j)
    ... | selₒ {s = s} {p} refl | e@(imap′ {s′} {p′} spq u) , ap | i , ip = go
      where
      go : _
      go with p ≟ˢ s′
      ... | no _ = sel e i
        , λ ρ j → ap ρ (eval e₁ ρ ++ j) ∙ cong (eval e ρ) (cong (_++ j) (ip ρ))
      ... | yes refl with (++-inj₂ {s = p} spq)
      ... | refl rewrite spq = sub u (sub-id ▹ i)
        , go₁ where
          go₁ : _
          go₁ ρ j rewrite ip ρ = ap ρ (eval i ρ ++ j)
            ∙ sym (eval-sub u ρ (sub-id ▹ i) j
                  ∙ eval-cong u (sub-env-id ▹ (sym $ splitP-proj₁ {j = j})) j
                  ∙ cong (eval u _) (sym $ splitP-proj₂ {i = eval i ρ}))
    ... | selₒ {s = s} {p} refl | e@(let′ {r} a b) , ap | i , ip =
      let′ a (sel b (i ↑)) , go where
      go : _
      go ρ j =
        ap ρ _
        ∙ sym (cong (λ x → eval b _ (x ++ j)) (eval-wk (skip ⊆-eq) i _
        ∙ eval-cong i wk-env-id
        ∙ sym (ip _)))
    -- default
    ... | selₒ refl | a , ap | i , ip = sel a i
      , λ ρ j → ap ρ (eval e₁ ρ ++ j) ∙ cong (eval a ρ) (cong (_++ j) (ip ρ))
  -- selb
    -- default
    ... | selbₒ eq | a , ap | i , ip = La.selb eq a i
      , λ ρ j → ap ρ (ix-combine (eval e₁ ρ) j eq)
        ∙ cong (eval a ρ) (cong (λ t → ix-combine t j eq ) (ip ρ))
-- zero-but
    opt (zero-but i j e₂) with opt e₂ | i ≟ᵉ j
    ... | a , p | just refl =
      a , go where
        go : _
        go ρ k = (eval-zb e₂ i _ _) ∙ p _ _
    ... | a , p | nothing = zero-but i j a , go
      where go : _
            go ρ k with eval i ρ ≟ₚ eval j ρ
            ... | yes _ = p ρ k
            ... | no _ = refl
-- let
    opt (let′ e e₁) with opt e | opt e₁
    ... | var v , ap | b , bp = sub b (sub-id ▹ var v)
      , λ ρ j → bp _ j
      ∙ sym (eval-sub b ρ _ j
      ∙ eval-cong b (sub-env-id ▹ (λ i → sym $ ap ρ i)) j)
    ... | let′ c d , ap | b , bp = (let′ c (let′ d (wk (keep (skip ⊆-eq)) b)))
      , go where
        go : _
        go ρ i = (bp (ρ , eval e ρ) i)
                  ∙ sym ((eval-wk (keep (skip ⊆-eq)) b _ i)
                  ∙ eval-cong b wk-env-id i
                  ∙ eval-cong b (reflᶜ ▹ λ j → sym (ap _ j)) i)
    -- default
    ... | a , ap | b , bp = let′ a b
      , λ ρ j → bp (ρ , eval e ρ) j ∙ eval-cong b (reflᶜ ▹ ap ρ) j

-- opt-out
  danger-opt : E Γ is → E Γ is
  danger-opt e = (opt e .proj₁)

  module _ where

    default : (e : E Γ is) → ∃ λ e′ → (e ≈ᵉ e′)
    default (var x) = var x , reflᵉ (var x)
    default (kop x) = (kop x) , reflᵉ (kop x)
    default (uop x e) with x  | default e
    ... | ⊟ₒ    | a , ap = ⊟ a
      , λ ρ j → cong -_ (ap ρ j)
    ... | reluₒ | a , ap = relu a
      , λ ρ j → cong (_∨_ 0ᵣ) (ap ρ j)
    ... | √ₒ    | a , ap = (La.√ a)
      , λ ρ j → cong √_ (ap ρ j)
    ... | 𝟙/ₒ   | a , ap = 𝟙/ a
      , λ ρ j → cong 1/_ (ap ρ j)
    ... | 𝕚+ₒ   | a , ap = 𝕚+ a
      , λ ρ j → cong I+ (ap ρ j)
    ... | lnₒ   | a , ap = ln a
      , λ ρ j → cong log (ap ρ j)
    ... | scₒ n | a , ap = scaledown n a
      , λ ρ j → cong (_÷ fromℕ n) (ap ρ j)
    ... | ℙₒ    | a , ap = ℙ a
      , λ ρ i → cong₂ _÷_ (cong e^_ (ap _ _)) (sum-cong _+_ _ {e^_ ∘ (eval e ρ)}
        λ j → cong e^_ (ap _ _))
    default (bop x e e₁) with x | default e | default e₁
    ... | ⊞ₒ | a , ap | b , bp = a ⊞ b
      , λ ρ j → cong₂ _+_ (ap ρ j) (bp ρ j)
    ... | ⊠ₒ | a , ap | b , bp = a ⊠ b
      , λ ρ j → cong₂ _*_ (ap ρ j) (bp ρ j)
    default (mop x e) with x  | default e
    ... | imapsₒ     | a , ap = imaps a
      , λ ρ i → ap (ρ , i) []
    ... | imapₒ refl | a , ap = imap a
      , λ ρ i → ap (ρ , splitP i .proj₁) (splitP i .proj₂)
    ... | imapbₒ eq  | a , ap = La.imapb eq a
      , λ ρ j → ap (ρ , ix-div j eq) (ix-mod j eq)
    ... | sumₒ       | a , ap = La.sum a
      , λ ρ j → sum-inv _+_ (fromℕ 0) {(λ i₁ → eval e (ρ , i₁))} j
        ∙ sum-cong _+_ (fromℕ 0) {λ j₁ → eval e (ρ , j₁) j} (λ i → ap (ρ , i) j)
        ∙ (sym (sum-inv _+_ (fromℕ 0) {λ i → eval a (ρ , i)} j))
    default (sop x e e₁) with x | default e | default e₁
    ... | selsₒ | a , ap | i , ip = sels a i ,
      λ ρ j → ap ρ (eval e₁ ρ) ∙ cong (eval a ρ) (ip ρ)
    ... | selₒ refl | a , ap | i , ip = sel a i
      , λ ρ j → ap ρ (eval e₁ ρ ++ j) ∙ cong (eval a ρ) (cong (_++ j) (ip ρ))
    ... | selbₒ eq | a , ap | i , ip = La.selb eq a i
      , λ ρ j → ap ρ (ix-combine (eval e₁ ρ) j eq)
        ∙ cong (eval a ρ) (cong (λ t → ix-combine t j eq ) (ip ρ))
    default (zero-but e e₁ e₂) with default e | default e₁ | default e₂
    ... | i , ip | j , jp | a , ap = zero-but i j a
      , go where
          go : _
          go ρ k rewrite (sym $ ip ρ) | (sym $ jp ρ) with eval e ρ ≟ₚ eval e₁ ρ
          ... | yes _ = ap ρ k
          ... | no _ = refl
    default (let′ e e₁) with default e | default e₁
    ... | a , ap | b , bp = let′ a b
      , λ ρ j → bp (ρ , eval e ρ) j ∙ eval-cong b (reflᶜ ▹ ap ρ) j