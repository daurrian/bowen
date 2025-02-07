import Mathlib
import Bowen.Bernoulli
import Bowen.RPF

open Real MeasureTheory Set Topology Classical
open Filter
open Bernoulli

variable {n : ℕ}

noncomputable def nnexp (x : ℝ) : NNReal := ⟨exp x, exp_nonneg x⟩

instance : ContainN ℤ where
  fromNat x := ↑x
  shift x := x + 1
  var_supp k := Icc (-k) k

class InvariantProb (μ : Measure (Bernoulli ℤ n)) extends IsProbabilityMeasure μ where
  invariant : ∀ s, μ s = μ (f ⁻¹' s)

class IsGibbs (φ : Bernoulli ℤ n → ℝ) (μ : Measure (Bernoulli ℤ n)) extends InvariantProb μ where
  gibbs_prop : ∃ P : ℝ, ∃ c₁ c₂ : NNReal, c₁ > 0 ∧ c₂ > 0 ∧ ∀ x : Bernoulli ℤ n, ∀ m : ℕ,
    μ (cylinder x m) / nnexp (- P * m + ∑ k ∈ Ico 0 m, φ (shift^[k] x)) ∈ Icc (c₁ : ENNReal) (c₂: ENNReal)

class IsErgodic (μ : Measure (Bernoulli ℤ n)) extends InvariantProb μ where
  ergodicity : ∀ s, f⁻¹' s = s → μ s = 0 ∨ μ s = 1

class IsMixing (μ : Measure (Bernoulli ℤ n)) extends InvariantProb μ where
  mixing : ∀ e f, Tendsto (fun n => μ (e ∩ preimage shift^[n] f)) atTop (nhds (μ e * μ f))

instance mixing_imp_ergodic (μ : Measure (Bernoulli ℤ n)) [IsMixing μ] : IsErgodic μ where
  ergodicity := by
    intros f s hs
    have intersect_trivial : ∀ n, s ∩ (shift^[n])⁻¹' s = s := sorry
    have lim : Tendsto (fun _ : ℕ => μ s) atTop (nhds (μ s * μ s)) := by sorry
    have lim2 : Tendsto (fun _ : ℕ => μ s) atTop (nhds (μ s)) := by exact tendsto_const_nhds
    have eq : μ s * μ s = μ s := by exact tendsto_nhds_unique lim lim2
    -- rw [← IsIdempotentElem.iff_eq_zero_or_one]
    -- exact eq
    sorry

lemma ergodic_shift_inv_imp_cst (μ : Measure (Bernoulli ℤ n)) [IsErgodic μ] (f : Bernoulli ℤ n → ℝ)
  (hf : Integrable f μ) (hμ : μ {x | (f ∘ shift) x = f x} = 1) :
    ∃ c, μ (f⁻¹' {c}) = 1 := by
      let Ec : ℝ → Set (Bernoulli ℤ n) :=
        fun c => (f ⁻¹' {c})
      have shift_inv c : shift ⁻¹' (Ec c) = Ec c := sorry
      sorry

namespace Uniqueness

  theorem gibbs_ergodic_unique (φ : Bernoulli ℤ n -> ℝ) (μ μ' : Measure (Bernoulli ℤ n))
    [IsGibbs φ μ] [IsGibbs φ μ'] [IsErgodic μ] :
      μ = μ' := sorry

end Uniqueness

namespace Equiv

  def equiv (f g : Bernoulli ℤ n → ℝ) : Prop :=
    ∃ u, Continuous u ∧ f = g - u + (u ∘ shift)

  def u_equiv (f g u: Bernoulli ℤ n → ℝ) : Prop :=
    Continuous u ∧ f = g - u + (u ∘ shift)

  lemma u_equiv_sym (f g u : Bernoulli ℤ n → ℝ) (h_equiv : u_equiv f g u) : u_equiv g f (-u) := by
    have relation : f = g - u + (u ∘ shift) := by exact h_equiv.right
    have eq : (-u) ∘ shift = - u ∘ shift := by rfl
    split_ands
    . exact @Continuous.neg ℝ (Bernoulli ℤ n) _ _ _ _ u (h_equiv.left) -- Fonctionne pas sans @
    . subst relation; rw [eq]; simp; ring

  lemma equiv_sym (f g : Bernoulli ℤ n → ℝ) (h_equiv : equiv f g) : equiv g f := by
    let u := choose h_equiv
    use -u
    have hu_equiv : u_equiv f g u := choose_spec (h_equiv)
    exact u_equiv_sym f g u hu_equiv

  lemma birkhoff_ineq (f g : Bernoulli ℤ n → ℝ) (u : C(Bernoulli ℤ n, ℝ)) (h_equiv : u_equiv f g u)
    (m : ℕ) (x : Bernoulli ℤ n) :
    ∑ k < m, (f (shift^[k] x) - g (shift^[k] x)) ≤ 2 * ‖u‖ := by
      have relation : f = g - u + (u ∘ shift) := h_equiv.right
      subst relation

  theorem equiv_imp_eq_gibbs (φ ψ : Bernoulli ℤ n → ℝ) (μ : Measure (Bernoulli ℤ n))
    [HolderLike φ] [HolderLike ψ] [hgibbs : IsGibbs φ μ] (h_equiv : equiv φ ψ) :
    IsGibbs ψ μ where
      gibbs_prop := by
        let u : C(Bernoulli ℤ n, ℝ) := {
          toFun := choose h_equiv,
          continuous_toFun := (choose_spec h_equiv).left
        }
        have u_relation := (choose_spec (h_equiv)).right
        have birkhoff_ineq1 (m : ℕ) (x : Bernoulli ℤ n) :
          ∑ k < m, (φ (shift^[k] x) - ψ (shift^[k] x)) ≤ 2 * ‖u‖ := by
          exact (birkhoff_ineq φ ψ u (choose_spec h_equiv) m x)
        have birkhoff_ineq2 (m : ℕ) (x : Bernoulli ℤ n) :
          ∑ k < m, (ψ (shift^[k] x) - φ (shift^[k] x)) ≤ 2 * ‖u‖ := by sorry
          -- exact (birkhoff_ineq ψ φ u (choose_spec h_equiv) m x)
        let P : ℝ := choose (hgibbs.gibbs_prop)
        let c₁ := choose (choose_spec hgibbs.gibbs_prop)
        let c₂ := choose (choose_spec (choose_spec hgibbs.gibbs_prop))
        have gibbs_ineq := choose_spec (choose_spec (choose_spec hgibbs.gibbs_prop))

        use P
        use c₁ * nnexp ((- 2) * ‖u‖)
        use c₂ * nnexp (2 * ‖u‖)
        split_ands
        . simp [mul_pos_iff_of_pos_left]
          split_ands
          . exact gibbs_ineq.left
          . exact exp_pos (-(2 * ‖u‖))
        . simp [mul_pos_iff_of_pos_left]
          split_ands
          . exact gibbs_ineq.right.left
          . exact exp_pos (2 * ‖u‖)
        intros x m
        have exp_ineq1 :
          exp (- 2 * ‖u‖ + ∑ k ∈ Ico 0 m, φ (shift^[k] x)) ≤ exp (∑ k ∈ Ico 0 m, ψ (shift^[k] x)) := by
          rw [exp_le_exp]
          sorry
        simp
        split_ands
        . sorry
        . sorry

  def DependOnlyPosCoords (φ : Bernoulli ℤ n → ℝ) : Prop :=
    ∀ x y : Bernoulli ℤ n, (∀ i : ℕ, x i = y i) → φ x = φ y

  lemma equiv_pos_coords (φ : Bernoulli ℤ n → ℝ) :
    ∃ ψ : Bernoulli ℤ n → ℝ, DependOnlyPosCoords ψ ∧ equiv φ ψ := sorry

end Equiv
