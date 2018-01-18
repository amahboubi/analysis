(* mathcomp analysis (c) 2017 Inria and AIST. License: CeCILL-C.              *)
Require Import Reals.
From mathcomp Require Import ssreflect ssrfun ssrbool ssrnat eqtype choice.
From mathcomp Require Import seq fintype bigop ssralg ssrnum finmap matrix.
From SsrReals Require Import boolp reals.
Require Import Rstruct Rbar set posnum.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.
Import GRing.Theory Num.Def Num.Theory.

Local Open Scope classical_set_scope.

Module Filtered.

(* Index a family of filters on a type, one for each element of the type *)
Definition locally_of U T := T -> set (set U).
Record class_of U T := Class {
  base : Pointed.class_of T;
  locally_op : locally_of U T
}.

Section ClassDef.
Variable U : Type.

Structure type := Pack { sort; _ : class_of U sort ; _ : Type }.
Local Coercion sort : type >-> Sortclass.
Variables (T : Type) (cT : type).
Definition class := let: Pack _ c _ := cT return class_of U cT in c.

Definition clone c of phant_id class c := @Pack T c T.
Let xT := let: Pack T _ _ := cT in T.
Notation xclass := (class : class_of U xT).
Local Coercion base : class_of >-> Pointed.class_of.

Definition pack m :=
  fun bT b of phant_id (Pointed.class bT) b => @Pack T (Class b m) T.

Definition eqType := @Equality.Pack cT xclass xT.
Definition choiceType := @Choice.Pack cT xclass xT.
Definition fpointedType := @Pointed.Pack cT xclass xT.

End ClassDef.

(* Index the filter (2nd proj) on a term (1st proj) *)
Structure on X Y := On {term : X; _ : set (set Y)}.

(* Defining the 2nd proj, not named before to prevent Warnings *)
(* when adding a canonical instance of canonical_filter_on *)
Definition term_filter {X Y} (F : on X Y) := let: On x f := F in f.
(* Coercion canonical_term_filter : canonical_filter_on >-> set. *)
Identity Coercion set_fun : set >-> Funclass.

(* filter on arrow sources *)
Structure source Z Y := Source {
  source_type :> Type;
  _ : (source_type -> Z) -> set (set Y)
}.
Definition source_filter Z Y (F : source Z Y) : (F -> Z) -> set (set Y) :=
  let: Source X f := F in f.

Module Exports.
Coercion sort : type >-> Sortclass.
Coercion base : class_of >-> Pointed.class_of.
Coercion locally_op : class_of >-> locally_of.
Coercion eqType : type >-> Equality.type.
Canonical eqType.
Coercion choiceType : type >-> Choice.type.
Canonical choiceType.
Coercion fpointedType : type >-> Pointed.type.
Canonical fpointedType.
Notation filteredType := type.
Notation FilteredType U T m := (@pack U T m _ _ idfun).
Notation "[ 'filteredType' U 'of' T 'for' cT ]" :=  (@clone U T cT _ idfun)
  (at level 0, format "[ 'filteredType'  U  'of'  T  'for'  cT ]") : form_scope.
Notation "[ 'filteredType' U 'of' T ]" := (@clone U T _ _ id)
  (at level 0, format "[ 'filteredType'  U  'of'  T ]") : form_scope.

(* The default filter for an arbitrary element is the one obtained *)
(* from its type *)
Canonical default_arrow_filter Y (Z : pointedType) (X : source Z Y) :=
  FilteredType Y (X -> Z) (@source_filter _ _ X).
Canonical source_filter_filter Y :=
  @Source Prop _ (_ -> Prop) (fun x : (set (set Y)) => x).
Canonical source_filter_filter' Y :=
  @Source Prop _ (set _) (fun x : (set (set Y)) => x).

Notation filter_term := term.
Notation term_filter := term_filter.
Notation filter_on_term := on.

End Exports.
End Filtered.
Export Filtered.Exports.

Definition locally {U} {T : filteredType U} : T -> set (set U) :=
  Filtered.locally_op (Filtered.class T).
Arguments locally {U T} _ _ : simpl never.

Canonical default_filter_on_term Y (X : filteredType Y) (x : X) :=
   @Filtered.On X Y x (locally x).

Definition filter_from {I T : Type} (D : set I) (B : I -> set T) : set (set T) :=
  [set P | exists2 i, D i & B i `<=` P].

(* the canonical filter on vectors on X is the product of the canonical filter
   on X *)
Canonical rV_filtered n X (Z : filteredType X) : filteredType 'rV[X]_n :=
  FilteredType 'rV[X]_n 'rV[Z]_n (fun vx => filter_from
    [set P | forall i, locally (vx ord0 i) (P i)]
    (fun P => [set vy : 'rV[X]_n | forall i, P i (vy ord0 i)])).

Definition filter_prod {T U : Type}
  (F : set (set T)) (G : set (set U)) : set (set (T * U)) :=
  filter_from (fun P => F P.1 /\ G P.2) (fun P => P.1 `*` P.2).

Section Near.

Local Notation "{ 'all1' P }" := (forall x, P x : Prop) (at level 0).
Local Notation "{ 'all2' P }" := (forall x y, P x y : Prop) (at level 0).
Local Notation "{ 'all3' P }" := (forall x y z, P x y z: Prop) (at level 0).
Local Notation ph := (phantom _).

Definition prop_near1 {X Y} (F : filter_on_term X Y) (x : X)
  (eq_x : x = filter_term F) P (phP : ph {all1 P}) :=
  (term_filter F) P.

Definition prop_near2 {X X' Y Y'} :=
 fun (F : filter_on_term X Y) (x : X) of x = filter_term F =>
 fun (F' : filter_on_term X' Y') (x' : X') of x' = filter_term F' =>
 fun P of ph {all2 P} =>
  filter_prod (term_filter F) (term_filter F') (fun x => P x.1 x.2).

End Near.

Notation "{ 'near' F , P }" :=
  (@prop_near1 _ _ _ F erefl _ (inPhantom P))
  (at level 0, format "{ 'near'  F ,  P }") : type_scope.
Notation "'\forall' x '\near' F , P" := {near F, forall x, P}
  (at level 200, x ident, P at level 200, format "'\forall'  x  '\near'  F ,  P") : type_scope.
Notation "'\near' x , P" := (\forall x \near x, P)
  (at level 200, x at level 99, P at level 200, format "'\near'  x ,  P", only parsing) : type_scope.
Notation "{ 'near' F & G , P }" :=
  (@prop_near2 _ _ _ _ _ F erefl _ G erefl _ (inPhantom P))
  (at level 0, format "{ 'near'  F  &  G ,  P }") : type_scope.
Notation "'\forall' x '\near' F & y '\near' G , P" :=
  {near F & G, forall x y, P}
  (at level 200, x ident, y ident, P at level 200, format "'\forall'  x  '\near'  F  &  y  '\near'  G ,  P") : type_scope.
Notation "'\forall' x & y '\near' F , P" :=
  {near F & F, forall x y, P}
  (at level 200, x ident, y ident, P at level 200, format "'\forall'  x  &  y  '\near'  F ,  P") : type_scope.
Notation "'\near' x & y , P" := (\forall x \near x & y \near y, P)
  (at level 200, x, y at level 99, P at level 200, format "'\near'  x  &  y ,  P", only parsing) : type_scope.
Arguments prop_near1 : simpl never.
Arguments prop_near2 : simpl never.

Lemma nearE {T} {F : set (set T)} (P : set T) : (\forall x \near F, P x) = F P.
Proof. by []. Qed.

Definition filter_of X Y (F : filter_on_term X Y)
  (x : X) (_ : x = filter_term F) := term_filter F.
Notation "[ 'filter' 'of' x ]" := (@filter_of _ _ _ x erefl)
  (format "[ 'filter'  'of'  x ]") : classical_set_scope.
Arguments filter_of _ _ _ _ _ _ /.

Lemma filter_of_filterE {T : Type} (F : set (set T)) :
  [filter of F] = F.
Proof. by []. Qed.

Lemma locally_filterE {T : Type} (F : set (set T)) : locally F = F.
Proof. by []. Qed.

Lemma filter_of_genericE X T (F : filter_on_term X T) :
  [filter of filter_term F] = term_filter F.
Proof. by []. Qed.

Module Export LocallyFilter.
Definition locally_simpl :=
  (@filter_of_filterE, @locally_filterE, @filter_of_genericE).
End LocallyFilter.

Definition flim {T : Type} (F G : set (set T)) := G `<=` F.
Notation "F `=>` G" := (flim F G)
  (at level 70, format "F  `=>`  G") : classical_set_scope.

Lemma flim_refl T (F : set (set T)) : F `=>` F.
Proof. exact. Qed.

Lemma flim_trans T (G F H : set (set T)) :
  (F `=>` G) -> (G `=>` H) -> (F `=>` H).
Proof. by move=> FG GH P /GH /FG. Qed.

Notation "F --> G" := (flim [filter of F] [filter of G])
  (at level 70, format "F  -->  G") : classical_set_scope.

Definition type_of_filter {T} (F : set (set T)) := T.
Definition lim_in {U : Type} (T : filteredType U) :=
  fun F : set (set U) => get (fun l : T => F --> l).

Notation "[ 'lim' F 'in' T ]" := (@lim_in _ T [filter of F])
  (format "[ 'lim'  F  'in'  T ]") : classical_set_scope.
Notation lim F := [lim F in [filteredType _ of @type_of_filter _ [filter of F]]].
Notation "[ 'cvg' F 'in' T ]" := (F --> [lim F in T])
  (format "[ 'cvg'  F  'in'  T ]") : classical_set_scope.
Notation cvg F := [cvg F in [filteredType _ of @type_of_filter _ [filter of F]]].

Section FilteredTheory.

Canonical filtered_prod X1 X2 (Z1 : filteredType X1)
  (Z2 : filteredType X2) : filteredType (X1 * X2) :=
  FilteredType (X1 * X2) (Z1 * Z2)
    (fun x => filter_prod (locally x.1) (locally x.2)).

Lemma cvg_ex {U : Type} (T : filteredType U) (F : set (set U)) :
  [cvg F in T] <-> (exists l : T, F --> l).
Proof. by split=> [cvg|/getPex//]; exists [lim F in T]. Qed.

Lemma cvgP {U : Type} (T : filteredType U) (F : set (set U)) (l : T) :
   F --> l -> [cvg F in T].
Proof. by move=> Fl; apply/cvg_ex; exists l. Qed.

Lemma dvgP {U : Type} (T : filteredType U) (F : set (set U)) :
  ~ [cvg F in T] -> [lim F in T] = point.
Proof. by rewrite /lim_in /=; case xgetP. Qed.

(* CoInductive cvg_spec {U : Type} (T : filteredType U) (F : set (set U)) : *)
(*    U -> Prop -> Type := *)
(* | HasLim  of F --> [lim F in T] : cvg_spec T F [lim F in T] True *)
(* | HasNoLim of ~ [cvg F in U] : cvg_spec F point False. *)

(* Lemma cvgP (F : set (set U)) : cvg_spec F (lim F) [cvg F in U]. *)
(* Proof. *)
(* have [cvg|dvg] := pselect [cvg F in U]. *)
(*   by rewrite (propT cvg); apply: HasLim; rewrite -cvgE. *)
(* by rewrite (propF dvg) (dvgP _) //; apply: HasNoLim. *)
(* Qed. *)


End FilteredTheory.

Lemma locally_nearE {U} {T : filteredType U} (x : T) (P : set U) :
  locally x P = \near x, P x.
Proof. by []. Qed.

Lemma near_locally {U} {T : filteredType U} (x : T) (P : set U) :
  (\forall x \near locally x, P x) = \near x, P x.
Proof. by []. Qed.

Lemma near2_curry {U V} (F : set (set U)) (G : set (set V)) (P : U -> set V) :
  {near F & G, forall x y, P x y} = {near (F, G), forall x, P x.1 x.2}.
Proof. by []. Qed.

Lemma near2_pair {U V} (F : set (set U)) (G : set (set V)) (P : set (U * V)) :
  {near F & G, forall x y, P (x, y)} = {near (F, G), forall x, P x}.
Proof. by symmetry; congr (locally _); rewrite predeqE => -[]. Qed.

Definition near2E := (@near2_curry, @near2_pair).

Lemma filter_of_nearI (X Y : Type) (F : filter_on_term X Y) (x : X) (e : x = filter_term F) P :
  @filter_of X Y F x e P = @prop_near1 X Y F x e P (inPhantom (forall x, P x)).
Proof. by []. Qed.

Module Export NearLocally.
Definition near_simpl := (@near_locally, @locally_nearE, filter_of_nearI).
Ltac near_simpl := rewrite ?near_simpl.
End NearLocally.

Lemma near_swap {U V} (F : set (set U)) (G : set (set V)) (P : U -> set V) :
  (\forall x \near F & y \near G, P x y) = (\forall y \near G & x \near F, P x y).
Proof.
rewrite propeqE; split => -[[/=A B] [FA FB] ABP];
by exists (B, A) => // -[x y] [/=Bx Ay]; apply: (ABP (y, x)).
Qed.

(** * Filters *)

(** ** Definitions *)

Class Filter {T : Type} (F : set (set T)) := {
  filterT : F setT ;
  filterI : forall P Q : set T, F P -> F Q -> F (P `&` Q) ;
  filterS : forall P Q : set T, P `<=` Q -> F P -> F Q
}.
Global Hint Mode Filter - ! : typeclass_instances.

Class ProperFilter' {T : Type} (F : set (set T)) := {
  filter_not_empty : not (F (fun _ => False)) ;
  filter_filter' :> Filter F
}.
Global Hint Mode ProperFilter' - ! : typeclass_instances.
Arguments filter_not_empty {T} F {_}.

Notation ProperFilter := ProperFilter'.

Lemma filter_setT (T' : Type) : Filter (@setT (set T')).
Proof. by constructor. Qed.

Lemma filter_bigI T (I : choiceType) (D : {fset I}) (f : I -> set T)
  (F : set (set T)) :
  Filter F -> (forall i, i \in D -> F (f i)) ->
  F (\bigcap_(i in [set i | i \in D]) f i).
Proof.
move=> FF FfD.
suff: F [set p | forall i, i \in enum_fset D -> f i p] by [].
have {FfD} : forall i, i \in enum_fset D -> F (f i) by move=> ? /FfD.
elim: (enum_fset D) => [|i s ihs] FfD; first exact: filterS filterT.
apply: (@filterS _ _ _ (f i `&` [set p | forall i, i \in s -> f i p])).
  by move=> p [fip fsp] j; rewrite inE => /orP [/eqP->|] //; apply: fsp.
apply: filterI; first by apply: FfD; rewrite inE eq_refl.
by apply: ihs => j sj; apply: FfD; rewrite inE sj orbC.
Qed.

Structure filter_on T := FilterType {
  filter :> (T -> Prop) -> Prop;
  filter_class : Filter filter
}.
Arguments FilterType {T} _ _.
Existing Instance filter_class.
Coercion filter_filter' : ProperFilter >-> Filter.

Structure pfilter_on T := PFilterPack {
  pfilter :> (T -> Prop) -> Prop;
  pfilter_class : ProperFilter pfilter
}.
Arguments PFilterPack {T} _ _.
Existing Instance pfilter_class.
Canonical pfilter_filter_on T (F : pfilter_on T) :=
  FilterType F (pfilter_class F).
Coercion pfilter_filter_on : pfilter_on >-> filter_on.
Definition PFilterType {T} (F : (T -> Prop) -> Prop)
  {fF : Filter F} (fN0 : not (F set0)) :=
  PFilterPack F (Build_ProperFilter' fN0 fF).
Arguments PFilterType {T} F {fF} fN0.

Canonical filter_on_eqType T := EqType (filter_on T) gen_eqMixin.
Canonical filter_on_choiceType T :=
  ChoiceType (filter_on T) gen_choiceMixin.
Canonical filter_on_PointedType T :=
  PointedType (filter_on T) (FilterType _ (filter_setT T)).
Canonical filter_on_FilteredType T :=
  FilteredType T (filter_on T) (@filter T).

Global Instance filter_on_Filter T (F : filter_on T) : Filter F.
Proof. by case: F. Qed.
Global Instance pfilter_on_ProperFilter T (F : pfilter_on T) : ProperFilter F.
Proof. by case: F. Qed.

Lemma filter_locallyT {T : Type} (F : set (set T)) :
   Filter F -> locally F setT.
Proof. by move=> FF; apply: filterT. Qed.
Hint Resolve filter_locallyT.

Lemma nearT {T : Type} (F : set (set T)) : Filter F -> \near F, True.
Proof. by move=> FF; apply: filterT. Qed.
Hint Resolve nearT.

Lemma filter_not_empty_ex {T : Type} (F : set (set T)) :
    (forall P, F P -> exists x, P x) -> ~ F set0.
Proof. by move=> /(_ set0) ex /ex []. Qed.

Definition Build_ProperFilter {T : Type} (F : set (set T))
  (filter_ex : forall P, F P -> exists x, P x)
  (filter_filter : Filter F) :=
  Build_ProperFilter' (filter_not_empty_ex filter_ex) (filter_filter).

Lemma filter_ex_subproof {T : Type} (F : set (set T)) :
     ~ F set0 -> (forall P, F P -> exists x, P x).
Proof.
move=> NFset0 P FP; apply: contrapNT NFset0 => nex; suff <- : P = set0 by [].
by rewrite funeqE => x; rewrite propeqE; split=> // Px; apply: nex; exists x.
Qed.

Definition filter_ex {T : Type} (F : set (set T)) {FF : ProperFilter F} :=
  filter_ex_subproof (filter_not_empty F).
Arguments filter_ex {T F FF _}.

Lemma filter_getP {T : pointedType} (F : set (set T)) {FF : ProperFilter F}
      (P : set T) : F P -> P (get P).
Proof. by move=> /filter_ex /getPex. Qed.

(* Near Tactic *)

Lemma filterP T (F : set (set T)) {FF : Filter F} (P : set T) :
  (exists2 Q : set T, F Q & forall x : T, Q x -> P x) <-> F P.
Proof.
split; last by exists P.
by move=> [Q FQ QP]; apply: (filterS QP).
Qed.

Definition extensible_property T (x : T) (P : Prop) := P.
Lemma extensible_propertyI T (x : T) (P : Prop) :
  P -> extensible_property x P.
Proof. by []. Qed.

Record in_filter T (F : set (set T)) := InFilter {
  prop_in_filter_proj : T -> Prop;
  prop_in_filterP_proj : F prop_in_filter_proj
}.
(* add ball x e as a canonical instance of locally x *)

Module Type PropInFilterSig.
Axiom t : forall (T : Type) (F : set (set T)), in_filter F -> T -> Prop.
Axiom tE : t = prop_in_filter_proj.
End PropInFilterSig.
Module PropInFilter : PropInFilterSig.
Definition t := prop_in_filter_proj.
Lemma tE : t = prop_in_filter_proj. Proof. by []. Qed.
End PropInFilter.
Coercion PropInFilter.t : in_filter >-> Funclass.
Definition prop_in_filterE := PropInFilter.tE.

Lemma prop_in_filterP T F (iF : @in_filter T F) : F iF.
Proof. by rewrite prop_in_filterE; apply: prop_in_filterP_proj. Qed.

Ltac begin_near x :=
apply/filterP;
let R := fresh "around" in
match goal with |- exists2 _ : set ?T, ?F _ & _ =>
  evar (R : set T);
  exists R; [rewrite /R {R}|
             move=> x /(extensible_propertyI x) ?]; last first
end.

Ltac have_near F x :=
match (type of ([filter of F] : (_ -> Prop) -> Prop))
  with (?T -> Prop) -> Prop =>
  let R := fresh "around" in
  evar (R : set T);
  have [|x /(extensible_propertyI x) ?] := @filter_ex _ [filter of F] _ R;
  [rewrite /R {R}|]; last first
end.

Ltac near x :=
match goal with Hx : extensible_property x _ |- _ =>
  eapply proj1; do 10?[by apply: Hx|eapply proj2] end.

Ltac end_near := do !
  [exact: prop_in_filterP|exact: filterT|by []|apply: filterI].

Ltac done :=
  trivial; hnf; intros; solve
   [ do ![solve [trivial | apply: sym_equal; trivial]
         | discriminate | contradiction | split]
   | case not_locked_false_eq_true; assumption
   | match goal with H : ~ _ |- _ => solve [case H; trivial] end
   | match goal with |- PropInFilter.t _ ?x => near x end ].

Lemma near T (F : set (set T)) P (FP : F P) (x : T) : (InFilter FP) x -> P x.
Proof. by rewrite prop_in_filterE. Qed.
Arguments near {T F P} FP _ _.

Notation "[ 'valid_near' F ]" := (@InFilter _ F _ _) (format "[ 'valid_near'  F ]").
Definition valid_nearE := prop_in_filterE.

Lemma filterE {T : Type} {F} {FF: @Filter T F} (P : T -> Prop) :
  (forall x, P x) -> F P.
Proof. by move=> ?; apply/filterP; exists setT => //; apply: filterT. Qed.

Lemma filter_app (T : Type) (F : set (set T)) :
  Filter F -> forall P Q : set T, F (fun x => P x -> Q x) -> F P -> F Q.
Proof.
by move=> FF P Q subPQ FP; begin_near x; [suff: P x; near x|end_near].
Qed.

Lemma filter_app2 (T : Type) (F : set (set T)) :
  Filter F -> forall P Q R : set T,  F (fun x => P x -> Q x -> R x) ->
  F P -> F Q -> F R.
Proof. by move=> ???? PQR FP; apply: filter_app; apply: filter_app FP. Qed.

Lemma filter_app3 (T : Type) (F : set (set T)) :
  Filter F -> forall P Q R S : set T, F (fun x => P x -> Q x -> R x -> S x) ->
  F P -> F Q -> F R -> F S.
Proof. by move=> ????? PQR FP; apply: filter_app2; apply: filter_app FP. Qed.

Lemma filterS2 (T : Type) (F : set (set T)) :
  Filter F -> forall P Q R : set T, (forall x, P x -> Q x -> R x) ->
  F P -> F Q -> F R.
Proof. by move=> ???? /filterE; apply: filter_app2. Qed.

Lemma filterS3 (T : Type) (F : set (set T)) :
  Filter F -> forall P Q R S : set T, (forall x, P x -> Q x -> R x -> S x) ->
  F P -> F Q -> F R -> F S.
Proof. by move=> ????? /filterE; apply: filter_app3. Qed.

Lemma filter_const {T : Type} {F} {FF: @ProperFilter T F} (P : Prop) :
  F (fun=> P) -> P.
Proof. by move=> FP; case: (filter_ex FP). Qed.

Lemma in_filter_from {I T : Type} (D : set I) (B : I -> set T) (i : I) :
   D i -> filter_from D B (B i).
Proof. by exists i. Qed.

Lemma nearP_dep {T U} {F : set (set T)} {G : set (set U)}
   {FF : Filter F} {FG : Filter G} (P : T -> U -> Prop) :
  (\forall x \near F & y \near G, P x y) ->
  \forall x \near F, \forall y \near G, P x y.
Proof.
move=> [[Q R] [/=FQ GR]] QRP.
by apply: filterS FQ => x Q1x; apply: filterS GR => y Q2y; apply: (QRP (_, _)).
Qed.

Lemma filter2P T U (F : set (set T)) (G : set (set U))
  {FF : Filter F} {FG : Filter G} (P : set (T * U)) :
  (exists2 Q : set T * set U, F Q.1 /\ G Q.2
     & forall (x : T) (y : U), Q.1 x -> Q.2 y -> P (x, y))
   <-> \forall x \near (F, G), P x.
Proof.
split=> [][[A B] /=[FA GB] ABP]; exists (A, B) => //=.
  by move=> [a b] [/=Aa Bb]; apply: ABP.
by move=> a b Aa Bb; apply: (ABP (_, _)).
Qed.

Ltac begin_near2 x y :=
apply/filter2P;
let R1 := fresh "around1" in
let R2 := fresh "around2" in
match goal with |- exists2 _ : set ?T * set ?U, ?F _.1 /\ ?G _.2 & _ =>
  evar (R1 : set T); evar (R2 : set U); exists (R1, R2);
  [rewrite /R1 {R1} /R2 {R2}
  |move=> x y /(extensible_propertyI x) ? /(extensible_propertyI y) ?];
  last first
end.

Lemma filter_ex2 {T U : Type} (F : set (set T)) (G : set (set U))
  {FF : ProperFilter F} {FG : ProperFilter G} (P : set T) (Q : set U) :
   F P -> G Q -> exists x : T, exists2 y : U, P x & Q y.
Proof. by move=> /filter_ex [x Px] /filter_ex [y Qy]; exists x, y. Qed.
Arguments filter_ex2 {T U F G FF FG _ _}.

Ltac have_near2 F G x y :=
match (type of ([filter of F] : (_ -> Prop) -> Prop))
  with (?T -> Prop) -> Prop =>
match (type of ([filter of G] : (_ -> Prop) -> Prop))
  with (?U -> Prop) -> Prop =>
let R1 := fresh "around1" in
let R2 := fresh "around2" in
  evar (R1 : set T); evar (R2 : set U); exists (R1, R2);
  have [||x [y /(extensible_propertyI x) ? /(extensible_propertyI y) ?]] :=
    @filter_ex2 _ _ [filter of F] [filter of G] _ _ R1 R2;
  [rewrite /R1 {R1} /R2 {R2}|rewrite /R1 {R1} /R2 {R2}|]; last first
end
end.

Lemma filter_fromP {I T : Type} (D : set I) (B : I -> set T) (F : set (set T)) :
  Filter F -> F `=>` filter_from D B <-> forall i, D i -> F (B i).
Proof.
split; first by move=> FB i ?; apply/FB/in_filter_from.
by move=> FB P [i Di BjP]; apply: (filterS BjP); apply: FB.
Qed.

Lemma filter_fromTP {I T : Type} (B : I -> set T) (F : set (set T)) :
  Filter F -> F `=>` filter_from setT B <-> forall i, F (B i).
Proof. by move=> FF; rewrite filter_fromP; split=> [P i|P i _]; apply: P. Qed.

Lemma filter_from_filter {I T : Type} (D : set I) (B : I -> set T) :
  (exists i : I, D i) ->
  (forall i j, D i -> D j -> exists2 k, D k & B k `<=` B i `&` B j) ->
  Filter (filter_from D B).
Proof.
move=> [i0 Di0] Binter; constructor; first by exists i0.
- move=> P Q [i Di BiP] [j Dj BjQ]; have [k Dk BkPQ]:= Binter _ _ Di Dj.
  by exists k => // x /BkPQ [/BiP ? /BjQ].
- by move=> P Q subPQ [i Di BiP]; exists i; apply: subset_trans subPQ.
Qed.

Lemma filter_fromT_filter {I T : Type} (B : I -> set T) :
  (exists _ : I, True) ->
  (forall i j, exists k, B k `<=` B i `&` B j) ->
  Filter (filter_from setT B).
Proof.
move=> [i0 _] BI; apply: filter_from_filter; first by exists i0.
by move=> i j _ _; have [k] := BI i j; exists k.
Qed.

Lemma filter_from_proper {I T : Type} (D : set I) (B : I -> set T) :
  Filter (filter_from D B) ->
  (forall i, D i -> B i !=set0) ->
  ProperFilter (filter_from D B).
Proof.
move=> FF BN0; apply: Build_ProperFilter=> P [i Di BiP].
by have [x Bix] := BN0 _ Di; exists x; apply: BiP.
Qed.

(** ** Limits expressed with filters *)

Definition filtermap {T U : Type} (f : T -> U) (F : set (set T)) :=
  [set P | F (f @^-1` P)].
Arguments filtermap _ _ _ _ _ /.

Lemma filtermapE {U V : Type} (f : U -> V)
  (F : set (set U)) (P : set V) : filtermap f F P = F (f @^-1` P).
Proof. by []. Qed.

Notation "E @[ x --> F ]" := (filtermap (fun x => E) [filter of F])
  (at level 60, x ident, format "E  @[ x  -->  F ]") : classical_set_scope.
Notation "f @ F" := (filtermap f [filter of F])
  (at level 60, format "f  @  F") : classical_set_scope.

Global Instance filtermap_filter T U (f : T -> U) (F : set (set T)) :
  Filter F -> Filter (f @ F).
Proof.
move=> FF; constructor => [|P Q|P Q PQ]; rewrite ?filtermapE ?filter_ofE //=.
- exact: filterT.
- exact: filterI.
- by apply: filterS=> ?/PQ.
Qed.

Global Instance filtermap_proper_filter T U (f : T -> U) (F : set (set T)) :
  ProperFilter F -> ProperFilter (f @ F).
Proof.
move=> FF; apply: Build_ProperFilter';
by rewrite filtermapE; apply: filter_not_empty.
Qed.
Definition filtermap_proper_filter' := filtermap_proper_filter.

Definition filtermapi {T U : Type} (f : T -> set U) (F : set (set T)) :=
  [set P | \forall x \near F, exists y, f x y /\ P y].

Notation "E `@[ x --> F ]" := (filtermapi (fun x => E) [filter of F])
  (at level 60, x ident, format "E  `@[ x  -->  F ]") : classical_set_scope.
Notation "f `@ F" := (filtermapi f [filter of F])
  (at level 60, format "f  `@  F") : classical_set_scope.

Lemma filtermapiE {U V : Type} (f : U -> set V)
  (F : set (set U)) (P : set V) :
  filtermapi f F P = \forall x \near F, exists y, f x y /\ P y.
Proof. by []. Qed.

Global Instance filtermapi_filter T U (f : T -> set U) (F : set (set T)) :
  infer {near F, is_totalfun f} -> Filter F -> Filter (f `@ F).
Proof.
move=> f_totalfun FF; rewrite /filtermapi; apply: Build_Filter. (* bug *)
- by apply: filterS f_totalfun => x [[y Hy] H]; exists y.
- move=> P Q FP FQ; begin_near x.
    have [//|y [fxy Py]] := near FP x.
    have [//|z [fxz Qz]] := near FQ x.
    have [//|_ fx_prop] := near f_totalfun x.
    by exists y; split => //; split => //; rewrite [y](fx_prop _ z).
  by end_near.
- move=> P Q subPQ FP; begin_near x.
    by have [//|y [fxy /subPQ Qy]] := near FP x; exists y.
  by end_near.
Qed.

Global Instance filtermapi_proper_filter
  T U (f : T -> U -> Prop) (F : set (set T)) :
  infer {near F, is_totalfun f} ->
  ProperFilter F -> ProperFilter (f `@ F).
Proof.
move=> f_totalfun FF; apply: Build_ProperFilter.
by move=> P; rewrite /filtermapi => /filter_ex [x [y [??]]]; exists y.
Qed.
Definition filter_map_proper_filter' := filtermapi_proper_filter.

Lemma flim_id T (F : set (set T)) : x @[x --> F] --> F.
Proof. exact. Qed.
Arguments flim_id {T F}.

Lemma appfilter U V (f : U -> V) (F : set (set U)) :
  f @ F = [set P : set _ | \forall x \near F, P (f x)].
Proof. by []. Qed.

Lemma flim_app U V (F G : set (set U)) (f : U -> V) :
  F --> G -> f @ F --> f @ G.
Proof. by move=> FG P /=; exact: FG. Qed.

Lemma flimi_app U V (F G : set (set U)) (f : U -> set V) :
  F --> G -> f `@ F --> f `@ G.
Proof. by move=> FG P /=; exact: FG. Qed.

Lemma flim_comp T U V (f : T -> U) (g : U -> V)
  (F : set (set T)) (G : set (set U)) (H : set (set V)) :
  f @ F `=>` G -> g @ G `=>` H -> g \o f @ F `=>` H.
Proof. by move=> fFG gGH; apply: flim_trans gGH => P /fFG. Qed.

Lemma flimi_comp T U V (f : T -> U) (g : U -> set V)
  (F : set (set T)) (G : set (set U)) (H : set (set V)) :
  f @ F `=>` G -> g `@ G `=>` H -> g \o f `@ F `=>` H.
Proof. by move=> fFG gGH; apply: flim_trans gGH => P /fFG. Qed.

Lemma flim_eq_loc {T U} {F : set (set T)} {FF : Filter F} (f g : T -> U) :
  {near F, f =1 g} -> g @ F `=>` f @ F.
Proof. by move=> eq_fg P /=; apply: filterS2 eq_fg => x <-. Qed.

Lemma flimi_eq_loc {T U} {F : set (set T)} {FF : Filter F} (f g : T -> set U) :
  {near F, f =2 g} -> g `@ F `=>` f `@ F.
Proof.
move=> eq_fg P /=; apply: filterS2 eq_fg => x eq_fg [y [fxy Py]].
by exists y; rewrite -eq_fg.
Qed.

(** ** Specific filters *)

(** Filters for pairs *)

Global Instance filter_prod_filter  T U (F : set (set T)) (G : set (set U)) :
  Filter F -> Filter G -> Filter (filter_prod F G).
Proof.
move=> FF FG; apply: filter_from_filter.
  by exists (setT, setT); split; apply: filterT.
move=> [P Q] [P' Q'] /= [FP GQ] [FP' GQ'].
exists (P `&` P', Q `&` Q') => /=; first by split; apply: filterI.
by move=> [x y] [/= [??] []].
Qed.

Global Instance filter_prod_proper {T1 T2 : Type}
  {F : (T1 -> Prop) -> Prop} {G : (T2 -> Prop) -> Prop}
  {FF : ProperFilter F} {FG : ProperFilter G} :
  ProperFilter (filter_prod F G).
Proof.
apply: filter_from_proper => -[A B] [/=FA GB].
by have [[x ?] [y ?]] := (filter_ex FA, filter_ex GB); exists (x, y).
Qed.
Definition filter_prod_proper' := @filter_prod_proper.

Lemma filter_prod1 {T U} {F : set (set T)} {G : set (set U)}
  {FG : Filter G} (P : set T) :
  (\forall x \near F, P x) -> \forall x \near F & _ \near G, P x.
Proof.
move=> FP; exists (P, setT)=> //= [|[?? []//]].
by split=> //; apply: filterT.
Qed.
Lemma filter_prod2 {T U} {F : set (set T)} {G : set (set U)}
  {FF : Filter F} (P : set U) :
  (\forall y \near G, P y) -> \forall _ \near F & y \near G, P y.
Proof.
move=> FP; exists (setT, P)=> //= [|[?? []//]].
by split=> //; apply: filterT.
Qed.

Lemma flim_fst {T U F G} {FG : Filter G} :
  (@fst T U) @ filter_prod F G --> F.
Proof. by move=> P; apply: filter_prod1. Qed.

Lemma flim_snd {T U F G} {FF : Filter F} :
  (@snd T U) @ filter_prod F G --> G.
Proof. by move=> P; apply: filter_prod2. Qed.

Lemma extensible_propertyE (T : Type) (x : T) (P : Prop) :
  extensible_property x P -> P.
Proof. by []. Qed.
Arguments extensible_propertyE {T} x {P}.

Lemma near_map {T U} (f : T -> U) (F : set (set T)) (P : set U) :
  (\forall y \near f @ F, P y) = (\forall x \near F, P (f x)).
Proof. by []. Qed.

Lemma near_map2 {T T' U U'} (f : T -> U) (g : T' -> U')
      (F : set (set T)) (G : set (set T')) (P : U -> set U') :
  Filter F -> Filter G ->
  (\forall y \near f @ F & y' \near g @ G, P y y') =
  (\forall x \near F     & x' \near G     , P (f x) (g x')).
Proof.
move=> FF FG; rewrite propeqE; split=> -[[A B] /= [fFA fGB] ABP].
  exists (f @^-1` A, g @^-1` B) => //= -[x y /=] xyAB.
  by apply: (ABP (_, _)); apply: xyAB.
exists (f @` A, g @` B) => //=; last first.
  by move=> -_ [/= [x Ax <-] [x' Bx' <-]]; apply: (ABP (_, _)).
rewrite !locally_simpl /filtermap /=; split.
  by apply: filterS fFA=> x Ax; exists x.
by apply: filterS fGB => x Bx; exists x.
Qed.

Lemma near_mapi {T U} (f : T -> set U) (F : set (set T)) (P : set U) :
  (\forall y \near f `@ F, P y) = (\forall x \near F, exists y, f x y /\ P y).
Proof. by []. Qed.

Module Export NearMap.
Definition near_simpl := (@near_simpl, @near_map, @near_mapi, @near_map2).
Ltac near_simpl := rewrite ?near_simpl.
End NearMap.

Lemma flim_pair {T U V F} {G : set (set U)} {H : set (set V)}
  {FF : Filter F} {FG : Filter G} {FH : Filter H} (f : T -> U) (g : T -> V) :
  f @ F --> G -> g @ F --> H ->
  (f x, g x) @[x --> F] --> (G, H).
Proof.
move=> fFG gFH P; rewrite !near_simpl => -[[A B] /=[GA HB] ABP]; begin_near x.
  by apply: (ABP (_, _)); split=> //=; near x.
by end_near; [apply: fFG|apply: gFH].
Qed.

Lemma flim_comp2 {T U V W}
  {F : set (set T)} {G : set (set U)} {H : set (set V)} {I : set (set W)}
  {FF : Filter F} {FG : Filter G} {FH : Filter H}
  (f : T -> U) (g : T -> V) (h : U -> V -> W) :
  f @ F --> G -> g @ F --> H ->
  h (fst x) (snd x) @[x --> (G, H)] --> I ->
  h (f x) (g x) @[x --> F] --> I.
Proof. by move=> fFG gFH hGHI P /= IP; apply: flim_pair (hGHI _ IP). Qed.
Arguments flim_comp2 {T U V W F G H I FF FG FH f g h} _ _ _.
Definition flim_comp_2 := @flim_comp2.

(* Lemma flimi_comp_2 {T U V W} *)
(*   {F : set (set T)} {G : set (set U)} {H : set (set V)} {I : set (set W)} *)
(*   {FF : Filter F} *)
(*   (f : T -> U) (g : T -> V) (h : U -> V -> set W) : *)
(*   f @ F --> G -> g @ F --> H -> *)
(*   h (fst x) (snd x) `@[x --> (G, H)] --> I -> *)
(*   h (f x) (g x) `@[x --> F] --> I. *)
(* Proof. *)
(* intros Cf Cg Ch. *)
(* change (fun x => h (f x) (g x)) with (fun x => h (fst (f x, g x)) (snd (f x, g x))). *)
(* apply: flimi_comp Ch. *)
(* now apply flim_pair. *)
(* Qed. *)

(** Restriction of a filter to a domain *)

Definition within {T : Type} (D : set T) (F : set (set T)) (P : set T) :=
  {near F, D `<=` P}.
Arguments within : simpl never.

Lemma near_withinE {T : Type} (D : set T) (F : set (set T)) (P : set T) :
  (\forall x \near within D F, P x) = {near F, D `<=` P}.
Proof. by []. Qed.

Lemma withinT  {T : Type} (F : set (set T)) (A : set T) : Filter F -> within A F A.
Proof. by move=> FF; rewrite /within; apply: filterE. Qed.

Lemma near_withinT  {T : Type} (F : set (set T)) (A : set T) : Filter F ->
  (\forall x \near within A F, A x).
Proof. exact: withinT. Qed.

Global Instance within_filter T D F : Filter F -> Filter (@within T D F).
Proof.
move=> FF; rewrite /within; constructor.
- by apply: filterE.
- by move=> P Q; apply: filterS2 => x DP DQ Dx; split; [apply: DP|apply: DQ].
- by move=> P Q subPQ; apply: filterS => x DP /DP /subPQ.
Qed.

Lemma flim_within {T} {F : set (set T)} {FF : Filter F} D :
  within D F --> F.
Proof. by move=> P; apply: filterS. Qed.

Definition subset_filter {T} (F : set (set T)) (D : set T) :=
  [set P : set {x | D x} | F [set x | forall Dx : D x, P (exist _ x Dx)]].
Arguments subset_filter {T} F D _.

Global Instance subset_filter_filter T F (D : set T) :
  Filter F -> Filter (subset_filter F D).
Proof.
move=> FF; constructor; rewrite /subset_filter.
- exact: filterE.
- by move=> P Q; apply: filterS2=> x PD QD Dx; split.
- by move=> P Q subPQ; apply: filterS => R PD Dx; apply: subPQ.
Qed.

Lemma subset_filter_proper {T F} {FF : Filter F} (D : set T) :
  (forall P, F P -> ~ ~ exists x, D x /\ P x) ->
  ProperFilter (subset_filter F D).
Proof.
move=> DAP; apply: Build_ProperFilter'; rewrite /subset_filter => subFD.
by have /(_ subFD) := DAP (~` D); apply => -[x [dx /(_ dx)]].
Qed.

(** * Topological spaces *)

Module Topological.

Record mixin_of (T : Type) (locally : T -> set (set T)) := Mixin {
  open : set (set T) ;
  ax1 : forall p : T, ProperFilter (locally p) ;
  ax2 : forall p : T, locally p =
    [set A : set T | exists B : set T, open B /\ B p /\ B `<=` A] ;
  ax3 : open = [set A : set T | A `<=` locally^~ A ]
}.

Record class_of (T : Type) := Class {
  base : Filtered.class_of T T;
  mixin : mixin_of (Filtered.locally_op base)
}.

Section ClassDef.

Structure type := Pack { sort; _ : class_of sort ; _ : Type }.
Local Coercion sort : type >-> Sortclass.
Variables (T : Type) (cT : type).
Definition class := let: Pack _ c _ := cT return class_of cT in c.

Definition clone c of phant_id class c := @Pack T c T.
Let xT := let: Pack T _ _ := cT in T.
Notation xclass := (class : class_of xT).
Local Coercion base : class_of >-> Filtered.class_of.
Local Coercion mixin : class_of >-> mixin_of.

Definition pack loc (m : @mixin_of T loc) :=
  fun bT (b : Filtered.class_of T T) of phant_id (@Filtered.class T bT) b =>
  fun m'   of phant_id m (m' : @mixin_of T (Filtered.locally_op b)) =>
  @Pack T (@Class _ b m') T.

Definition eqType := @Equality.Pack cT xclass xT.
Definition choiceType := @Choice.Pack cT xclass xT.
Definition pointedType := @Pointed.Pack cT xclass xT.
Definition filteredType := @Filtered.Pack cT cT xclass xT.

End ClassDef.

Module Exports.

Coercion sort : type >-> Sortclass.
Coercion base : class_of >-> Filtered.class_of.
Coercion mixin : class_of >-> mixin_of.
Coercion eqType : type >-> Equality.type.
Canonical eqType.
Coercion choiceType : type >-> Choice.type.
Canonical choiceType.
Coercion pointedType : type >-> Pointed.type.
Canonical pointedType.
Coercion filteredType : type >-> Filtered.type.
Canonical filteredType.
Notation topologicalType := type.
Notation TopologicalType T m := (@pack T _ m _ _ idfun _ idfun).
Notation TopologicalMixin := Mixin.
Notation "[ 'topologicalType' 'of' T 'for' cT ]" :=  (@clone T cT _ idfun)
  (at level 0, format "[ 'topologicalType'  'of'  T  'for'  cT ]") : form_scope.
Notation "[ 'topologicalType' 'of' T ]" := (@clone T _ _ id)
  (at level 0, format "[ 'topologicalType'  'of'  T ]") : form_scope.

End Exports.

End Topological.

Export Topological.Exports.

Section Topological1.

Context {T : topologicalType}.

Definition open := Topological.open (Topological.class T).

Definition neigh (p : T) (A : set T) := open A /\ A p.

Global Instance locally_filter (p : T) : ProperFilter (locally p).
Proof. by apply: Topological.ax1; case: T p => ? []. Qed.

Canonical locally_filter_on (x : T) :=
  FilterType (locally x) (@filter_filter' _ _ (locally_filter x)).

Lemma locallyE (p : T) :
  locally p = [set A : set T | exists B : set T, neigh p B /\ B `<=` A].
Proof.
have -> : locally p = [set A : set T | exists B, open B /\ B p /\ B `<=` A].
  exact: Topological.ax2.
by rewrite predeqE => A; split=> [[B [? []]]|[B [[]]]]; exists B.
Qed.

Notation "D ^o" := (locally^~ D) : classical_set_scope.

Lemma openE : open = [set A : set T | A `<=` A^o].
Proof. exact: Topological.ax3. Qed.

Lemma locally_singleton (p : T) (A : set T) : locally p A -> A p.
Proof. by rewrite locallyE => - [? [[_ ?]]]; apply. Qed.

Lemma locally_locally (p : T) (A : set T) : locally p A -> locally p A^o.
Proof.
rewrite locallyE /neigh openE => - [B [[Bop Bp] sBA]].
by exists B; split=> // q Bq; apply: filterS sBA _; apply: Bop.
Qed.

Lemma open0 : open set0.
Proof. by rewrite openE. Qed.

Lemma openT : open setT.
Proof. by rewrite openE => ??; apply: filterT. Qed.

Lemma openI (A B : set T) : open A -> open B -> open (A `&` B).
Proof.
rewrite openE => Aop Bop p [Ap Bp].
by apply: filterI; [apply: Aop|apply: Bop].
Qed.

Lemma open_bigU (I : Type) (f : I -> set T) :
  (forall i, open (f i)) -> open (\bigcup_i f i).
Proof.
by rewrite openE => fop p [i _ /fop]; apply: filterS => ??; exists i.
Qed.

Lemma openU (A B : set T) : open A -> open B -> open (A `|` B).
Proof.
by rewrite openE => Aop Bop p [/Aop|/Bop]; apply: filterS => ??; [left|right].
Qed.

Lemma openP (A B : set T) : open A -> (A `<=` B) -> (A `<=` B^o).
Proof.
by rewrite openE => Aop sAB p Ap; apply: filterS sAB _; apply: Aop.
Qed.
Definition locally_open := @openP.

Lemma neighT (p : T) : neigh p setT.
Proof. by split=> //; apply: openT. Qed.

Lemma neighI (p : T) (A B : set T) :
  neigh p A -> neigh p B -> neigh p (A `&` B).
Proof. by move=> [Aop Ap] [Bop Bp]; split; [apply: openI|split]. Qed.

Lemma neigh_locally (p : T) (A : set T) : neigh p A -> locally p A.
Proof. by rewrite locallyE => p_A; exists A; split. Qed.

End Topological1.

Notation continuous f := (forall x, f%function @ x --> f%function x).

Lemma continuousP (S T : topologicalType) (f : S -> T) :
  continuous f <-> forall A, open A -> open (f @^-1` A).
Proof.
split=> fcont; first by rewrite !openE => A Aop ? /Aop /fcont.
move=> s A; rewrite locally_simpl /= !locallyE => - [B [[Bop Bfs] sBA]].
by exists (f @^-1` B); split; [split=> //; apply/fcont|move=> ? /sBA].
Qed.

Lemma near_join (T : topologicalType) (x : T) (P : set T) :
  (\near x, P x) -> \near x, \near x, P x.
Proof. exact: locally_locally. Qed.

Lemma near_bind (T : topologicalType) (P Q : set T) (x : T) :
  (\near x, (\near x, P x) -> Q x) -> (\near x, P x) -> \near x, Q x.
Proof.
move=> PQ xP; begin_near y.
  by apply: (near PQ y) => //; apply: (near (near_join xP) y).
by end_near.
Qed.

(** ** Topology defined by a filter *)

Section TopologyOfFilter.

Context {T : Type} {loc : T -> set (set T)}.
Hypothesis (loc_filter : forall p : T, ProperFilter (loc p)).
Hypothesis (loc_singleton : forall (p : T) (A : set T), loc p A -> A p).
Hypothesis (loc_loc : forall (p : T) (A : set T), loc p A -> loc p (loc^~ A)).

Definition open_of_locally := [set A : set T | A `<=` loc^~ A].

Program Definition topologyOfFilterMixin : Topological.mixin_of loc :=
  @Topological.Mixin T loc open_of_locally _ _ _.
Next Obligation.
rewrite predeqE => A; split=> [p_A|]; last first.
  by move=> [B [Bop [Bp sBA]]]; apply: filterS sBA _; apply: Bop.
exists (loc^~ A); split; first by move=> ?; apply: loc_loc.
by split => // q /loc_singleton.
Qed.

End TopologyOfFilter.

(** ** Topology defined by open sets *)

Section TopologyOfOpen.

Variable (T : Type) (op : set T -> Prop).
Hypothesis (opT : op setT).
Hypothesis (opI : forall (A B : set T), op A -> op B -> op (A `&` B)).
Hypothesis (op_bigU : forall (I : Type) (f : I -> set T),
  (forall i, op (f i)) -> op (\bigcup_i f i)).

Definition locally_of_open (p : T) (A : set T) :=
  exists B, op B /\ B p /\ B `<=` A.

Program Definition topologyOfOpenMixin : Topological.mixin_of locally_of_open :=
  @Topological.Mixin T locally_of_open op _ _ _.
Next Obligation.
apply Build_ProperFilter.
  by move=> A [B [_ [Bp sBA]]]; exists p; apply: sBA.
split; first by exists setT.
  move=> A B [C [Cop [Cp sCA]]] [D [Dop [Dp sDB]]].
  exists (C `&` D); split; first exact: opI.
  by split=> // q [/sCA Aq /sDB Bq].
move=> A B sAB [C [Cop [p_C sCA]]].
by exists C; split=> //; split=> //; apply: subset_trans sAB.
Qed.
Next Obligation.
rewrite predeqE => A; split=> [Aop p Ap|Aop].
  by exists A; split=> //; split.
suff -> : A = \bigcup_(B : {B : set T & op B /\ B `<=` A}) projT1 B.
  by apply: op_bigU => B; have [] := projT2 B.
rewrite predeqE => p; split=> [|[B _ Bp]]; last by have [_] := projT2 B; apply.
by move=> /Aop [B [Bop [Bp sBA]]]; exists (existT _ B (conj Bop sBA)).
Qed.

End TopologyOfOpen.

(** ** Topology defined by a base of open sets *)

Section TopologyOfBase.

Definition open_from I T (D : set I) (b : I -> set T) :=
  [set \bigcup_(i in D') b i | D' in subset^~ D].

Lemma open_fromT I T (D : set I) (b : I -> set T) :
  \bigcup_(i in D) b i = setT -> open_from D b setT.
Proof. by move=> ?; exists D. Qed.

Variable (I : pointedType) (T : Type) (D : set I) (b : I -> (set T)).
Hypothesis (b_cover : \bigcup_(i in D) b i = setT).
Hypothesis (b_join : forall i j t, D i -> D j -> b i t -> b j t ->
  exists k, D k /\ b k t /\ b k `<=` b i `&` b j).

Program Definition topologyOfBaseMixin :=
  @topologyOfOpenMixin _ (open_from D b) (open_fromT b_cover) _ _.
Next Obligation.
have [DA sDAD AeUbA] := H; have [DB sDBD BeUbB] := H0.
have ABU : forall t, (A `&` B) t ->
  exists it, D it /\ b it t /\ b it `<=` A `&` B.
  move=> t [At Bt].
  have [iA [DiA [biAt sbiA]]] : exists i, D i /\ b i t /\ b i `<=` A.
    move: At; rewrite -AeUbA => - [i DAi bit]; exists i.
    by split; [apply: sDAD|split=> // ?; exists i].
  have [iB [DiB [biBt sbiB]]] : exists i, D i /\ b i t /\ b i `<=` B.
    move: Bt; rewrite -BeUbB => - [i DBi bit]; exists i.
    by split; [apply: sDBD|split=> // ?; exists i].
  have [i [Di [bit sbiAB]]] := b_join DiA DiB biAt biBt.
  by exists i; split=> //; split=> // s /sbiAB [/sbiA ? /sbiB].
set Dt := fun t => [set it | D it /\ b it t /\ b it `<=` A `&` B].
exists [set get (Dt t) | t in A `&` B].
  by move=> _ [t ABt <-]; have /ABU/getPex [] := ABt.
rewrite predeqE => t; split=> [[_ [s ABs <-] bDtst]|ABt].
  by have /ABU/getPex [_ [_]] := ABs; apply.
by exists (get (Dt t)); [exists t| have /ABU/getPex [? []]:= ABt].
Qed.
Next Obligation.
set fop := fun j => [set Dj | Dj `<=` D /\ f j = \bigcup_(i in Dj) b i].
exists (\bigcup_j get (fop j)).
  move=> i [j _ fopji].
  suff /getPex [/(_ _ fopji)] : exists Dj, fop j Dj by [].
  by have [Dj] := H j; exists Dj.
rewrite predeqE => t; split=> [[i [j _ fopji bit]]|[j _]].
  exists j => //; suff /getPex [_ ->] : exists Dj, fop j Dj by exists i.
  by have [Dj] := H j; exists Dj.
have /getPex [_ ->] : exists Dj, fop j Dj by have [Dj] := H j; exists Dj.
by move=> [i]; exists i => //; exists j.
Qed.

End TopologyOfBase.

(** ** Topology defined by a subbase of open sets *)

Definition finI_from (I : choiceType) T (D : set I) (f : I -> set T) :=
  [set \bigcap_(i in [set i | i \in D']) f i |
    D' in [set A : {fset I} | {subset A <= D}]].

Lemma finI_from_cover (I : choiceType) T (D : set I) (f : I -> set T) :
  \bigcup_(A in finI_from D f) A = setT.
Proof.
rewrite predeqE => t; split=> // _; exists setT => //.
by exists fset0 => //; rewrite predeqE.
Qed.

Lemma finI_from1 (I : choiceType) T (D : set I) (f : I -> set T) i :
  D i -> finI_from D f (f i).
Proof.
move=> Di; exists [fset i]%fset.
  by move=> ?; rewrite in_fsetE in_setE => /eqP->.
rewrite predeqE => t; split=> [|fit]; first by apply; rewrite in_fsetE.
by move=> ?; rewrite in_fsetE => /eqP->.
Qed.

Section TopologyOfSubbase.

Local Open Scope fset_scope.
Local Open Scope classical_set_scope.

Variable (I : pointedType) (T : Type) (D : set I) (b : I -> set T).

Program Definition topologyOfSubbaseMixin :=
  @topologyOfBaseMixin _ _ (finI_from D b) id (finI_from_cover D b) _.
Next Obligation.
move: i j t H H0 H1 H2 => A B t [DA sDAD AeIbA] [DB sDBD BeIbB] At Bt.
exists (A `&` B); split; last by split.
exists (DA `|` DB)%fset; first by move=> i /fsetUP [/sDAD|/sDBD].
rewrite predeqE => s; split=> [Ifs|[As Bs] i /fsetUP].
  split; first by rewrite -AeIbA => i DAi; apply: Ifs; rewrite in_fsetE DAi.
  by rewrite -BeIbB => i DBi; apply: Ifs; rewrite in_fsetE DBi orbC.
by move=> [DAi|DBi];
  [have := As; rewrite -AeIbA; apply|have := Bs; rewrite -BeIbB; apply].
Qed.

End TopologyOfSubbase.

(** ** Topology on vectors *)

Section rV_Topology.

Variables (n : nat) (T : topologicalType).

Implicit Types p : 'rV[T]_n.

Lemma rV_loc_filter p : ProperFilter (locally p).
Proof.
apply: (filter_from_proper (filter_from_filter _ _)) => [|P Q p_P p_Q|P p_P].
- by exists (fun i => setT) => ?; apply: filterT.
- exists (fun i => P i `&` Q i) => [?|vx PQvx]; first exact: filterI.
  by split=> i; have [] := PQvx i.
- exists (\row_i get (P i)) => i; rewrite mxE; apply: getPex.
  exact: filter_ex (p_P i).
Qed.

Lemma rV_loc_singleton p (A : set 'rV[T]_n) : locally p A -> A p.
Proof. by move=> [P p_P]; apply=> i; apply: locally_singleton. Qed.

Lemma rV_loc_loc p (A : set 'rV[T]_n) : locally p A -> locally p (locally^~ A).
Proof.
move=> [P p_P sPA]; exists (fun i => locally^~ (P i)).
  by move=> ?; apply: locally_locally.
by move=> ??; exists P.
Qed.

Definition rV_topologicalTypeMixin :=
  topologyOfFilterMixin rV_loc_filter rV_loc_singleton rV_loc_loc.

Canonical rV_topologicalType :=
  TopologicalType 'rV[T]_n rV_topologicalTypeMixin.

End rV_Topology.

(** ** Topology on the product of two spaces *)

Section Prod_Topology.

Context {T U : topologicalType}.

Let prod_loc (p : T * U) := filter_prod (locally p.1) (locally p.2).

Lemma prod_loc_filter (p : T * U) : ProperFilter (prod_loc p).
Proof. exact: filter_prod_proper. Qed.

Lemma prod_loc_singleton (p : T * U) (A : set (T * U)) : prod_loc p A -> A p.
Proof.
by move=> [QR [/locally_singleton Qp1 /locally_singleton Rp2]]; apply.
Qed.

Lemma prod_loc_loc (p : T * U) (A : set (T * U)) :
  prod_loc p A -> prod_loc p (prod_loc^~ A).
Proof.
move=> [QR [/locally_locally p1_Q /locally_locally p2_R] sQRA].
by exists (locally^~ QR.1, locally^~ QR.2) => // ??; exists QR.
Qed.

Definition prod_topologicalTypeMixin :=
  topologyOfFilterMixin prod_loc_filter prod_loc_singleton prod_loc_loc.

Canonical prod_topologicalType :=
  TopologicalType (T * U) prod_topologicalTypeMixin.

End Prod_Topology.

(** ** Weak topology by a function *)

Section Weak_Topology.

Variable (S : pointedType) (T : topologicalType) (f : S -> T).

Definition wopen := [set f @^-1` A | A in open].

Lemma wopT : wopen setT.
Proof. by exists setT => //; apply: openT. Qed.

Lemma wopI (A B : set S) : wopen A -> wopen B -> wopen (A `&` B).
Proof.
by move=> [C Cop <-] [D Dop <-]; exists (C `&` D) => //; apply: openI.
Qed.

Lemma wop_bigU (I : Type) (g : I -> set S) :
  (forall i, wopen (g i)) -> wopen (\bigcup_i g i).
Proof.
move=> gop.
set opi := fun i => [set Ui | open Ui /\ g i = f @^-1` Ui].
exists (\bigcup_i get (opi i)).
  apply: open_bigU => i.
  by have /getPex [] : exists U, opi i U by have [U] := gop i; exists U.
have g_preim i : g i = f @^-1` (get (opi i)).
  by have /getPex [] : exists U, opi i U by have [U] := gop i; exists U.
rewrite predeqE => s; split=> [[i _]|[i _]]; last by rewrite g_preim; exists i.
by rewrite -[_ _]/((f @^-1` _) _) -g_preim; exists i.
Qed.

Definition weak_topologicalTypeMixin := topologyOfOpenMixin wopT wopI wop_bigU.

Let S_filteredClass := Filtered.Class (Pointed.class S) (locally_of_open wopen).
Definition weak_topologicalType :=
  Topological.Pack (@Topological.Class _ S_filteredClass
    weak_topologicalTypeMixin) S.

Lemma weak_continuous : continuous (f : weak_topologicalType -> T).
Proof. by apply/continuousP => A ?; exists A. Qed.

Lemma flim_image (F : set (set S)) (s : S) :
  Filter F -> f @` setT = setT ->
  F --> (s : weak_topologicalType) <-> [set f @` A | A in F] --> (f s).
Proof.
move=> FF fsurj; split=> [cvFs|cvfFfs].
  move=> A /weak_continuous [B [Bop [Bs sBAf]]].
  have /cvFs FB: locally (s : weak_topologicalType) B by apply: neigh_locally.
  rewrite locally_simpl; exists (f @^-1` A); first exact: filterS FB.
  exact: image_preimage.
move=> A /= [_ [[B Bop <-] [Bfs sBfA]]].
have /cvfFfs [C FC fCeB] : locally (f s) B by rewrite locallyE; exists B; split.
rewrite locally_filterE; apply: filterS FC.
by apply: subset_trans sBfA; rewrite -fCeB; apply: preimage_image.
Qed.

End Weak_Topology.

(** ** Supremum of a family of topologies *)

Section Sup_Topology.

Variable (T : pointedType) (I : Type) (Tc : I -> Topological.class_of T).

Let TS := fun i => Topological.Pack (Tc i) T.

Definition sup_subbase := \bigcup_i (@open (TS i) : set (set T)).

Definition sup_topologicalTypeMixin := topologyOfSubbaseMixin sup_subbase id.

Definition sup_topologicalType :=
  Topological.Pack (@Topological.Class _ (Filtered.Class (Pointed.class T) _)
  sup_topologicalTypeMixin) T.

Lemma flim_sup (F : set (set T)) (t : T) :
  Filter F -> F --> (t : sup_topologicalType) <-> forall i, F --> (t : TS i).
Proof.
move=> Ffilt; split=> cvFt.
  move=> i A /=; rewrite (@locallyE (TS i)) => - [B [[Bop Bt] sBA]].
  apply: cvFt; exists B; split=> //; exists [set B]; last first.
    by rewrite predeqE => ?; split=> [[_ ->]|] //; exists B.
  move=> _ ->; exists [fset B]%fset.
    by move=> ?; rewrite in_fsetE in_setE => /eqP->; exists i.
  by rewrite predeqE=> ?; split=> [|??]; [apply|]; rewrite in_fsetE // =>/eqP->.
move=> A /=; rewrite (@locallyE sup_topologicalType).
move=> [_ [[[B sB <-] [C BC Ct]] sUBA]].
rewrite locally_filterE; apply: filterS sUBA _; apply: (@filterS _ _ _ C).
  by move=> ??; exists C.
have /sB [D sD IDeC] := BC; rewrite -IDeC; apply: filter_bigI => E DE.
have /sD := DE; rewrite in_setE => - [i _]; rewrite openE => Eop.
by apply: (cvFt i); apply: Eop; move: Ct; rewrite -IDeC => /(_ _ DE).
Qed.

End Sup_Topology.

(** ** Product topology *)

Section Product_Topology.

Variable (I : Type) (T : I -> topologicalType).

Definition dep_arrow_choiceClass :=
  Choice.Class (Equality.class (dep_arrow_eqType T)) gen_choiceMixin.

Definition dep_arrow_pointedType :=
  Pointed.Pack (Pointed.Class dep_arrow_choiceClass (fun i => @point (T i)))
  (forall i, T i).

Definition product_topologicalType :=
  sup_topologicalType (fun i => Topological.class
    (weak_topologicalType (fun f : dep_arrow_pointedType => f i))).

End Product_Topology.

(** * Uniform spaces defined using balls *)

Definition locally_ {T T'} (ball : T -> R -> set T') (x : T) :=
   @filter_from R _ [set x | 0 < x] (ball x).

Lemma locally_E {T T'} (ball : T -> R -> set T') x :
  locally_ ball x = @filter_from R _ [set x : R | 0 < x] (ball x).
Proof. by []. Qed.

Module Uniform.

Record mixin_of (M : Type) (locally : M -> set (set M)) := Mixin {
  ball : M -> R -> M -> Prop ;
  ax1 : forall x (e : R), 0 < e -> ball x e x ;
  ax2 : forall x y (e : R), ball x e y -> ball y e x ;
  ax3 : forall x y z e1 e2, ball x e1 y -> ball y e2 z -> ball x (e1 + e2) z;
  ax4 : locally = locally_ ball
}.

Record class_of (M : Type) := Class {
  base : Topological.class_of M;
  mixin : mixin_of (Filtered.locally_op base)
}.

Section ClassDef.

Structure type := Pack { sort; _ : class_of sort ; _ : Type }.
Local Coercion sort : type >-> Sortclass.
Variables (T : Type) (cT : type).
Definition class := let: Pack _ c _ := cT return class_of cT in c.

Definition clone c of phant_id class c := @Pack T c T.
Let xT := let: Pack T _ _ := cT in T.
Notation xclass := (class : class_of xT).
Local Coercion base : class_of >-> Topological.class_of.
Local Coercion mixin : class_of >-> mixin_of.

Definition pack loc (m : @mixin_of T loc) :=
  fun bT (b : Topological.class_of T) of phant_id (@Topological.class bT) b =>
  fun m'   of phant_id m (m' : @mixin_of T (Filtered.locally_op b)) =>
  @Pack T (@Class _ b m') T.

Definition eqType := @Equality.Pack cT xclass xT.
Definition choiceType := @Choice.Pack cT xclass xT.
Definition pointedType := @Pointed.Pack cT xclass xT.
Definition filteredType := @Filtered.Pack cT cT xclass xT.
Definition topologicalType := @Topological.Pack cT xclass xT.

End ClassDef.

Module Exports.

Coercion sort : type >-> Sortclass.
Coercion base : class_of >-> Topological.class_of.
Coercion mixin : class_of >-> mixin_of.
Coercion eqType : type >-> Equality.type.
Canonical eqType.
Coercion choiceType : type >-> Choice.type.
Canonical choiceType.
Coercion pointedType : type >-> Pointed.type.
Canonical pointedType.
Coercion filteredType : type >-> Filtered.type.
Canonical filteredType.
Coercion topologicalType : type >-> Topological.type.
Canonical topologicalType.
Notation uniformType := type.
Notation UniformType T m := (@pack T _ m _ _ idfun _ idfun).
Notation UniformMixin := Mixin.
Notation "[ 'uniformType' 'of' T 'for' cT ]" :=  (@clone T cT _ idfun)
  (at level 0, format "[ 'uniformType'  'of'  T  'for'  cT ]") : form_scope.
Notation "[ 'uniformType' 'of' T ]" := (@clone T _ _ id)
  (at level 0, format "[ 'uniformType'  'of'  T ]") : form_scope.

End Exports.

End Uniform.

Export Uniform.Exports.

Section UniformTopology.

Lemma my_ball_le (M : Type) (loc : M -> set (set M))
  (m : Uniform.mixin_of loc) :
  forall (x : M) (e1 e2 : R), e1 <= e2 ->
  forall (y : M), Uniform.ball m x e1 y -> Uniform.ball m x e2 y.
Proof.
move=> x e1 e2 le12 y xe1_y.
move: le12; rewrite ler_eqVlt => /orP [/eqP <- //|].
rewrite -subr_gt0 => lt12.
rewrite -[e2](subrK e1); apply: Uniform.ax3 xe1_y.
suff : Uniform.ball m x (PosNum lt12)%:num x by [].
exact: Uniform.ax1.
Qed.

Program Definition uniform_TopologicalTypeMixin (T : Type)
  (loc : T -> set (set T)) (m : Uniform.mixin_of loc) :
  Topological.mixin_of loc := topologyOfFilterMixin _ _ _.
Next Obligation.
rewrite (Uniform.ax4 m) locally_E; apply filter_from_proper; last first.
  move=> e egt0; exists p; suff : Uniform.ball m p (PosNum egt0)%:num p by [].
  exact: Uniform.ax1.
apply: filter_from_filter; first by exists 1%:pos%:num.
move=> e1 e2 e1gt0 e2gt0; exists (Num.min e1 e2).
  by have := min_pos_gt0 (PosNum e1gt0) (PosNum e2gt0).
by move=> q pmin_q; split; apply: my_ball_le pmin_q;
  rewrite ler_minl lerr // orbC.
Qed.
Next Obligation.
move: H; rewrite (Uniform.ax4 m) locally_E => - [e egt0]; apply.
by have : Uniform.ball m p (PosNum egt0)%:num p by exact: Uniform.ax1.
Qed.
Next Obligation.
move: H; rewrite (Uniform.ax4 m) locally_E => - [e egt0 pe_A].
exists ((PosNum egt0)%:num / 2) => // q phe_q.
rewrite locally_E; exists ((PosNum egt0)%:num / 2) => // r qhe_r.
by apply: pe_A; rewrite [e]splitr; apply: Uniform.ax3 qhe_r.
Qed.

End UniformTopology.

Definition ball {M : uniformType} := Uniform.ball (Uniform.class M).

Lemma locally_ballE {M : uniformType} : locally_ (@ball M) = locally.
Proof. by case: M=> [?[?[]]]. Qed.

Lemma filter_from_ballE {M : uniformType} x :
  @filter_from R _ [set x : R | 0 < x] (@ball M x) = locally x.
Proof. by rewrite -locally_ballE. Qed.

Module Export LocallyBall.
Definition locally_simpl := (locally_simpl,@filter_from_ballE,@locally_ballE).
End LocallyBall.

Lemma locallyP {M : uniformType} (x : M) P :
  locally x P <-> locally_ ball x P.
Proof. by rewrite locally_simpl. Qed.

Module AbsRing.

Record mixin_of (D : ringType) := Mixin {
  abs : D -> R;
  ax1 : abs 0 = 0 ;
  ax2 : abs (- 1) = 1 ;
  ax3 : forall x y : D, abs (x + y) <= abs x + abs y ;
  ax4 : forall x y : D, abs (x * y) <= abs x * abs y ;
  ax5 : forall x : D, abs x = 0 -> x = 0
}.

Section ClassDef.

Record class_of (K : Type) := Class {
  base : Num.NumDomain.class_of K ;
  mixin : mixin_of (Num.NumDomain.Pack base K)
}.
Local Coercion base : class_of >-> Num.NumDomain.class_of.
Local Coercion mixin : class_of >-> mixin_of.

Structure type := Pack { sort; _ : class_of sort ; _ : Type }.
Local Coercion sort : type >-> Sortclass.

Variables (T : Type) (cT : type).
Definition class := let: Pack _ c _ := cT return class_of cT in c.
Let xT := let: Pack T _ _ := cT in T.
Notation xclass := (class : class_of xT).
Definition clone c of phant_id class c := @Pack T c T.
Definition pack b0 (m0 : mixin_of (@Num.NumDomain.Pack T b0 T)) :=
  fun bT b & phant_id (Num.NumDomain.class bT) b =>
  fun    m & phant_id m0 m => Pack (@Class T b m) T.

Definition eqType := @Equality.Pack cT xclass xT.
Definition choiceType := @Choice.Pack cT xclass xT.
Definition zmodType := @GRing.Zmodule.Pack cT xclass xT.
Definition ringType := @GRing.Ring.Pack cT xclass xT.
Definition comRingType := @GRing.ComRing.Pack cT xclass xT.
Definition unitRingType := @GRing.UnitRing.Pack cT xclass xT.
Definition comUnitRingType := @GRing.ComUnitRing.Pack cT xclass xT.
Definition idomainType := @GRing.IntegralDomain.Pack cT xclass xT.
Definition numDomainType := @Num.NumDomain.Pack cT xclass xT.

End ClassDef.

Module Exports.

Coercion base : class_of >-> Num.NumDomain.class_of.
Coercion mixin : class_of >-> mixin_of.
Coercion sort : type >-> Sortclass.
Coercion eqType : type >-> Equality.type.
Canonical eqType.
Coercion choiceType : type >-> Choice.type.
Canonical choiceType.
Coercion zmodType : type >-> GRing.Zmodule.type.
Canonical zmodType.
Coercion ringType : type >-> GRing.Ring.type.
Canonical ringType.
Coercion comRingType : type >-> GRing.ComRing.type.
Canonical comRingType.
Coercion unitRingType : type >-> GRing.UnitRing.type.
Canonical unitRingType.
Coercion comUnitRingType : type >-> GRing.ComUnitRing.type.
Canonical comUnitRingType.
Coercion idomainType : type >-> GRing.IntegralDomain.type.
Canonical idomainType.
Coercion numDomainType : type >-> Num.NumDomain.type.
Canonical numDomainType.
Notation AbsRingMixin := Mixin.
Notation AbsRingType T m := (@pack T _ m _ _ id _ id).
Notation "[ 'absRingType' 'of' T 'for' cT ]" := (@clone T cT _ idfun)
  (at level 0, format "[ 'absRingType'  'of'  T  'for'  cT ]") : form_scope.
Notation "[ 'absRingType' 'of' T ]" := (@clone T _ _ id)
  (at level 0, format "[ 'absRingType'  'of'  T ]") : form_scope.
Notation absRingType := type.

End Exports.

End AbsRing.

Export AbsRing.Exports.

Definition abs {K : absRingType} : K -> R := @AbsRing.abs _ (AbsRing.class K).
Notation "`| x |" := (abs x%R) : R_scope.
Notation "`| x |" := (abs x%R) : real_scope.

Section AbsRing1.

Context {K : absRingType}.
Implicit Types x : K.

Lemma absr0 : `|0 : K| = 0. Proof. exact: AbsRing.ax1. Qed.

Lemma absrN1: `|- 1 : K| = 1.
Proof. exact: AbsRing.ax2. Qed.

Lemma ler_abs_add (x y : K) :  `|x + y| <= `|x|%real + `|y|%real.
Proof. exact: AbsRing.ax3. Qed.

Lemma absrM (x y : K) : `|x * y| <= `|x|%real * `|y|%real.
Proof. exact: AbsRing.ax4. Qed.

Lemma absr0_eq0 (x : K) : `|x| = 0 -> x = 0.
Proof. exact: AbsRing.ax5. Qed.

Lemma absrN x : `|- x| = `|x|.
Proof.
gen have le_absN1 : x / `|- x| <= `|x|.
  by rewrite -mulN1r (ler_trans (absrM _ _)) //= absrN1 mul1r.
by apply/eqP; rewrite eqr_le le_absN1 /= -{1}[x]opprK le_absN1.
Qed.

Lemma absrB (x y : K) : `|x - y| = `|y - x|.
Proof. by rewrite -absrN opprB. Qed.

Lemma absr1 : `|1 : K| = 1. Proof. by rewrite -absrN absrN1. Qed.

Lemma absr_ge0 x : 0 <= `|x|.
Proof.
rewrite -(@pmulr_rge0 _ 2) // mulr2n mulrDl !mul1r.
by rewrite -{2}absrN (ler_trans _ (ler_abs_add _ _)) // subrr absr0.
Qed.

Lemma absr_eq0 x : (`|x| == 0) = (x == 0).
Proof. by apply/eqP/eqP=> [/absr0_eq0//|->]; rewrite absr0. Qed.

Lemma absr1_gt0 : `|1 : K| > 0.
Proof. by rewrite ltr_def absr1 oner_eq0 /=. Qed.

Lemma absrX x n : `|x ^+ n| <= `|x|%real ^+ n.
Proof.
elim: n => [|n IH]; first  by rewrite !expr0 absr1.
by rewrite !exprS (ler_trans (absrM _ _)) // ler_pmul // absr_ge0.
Qed.

End AbsRing1.
Hint Resolve absr_ge0.
Hint Resolve absr1_gt0.

Definition ball_ (V : zmodType) (norm : V -> R) (x : V)
  (e : R) := [set y | norm (x - y) < e].
Arguments ball_ {V} norm x e%R y /.

Section AbsRing_UniformSpace.

Context {K : absRingType}.

Definition AbsRing_ball := ball_ (@abs K).

Lemma AbsRing_ball_center (x : K) (e : R) : 0 < e -> AbsRing_ball x e x.
Proof. by rewrite /AbsRing_ball /= subrr absr0. Qed.

Lemma AbsRing_ball_sym (x y : K) (e : R) :
  AbsRing_ball x e y -> AbsRing_ball y e x.
Proof. by rewrite /AbsRing_ball /= absrB. Qed.

(* :TODO: to math-comp *)
Lemma subr_trans (M : zmodType) (z x y : M) : x - y = (x - z) + (z - y).
Proof. by rewrite addrA addrNK. Qed.

Lemma AbsRing_ball_triangle (x y z : K) (e1 e2 : R) :
  AbsRing_ball x e1 y -> AbsRing_ball y e2 z -> AbsRing_ball x (e1 + e2) z.
Proof.
rewrite /AbsRing_ball /= => xy yz.
by rewrite (subr_trans y) (ler_lt_trans (ler_abs_add _ _)) ?ltr_add.
Qed.

Definition AbsRingUniformMixin :=
  UniformMixin AbsRing_ball_center AbsRing_ball_sym AbsRing_ball_triangle erefl.

End AbsRing_UniformSpace.

(* :TODO: DANGEROUS ! Must change this to include uniform type et al inside absring *)
Coercion absRing_pointedType (K : absRingType) := PointedType K 0.
Canonical absRing_pointedType.
Coercion absRing_filteredType (K : absRingType) :=
   FilteredType K K (locally_ AbsRing_ball).
Canonical absRing_filteredType.
Coercion absRing_topologicalType (K : absRingType) :=
  TopologicalType K (uniform_TopologicalTypeMixin AbsRingUniformMixin).
Canonical absRing_topologicalType.
Coercion absRing_UniformType (K : absRingType) := UniformType K AbsRingUniformMixin.
Canonical absRing_UniformType.

Reserved Notation  "`|[ x ]|" (at level 0, x at level 99, format "`|[ x ]|").

Program Definition R_AbsRingMixin :=
 @AbsRing.Mixin _ normr (normr0 _) (normrN1 _) (@ler_norm_add _) _ (@normr0_eq0 _).
Next Obligation. by rewrite normrM. Qed.
Canonical R_absRingType := AbsRingType R R_AbsRingMixin.

Canonical R_pointedType := [pointedType of R for R_absRingType].
Canonical R_filteredType := [filteredType R of R for R_absRingType].
Canonical R_topologicalType := [topologicalType of R for R_absRingType].
Canonical R_UniformSpace := [uniformType of R for R_absRingType].
Canonical Ro_pointedType := [pointedType of R^o for R_absRingType].
Canonical Ro_filteredType := [filteredType R^o of R^o for R_absRingType].
Canonical Ro_topologicalType := [topologicalType of R^o for R_absRingType].
Canonical Ro_UniformSpace := [uniformType of R^o for R_absRingType].

Section uniformType1.
Context {M : uniformType}.

Lemma ball_center (x : M) (e : posreal) : ball x e%:num x.
Proof. exact: Uniform.ax1. Qed.
Hint Resolve ball_center.

Lemma ballxx (x : M) (e : R) : (0 < e)%R -> ball x e x.
Proof. by move=> e_gt0; apply: ball_center (PosNum e_gt0). Qed.

Lemma ball_sym (x y : M) (e : R) : ball x e y -> ball y e x.
Proof. exact: Uniform.ax2. Qed.

Lemma ball_triangle (y x z : M) (e1 e2 : R) :
  ball x e1 y -> ball y e2 z -> ball x (e1 + e2)%R z.
Proof. exact: Uniform.ax3. Qed.

Lemma ball_split (z x y : M) (e : R) :
  ball x (e / 2)%R z -> ball z (e / 2)%R y -> ball x e y.
Proof. by move=> /ball_triangle h /h; rewrite -splitr. Qed.

Lemma ball_splitr (z x y : M) (e : R) :
  ball z (e / 2)%R x -> ball z (e / 2)%R y -> ball x e y.
Proof. by move=> /ball_sym /ball_split; apply. Qed.

Lemma ball_splitl (z x y : M) (e : R) :
  ball x (e / 2) z -> ball y (e / 2) z -> ball x e y.
Proof. by move=> bxz /ball_sym /(ball_split bxz). Qed.

Lemma ball_ler (x : M) (e1 e2 : R) : e1 <= e2 -> ball x e1 `<=` ball x e2.
Proof.
move=> le12 y; case: ltrgtP le12 => [//|lte12 _|->//].
by rewrite -[e2](subrK e1); apply/ball_triangle/ballxx; rewrite subr_gt0.
Qed.

Lemma ball_le (x : M) (e1 e2 : R) : (e1 <= e2)%coqR -> ball x e1 `<=` ball x e2.
Proof. by move=> /RleP/ball_ler. Qed.

Definition close (x y : M) : Prop := forall eps : posreal, ball x eps%:num y.

Lemma close_refl (x : M) : close x x. Proof. by []. Qed.

Lemma close_sym (x y : M) : close x y -> close y x.
Proof. by move=> ??; apply: ball_sym. Qed.

Lemma close_trans (x y z : M) : close x y -> close y z -> close x z.
Proof. by move=> cxy cyz eps; apply: ball_split (cxy _) (cyz _). Qed.

Lemma close_limxx (x y : M) : close x y -> x --> y.
Proof.
move=> cxy P /= /locallyP /= [_/posnumP [eps] epsP].
apply/locallyP; exists (eps%:num / 2) => // z bxz.
by apply: epsP; apply: ball_splitr (cxy _) bxz.
Qed.

End uniformType1.

Hint Resolve ball_center.
Hint Resolve close_refl.

(** ** Specific uniform spaces *)

(** locally *)

Section Locally.
Context {T : uniformType}.

Lemma locally_ball (x : T) (eps : posreal) : locally x (ball x eps%:num).
Proof. by apply/locallyP; exists eps%:num. Qed.
Hint Resolve locally_ball.

Lemma forallN {U} (P : set U) : (forall x, ~ P x) = ~ exists x, P x.
Proof. (*boolP*)
rewrite propeqE; split; first by move=> fP [x /fP].
by move=> nexP x Px; apply: nexP; exists x.
Qed.

Lemma NNP (P : Prop) : (~ ~ P) <-> P. (*boolP*)
Proof. by split=> [nnp|p /(_ p)//]; have [//|/nnp] := asboolP P. Qed.

Lemma eqNNP (P : Prop) : (~ ~ P) = P. (*boolP*)
Proof. by rewrite propeqE NNP. Qed.

Lemma existsN {U} (P : set U) : (exists x, ~ P x) = ~ forall x, P x. (*boolP*)
Proof.
rewrite propeqE; split=> [[x Px] Nall|Nall]; first exact: Px.
by apply/NNP; rewrite -forallN => allP; apply: Nall => x; apply/NNP.
Qed.

Lemma ex_ball_sig (x : T) (P : set T) :
  ~ (forall eps : posreal, ~ (ball x eps%:num `<=` ~` P)) ->
    {d : posreal | ball x d%:num `<=` ~` P}.
Proof.
rewrite forallN eqNNP => exNP.
pose D := [set d : R | d > 0 /\ ball x d `<=` ~` P].
have [|d_gt0] := @getPex _ D; last by exists (PosNum d_gt0).
by move: exNP => [e eP]; exists e%:num.
Qed.

Lemma locallyN (x : T) (P : set T) :
  ~ (forall eps : posreal, ~ (ball x eps%:num `<=` ~` P)) ->
  locally x (~` P).
Proof. by move=> /ex_ball_sig [e] ?; apply/locallyP; exists e%:num. Qed.

Lemma locallyN_ball (x : T) (P : set T) :
  locally x (~` P) -> {d : posreal | ball x d%:num `<=` ~` P}.
Proof.
move=> /locallyP xNP; apply: ex_ball_sig.
by have [_ /posnumP[e] eP /(_ _ eP)] := xNP.
Qed.

Lemma locally_ex (x : T) (P : T -> Prop) : locally x P ->
  {d : posreal | forall y, ball x d%:num y -> P y}.
Proof.
move=> /locallyP xP.
pose D := [set d : R | d > 0 /\ forall y, ball x d y -> P y].
have [|d_gt0 dP] := @getPex _ D; last by exists (PosNum d_gt0).
by move: xP => [e bP]; exists (e : R).
Qed.

Lemma flim_close {F} {FF : ProperFilter F} (x y : T) :
  F --> x -> F --> y -> close x y.
Proof.
move=> Fx Fy e; have_near F z; [by apply: (@ball_splitl _ z); near z|].
by end_near; [apply/Fx/locally_ball|apply/Fy/locally_ball].
Qed.

Lemma flimx_close (x y : T) : x --> y -> close x y.
Proof. exact: flim_close. Qed.

End Locally.
Hint Resolve locally_ball.

Section prod_Uniform.

Context {U V : uniformType}.
Implicit Types (x y : U * V).

Definition prod_point : U * V := (point, point).

Definition prod_ball x (eps : R) y :=
  ball (fst x) eps (fst y) /\ ball (snd x) eps (snd y).

Lemma prod_ball_center x (eps : R) : 0 < eps -> prod_ball x eps x.
Proof. by move=> /posnumP[e]; split. Qed.

Lemma prod_ball_sym x y (eps : R) : prod_ball x eps y -> prod_ball y eps x.
Proof. by move=> [bxy1 bxy2]; split; apply: ball_sym. Qed.

Lemma prod_ball_triangle x y z (e1 e2 : R) :
  prod_ball x e1 y -> prod_ball y e2 z -> prod_ball x (e1 + e2) z.
Proof.
by move=> [bxy1 bxy2] [byz1 byz2]; split; eapply ball_triangle; eassumption.
Qed.

Lemma prod_locally : locally = locally_ prod_ball.
Proof.
rewrite predeq2E => -[x y] P; split=> [[[A B] /=[xX yY] XYP] |]; last first.
  by move=> [_ /posnumP[eps] epsP]; exists (ball x eps%:num, ball y eps%:num) => /=.
move: xX yY => /locallyP [_ /posnumP[ex] eX] /locallyP [_ /posnumP[ey] eY].
exists (minr ex%:num ey%:num) => // -[x' y'] [/= xx' yy'].
apply: XYP; split=> /=.
  by apply/eX/(ball_ler _ xx'); rewrite ler_minl lerr.
by apply/eY/(ball_ler _ yy'); rewrite ler_minl lerr orbT.
Qed.

Definition prod_uniformType_mixin :=
  Uniform.Mixin prod_ball_center prod_ball_sym prod_ball_triangle prod_locally.

End prod_Uniform.

Canonical prod_uniformType (U V : uniformType) :=
  UniformType (U * V) (@prod_uniformType_mixin U V).

(** Functional metric spaces *)

Section fct_Uniform.

Variable (T : choiceType) (U : uniformType).

Definition fct_ball (x : T -> U) (eps : R) (y : T -> U) :=
  forall t : T, ball (x t) eps (y t).

Lemma fct_ball_center (x : T -> U) (e : R) : 0 < e -> fct_ball x e x.
Proof. by move=> /posnumP[{e}e] t. Qed.

Lemma fct_ball_sym (x y : T -> U) (e : R) : fct_ball x e y -> fct_ball y e x.
Proof. by move=> P t; apply: ball_sym. Qed.

Lemma fct_ball_triangle (x y z : T -> U) (e1 e2 : R) :
  fct_ball x e1 y -> fct_ball y e2 z -> fct_ball x (e1 + e2) z.
Proof. by move=> xy yz t; apply: (@ball_triangle _ (y t)). Qed.

Definition fct_uniformType_mixin :=
  UniformMixin fct_ball_center fct_ball_sym fct_ball_triangle erefl.

Definition fct_topologicalTypeMixin :=
  uniform_TopologicalTypeMixin fct_uniformType_mixin.

Canonical generic_source_filter := @Filtered.Source _ _ _ (locally_ fct_ball).
Canonical fct_topologicalType :=
  TopologicalType (T -> U) fct_topologicalTypeMixin.
Canonical fct_uniformType := UniformType (T -> U) fct_uniformType_mixin.

End fct_Uniform.

(** ** Local predicates *)
(** locally_dist *)
(** Where is it used ??*)

Definition locally_dist {T : Type}  :=
  locally_ (fun (d : T -> R) delta => [set y | (d y < (delta : R))%R]).

Global Instance locally_dist_filter T (d : T -> R) : Filter (locally_dist d).
Proof.
apply: filter_from_filter; first by exists 1.
move=> _ _ /posnumP[e1] /posnumP[e2]; exists (minr e1%:num e2%:num) => //.
by move=> P /=; rewrite ltr_minr => /andP [dPe1 dPe2].
Qed.

Lemma open_comp  {T U : topologicalType} (f : T -> U) (D : set U) :
  {in f @^-1` D, continuous f} -> open D -> open (f @^-1` D).
Proof.
rewrite !openE => fcont Dop x /= Dfx.
by apply: fcont; [rewrite in_setE|apply: Dop].
Qed.

Section Locally_fct.

Context {T : Type} {U : uniformType}.

Lemma near_ball (y : U) (eps : posreal) :
   \forall y' \near y, ball y eps%:num y'.
Proof. exact: locally_ball. Qed.

Lemma flim_ballP {F} {FF : Filter F} (y : U) :
  F --> y <-> forall eps : R, 0 < eps -> \forall y' \near F, ball y eps y'.
Proof. by rewrite -filter_fromP !locally_simpl /=. Qed.
Definition flim_locally := @flim_ballP.

Lemma flim_ball {F} {FF : Filter F} (y : U) :
  F --> y -> forall eps : R, 0 < eps -> \forall y' \near F, ball y eps y'.
Proof. by move/flim_ballP. Qed.

Lemma app_flim_locally {F} {FF : Filter F} (f : T -> U) y :
  f @ F --> y <-> forall eps : R, 0 < eps -> \forall x \near F, ball y eps (f x).
Proof. exact: flim_ballP. Qed.

Lemma flimi_ballP {F} {FF : Filter F} (f : T -> U -> Prop) y :
  f `@ F --> y <->
  forall eps : R, 0 < eps -> \forall x \near F, exists z, f x z /\ ball y eps z.
Proof.
split=> [Fy _/posnumP[eps] |Fy P] /=; first exact/Fy/locally_ball.
move=> /locallyP[_ /posnumP[eps] subP].
rewrite near_simpl near_mapi; begin_near x.
  have [//|z [fxz yz]] := near (Fy _ (posnum_gt0 eps)) x.
  by exists z => //; split => //; apply: subP.
by end_near.
Qed.
Definition flimi_locally := @flimi_ballP.

Lemma flimi_ball {F} {FF : Filter F} (f : T -> U -> Prop) y :
  f `@ F --> y ->
  forall eps : R, 0 < eps -> F [set x | exists z, f x z /\ ball y eps z].
Proof. by move/flimi_ballP. Qed.

Lemma flimi_close {F} {FF: ProperFilter F} (f : T -> set U) (l l' : U) :
  {near F, is_fun f} -> f `@ F --> l -> f `@ F --> l' -> close l l'.
Proof.
move=> f_prop fFl fFl'.
suff f_totalfun: infer {near F, is_totalfun f} by exact: flim_close fFl fFl'.
apply: filter_app f_prop; begin_near x; first split=> //=.
  by have [//|y [fxy _]] := near (flimi_ball fFl [gt0 of 1]) x; exists y.
by end_near.
Qed.
Definition flimi_locally_close := @flimi_close.

End Locally_fct.

Section Locally_fct2.

Context {T : Type} {U V : uniformType}.

Lemma flim_ball2P {F : set (set U)} {G : set (set V)}
  {FF : Filter F} {FG : Filter G} (y : U) (z : V):
  (F, G) --> (y, z) <->
  forall eps : R, eps > 0 -> \forall y' \near F & z' \near G,
                ball y eps y' /\ ball z eps z'.
Proof. exact: flim_ballP. Qed.

End Locally_fct2.

Lemma flim_const {T} {U : uniformType} {F : set (set T)}
   {FF : Filter F} (a : U) : a @[_ --> F] --> a.
Proof.
move=> P /locallyP[_ /posnumP[eps] subP]; rewrite !near_simpl /=.
by apply: filterE=> ?; apply/subP.
Qed.
Arguments flim_const {T U F FF} a.

Section Cvg.

Context {U : uniformType}.

Lemma close_lim (F1 F2 : set (set U)) {FF2 : ProperFilter F2} :
  F1 --> F2 -> F2 --> F1 -> close (lim F1) (lim F2).
Proof.
move=> F12 F21; have [/(flim_trans F21) F2l|dvgF1] := pselect (cvg F1).
  by apply: (@flim_close _ F2) => //; apply: cvgP F2l.
have [/(flim_trans F12)/cvgP//|dvgF2] := pselect (cvg F2).
by rewrite dvgP // dvgP //.
Qed.

Lemma flim_closeP (F : set (set U)) (l : U) : ProperFilter F ->
  F --> l <-> ([cvg F in U] /\ close (lim F) l).
Proof.
move=> FF; split=> [Fl|[cvF]Cl].
  by have /cvgP := Fl; split=> //; apply: flim_close.
by apply: flim_trans (close_limxx Cl).
Qed.

End Cvg.
Arguments close_lim {U} F1 F2 {FF2} _.

Lemma is_filter_lim_filtermap {T: topologicalType} {U : topologicalType}
  (F : set (set T)) x (f : T -> U) :
   {for x, continuous f} -> F --> x -> f @ F --> f x.
Proof. by move=> cf fx P /cf /fx. Qed.

(** locally' *)

(* Should have a generic ^' operator *)
Definition locally' {T : topologicalType} (x : T) :=
  within (fun y => y <> x) (locally x).

Global Instance locally'_filter {T : topologicalType} (x : T) :
  Filter (locally' x).
Proof. exact: within_filter. Qed.

Section at_point.

Context {T : Type}.

Definition at_point (a : T) (P : set T) : Prop := P a.

Global Instance at_point_filter (a : T) : ProperFilter (at_point a).
Proof. by constructor=> //; constructor=> // P Q subPQ /subPQ. Qed.

End at_point.

(** ** Closed sets in topological spaces *)

Section Closed.

Context {T : topologicalType}.

Definition closure (A : set T) :=
  [set p : T | forall B, locally p B -> A `&` B !=set0].

Lemma subset_closure (A : set T) : A `<=` closure A.
Proof. by move=> p ??; exists p; split=> //; apply: locally_singleton. Qed.

Definition closed (D : set T) := closure D `<=` D.

Lemma closedN (D : set T) : open D -> closed (~` D).
Proof. by rewrite openE => Dop p clNDp /Dop /clNDp [? []]. Qed.

Lemma closed_bigI {I} (D : I -> set T) :
  (forall i, closed (D i)) -> closed (\bigcap_i D i).
Proof.
move=> Dcl p clDp i _; apply/Dcl => A /clDp [q [Dq Aq]].
by exists q; split=> //; apply: Dq.
Qed.

Lemma closedI (D E : set T) : closed D -> closed E -> closed (D `&` E).
Proof.
by move=> Dcl Ecl p clDEp; split; [apply: Dcl|apply: Ecl];
  move=> A /clDEp [q [[]]]; exists q.
Qed.

Lemma closedT : closed setT. Proof. by []. Qed.

Lemma closed0 : closed set0.
Proof. by move=> ? /(_ setT) [|? []] //; apply: filterT. Qed.

Lemma closedE : closed = [set A : set T | forall p, ~ (\near p, ~ A p) -> A p].
Proof.
rewrite predeqE => A; split=> Acl p; last first.
  by move=> clAp; apply: Acl; rewrite -locally_nearE => /clAp [? []].
rewrite -locally_nearE locallyE => /asboolP.
rewrite asbool_neg => /forallp_asboolPn clAp.
apply: Acl => B; rewrite locallyE => - [C [p_C sCB]].
have /asboolP := clAp C.
rewrite asbool_neg asbool_and => /nandP [/asboolP//|/existsp_asboolPn [q]].
move/asboolP; rewrite asbool_neg => /imply_asboolPn [/sCB Bq /contrapT Aq].
by exists q.
Qed.

Lemma openN (D : set T) : closed D -> open (~` D).
Proof.
rewrite closedE openE => Dcl t nDt; apply: contrapT.
by rewrite locally_nearE => /Dcl.
Qed.

Lemma closed_closure (A : set T) : closed (closure A).
Proof. by move=> p clclAp B /locally_locally /clclAp [q [clAq /clAq]]. Qed.

End Closed.

Lemma closed_comp {T U : topologicalType} (f : T -> U) (D : set U) :
  {in ~` f @^-1` D, continuous f} -> closed D -> closed (f @^-1` D).
Proof.
rewrite !closedE=> f_cont D_cl x /= xDf; apply: D_cl; apply: contrap xDf => fxD.
have NDfx : ~ D (f x).
  by move: fxD; rewrite -locally_nearE locallyE => - [A [[??]]]; apply.
by apply: f_cont fxD; rewrite in_setE.
Qed.

Lemma closed_flim_loc {T} {U : topologicalType} {F} {FF : ProperFilter F}
  (f : T -> U) (D : U -> Prop) :
  forall y, f @ F --> y -> F (f @^-1` D) -> closed D -> D y.
Proof.
move=> y Ffy Df; apply => A /Ffy /=; rewrite locally_filterE.
by move=> /(filterI Df); apply: filter_ex.
Qed.

Lemma closed_flim {T} {U : topologicalType} {F} {FF : ProperFilter F}
  (f : T -> U) (D : U -> Prop) :
  forall y, f @ F --> y -> (forall x, D (f x)) -> closed D -> D y.
Proof.
by move=> y fy FDf; apply: (closed_flim_loc fy); apply: filterE.
Qed.

(** ** Compact sets *)

Section Compact.

Context {T : topologicalType}.

Definition cluster (F : set (set T)) (p : T) :=
  forall A B, F A -> locally p B -> A `&` B !=set0.

Lemma clusterE F : cluster F = \bigcap_(A in F) (closure A).
Proof. by rewrite predeqE => p; split=> cF ????; apply: cF. Qed.

Lemma flim_cluster F G : F --> G -> cluster F `<=` cluster G.
Proof. by move=> sGF p Fp P Q GP Qp; apply: Fp Qp; apply: sGF. Qed.

Lemma cluster_flimE F :
  ProperFilter F ->
  cluster F = [set p | exists2 G, ProperFilter G & G --> p /\ F `<=` G].
Proof.
move=> FF; rewrite predeqE => p.
split=> [clFp|[G Gproper [cvGp sFG]] A B]; last first.
  by move=> /sFG GA /cvGp GB; apply/filter_ex/filterI.
exists (filter_from (\bigcup_(A in F) [set A `&` B | B in locally p]) id).
  apply filter_from_proper; last first.
    by move=> _ [A FA [B p_B <-]]; have := clFp _ _ FA p_B.
  apply: filter_from_filter.
    exists setT; exists setT; first exact: filterT.
    by exists setT; [apply: filterT|rewrite setIT].
  move=> _ _ [A1 FA1 [B1 p_B1 <-]] [A2 FA2 [B2 p_B2 <-]].
  exists (A1 `&` B1 `&` (A2 `&` B2)) => //; exists (A1 `&` A2).
    exact: filterI.
  by exists (B1 `&` B2); [apply: filterI|rewrite setIACA].
split.
  move=> A p_A; exists A => //; exists setT; first exact: filterT.
  by exists A => //; rewrite setIC setIT.
move=> A FA; exists A => //; exists A => //; exists setT; first exact: filterT.
by rewrite setIT.
Qed.

Definition compact A := forall (F : set (set T)),
  ProperFilter F -> F A -> A `&` cluster F !=set0.

Lemma compact0 : compact set0.
Proof. by move=> F FF /filter_ex []. Qed.

Lemma subclosed_compact (A B : set T) :
  closed A -> compact B -> A `<=` B -> compact A.
Proof.
move=> Acl Bco sAB F Fproper FA.
have [|p [Bp Fp]] := Bco F; first exact: filterS FA.
by exists p; split=> //; apply: Acl=> C Cp; apply: Fp.
Qed.

Definition hausdorff := forall p q : T, cluster (locally p) q -> p = q.

Typeclasses Opaque within.
Global Instance within_locally_proper (A : set T) p :
  infer (closure A p) -> ProperFilter (within A (locally p)).
Proof.
move=> clAp; apply: Build_ProperFilter => B.
by move=> /clAp [q [Aq AqsoBq]]; exists q; apply: AqsoBq.
Qed.

Lemma compact_closed (A : set T) : hausdorff -> compact A -> closed A.
Proof.
move=> hT Aco p clAp; have pA := !! @withinT _ (locally p) A _.
have [q [Aq clsAp_q]] := !! Aco _ _ pA; rewrite (hT p q) //.
by apply: flim_cluster clsAp_q; apply: flim_within.
Qed.

End Compact.

Lemma continuous_compact (T U : topologicalType) (f : T -> U) A :
  {in A, continuous f} -> compact A -> compact (f @` A).
Proof.
move=> fcont Aco F FF FfA; set G := filter_from F (fun C => A `&` f @^-1` C).
have GF : ProperFilter G.
  apply: (filter_from_proper (filter_from_filter _ _)); first by exists (f @` A).
    move=> C1 C2 F1 F2; exists (C1 `&` C2); first exact: filterI.
    by move=> ?[?[]]; split; split.
  by move=> C /(filterI FfA) /filter_ex [_ [[p ? <-]]]; eexists p.
case: Aco; first by exists (f @` A) => // ? [].
move=> p [Ap clsGp]; exists (f p); split; first exact/imageP.
move=> B C FB /fcont; rewrite in_setE /= locally_filterE => /(_ Ap) p_Cf.
have : G (A `&` f @^-1` B) by exists B.
by move=> /clsGp /(_ p_Cf) [q [[]]]; exists (f q).
Qed.

Section Tychonoff.

Class UltraFilter T (F : set (set T)) := {
  ultra_proper :> ProperFilter F ;
  max_filter : forall G : set (set T), ProperFilter G -> F `<=` G -> G = F
}.

Lemma ultra_flim_clusterE (T : topologicalType) (F : set (set T)) :
  UltraFilter F -> cluster F = [set p | F --> p].
Proof.
move=> FU; rewrite predeqE => p; split.
  by rewrite cluster_flimE => - [G GF [cvGp /max_filter <-]].
by move=> cvFp; rewrite cluster_flimE; exists F; [apply: ultra_proper|split].
Qed.

Lemma ultraFilterLemma T (F : set (set T)) :
  ProperFilter F -> exists G, UltraFilter G /\ F `<=` G.
Proof.
move=> FF.
set filter_preordset := ({G : set (set T) & ProperFilter G /\ F `<=` G}).
set preorder := fun G1 G2 : filter_preordset => projT1 G1 `<=` projT1 G2.
suff [G Gmax] : exists G : filter_preordset, premaximal preorder G.
  have [GF sFG] := projT2 G; exists (projT1 G); split=> //; split=> // H HF sGH.
  have sFH : F `<=` H by apply: subset_trans sGH.
  have sHG : preorder (existT _ H (conj HF sFH)) G by apply: Gmax.
  by rewrite predeqE => ?; split=> [/sHG|/sGH].
have sFF : F `<=` F by [].
apply: (ZL_preorder ((existT _ F (conj FF sFF)) : filter_preordset)) =>
  [?|G H I sGH sHI ? /sGH /sHI|A Atot] //.
case: (pselect (A !=set0)) => [[G AG] | A0]; last first.
  exists (existT _ F (conj FF sFF)) => G AG.
  by have /asboolP := A0; rewrite asbool_neg => /forallp_asboolPn /(_ G).
have [GF sFG] := projT2 G.
suff UAF : ProperFilter (\bigcup_(H in A) projT1 H).
  have sFUA : F `<=` \bigcup_(H in A) projT1 H.
    by move=> B FB; exists G => //; apply: sFG.
  exists (existT _ (\bigcup_(H in A) projT1 H) (conj UAF sFUA)) => H AH B HB /=.
  by exists H.
apply Build_ProperFilter.
  by move=> B [H AH HB]; have [HF _] := projT2 H; apply: filter_ex.
split; first by exists G => //; apply: filterT.
  move=> B C [HB AHB HBB] [HC AHC HCC]; have [sHBC|sHCB] := Atot _ _ AHB AHC.
    exists HC => //; have [HCF _] := projT2 HC; apply: filterI HCC.
    exact: sHBC.
  exists HB => //; have [HBF _] := projT2 HB; apply: filterI HBB _.
  exact: sHCB.
move=> B C SBC [H AH HB]; exists H => //; have [HF _] := projT2 H.
exact: filterS HB.
Qed.

Lemma compact_ultra (T : topologicalType) :
  compact = [set A | forall F : set (set T),
  UltraFilter F -> F A -> A `&` [set p | F --> p] !=set0].
Proof.
rewrite predeqE => A; split=> Aco F FF FA.
  by have /Aco [p [?]] := FA; rewrite ultra_flim_clusterE; exists p.
have [G [GU sFG]] := ultraFilterLemma FF.
have /Aco [p [Ap]] : G A by apply: sFG.
rewrite -[_ --> p]/([set _ | _] p) -ultra_flim_clusterE.
by move=> /(flim_cluster sFG); exists p.
Qed.

Lemma filter_image (T U : Type) (f : T -> U) (F : set (set T)) :
  Filter F -> f @` setT = setT -> Filter [set f @` A | A in F].
Proof.
move=> FF fsurj; split.
- by exists setT => //; apply: filterT.
- move=> _ _ [A FA <-] [B FB <-].
  exists (f @^-1` (f @` A `&` f @` B)); last by rewrite image_preimage.
  have sAB : A `&` B `<=` f @^-1` (f @` A `&` f @` B).
    by move=> x [Ax Bx]; split; exists x.
  by apply: filterS sAB _; apply: filterI.
- move=> A B sAB [C FC fC_eqA].
  exists (f @^-1` B); last by rewrite image_preimage.
  by apply: filterS FC => p Cp; apply: sAB; rewrite -fC_eqA; exists p.
Qed.

Lemma proper_image (T U : Type) (f : T -> U) (F : set (set T)) :
  ProperFilter F -> f @` setT = setT -> ProperFilter [set f @` A | A in F].
Proof.
move=> FF fsurj; apply Build_ProperFilter; last exact: filter_image.
by move=> _ [A FA <-]; have /filter_ex [p Ap] := FA; exists (f p); exists p.
Qed.

Lemma in_ultra_setVsetC T (F : set (set T)) (A : set T) :
  UltraFilter F -> F A \/ F (~` A).
Proof.
move=> FU; case: (pselect (F (~` A))) => [|nFnA]; first by right.
left; suff : ProperFilter (filter_from (F `|` [set A `&` B | B in F]) id).
  move=> /max_filter <-; last by move=> B FB; exists B => //; left.
  by exists A => //; right; exists setT; [apply: filterT|rewrite setIT].
apply filter_from_proper; last first.
  move=> B [|[C FC <-]]; first exact: filter_ex.
  apply: contrapT => /asboolP; rewrite asbool_neg => /forallp_asboolPn AC0.
  by apply: nFnA; apply: filterS FC => p Cp Ap; apply: (AC0 p).
apply: filter_from_filter.
  by exists A; right; exists setT; [apply: filterT|rewrite setIT].
move=> B C [FB|[DB FDB <-]].
  move=> [FC|[DC FDC <-]]; first by exists (B `&` C)=> //; left; apply: filterI.
  exists (A `&` (B `&` DC)); last by rewrite setICA.
  by right; exists (B `&` DC) => //; apply: filterI.
move=> [FC|[DC FDC <-]].
  exists (A `&` (DB `&` C)); last by rewrite setIA.
  by right; exists (DB `&` C) => //; apply: filterI.
exists (A `&` (DB `&` DC)); last by move=> ??; rewrite setIACA setIid.
by right; exists (DB `&` DC) => //; apply: filterI.
Qed.

Lemma ultra_image (T U : Type) (f : T -> U) (F : set (set T)) :
  UltraFilter F -> f @` setT = setT -> UltraFilter [set f @` A | A in F].
Proof.
move=> FU fsurj; split; first exact: proper_image.
move=> G GF sfFG; rewrite predeqE => A; split; last exact: sfFG.
move=> GA; exists (f @^-1` A); last by rewrite image_preimage.
have [//|FnAf] := in_ultra_setVsetC (f @^-1` A) FU.
have : G (f @` (~` (f @^-1` A))) by apply: sfFG; exists (~` (f @^-1` A)).
suff : ~ G (f @` (~` (f @^-1` A))) by [].
rewrite preimage_setC image_preimage // => GnA.
by have /filter_ex [? []] : G (A `&` (~` A)) by apply: filterI.
Qed.

Lemma tychonoff (I : eqType) (T : I -> topologicalType)
  (A : forall i, set (T i)) :
  (forall i, compact (A i)) ->
  @compact (product_topologicalType T)
    [set f : forall i, T i | forall i, A i (f i)].
Proof.
move=> Aco; rewrite compact_ultra => F FU FA.
set subst_coord := fun i pi f j =>
  match eqVneq i j with
  | left e => eq_rect i T pi _ e
  | _ => f j
  end.
have subst_coordT i pi f : subst_coord i pi f i = pi.
  rewrite /subst_coord; case: (eqVneq i i) => [e|/negP] //.
  by rewrite (eq_irrelevance e (erefl _)).
have subst_coordN i pi f j : i != j -> subst_coord i pi f j = f j.
  move=> inej; rewrite /subst_coord; case: (eqVneq i j) => [e|] //.
  by move: inej; rewrite {1}e => /negP.
have pr_surj i : @^~ i @` (@setT (forall i, T i)) = setT.
  rewrite predeqE => pi; split=> // _.
  by exists (subst_coord i pi (fun _ => point))=> //; rewrite subst_coordT.
set pF := fun i => [set @^~ i @` B | B in F].
have pFultra : forall i, UltraFilter (pF i).
  by move=> i; apply: ultra_image (pr_surj i).
have pFA : forall i, pF i (A i).
  move=> i; exists [set g | forall i, A i (g i)] => //.
  rewrite predeqE => pi; split; first by move=> [g Ag <-]; apply: Ag.
  move=> Aipi; have [f Af] := filter_ex FA.
  exists (subst_coord i pi f); last exact: subst_coordT.
  move=> j; case: (eqVneq i j); first by case: _ /; rewrite subst_coordT.
  by move=> /subst_coordN ->; apply: Af.
have cvpFA i : A i `&` [set p | pF i --> p] !=set0.
  by rewrite -ultra_flim_clusterE; apply: Aco.
exists (fun i => get (A i `&` [set p | pF i --> p])).
split=> [i|]; first by have /getPex [] := cvpFA i.
by apply/flim_sup => i; apply/flim_image=> //; have /getPex [] := cvpFA i.
Qed.

End Tychonoff.

Definition finI (I : choiceType) T (D : set I) (f : I -> set T) :=
  forall D' : {fset I}, {subset D' <= D} ->
  \bigcap_(i in [set i | i \in D']) f i !=set0.

Lemma finI_filter (I : choiceType) T (D : set I) (f : I -> set T) :
  finI D f -> ProperFilter (filter_from (finI_from D f) id).
Proof.
move=> finIf; apply: (filter_from_proper (filter_from_filter _ _)).
- by exists setT; exists fset0 => //; rewrite predeqE.
- move=> A B [DA sDA IfA] [DB sDB IfB]; exists (A `&` B) => //.
  exists (DA `|` DB)%fset.
    by move=> ?; rewrite in_fsetE => /orP [/sDA|/sDB].
  rewrite -IfA -IfB predeqE => p; split=> [Ifp|[IfAp IfBp] i].
    by split=> i Di; apply: Ifp; rewrite in_fsetE Di // orbC.
  by rewrite in_fsetE => /orP []; [apply: IfAp|apply: IfBp].
- by move=> _ [?? <-]; apply: finIf.
Qed.

Lemma filter_finI (T : pointedType) (F : set (set T)) (D : set (set T))
  (f : set T -> set T) :
  ProperFilter F -> (forall A, D A -> F (f A)) -> finI D f.
Proof.
move=> FF sDFf D' sD; apply/filter_ex/filter_bigI.
by move=> A /sD; rewrite in_setE => /sDFf.
Qed.

Section Covers.

Variable T : topologicalType.

Definition cover_compact (A : set T) :=
  forall (I : choiceType) (D : set I) (f : I -> set T),
  (forall i, D i -> open (f i)) -> A `<=` \bigcup_(i in D) f i ->
  exists2 D' : {fset I}, {subset D' <= D} &
    A `<=` \bigcup_(i in [set i | i \in D']) f i.

Definition open_fam_of (A : set T) I (D : set I) (f : I -> set T) :=
  exists2 g : I -> set T, (forall i, D i -> open (g i)) &
    forall i, D i -> f i = A `&` g i.

Lemma cover_compactE :
  cover_compact =
  [set A | forall (I : choiceType) (D : set I) (f : I -> set T),
    open_fam_of A D f -> A `<=` \bigcup_(i in D) f i ->
    exists2 D' : {fset I}, {subset D' <= D} &
      A `<=` \bigcup_(i in [set i | i \in D']) f i].
Proof.
rewrite predeqE => A; split=> [Aco I D f [g gop feAg] fcov|Aco I D f fop fcov].
  have gcov : A `<=` \bigcup_(i in D) g i.
    by move=> p /fcov [i Di]; rewrite feAg // => - []; exists i.
  have [D' sD sgcov] := Aco _ _ _ gop gcov.
  exists D' => // p Ap; have /sgcov [i D'i gip] := Ap.
  by exists i => //; rewrite feAg //; have /sD := D'i; rewrite in_setE.
have Afcov : A `<=` \bigcup_(i in D) (A `&` f i).
  by move=> p Ap; have /fcov [i ??] := Ap; exists i.
have Afop : open_fam_of A D (fun i => A `&` f i) by exists f.
have [D' sD sAfcov] := Aco _ _ _ Afop Afcov.
by exists D' => // p /sAfcov [i ? []]; exists i.
Qed.

Definition closed_fam_of (A : set T) I (D : set I) (f : I -> set T) :=
  exists2 g : I -> set T, (forall i, D i -> closed (g i)) &
    forall i, D i -> f i = A `&` g i.

Lemma compact_In0 :
  compact = [set A | forall (I : choiceType) (D : set I) (f : I -> set T),
    closed_fam_of A D f -> finI D f -> \bigcap_(i in D) f i !=set0].
Proof.
rewrite predeqE => A; split=> [Aco I D f [g gcl feAg] finIf|Aco F FF FA].
  case: (pselect (exists i, D i)) => [[i Di] | /asboolP]; last first.
    by rewrite asbool_neg => /forallp_asboolPn D0; exists point => ? /D0.
  have [|p [Ap clfinIfp]] := Aco _ (finI_filter finIf).
    by exists (f i); [apply: finI_from1|rewrite feAg // => ? []].
  exists p => j Dj; rewrite feAg //; split=> //; apply: gcl => // B.
  by apply: clfinIfp; exists (f j); [apply: finI_from1|rewrite feAg // => ? []].
have finIAclF : finI F (fun B => A `&` closure B).
  apply: filter_finI => B FB; apply: filterI => //; apply: filterS FB.
  exact: subset_closure.
have [|p AclFIp] := Aco _ _ _ _ finIAclF.
  by exists closure=> //; move=> ??; apply: closed_closure.
exists p; split=> [|B C FB p_C]; first by have /AclFIp [] := FA.
by have /AclFIp [_] := FB; move=> /(_ _ p_C).
Qed.

Lemma exists2P A (P Q : A -> Prop) :
  (exists2 x, P x & Q x) <-> exists x, P x /\ Q x.
Proof. by split=> [[x ??] | [x []]]; exists x. Qed.

Lemma compact_cover : compact = cover_compact.
Proof.
rewrite compact_In0 cover_compactE predeqE => A.
split=> [Aco I D f [g gop feAg] fcov|Aco I D f [g gcl feAg]].
  case: (pselect (exists i, D i)) => [[j Dj] | /asboolP]; last first.
    rewrite asbool_neg => /forallp_asboolPn D0.
    by exists fset0 => // ? /fcov [? /D0].
  apply/exists2P; apply: contrapT.
  move=> /asboolP; rewrite asbool_neg => /forallp_asboolPn sfncov.
  suff [p IAnfp] : \bigcap_(i in D) (A `\` f i) !=set0.
    by have /IAnfp [Ap _] := Dj; have /fcov [k /IAnfp [_]] := Ap.
  apply: Aco.
    exists (fun i => ~` g i) => i Di; first exact/closedN/gop.
    rewrite predeqE => p; split=> [[Ap nfip] | [Ap ngip]]; split=> //.
      by move=> gip; apply: nfip; rewrite feAg.
    by rewrite feAg // => - [].
  move=> D' sD.
  have /asboolP : ~ A `<=` \bigcup_(i in [set i | i \in D']) f i.
    by move=> sAIf; apply: (sfncov D').
  rewrite asbool_neg => /existsp_asboolPn [p /asboolP].
  rewrite asbool_neg => /imply_asboolPn [Ap nUfp].
  by exists p => i D'i; split=> // fip; apply: nUfp; exists i.
case: (pselect (exists i, D i)) => [[j Dj] | /asboolP]; last first.
  by rewrite asbool_neg => /forallp_asboolPn D0 => _; exists point => ? /D0.
apply: contrapTT => /asboolP; rewrite asbool_neg => /forallp_asboolPn If0.
apply/asboolP; rewrite asbool_neg; apply/existsp_asboolPn.
have Anfcov : A `<=` \bigcup_(i in D) (A `\` f i).
  move=> p Ap; have /asboolP := If0 p; rewrite asbool_neg => /existsp_asboolPn.
  move=> [i /asboolP]; rewrite asbool_neg => /imply_asboolPn [Di nfip].
  by exists i.
have Anfop : open_fam_of A D (fun i => A `\` f i).
  exists (fun i => ~` g i) => i Di; first exact/openN/gcl.
  rewrite predeqE => p; split=> [[Ap nfip] | [Ap ngip]]; split=> //.
    by move=> gip; apply: nfip; rewrite feAg.
  by rewrite feAg // => - [].
have [D' sD sAnfcov] := Aco _ _ _ Anfop Anfcov.
wlog [k D'k] : D' sD sAnfcov / exists i, i \in D'.
  move=> /(_ (D' `|` [fset j])%fset); apply.
  - by move=> k; rewrite !in_fsetE => /orP [/sD|/eqP->] //; rewrite in_setE.
  - by move=> p /sAnfcov [i D'i Anfip]; exists i => //; rewrite !in_fsetE D'i.
  - by exists j; rewrite !in_fsetE orbC eq_refl.
exists D' => /(_ sD) [p Ifp].
have /Ifp := D'k; rewrite feAg; last by have /sD := D'k; rewrite in_setE.
by move=> [/sAnfcov [i D'i [_ nfip]] _]; have /Ifp := D'i.
Qed.

End Covers.

(** ** Complete uniform spaces *)

(* :TODO: Use cauchy2 alternative to define cauchy? *)
(* Or not: is the fact that cauchy F -/> ProperFilter F a problem? *)
Definition cauchy_ex {T : uniformType} (F : set (set T)) :=
  forall eps : R, 0 < eps -> exists x, F (ball x eps).

Definition cauchy {T : uniformType} (F : set (set T)) :=
  forall e, e > 0 -> \forall x & y \near F, ball x e y.

Lemma cvg_cauchy_ex {T : uniformType} (F : set (set T)) :
  [cvg F in T] -> cauchy_ex F.
Proof. by move=> Fl _/posnumP[eps]; exists (lim F); apply/Fl/locally_ball. Qed.

Lemma cauchy_exP (T : uniformType) (F : set (set T)) : Filter F ->
  cauchy_ex F -> cauchy F.
Proof.
move=> FF Fcauchy /= _/posnumP[e].
have [//|x /= Fbx] := Fcauchy (e%:num / 2).
exists ((ball x (e%:num / 2)), (ball x (e%:num / 2))) => //.
by move=> [y z] [/=] /ball_splitr; apply.
Qed.

Lemma cauchyP (T : uniformType) (F : set (set T)) : ProperFilter F ->
  cauchy F <-> cauchy_ex F.
Proof.
move=> FF; split=> [Fcauchy _/posnumP[e] |/cauchy_exP//].
have_near F x; first by exists x; near x.
by end_near; apply: (@nearP_dep _ _ F F); apply: Fcauchy.
Qed.

Lemma cvg_cauchy {T : uniformType} (F : set (set T)) : Filter F ->
  [cvg F in T] -> cauchy F.
Proof. by move=> FF /cvg_cauchy_ex /cauchy_exP. Qed.

Module Complete.

Definition axiom (T : uniformType) :=
  forall (F : set (set T)), ProperFilter F -> cauchy F -> F --> lim F.

Section ClassDef.

Record class_of (T : Type) := Class {
  base : Uniform.class_of T ;
  mixin : axiom (Uniform.Pack base T)
}.
Local Coercion base : class_of >-> Uniform.class_of.
Local Coercion mixin : class_of >-> Complete.axiom.

Structure type := Pack { sort; _ : class_of sort ; _ : Type }.
Local Coercion sort : type >-> Sortclass.

Variables (T : Type) (cT : type).

Definition class := let: Pack _ c _ := cT return class_of cT in c.

Definition clone c of phant_id class c := @Pack T c T.
Let xT := let: Pack T _ _ := cT in T.
Notation xclass := (class : class_of xT).

Definition pack b0 (m0 : axiom (@Uniform.Pack T b0 T)) :=
  fun bT b of phant_id (Uniform.class bT) b =>
  fun m of phant_id m m0 => @Pack T (@Class T b m) T.

Definition eqType := @Equality.Pack cT xclass xT.
Definition choiceType := @Choice.Pack cT xclass xT.
Definition pointedType := @Pointed.Pack cT xclass xT.
Definition filteredType := @Filtered.Pack cT cT xclass xT.
Definition topologicalType := @Topological.Pack cT xclass xT.
Definition uniformType := @Uniform.Pack cT xclass xT.

End ClassDef.

Module Exports.

Coercion base : class_of >-> Uniform.class_of.
Coercion mixin : class_of >-> axiom.
Coercion sort : type >-> Sortclass.
Coercion eqType : type >-> Equality.type.
Canonical eqType.
Coercion choiceType : type >-> Choice.type.
Canonical choiceType.
Coercion pointedType : type >-> Pointed.type.
Canonical pointedType.
Coercion filteredType : type >-> Filtered.type.
Canonical filteredType.
Coercion topologicalType : type >-> Topological.type.
Canonical topologicalType.
Coercion uniformType : type >-> Uniform.type.
Canonical uniformType.
Notation completeType := type.
Notation "[ 'completeType' 'of' T 'for' cT ]" :=  (@clone T cT _ idfun)
  (at level 0, format "[ 'completeType'  'of'  T  'for'  cT ]") : form_scope.
Notation "[ 'completeType' 'of' T ]" := (@clone T _ _ id)
  (at level 0, format "[ 'completeType'  'of'  T ]") : form_scope.
Notation CompleteType T m := (@pack T _ m _ _ idfun _ idfun).

End Exports.

End Complete.

Export Complete.Exports.

Section completeType1.

Context {T : completeType}.

Lemma complete_cauchy (F : set (set T)) (FF : ProperFilter F) :
  cauchy F -> F --> lim F.
Proof. by case: T F FF => [? [?]]. Qed.

End completeType1.
Arguments complete_cauchy {T} F {FF} _.

Section fct_Complete.

Context {T : choiceType} {U : completeType}.

Lemma complete_cauchy_fct (F : set (set (T -> U))) :
  ProperFilter F -> cauchy F -> cvg F.
Proof.
move=> FF Fc; have /(_ _) /complete_cauchy Gl : cauchy (@^~ _ @ F).
  by move=> t _/posnumP[e]; rewrite near_simpl; apply: filterS (Fc _ _).
apply/cvg_ex; exists (fun t => lim (@^~t @ F)).
apply/flim_ballP => _ /posnumP[e]; begin_near g.
  move=> t; have_near F h => /=.
    by apply: (@ball_splitl _ (h t)); last move: (t); near h.
  by end_near; [exact/Gl/locally_ball|near g].
by end_near; apply: nearP_dep; apply: filterS (Fc _ _).
Qed.

Canonical fct_completeType := CompleteType (T -> U) complete_cauchy_fct.

End fct_Complete.

(** ** Limit switching *)

Section Flim_switch.

Context {T1 T2 : choiceType}.

(* :TODO: Use bigenough reasonning here *)
Lemma flim_switch_1 {U : uniformType}
  F1 {FF1 : ProperFilter F1} F2 {FF2 : Filter F2}
  (f : T1 -> T2 -> U) (g : T2 -> U) (h : T1 -> U) (l : U) :
  f @ F1 --> g -> (forall x, f x @ F2 --> h x) -> h @ F1 --> l ->
  g @ F2 --> l.
Proof.
move=> fg fh hl; apply/flim_ballP => _ /posnumP[eps]; rewrite !near_simpl.
have_near F1 x; first begin_near y.
+ apply: (@ball_split _ (h x)); first by near x.
  apply: (@ball_split _ (f x y)); first by near y.
  by apply/ball_sym; move: (y); near x.
+ by end_near; apply/fh/locally_ball.
end_near; first exact/hl/locally_ball.
by have /flim_locally /= := fg; apply.
Qed.

(* :TODO: Use bigenough reasonning here *)
Lemma flim_switch_2 {U : completeType}
  F1 {FF1 : ProperFilter F1} F2 {FF2 : ProperFilter F2}
  (f : T1 -> T2 -> U) (g : T2 -> U) (h : T1 -> U) :
  f @ F1 --> g -> (forall x, f x @ F2 --> h x) ->
  [cvg h @ F1 in U].
Proof.
move=> fg fh; apply: complete_cauchy => _/posnumP[e] /=; rewrite !near_simpl.
begin_near2 x x'=> /=; [have_near F2 y|].
+ apply: (@ball_splitl _ (f x y)); first by near y.
  apply: (@ball_split _ (f x' y)); first by near y.
  by apply: (@ball_splitr _ (g y)); move: (y); [near x'|near x].
+ by end_near; apply/fh/locally_ball.
by split; end_near; have /flim_locally /= := fg; apply.
Qed.

(* Alternative version *)
(* Lemma flim_switch {U : completeType} *)
(*   F1 (FF1 : ProperFilter F1) F2 (FF2 : ProperFilter F2) (f : T1 -> T2 -> U) (g : T2 -> U) (h : T1 -> U) : *)
(*   [cvg f @ F1 in T2 -> U] -> (forall x, [cvg f x @ F2 in U]) -> *)
(*   [/\ [cvg [lim f @ F1] @ F2 in U], [cvg (fun x => [lim f x @ F2]) @ F1 in U] *)
(*   & [lim [lim f @ F1] @ F2] = [lim (fun x => [lim f x @ F2]) @ F1]]. *)
Lemma flim_switch {U : completeType}
  F1 (FF1 : ProperFilter F1) F2 (FF2 : ProperFilter F2)
  (f : T1 -> T2 -> U) (g : T2 -> U) (h : T1 -> U) :
  f @ F1 --> g -> (forall x, f x @ F2 --> h x) ->
  exists l : U, h @ F1 --> l /\ g @ F2 --> l.
Proof.
move=> Hfg Hfh; have hcv := !! flim_switch_2 Hfg Hfh.
by exists [lim h @ F1 in U]; split=> //; apply: flim_switch_1 Hfg Hfh hcv.
Qed.

End Flim_switch.

(** ** Modules with a norm *)

Module NormedModule.

Record mixin_of (K : absRingType) (V : lmodType K) loc (m : @Uniform.mixin_of V loc) := Mixin {
  norm : V -> R ;
  ax1 : forall (x y : V), norm (x + y) <= norm x + norm y ;
  ax2 : forall (l : K) (x : V), norm (l *: x) <= abs l * norm x;
  ax3 : Uniform.ball m = ball_ norm;
  ax4 : forall x : V, norm x = 0 -> x = 0
}.

Section ClassDef.

Variable K : absRingType.

Record class_of (T : Type) := Class {
  base : GRing.Lmodule.class_of K T ;
  pointed_mixin : Pointed.point_of T ;
  locally_mixin : Filtered.locally_of T T ;
  topological_mixin : @Topological.mixin_of T locally_mixin ;
  uniform_mixin : @Uniform.mixin_of T locally_mixin;
  mixin : @mixin_of _ (@GRing.Lmodule.Pack K (Phant K) T base T) _ uniform_mixin
}.
Local Coercion base : class_of >-> GRing.Lmodule.class_of.
Definition base2 T (c : class_of T) :=
  @Uniform.Class _
    (@Topological.Class _
      (Filtered.Class
       (Pointed.Class (@base T c) (pointed_mixin c))
       (locally_mixin c))
      (topological_mixin c))
    (uniform_mixin c).
Local Coercion base2 : class_of >-> Uniform.class_of.
Local Coercion mixin : class_of >-> mixin_of.

Structure type (phK : phant K) :=
  Pack { sort; _ : class_of sort ; _ : Type }.
Local Coercion sort : type >-> Sortclass.

Variables (phK : phant K) (T : Type) (cT : type phK).

Definition class := let: Pack _ c _ := cT return class_of cT in c.
Definition clone c of phant_id class c := @Pack phK T c T.
Let xT := let: Pack T _ _ := cT in T.
Notation xclass := (class : class_of xT).

Definition pack b0 l0 um0 (m0 : @mixin_of _ (@GRing.Lmodule.Pack K (Phant K) T b0 T) l0 um0) :=
  fun bT b & phant_id (@GRing.Lmodule.class K phK bT) b =>
  fun ubT (ub : Uniform.class_of _) & phant_id (@Uniform.class ubT) ub =>
  fun   m & phant_id m0 m => Pack phK (@Class T b ub ub ub ub m) T.

Definition eqType := @Equality.Pack cT xclass xT.
Definition choiceType := @Choice.Pack cT xclass xT.
Definition zmodType := @GRing.Zmodule.Pack cT xclass xT.
Definition lmodType := @GRing.Lmodule.Pack K phK cT xclass xT.
Definition pointedType := @Pointed.Pack cT xclass xT.
Definition filteredType := @Filtered.Pack cT cT xclass xT.
Definition topologicalType := @Topological.Pack cT xclass xT.
Definition uniformType := @Uniform.Pack cT xclass xT.
Definition join_zmodType := @GRing.Zmodule.Pack uniformType xclass xT.
Definition join_lmodType := @GRing.Lmodule.Pack K phK uniformType xclass xT.
End ClassDef.

Module Exports.

Coercion base : class_of >-> GRing.Lmodule.class_of.
Coercion base2 : class_of >-> Uniform.class_of.
Coercion mixin : class_of >-> mixin_of.
Coercion sort : type >-> Sortclass.
Coercion eqType : type >-> Equality.type.
Canonical eqType.
Coercion choiceType : type >-> Choice.type.
Canonical choiceType.
Coercion zmodType : type >-> GRing.Zmodule.type.
Canonical zmodType.
Coercion lmodType : type >-> GRing.Lmodule.type.
Canonical lmodType.
Coercion pointedType : type >-> Pointed.type.
Canonical pointedType.
Coercion filteredType : type >-> Filtered.type.
Canonical filteredType.
Coercion topologicalType : type >-> Topological.type.
Canonical topologicalType.
Coercion uniformType : type >-> Uniform.type.
Canonical uniformType.
Canonical join_zmodType.
Canonical join_lmodType.

Notation normedModType K := (type (Phant K)).
Notation NormedModType K T m := (@pack _ (Phant K) T _ _ _ m _ _ id _ _ id _ id).
Notation NormedModMixin := Mixin.
Notation "[ 'normedModType' K 'of' T 'for' cT ]" := (@clone _ (Phant K) T cT _ idfun)
  (at level 0, format "[ 'normedModType'  K  'of'  T  'for'  cT ]") : form_scope.
Notation "[ 'normedModType' K 'of' T ]" := (@clone _ (Phant K) T _ _ id)
  (at level 0, format "[ 'normedModType'  K  'of'  T ]") : form_scope.

End Exports.

End NormedModule.

Export NormedModule.Exports.

Definition norm {K : absRingType} {V : normedModType K} : V -> R :=
  NormedModule.norm (NormedModule.class _).
Notation "`|[ x ]|" := (norm x) : ring_scope.

Section NormedModule1.
Context {K : absRingType} {V : normedModType K}.
Implicit Types (l : K) (x y : V) (eps : posreal).

Lemma ler_normm_add x y : `|[x + y]| <= `|[x]| + `|[y]|.
Proof. exact: NormedModule.ax1. Qed.

Lemma ler_normmZ l x : `|[l *: x]| <= `|l|%real * `|[x]|.
Proof. exact: NormedModule.ax2. Qed.

Notation ball_norm := (ball_ (@norm K V)).

Notation locally_norm := (locally_ ball_norm).

Lemma ball_normE : ball_norm = ball.
Proof. by rewrite -NormedModule.ax3. Qed.

Lemma normm0_eq0 x : `|[x]| = 0 -> x = 0.
Proof. exact: NormedModule.ax4. Qed.

Lemma normmN x : `|[- x]| = `|[x]|.
Proof.
gen have le_absN1 : x / `|[- x]| <= `|[x]|.
  by rewrite -scaleN1r (ler_trans (ler_normmZ _ _)) //= absrN1 mul1r.
by apply/eqP; rewrite eqr_le le_absN1 /= -{1}[x]opprK le_absN1.
Qed.

Lemma normmB x y : `|[x - y]| = `|[y - x]|.
Proof. by rewrite -normmN opprB. Qed.

Lemma normm0 : `|[0 : V]| = 0.
Proof.
apply/eqP; rewrite eqr_le; apply/andP; split.
  by rewrite -{1}(scale0r 0) (ler_trans (ler_normmZ _ _)) ?absr0 ?mul0r.
by rewrite -(ler_add2r `|[0 : V]|) add0r -{1}[0 : V]add0r ler_normm_add.
Qed.
Hint Resolve normm0.

Lemma normm_eq0 x : (`|[x]| == 0) = (x == 0).
Proof. by apply/eqP/eqP=> [/normm0_eq0|->//]. Qed.

Lemma normm_ge0 x : 0 <= `|[x]|.
Proof.
rewrite -(@pmulr_rge0 _ 2) // mulr2n mulrDl !mul1r.
by rewrite -{2}normmN (ler_trans _ (ler_normm_add _ _)) // subrr normm0.
Qed.

Lemma normm_gt0 x : (0 < `|[x]|) = (x != 0).
Proof. by rewrite ltr_def normm_eq0 normm_ge0 andbT. Qed.

Lemma normm_lt0 x : (`|[x]| < 0) = false.
Proof. by rewrite ltrNge normm_ge0. Qed.

Lemma normm_le0 x : (`|[x]| <= 0) = (x == 0).
Proof. by rewrite lerNgt normm_gt0 negbK. Qed.

Lemma absRE (x : R) : `|x|%real = `|x|%R.
Proof. by []. Qed.

Lemma ler_distm_dist x y : `| `|[x]| - `|[y]| | <= `|[x - y]|.
Proof.
wlog gt_xy : x y / `|[x]| >= `|[y]| => [hw|].
  by have [/hw//|/ltrW/hw] := lerP `|[y]| `|[x]|; rewrite absRE distrC normmB.
rewrite absRE ger0_norm ?subr_ge0 // ler_subl_addr.
by rewrite -{1}[x](addrNK y) ler_normm_add.
Qed.

Lemma closeE x y : close x y = (x = y).
Proof.
rewrite propeqE; split => [cl_xy|->//]; have [//|neq_xy] := eqVneq x y.
have dxy_gt0 : `|[x - y]| > 0 by rewrite normm_gt0 subr_eq0.
have dxy_ge0 := ltrW dxy_gt0.
have := cl_xy ((PosNum dxy_gt0)%:num / 2)%:pos.
rewrite -ball_normE /= -subr_lt0 ler_gtF //.
rewrite -[X in X - _]mulr1 -mulrBr mulr_ge0 //.
by rewrite subr_ge0 -(@ler_pmul2r _ 2) // mulVf // mul1r ler1n.
Qed.
Lemma eq_close x y : close x y -> x = y. by rewrite closeE. Qed.

Lemma locally_le_locally_norm x : flim (locally x) (locally_norm x).
Proof.
move=> P [_ /posnumP[e] subP]; apply/locallyP.
by eexists; last (move=> y Py; apply/subP; rewrite ball_normE; apply/Py).
Qed.

Lemma locally_norm_le_locally x : flim (locally_norm x) (locally x).
Proof.
move=> P /locallyP [_ /posnumP[e] Pxe].
by exists e%:num => // y; rewrite ball_normE; apply/Pxe.
Qed.

(* NB: this lemmas was not here before *)
Lemma locally_locally_norm : locally_norm = locally.
Proof.
by rewrite funeqE => x; rewrite /locally_norm ball_normE filter_from_ballE.
Qed.

Lemma locally_normP x P : locally x P <-> locally_norm x P.
Proof. by rewrite locally_locally_norm. Qed.

Lemma filter_from_norm_locally x :
  @filter_from R _ [set x : R | 0 < x] (ball_norm x) = locally x.
Proof. by rewrite -locally_locally_norm. Qed.

Lemma locally_normE (x : V) (P : set V) :
  locally_norm x P = \near x, P x.
Proof. by rewrite locally_locally_norm near_simpl. Qed.

Lemma filter_from_normE (x : V) (P : set V) :
  @filter_from R _ [set x : R | 0 < x] (ball_norm x) P = \near x, P x.
Proof. by rewrite filter_from_norm_locally. Qed.

Lemma near_locally_norm (x : V) (P : set V) :
  (\forall x \near locally_norm x, P x) = \near x, P x.
Proof. exact: locally_normE. Qed.

Lemma locally_norm_ball_norm x (e : posreal) :
  locally_norm x (ball_norm x e%:num).
Proof. by exists e%:num. Qed.

Lemma locally_norm_ball x (eps : posreal) : locally_norm x (ball x eps%:num).
Proof. rewrite locally_locally_norm; by apply: locally_ball. Qed.

Lemma locally_ball_norm (x : V) (eps : posreal) : locally x (ball_norm x eps%:num).
Proof. rewrite -locally_locally_norm; apply: locally_norm_ball_norm. Qed.

Lemma ball_norm_triangle (x y z : V) (e1 e2 : R) :
  ball_norm x e1 y -> ball_norm y e2 z -> ball_norm x (e1 + e2) z.
Proof.
rewrite /ball_norm => H1 H2; rewrite (subr_trans y).
by rewrite (ler_lt_trans (ler_normm_add _ _)) ?ltr_add.
Qed.

Lemma ball_norm_center (x : V) (e : posreal) : ball_norm x e%:num x.
Proof. by rewrite /ball_norm subrr normm0. Qed.

Lemma ball_norm_dec x y (e : R) : {ball_norm x e y} + {~ ball_norm x e y}.
Proof. exact: pselect. Qed.

Lemma ball_norm_sym x y (e : R) : ball_norm x e y -> ball_norm y e x.
Proof. by rewrite /ball_norm -opprB normmN. Qed.

Lemma ball_norm_le x (e1 e2 : R) :
  e1 <= e2 -> ball_norm x e1 `<=` ball_norm x e2.
Proof. by move=> e1e2 y /ltr_le_trans; apply. Qed.

Lemma norm_close x y : close x y = (forall eps : posreal, ball_norm x eps%:num y).
Proof. by rewrite propeqE ball_normE. Qed.

Lemma ball_norm_eq x y : (forall eps : posreal, ball_norm x eps%:num y) -> x = y.
Proof. by rewrite -norm_close closeE. Qed.

Lemma flim_unique {F} {FF : ProperFilter F} :
  is_prop [set x : V | F --> x].
Proof. by move=> Fx Fy; rewrite -closeE; apply: flim_close. Qed.

Lemma locally_flim_unique (x y : V) : x --> y -> x = y.
Proof. by rewrite -closeE; apply: flim_close. Qed.

Lemma lim_id (x : V) : lim x = x.
Proof. by symmetry; apply: locally_flim_unique; apply/cvg_ex; exists x. Qed.

End NormedModule1.

Module Export LocallyNorm.
Definition locally_simpl := (locally_simpl,@locally_locally_norm,@filter_from_norm_locally).
End LocallyNorm.

Module Export NearNorm.
Definition near_simpl := (@near_simpl, @locally_normE,
   @filter_from_normE, @near_locally_norm).
Ltac near_simpl := rewrite ?near_simpl.
End NearNorm.

Section NormedModule2.

Context {T : Type} {K : absRingType} {V : normedModType K}.

Lemma flimi_unique {F} {FF : ProperFilter F} (f : T -> set V) :
  {near F, is_fun f} -> is_prop [set x : V | f `@ F --> x].
Proof. by move=> ffun fx fy; rewrite -closeE; apply: flimi_close. Qed.

Lemma flim_normP {F : set (set V)} {FF : Filter F} (y : V) :
  F --> y <-> forall eps : R, 0 < eps -> \forall y' \near F, `|[y - y']| < eps.
Proof. by rewrite -filter_fromP /= !locally_simpl. Qed.

Lemma flim_normW {F : set (set V)} {FF : Filter F} (y : V) :
  (forall eps : R, 0 < eps -> \forall y' \near F, `|[y - y']| <= eps) ->
  F --> y.
Proof.
move=> cv; apply/flim_normP => _/posnumP[e]; begin_near x.
  by rewrite [e%:num]splitr ltr_spaddl //; near x.
by end_near; apply: cv.
Qed.

Lemma flim_norm {F : set (set V)} {FF : Filter F} (y : V) :
  F --> y -> forall eps, eps > 0 -> \forall y' \near F, `|[y - y']| < eps.
Proof. by move=> /flim_normP. Qed.

Lemma flim_bounded {F : set (set V)} {FF : Filter F} (y : V) :
  F --> y -> forall M, M > `|[y]| -> \forall y' \near F, `|[y']|%real < M.
Proof.
move=> /flim_norm Fy M; rewrite -subr_gt0 => subM_gt0; have := Fy _ subM_gt0.
apply: filterS => y' yy'; rewrite -(@ltr_add2r _ (- `|[y]|)).
rewrite (ler_lt_trans _ yy') //.
by rewrite (ler_trans _ (ler_distm_dist _ _)) // absRE distrC ler_norm.
Qed.

End NormedModule2.
Hint Resolve normm_ge0.
Arguments flim_norm {_ _ F FF}.
Arguments flim_bounded {_ _ F FF}.
(** Rings with absolute values are normed modules *)

(** ** Pairs *)

Section prod_NormedModule.

Context {K : absRingType} {U V : normedModType K}.

Definition prod_norm (x : U * V) := maxr `|[x.1]| `|[x.2]|.

Lemma prod_norm_triangle : forall x y : U * V, prod_norm (x + y) <= prod_norm x + prod_norm y.
Proof.
by move=> [xu xv] [yu yv]; rewrite ler_maxl /=; apply/andP; split;
  apply: ler_trans (ler_normm_add _ _) _; apply: ler_add;
  rewrite ler_maxr lerr // orbC.
Qed.

Lemma prod_norm_scal (l : K) : forall (x : U * V), prod_norm (l *: x) <= abs l * prod_norm x.
Proof.
by move=> [xu xv]; rewrite /prod_norm /= ler_maxl; apply/andP; split;
  apply: ler_trans (ler_normmZ _ _) _; apply: ler_wpmul2l => //;
  rewrite ler_maxr lerr // orbC.
Qed.

Lemma ball_prod_normE : ball = ball_ prod_norm.
Proof.
rewrite funeq2E => - [xu xv] e; rewrite predeqE => - [yu yv].
by rewrite /ball /= /prod_ball -!ball_normE /ball_ ltr_maxl; split=> /andP.
Qed.

Lemma prod_norm_eq0 (x : U * V) : prod_norm x = 0 -> x = 0.
Proof.
case: x => [xu xv]; rewrite /prod_norm /= => nx0.
suff /andP [/eqP -> /eqP ->] : (xu == 0) && (xv == 0) by [].
rewrite -!normm_eq0 !eqr_le !normm_ge0.
have : maxr `|[xu]| `|[xv]| <= 0 by rewrite nx0 lerr.
by rewrite ler_maxl => /andP [-> ->].
Qed.

End prod_NormedModule.

Definition prod_NormedModule_mixin (K : absRingType) (U V : normedModType K) :=
  @NormedModMixin K _ _ _ (@prod_norm K U V) prod_norm_triangle
  prod_norm_scal ball_prod_normE prod_norm_eq0.

Canonical prod_NormedModule (K : absRingType) (U V : normedModType K) :=
  NormedModType K (U * V) (@prod_NormedModule_mixin K U V).

Section NormedModule3.

Context {T : Type} {K : absRingType} {U : normedModType K}
                   {V : normedModType K}.

Lemma flim_norm2P {F : set (set U)} {G : set (set V)}
  {FF : Filter F} {FG : Filter G} (y : U) (z : V):
  (F, G) --> (y, z) <->
  forall eps : R, 0 < eps ->
   \forall y' \near F & z' \near G, `|[(y, z) - (y', z')]| < eps.
Proof. exact: flim_normP. Qed.

(* Lemma flim_norm_supP {F : set (set U)} {G : set (set V)} *)
(*   {FF : Filter F} {FG : Filter G} (y : U) (z : V): *)
(*   (F, G) --> (y, z) <-> *)
(*   forall eps : posreal, {near F & G, forall y' z', *)
(*           (`|[y - y']| < eps) /\ (`|[z - z']| < eps) }. *)
(* Proof. *)
(* rewrite flim_ballP; split => [] P eps. *)
(* - have [[A B] /=[FA GB] ABP] := P eps; exists (A, B) => -//[a b] [/= Aa Bb]. *)
(*   apply/andP; rewrite -ltr_maxl. *)
(*   have /= := (@sub_ball_norm_rev _ _ (_, _)). *)

Lemma flim_norm2 {F : set (set U)} {G : set (set V)}
  {FF : Filter F} {FG : Filter G} (y : U) (z : V):
  (F, G) --> (y, z) ->
  forall eps : R, 0 < eps ->
   \forall y' \near F & z' \near G, `|[(y, z) - (y', z')]| < eps.
Proof. by rewrite flim_normP. Qed.

End NormedModule3.
Arguments flim_norm2 {_ _ _ F G FF FG}.

(** Rings with absolute values are normed modules *)

Section AbsRing_NormedModule.

Variable (K : absRingType).
Implicit Types (x y : K) (eps : R).

Lemma ball_absE : ball = ball_ (@abs K).
Proof. by []. Qed.

Definition AbsRing_NormedModMixin := @NormedModule.Mixin K _ _ _
  (abs : K^o -> R) ler_abs_add absrM ball_absE absr0_eq0.

Canonical AbsRing_NormedModType := NormedModType K K^o AbsRing_NormedModMixin.

End AbsRing_NormedModule.

(* Quick fix for non inferred instances *)
(* This does not fix everything, see below *)
Instance NormedModule_locally_filter (K : absRingType) (V : normedModType K)
  (p : V) :
  @ProperFilter (@NormedModule.sort K (Phant K) V)
  (@locally (@NormedModule.uniformType K (Phant K) V) _ p).
Proof. exact: locally_filter. Qed.

(** Normed vector spaces have some continuous functions *)

Section NVS_continuity.

Context {K : absRingType} {V : normedModType K}.

Lemma flim_add : continuous (fun z : V * V => z.1 + z.2).
Proof.
move=> [/=x y]; apply/flim_normP=> _/posnumP[e].
rewrite !near_simpl /=; begin_near2 a b.
  rewrite opprD addrACA [e%:num]splitr (ler_lt_trans (ler_normm_add _ _)) //.
  by rewrite ltr_add //=; [near a|near b].
by split; end_near=> /=; apply: flim_norm.
Qed.


Lemma flim_scal : continuous (fun z : K * V => z.1 *: z.2).
Proof.
move=> [k x]; apply/flim_normP=> _/posnumP[e].
rewrite !near_simpl /=; begin_near z.
  rewrite (@subr_trans _ (k *: z.2)).
  rewrite (splitr e%:num) (ler_lt_trans (ler_normm_add _ _)) //.
  rewrite ltr_add // -?(scalerBr, scalerBl).
    rewrite (ler_lt_trans (ler_normmZ _ _)) //.
    rewrite (ler_lt_trans (ler_pmul _ _ (_ : _ <= `|k|%real + 1) (lerr _)))
            ?ler_addl//.
    by rewrite -ltr_pdivl_mull // ?(ltr_le_trans ltr01) ?ler_addr //; near z.
  rewrite (ler_lt_trans (ler_normmZ _ _)) //.
  rewrite (ler_lt_trans (ler_pmul _ _ (lerr _) (_ : _ <= `|[x]| + 1))) //.
    by rewrite ltrW //; near z.
  rewrite -ltr_pdivl_mulr // ?(ltr_le_trans ltr01) ?ler_addr //.
  by near z.
end_near; rewrite /= ?near_simpl.
- by apply: (flim_norm _ flim_snd); rewrite mulr_gt0 // ?invr_gt0 ltr_paddl.
- by apply: (flim_bounded _ flim_snd); rewrite ltr_addl.
- apply: (flim_norm (_ : K^o) flim_fst).
  by rewrite mulr_gt0// ?invr_gt0 ltr_paddl.
Qed.
Arguments flim_scal _ _ : clear implicits.

Lemma flim_scalr k : continuous (fun x : V => k *: x).
Proof.
by move=> x; apply: (flim_comp2 (flim_const _) flim_id (flim_scal (_, _))).
Qed.

Lemma flim_scall (x : V) : continuous (fun k : K => k *: x).
Proof.
by move=> k; apply: (flim_comp2 flim_id (flim_const _) (flim_scal (_, _))).
Qed.

Lemma flim_opp : continuous (@GRing.opp V).
Proof.
move=> x; rewrite -scaleN1r => P /flim_scalr /=.
rewrite !locally_nearE near_map.
by apply: filterS => x'; rewrite scaleN1r.
Qed.

End NVS_continuity.

Lemma flim_mult {K : absRingType} (x y : K) :
   z.1 * z.2 @[z --> (x, y)] --> x * y.
Proof. exact: (@flim_scal _ (AbsRing_NormedModType K)). Qed.


(** ** Complete Normed Modules *)

Module CompleteNormedModule.

Section ClassDef.

Variable K : absRingType.

Record class_of (T : Type) := Class {
  base : NormedModule.class_of K T ;
  mixin : Complete.axiom (Uniform.Pack base T)
}.
Local Coercion base : class_of >-> NormedModule.class_of.
Definition base2 T (cT : class_of T) : Complete.class_of T :=
  @Complete.Class _ (@base T cT) (@mixin T cT).
Local Coercion base2 : class_of >-> Complete.class_of.

Structure type (phK : phant K) := Pack { sort; _ : class_of sort ; _ : Type }.
Local Coercion sort : type >-> Sortclass.

Variables (phK : phant K) (cT : type phK) (T : Type).

Definition class := let: Pack _ c _ := cT return class_of cT in c.

Definition pack :=
  fun bT b & phant_id (@NormedModule.class K phK bT) (b : NormedModule.class_of K T) =>
  fun mT m & phant_id (@Complete.class mT) (@Complete.Class T b m) =>
    Pack phK (@Class T b m) T.
Let xT := let: Pack T _ _ := cT in T.
Notation xclass := (class : class_of xT).

Definition eqType := @Equality.Pack cT xclass xT.
Definition choiceType := @Choice.Pack cT xclass xT.
Definition zmodType := @GRing.Zmodule.Pack cT xclass xT.
Definition lmodType := @GRing.Lmodule.Pack K phK cT xclass xT.
Definition pointedType := @Pointed.Pack cT xclass xT.
Definition filteredType := @Filtered.Pack cT cT xclass xT.
Definition topologicalType := @Topological.Pack cT xclass xT.
Definition uniformType := @Uniform.Pack cT xclass xT.
Definition join_zmodType := @GRing.Zmodule.Pack uniformType xclass xT.
Definition join_lmodType := @GRing.Lmodule.Pack K phK uniformType xclass xT.
Definition normedModType := @NormedModule.Pack K phK cT xclass xT.
Definition join_uniformType := @Uniform.Pack normedModType xclass xT.
End ClassDef.

Module Exports.

Coercion base : class_of >-> NormedModule.class_of.
Coercion base2 : class_of >-> Complete.class_of.
Coercion sort : type >-> Sortclass.
Coercion eqType : type >-> Equality.type.
Canonical eqType.
Coercion choiceType : type >-> Choice.type.
Canonical choiceType.
Coercion zmodType : type >-> GRing.Zmodule.type.
Canonical zmodType.
Coercion lmodType : type >-> GRing.Lmodule.type.
Canonical lmodType.
Coercion pointedType : type >-> Pointed.type.
Canonical pointedType.
Coercion filteredType : type >-> Filtered.type.
Canonical filteredType.
Coercion topologicalType : type >-> Topological.type.
Canonical topologicalType.
Coercion uniformType : type >-> Uniform.type.
Canonical uniformType.
Canonical join_zmodType.
Canonical join_lmodType.
Coercion normedModType : type >-> NormedModule.type.
Canonical normedModType.
Canonical join_uniformType.
Notation completeNormedModType K := (type (Phant K)).
Notation "[ 'completeNormedModType' K 'of' T ]" := (@pack _ (Phant K) T _ _ id _ _ id)
  (at level 0, format "[ 'completeNormedModType'  K  'of'  T ]") : form_scope.

End Exports.

End CompleteNormedModule.

Export CompleteNormedModule.Exports.

Section CompleteNormedModule1.

Context {K : absRingType} {V : completeNormedModType K}.

Lemma flim_lim {F} {FF : ProperFilter F} (l : V) :
  F --> l -> lim F = l.
Proof. by move=> Fl; have Fcv := cvgP Fl; apply: flim_unique. Qed.

Context {T : Type}.

Lemma flim_map_lim {F} {FF : ProperFilter F} (f : T -> V) l :
  f @ F --> l -> lim (f @ F) = l.
Proof. exact: flim_lim. Qed.

Lemma flimi_map_lim {F} {FF : ProperFilter F} (f : T -> V -> Prop) l :
  F (fun x => is_prop (f x)) ->
  f `@ F --> l -> lim (f `@ F) = l.
Proof.
move=> f_prop f_l; apply: get_unique => // l' f_l'.
exact: flimi_unique _ f_l' f_l.
Qed.

End CompleteNormedModule1.

(** * Extended Types *)

(** * The topology on natural numbers *)

(* :TODO: ultimately nat could be replaced by any lattice *)
Definition eventually := filter_from setT (fun N => [set n | (N <= n)%N]).
Notation "'\oo'" := eventually : classical_set_scope.

Canonical eventually_filter_source X :=
   @Filtered.Source X _ nat (fun f => f @ \oo).

Global Instance eventually_filter : ProperFilter eventually.
Proof.
eapply @filter_from_proper; last by move=> i _; exists i.
apply: filter_fromT_filter; first by exists 0%N.
move=> i j; exists (maxn i j) => n //=.
by rewrite geq_max => /andP[ltin ltjn].
Qed.

(** * The topology on real numbers *)

(* Definition R_AbsRing_mixin := *)
(*   @AbsRingMixin [ringType of R] _ absr0 absrN1 ler_abs_add absrM absr0_eq0. *)
(* Canonical R_AbsRing := @AbsRingType R R_AbsRing_mixin. *)
(* Definition R_uniformType_mixin := @AbsRingUniformMixin R_AbsRing. *)

(* Canonical R_uniformType := UniformType R R_uniformType_mixin. *)
(*NB: already exists Canonical R_filter := @CanonicalFilter R R locally.*)

(* TODO: Remove R_complete_lim and use lim instead *)
(* Definition R_lim (F : (R -> Prop) -> Prop) : R := *)
(*   sup (fun x : R => `[<F (ball (x + 1) 1)>]). *)

(* move: (Lub_Rbar_correct (fun x : R => F (ball (x + 1) 1))). *)
(* move Hl : (Lub_Rbar _) => l{Hl}; move: l => [x| |] [Hx1 Hx2]. *)
(* - case: (HF (Num.min 2 eps%:num / 2)%:pos) => z Hz. *)
(*   have H1 : z - Num.min 2 eps%:num / 2 + 1 <= x + 1. *)
(*     rewrite ler_add //; apply/RleP/Hx1. *)
(*     apply: filterS Hz. *)
(*     rewrite /ball /= => u; rewrite /AbsRing_ball absrB ltr_distl. *)
(*     rewrite absrB ltr_distl. *)
(*     case/andP => {Hx1 Hx2 FF HF x F} Bu1 Bu2. *)
(*     have H : Num.min 2 eps%:num <= 2 by rewrite ler_minl lerr. *)
(*     rewrite addrK -addrA Bu1 /= (ltr_le_trans Bu2) //. *)
(*     rewrite -addrA ler_add // -addrA addrC ler_subr_addl. *)
(*     by rewrite ler_add // ler_pdivr_mulr // ?mul1r. *)
(*   have H2 : x + 1 <= z + Num.min 2 eps%:num / 2 + 1. *)
(*     rewrite ler_add //; apply/RleP/(Hx2 (Finite _)) => v Hv. *)
(*     apply: Rbar_not_lt_le => /RltP Hlt. *)
(*     apply: filter_not_empty. *)
(*     apply: filterS (filterI Hz Hv). *)
(*     rewrite /ball /= => w []; rewrite /AbsRing_ball //. *)
(*     rewrite absrB ltr_distl => /andP[_ Hw1]. *)
(*     rewrite absrB ltr_distl addrK => /andP[Hw2 _]. *)
(*     by move: (ltr_trans (ltr_trans Hw1 Hlt) Hw2); rewrite ltrr. *)
(*   apply: filterS Hz. *)
(*   rewrite /ball /= => u; rewrite /AbsRing_ball absrB absRE 2!ltr_distl. *)
(*   case/andP => {Hx1 Hx2 F FF HF} H H0. *)
(*   have H3 : Num.min 2 eps%:num <= eps by rewrite ler_minl lerr orbT. *)
(*   apply/andP; split. *)
(*   - move: H1; rewrite -ler_subr_addr addrK ler_subl_addr => H1. *)
(*     rewrite ltr_subl_addr // (ltr_le_trans H0) //. *)
(*     rewrite -ler_subr_addr (ler_trans H1) //. *)
(*     rewrite -ler_subr_addl -!addrA (addrC x) !addrA subrK. *)
(*     rewrite ler_subr_addr -mulrDl ler_pdivr_mulr //. *)
(*     by rewrite -mulr2n -mulr_natl mulrC ler_pmul. *)
(*   - move: H2; rewrite -ler_subr_addr addrK. *)
(*     move/ler_lt_trans; apply. *)
(*     move: H; rewrite // ltr_subl_addr => H. *)
(*     rewrite -ltr_subr_addr (ltr_le_trans H) //. *)
(*     rewrite addrC -ler_subr_addr -!addrA (addrC u) !addrA subrK. *)
(*     rewrite -ler_subl_addr opprK -mulrDl ler_pdivr_mulr // -mulr2n -mulr_natl. *)
(*     by rewrite mulrC ler_pmul. *)
(* - case (HF 1%:pos) => y Fy. *)
(*   case: (Hx2 (y + 1)) => x Fx. *)
(*   apply: Rbar_not_lt_le => Hlt. *)
(*   apply: filter_not_empty. *)
(*   apply: filterS (filterI Fy Fx) => z [Hz1 Hz2]. *)
(*   apply: Rbar_le_not_lt Hlt;  apply/RleP. *)
(*   rewrite -(ler_add2r (-(y - 1))) opprB !addrA -![in X in _ <= X]addrA. *)
(*   rewrite (addrC y) ![in X in _ <= X]addrA subrK. *)
(*   suff : `|x + 1 - y|%R <= 1 + 1 by rewrite ler_norml => /andP[]. *)
(*   rewrite ltrW // (@subr_trans _ z). *)
(*   by rewrite (ler_lt_trans (ler_norm_add _ _)) // ltr_add // distrC. *)
(* - case: (HF 1%:pos) => y Fy. *)
(*   case: (Hx1 (y - 1)); by rewrite addrAC addrK. *)
(* Qed. *)
(* Admitted. *)

Arguments flim_normW {_ _ F FF}.

Lemma filterP_strong T (F : set (set T)) {FF : Filter F} (P : set T) :
  (exists Q : set T, exists FQ  : F Q, forall x : T, Q x -> P x) <-> F P.
Proof.
split; last by exists P.
by move=> [Q [FQ QP]]; apply: (filterS QP).
Qed.

(* :TODO: add to mathcomp *)
Lemma ltr_distW (R : realDomainType) (x y e : R):
   (`|x - y|%R < e) -> y - e < x.
Proof. by rewrite ltr_distl => /andP[]. Qed.

(* :TODO: add to mathcomp *)
Lemma ler_distW (R : realDomainType) (x y e : R):
   (`|x - y|%R <= e) -> y - e <= x.
Proof. by rewrite ler_distl => /andP[]. Qed.

Lemma R_complete (F : set (set R)) : ProperFilter F -> cauchy F -> cvg F.
Proof.
move=> FF F_cauchy; apply/cvg_ex.
pose D := \bigcap_(A in F) (down (mem A)).
have /cauchyP /(_ 1) [//|x0 x01] := F_cauchy.
have D_has_sup : has_sup (mem D); first split.
- exists (x0 - 1); rewrite in_setE => A FA.
  apply/existsbP; have_near F x; first exists x.
    by rewrite ler_distW 1?distrC 1?ltrW ?andbT ?in_setE //; near x.
  end_near.
- exists (x0 + 1); apply/forallbP => x; apply/implyP; rewrite in_setE.
  move=> /(_ _ x01) /existsbP [y /andP[]]; rewrite in_setE.
  rewrite -[ball _ _ _]/(_ (_ < _)) ltr_distl ltr_subl_addr => /andP[/ltrW].
  by move=> /(ler_trans _) yx01 _ /yx01.
exists (sup (mem D)).
apply: (flim_normW (_ : R^o)) => /= _ /posnumP[eps]; begin_near x.
  rewrite ler_distl sup_upper_bound //=.
    apply: sup_le_ub => //; first by case: D_has_sup.
    apply/forallbP => y; apply/implyP; rewrite in_setE.
    move=> /(_ (ball_ norm x eps%:num) _) /existsbP []; first by near x.
    move=> z /andP[]; rewrite in_setE /ball_ ltr_distl ltr_subl_addr.
    by move=> /andP [/ltrW /(ler_trans _) le_xeps _ /le_xeps].
  rewrite in_setE /D /= => A FA; have_near F y.
    apply/existsbP; exists y; apply/andP; split.
      by rewrite in_setE; near y.
    rewrite ler_subl_addl -ler_subl_addr ltrW //.
    by suff: `|x - y| < eps%:num; [by rewrite ltr_norml => /andP[_] | near y].
  end_near; near x.
by end_near; rewrite /= !near_simpl; apply: nearP_dep; apply: F_cauchy.
Qed.

Canonical R_completeType := CompleteType R R_complete.

Canonical R_NormedModule := [normedModType R of R^o].
Canonical R_CompleteNormedModule := [completeNormedModType R of R^o].

Definition at_left x := within (fun u : R => u < x) (locally x).
Definition at_right x := within (fun u : R => x < u) (locally x).
(* :TODO: We should have filter notation ^- and ^+ for these *)

Global Instance at_right_proper_filter (x : R) : ProperFilter (at_right x).
Proof.
apply: Build_ProperFilter' => -[_ /posnumP[d] /(_ (x + d%:num / 2))].
apply; last (by rewrite ltr_addl); rewrite /AbsRing_ball /=.
rewrite opprD !addrA subrr add0r absrN absRE normf_div !ger0_norm //.
by rewrite ltr_pdivr_mulr // ltr_pmulr // (_ : 1 = 1%:R) // ltr_nat.
Qed.

Global Instance at_left_proper_filter (x : R) : ProperFilter (at_left x).
Proof.
apply: Build_ProperFilter' => -[_ /posnumP[d] /(_ (x - d%:num / 2))].
apply; last (by rewrite ltr_subl_addl ltr_addr); rewrite /AbsRing_ball /=.
rewrite opprD !addrA subrr add0r opprK absRE normf_div !ger0_norm //.
by rewrite ltr_pdivr_mulr // ltr_pmulr // (_ : 1 = 1%:R) // ltr_nat.
Qed.

(** Continuity of norm *)

Lemma continuous_norm {K : absRingType} {V : normedModType K} :
  continuous (@norm _ V).
Proof.
move=> x; apply/(@flim_normP _ [normedModType R of R^o]) => _/posnumP[e] /=.
rewrite !near_simpl; apply/locally_normP; exists e%:num => // y Hy.
exact/(ler_lt_trans (ler_distm_dist _ _)).
Qed.

(* :TODO: yet, not used anywhere?! *)
Lemma flim_norm0 {U} {K : absRingType} {V : normedModType K}
  {F : set (set U)} {FF : Filter F} (f : U -> V) :
  (fun x => `|[f x]|) @ F --> (0 : R)
  -> f @ F --> (0 : V).
Proof.
move=> /(flim_norm (_ : R^o)) fx0; apply/flim_normP => _/posnumP[e].
rewrite near_simpl; have := fx0 _ [gt0 of e%:num]; rewrite near_simpl.
by apply: filterS => x; rewrite !sub0r !normmN [ `|[_]| ]ger0_norm.
Qed.

Lemma cvg_seq_bounded {K : absRingType} {V : normedModType K} (a : nat -> V) :
  [cvg a in V] -> {M : R | forall n, norm (a n) <= M}.
Proof.
move=> a_cvg; suff: exists M, forall n, norm (a n) <= M.
  by move=> /getPex; set M := get _; exists M.
pose M := `|[lim (a @ \oo)]| + 1.
have [] := !! flim_bounded _ a_cvg M; first by rewrite ltr_addl.
move=> N /= _ /(_ _ _) /ltrW a_leM.
exists (maxr M (\big[maxr/M]_(n < N) `|[a (val (rev_ord n))]|)) => /= n.
rewrite ler_maxr; have [nN|nN] := leqP N n; first by rewrite a_leM.
apply/orP; right => {a_leM}; elim: N n nN=> //= N IHN n.
rewrite leq_eqVlt => /orP[/eqP[->] |/IHN a_le];
by rewrite big_ord_recl subn1 /= ler_maxr ?a_le ?lerr ?orbT.
Qed.

(** Some open sets of [R] *)

Lemma open_lt (y : R) : open (< y).
Proof.
move=> x /=; rewrite -subr_gt0 => yDx_gt0; exists (y - x) => // z.
by rewrite /AbsRing_ball /= absrB ltr_distl addrCA subrr addr0 => /andP[].
Qed.
Hint Resolve open_lt.

Lemma open_gt (y : R) : open (> y).
Proof.
move=> x /=; rewrite -subr_gt0 => xDy_gt0; exists (x - y) => // z.
by rewrite /AbsRing_ball /= absrB ltr_distl opprB addrCA subrr addr0 => /andP[].
Qed.
Hint Resolve open_gt.

Lemma open_neq (y : R) : open (xpredC (eq_op^~ y)).
Proof.
rewrite (_ : xpredC _ = (< y) `|` (> y) :> set _) /=.
  by apply: openU => //; apply: open_lt.
rewrite predeqE => x /=; rewrite eqr_le !lerNgt negb_and !negbK orbC.
by symmetry; apply (rwP orP).
Qed.

(** Some closed sets of [R] *)

Lemma closed_le (y : R) : closed (<= y).
Proof.
rewrite (_ : (<= _) = ~` (> y) :> set _).
  by apply: closedN; exact: open_gt.
by rewrite predeqE => x /=; rewrite lerNgt; split => /negP.
Qed.

Lemma closed_ge (y : R) : closed (>= y).
Proof.
rewrite (_ : (>= _) = ~` (< y) :> set _).
  by apply: closedN; exact: open_lt.
by rewrite predeqE => x /=; rewrite lerNgt; split => /negP.
Qed.

Lemma closed_eq (y : R) : closed (eq^~ y).
Proof.
rewrite [X in closed X](_ : (eq^~ _) = ~` (xpredC (eq_op^~ y))).
  by apply: closedN; exact: open_neq.
by rewrite predeqE /setC => x /=; rewrite (rwP eqP); case: eqP; split.
Qed.

(** Local properties in [R] *)

Lemma locally_interval (P : R -> Prop) (x : R) (a b : Rbar) :
  Rbar_lt a x -> Rbar_lt x b ->
  (forall (y : R), Rbar_lt a y -> Rbar_lt y b -> P y) ->
  locally x P.
Proof.
move => Hax Hxb Hp; case: (Rbar_lt_locally _ _ _ Hax Hxb) => d Hd.
exists d%:num => //= y; rewrite /AbsRing_ball /= absrB.
by move=> /Hd /andP[??]; apply: Hp.
Qed.

(** * Topology on [R]² *)

(* Lemma locally_2d_align : *)
(*   forall (P Q : R -> R -> Prop) x y, *)
(*   ( forall eps : posreal, (forall uv, ball (x, y) eps uv -> P uv.1 uv.2) -> *)
(*     forall uv, ball (x, y) eps uv -> Q uv.1 uv.2 ) -> *)
(*   {near x & y, forall x y, P x y} ->  *)
(*   {near x & y, forall x y, Q x y}. *)
(* Proof. *)
(* move=> P Q x y /= K => /locallyP [d _ H]. *)
(* apply/locallyP; exists d => // uv Huv. *)
(* by apply (K d) => //. *)
(* Qed. *)

(* Lemma locally_2d_1d_const_x : *)
(*   forall (P : R -> R -> Prop) x y, *)
(*   locally_2d x y P -> *)
(*   locally y (fun t => P x t). *)
(* Proof. *)
(* move=> P x y /locallyP [d _ Hd]. *)
(* exists d => // z Hz. *)
(* by apply (Hd (x, z)). *)
(* Qed. *)

(* Lemma locally_2d_1d_const_y : *)
(*   forall (P : R -> R -> Prop) x y, *)
(*   locally_2d x y P -> *)
(*   locally x (fun t => P t y). *)
(* Proof. *)
(* move=> P x y /locallyP [d _ Hd]. *)
(* apply/locallyP; exists d => // z Hz. *)
(* by apply (Hd (z, y)). *)
(* Qed. *)

Lemma locally_2d_1d_strong (P : R -> R -> Prop) (x y : R):
  (\near x & y, P x y) ->
  \forall u \near x & v \near y,
      forall (t : R), 0 <= t <= 1 ->
      \forall z \near t, \forall a \near (x + z * (u - x))
                               & b \near (y + z * (v - y)), P a b.
Proof.
(* move=> P x y. *)
(* apply locally_2d_align => eps HP uv Huv t Ht. *)
(* set u := uv.1. set v := uv.2. *)
(* have Zm : 0 <= Num.max `|u - x| `|v - y| by rewrite ler_maxr 2!normr_ge0. *)
(* rewrite ler_eqVlt in Zm. *)
(* case/orP : Zm => Zm. *)
(* - apply filterE => z. *)
(*   apply/locallyP. *)
(*   exists eps => // pq. *)
(*   rewrite !(RminusE,RmultE,RplusE). *)
(*   move: (Zm). *)
(*   have : Num.max `|u - x| `|v - y| <= 0 by rewrite -(eqP Zm). *)
(*   rewrite ler_maxl => /andP[H1 H2] _. *)
(*   rewrite (_ : u - x = 0); last by apply/eqP; rewrite -normr_le0. *)
(*   rewrite (_ : v - y = 0); last by apply/eqP; rewrite -normr_le0. *)
(*   rewrite !(mulr0,addr0); by apply HP. *)
(* - have : Num.max (`|u - x|) (`|v - y|) < eps. *)
(*     rewrite ltr_maxl; apply/andP; split. *)
(*     - case: Huv => /sub_ball_abs /=; by rewrite mul1r absrB. *)
(*     - case: Huv => _ /sub_ball_abs /=; by rewrite mul1r absrB. *)
(*   rewrite -subr_gt0 => /RltP H1. *)
(*   set d1 := mkposreal _ H1. *)
(*   have /RltP H2 : 0 < pos d1 / 2 / Num.max `|u - x| `|v - y| *)
(*     by rewrite mulr_gt0 // invr_gt0. *)
(*   set d2 := mkposreal _ H2. *)
(*   exists d2 => // z Hz. *)
(*   apply/locallyP. *)
(*   exists [posreal of d1 / 2] => //= pq Hpq. *)
(*   set p := pq.1. set q := pq.2. *)
(*   apply HP; split. *)
(*   + apply/sub_abs_ball => /=. *)
(*     rewrite absrB. *)
(*     rewrite (_ : p - x = p - (x + z * (u - x)) + (z - t + t) * (u - x)); last first. *)
(*       by rewrite subrK opprD addrA subrK. *)
(*     apply: (ler_lt_trans (ler_abs_add _ _)). *)
(*     rewrite (_ : pos eps = pos d1 / 2 + (pos eps - pos d1 / 2)); last first. *)
(*       by rewrite addrCA subrr addr0. *)
(*     rewrite (_ : pos eps - _ = d1) // in Hpq. *)
(*     case: Hpq => /sub_ball_abs Hp /sub_ball_abs Hq. *)
(*     rewrite mul1r /= (_ : pos eps - _ = d1) // !(RminusE,RplusE,RmultE,RdivE) // in Hp, Hq. *)
(*     rewrite absrB in Hp. rewrite absrB in Hq. *)
(*     rewrite (ltr_le_add Hp) // (ler_trans (absrM _ _)) //. *)
(*     apply (@ler_trans _ ((pos d2 + 1) * Num.max `|u - x| `|v - y|)). *)
(*     apply ler_pmul; [by rewrite normr_ge0 | by rewrite normr_ge0 | | ]. *)
(*     rewrite (ler_trans (ler_abs_add _ _)) // ler_add //. *)
(*     move/sub_ball_abs : Hz; rewrite mul1r => tzd2; by rewrite absrB ltrW. *)
(*     rewrite absRE ger0_norm //; by case/andP: Ht. *)
(*     by rewrite ler_maxr lerr. *)
(*     rewrite /d2 /d1 /=. *)
(*     set n := Num.max _ _. *)
(*     rewrite mulrDl mul1r -mulrA mulVr ?unitfE ?lt0r_neq0 // mulr1. *)
(*     rewrite ler_sub_addr addrAC -mulrDl -mulr2n -mulr_natr. *)
(*     by rewrite -mulrA mulrV ?mulr1 ?unitfE // subrK. *)
(*   + apply/sub_abs_ball => /=. *)
(*     rewrite absrB. *)
(*     rewrite (_ : (q - y) = (q - (y + z * (v - y)) + (z - t + t) * (v - y))); last first. *)
(*       by rewrite subrK opprD addrA subrK. *)
(*     apply: (ler_lt_trans (ler_abs_add _ _)). *)
(*     rewrite (_ : pos eps = pos d1 / 2 + (pos eps - pos d1 / 2)); last first. *)
(*       by rewrite addrCA subrr addr0. *)
(*     rewrite (_ : pos eps - _ = d1) // in Hpq. *)
(*     case: Hpq => /sub_ball_abs Hp /sub_ball_abs Hq. *)
(*     rewrite mul1r /= (_ : pos eps - _ = d1) // !(RminusE,RplusE,RmultE,RdivE) // in Hp, Hq. *)
(*     rewrite absrB in Hp. rewrite absrB in Hq. *)
(*     rewrite (ltr_le_add Hq) // (ler_trans (absrM _ _)) //. *)
(*     rewrite (@ler_trans _ ((pos d2 + 1) * Num.max `|u - x| `|v - y|)) //. *)
(*     apply ler_pmul; [by rewrite normr_ge0 | by rewrite normr_ge0 | | ]. *)
(*     rewrite (ler_trans (ler_abs_add _ _)) // ler_add //. *)
(*     move/sub_ball_abs : Hz; rewrite mul1r => tzd2; by rewrite absrB ltrW. *)
(*     rewrite absRE ger0_norm //; by case/andP: Ht. *)
(*     by rewrite ler_maxr lerr orbT. *)
(*     rewrite /d2 /d1 /=. *)
(*     set n := Num.max _ _. *)
(*     rewrite mulrDl mul1r -mulrA mulVr ?unitfE ?lt0r_neq0 // mulr1. *)
(*     rewrite ler_sub_addr addrAC -mulrDl -mulr2n -mulr_natr. *)
(*     by rewrite -mulrA mulrV ?mulr1 ?unitfE // subrK. *)
(* Qed. *)
Admitted.

(* TODO redo *)
(* Lemma locally_2d_1d (P : R -> R -> Prop) x y : *)
(*   locally_2d x y P -> *)
(*   locally_2d x y (fun u v => forall t, 0 <= t <= 1 -> locally_2d (x + t * (u - x)) (y + t * (v - y)) P). *)
(* Proof. *)
(* move/locally_2d_1d_strong. *)
(* apply: locally_2d_impl. *)
(* apply locally_2d_forall => u v H t Ht. *)
(* specialize (H t Ht). *)
(* have : locally t (fun z => locally_2d (x + z * (u - x)) (y + z * (v - y)) P) by []. *)
(* by apply: locally_singleton. *)
(* Qed. *)

(* TODO redo *)
(* Lemma locally_2d_ex_dec : *)
(*   forall P x y, *)
(*   (forall x y, P x y \/ ~P x y) -> *)
(*   locally_2d x y P -> *)
(*   {d : posreal | forall u v, `|u - x| < d -> `|v - y| < d -> P u v}. *)
(* Proof. *)
(* move=> P x y P_dec H. *)
(* destruct (@locally_ex _ (x, y) (fun z => P (fst z) (snd z))) as [d Hd]. *)
(* - move: H => /locallyP [e _ H]. *)
(*   by apply/locallyP; exists e. *)
(* exists d=>  u v Hu Hv. *)
(* by apply (Hd (u, v)) => /=; split; apply sub_abs_ball; rewrite absrB. *)
(* Qed. *)

(** * Some Topology on [Rbar] *)

(* NB: already defined in R_scope in Rbar.v *)
Notation "'+oo'" := p_infty : real_scope.
Notation "'-oo'" := m_infty : real_scope.

Definition Rbar_locally' (a : Rbar) (P : R -> Prop) :=
  match a with
    | Finite a => locally' a P
    | +oo => exists M : R, forall x, M < x -> P x
    | -oo => exists M : R, forall x, x < M -> P x
  end.
Definition Rbar_locally (a : Rbar) (P : R -> Prop) :=
  match a with
    | Finite a => locally a P
    | +oo => exists M : R, forall x, M < x -> P x
    | -oo => exists M : R, forall x, x < M -> P x
  end.

Canonical Rbar_eqType := EqType Rbar gen_eqMixin.
Canonical Rbar_choiceType := ChoiceType Rbar gen_choiceMixin.
Canonical Rbar_pointed := PointedType Rbar (+oo).
Canonical Rbar_filter := FilteredType R Rbar (Rbar_locally).

Global Instance Rbar_locally'_filter : forall x, ProperFilter (Rbar_locally' x).
Proof.
(* move=> [x| |] ; (constructor ; [idtac | constructor]). *)
(* - case => _/posnumP[eps] HP. *)
(*   apply: (HP (x + (eps : R) / 2)). *)
(*     rewrite /ball /= /AbsRing_ball opprD addrA subrr add0r absrN. *)
(*     rewrite !absRE normf_div !ger0_norm // ltr_pdivr_mulr //. *)
(*     by rewrite mulr_natr mulr2n ltr_addr. *)
(*   move/eqP; rewrite eq_sym addrC -subr_eq subrr => /eqP. *)
(*   by apply/eqP; rewrite ltr_eqF. *)
(* - now exists 1. *)
(* - move=> P Q [_/posnumP[dP] HP] [_/posnumP[dQ] HQ]. *)
(*   exists (Num.min (dP : R) (dQ : R)) => // y Hy H; split. *)
(*   + apply/(HP _ _ H)/sub_abs_ball; move/sub_ball_abs : Hy; rewrite mul1r /=. *)
(*     move/ltr_le_trans; apply; by rewrite ler_minl lerr. *)
(*   + apply/(HQ _ _ H)/sub_abs_ball; move/sub_ball_abs : Hy. *)
(*     rewrite mul1r /= => /ltr_le_trans; apply;  by rewrite ler_minl lerr orbT. *)
(* - move=> P Q H [_ /posnumP[dP] HP]. *)
(*   exists dP => // y Hy H'; by apply/H/HP. *)
(* - case=> N HP. *)
(*   apply: (HP (N + 1)). *)
(*   by rewrite ltr_addl. *)
(* - now exists 0. *)
(* - move=> P Q [MP HP] [MQ HQ]. *)
(*   exists (Num.max MP MQ) => y Hy; split. *)
(*   + apply: HP; by rewrite (ler_lt_trans _ Hy) // ler_maxr lerr. *)
(*   + apply: HQ; by rewrite (ler_lt_trans _ Hy) // ler_maxr lerr orbT. *)
(* - move=> P Q H [dP HP]. *)
(*   exists dP => y Hy; by apply/H/HP. *)
(* - case=> N HP. *)
(*   apply: (HP (N - 1)). *)
(*   by rewrite ltr_subl_addl ltr_addr. *)
(* - now exists 0. *)
(* - move=> P Q [MP HP] [MQ HQ]. *)
(*   exists (Num.min MP MQ) => y Hy; split. *)
(*   + apply/HP/(ltr_le_trans Hy); by rewrite ler_minl lerr. *)
(*   + apply/HQ/(ltr_le_trans Hy); by rewrite ler_minl lerr orbT. *)
(* - move=> P Q H [dP HP]. *)
(*   exists dP => y Hy; by apply/H/HP. *)
(* Qed. *)
Admitted.

Global Instance Rbar_locally_filter : forall x, ProperFilter (Rbar_locally x).
Proof.
case=> [x||].
by apply/locally_filter.
exact: (Rbar_locally'_filter +oo).
exact: (Rbar_locally'_filter -oo).
Qed.

(** Open sets in [Rbar] *)

Lemma open_Rbar_lt y : open (fun u : R => Rbar_lt u y).
Proof.
case: y => [y||] /=.
exact: open_lt.
by rewrite trueE; apply: openT.
by rewrite falseE; apply: open0.
Qed.

Lemma open_Rbar_gt y : open (fun u : R => Rbar_lt y u).
Proof.
case: y => [y||] /=.
exact: open_gt.
by rewrite falseE; apply: open0.
by rewrite trueE; apply: openT.
Qed.

Lemma open_Rbar_lt' x y : Rbar_lt x y -> Rbar_locally x (fun u => Rbar_lt u y).
Proof.
case: x => [x|//|] xy; first exact: open_Rbar_lt.
case: y => [y||//] /= in xy *.
exists y => /= x ? //.
by exists 0.
Qed.

Lemma open_Rbar_gt' x y : Rbar_lt y x -> Rbar_locally x (fun u => Rbar_lt y u).
Proof.
case: x => [x||] //=; do ?[exact: open_Rbar_gt];
  case: y => [y||] //=; do ?by exists 0.
by exists y => x yx //=.
Qed.

Lemma Rbar_locally'_le x : Rbar_locally' x --> Rbar_locally x.
Proof.
move: x => [x P [_/posnumP[e] HP] |x P|x P] //=.
by exists e%:num => // ???; apply: HP.
Qed.

Lemma Rbar_locally'_le_finite (x : R) : Rbar_locally' x --> locally x.
Proof.
by move=> P [_/posnumP[e] HP] //=; exists e%:num => // ???; apply: HP.
Qed.

(** * Some limits on real functions *)

Definition Rbar_loc_seq (x : Rbar) (n : nat) := match x with
    | Finite x => x + (INR n + 1)^-1
    | +oo => INR n
    | -oo => - INR n
  end.

Lemma flim_Rbar_loc_seq x : Rbar_loc_seq x --> Rbar_locally' x.
Proof.
move=> P; rewrite /Rbar_loc_seq.
case: x => /= [x [_/posnumP[delta] Hp] |[delta Hp] |[delta Hp]].
(* - (* x \in R *) *)
(*   case: (nfloor_ex (delta^-1)) => [ | N [_ /RltP HN]]. *)
(*     by apply Rlt_le, Rinv_0_lt_compat, delta. *)
(*   exists N => // n Hn. *)
(*   apply: Hp => /=. *)
(*     rewrite /ball /= /AbsRing_ball. *)
(*     rewrite INRE (_ : n%:R + _ = n.+1%:R); last by rewrite -addn1 natrD. *)
(*     rewrite opprD addrA subrr add0r absrN absRE ger0_norm //. *)
(*     rewrite -(invrK (pos delta)) ltr_pinv; last 2 first. *)
(*       by rewrite inE ltr0n andbT unitfE. *)
(*       by rewrite !inE unitfE gtr_eqF /= invr_gt0. *)
(*     move: HN; rewrite RinvE // RplusE => /ltr_le_trans; apply. *)
(*     by rewrite -addn1 natrD ler_add // INRE // ler_nat. *)
(*   move/eqP. *)
(*   rewrite eq_sym addrC -subr_eq subrr eq_sym INRE. *)
(*   rewrite (_ : n%:R + 1 = n.+1%:R); last by rewrite -addn1 natrD. *)
(*   by rewrite invr_eq0 pnatr_eq0. *)
(* - (* x = +oo *) *)
(*   case: (nfloor_ex (Num.max 0 delta)) => [ | N [_ /RltP HN]]. *)
(*     by apply/RleP; rewrite ler_maxr lerr. *)
(*   exists N.+1 => // n. *)
(*   rewrite -(@ler_nat [numDomainType of R]) => Hn. *)
(*   apply: Hp. *)
(*   move: HN; rewrite RplusE INRE (_ : _ + 1 = N%:R + 1%:R) // -natrD addn1 => HN. *)
(*   move: (ltr_le_trans HN Hn); rewrite INRE; apply: ler_lt_trans. *)
(*   by rewrite ler_maxr lerr orbT. *)
(* - (* x = -oo *) *)
(*   case: (nfloor_ex (Num.max 0 (-delta))) => [ | N [_ /RltP HN]]. *)
(*     by apply/RleP; rewrite ler_maxr lerr. *)
(*   exists N.+1 => // n. *)
(*   rewrite -(@ler_nat [numDomainType of R]) => Hn. *)
(*   apply: Hp. *)
(*   move: HN; rewrite RplusE INRE (_ : _ + 1 = N%:R + 1%:R) // -natrD addn1 => HN. *)
(*   rewrite lter_oppl. *)
(*   move: (ltr_le_trans HN Hn); rewrite INRE; apply: ler_lt_trans. *)
(*   by rewrite ler_maxr lerr orbT. *)
(* Qed. *)
Admitted.

Lemma continuity_pt_locally f x : continuity_pt f x <->
  forall eps : posreal, locally x (fun u => Rabs (f u - f x) < eps (* TODO: express using ball?*)).
Proof.
(* split. *)
(* - move=> H eps. *)
(*   move: (H eps%:num [gt0 of eps%:num]) => {H} [d [H1 H2]]. *)
(*   rewrite /= /R_dist /D_x /no_cond in H2. *)
(*   exists (mkposreal _ H1) => // y H. *)
(*   case/boolP: (x == y) => [/eqP <-|xy]. *)
(*   + by rewrite RminusE subrr Rabs_R0. *)
(*   + apply/RltP/H2; split; [split => //; by apply/eqP|]. *)
(*     by move/sub_ball_abs : H; rewrite mul1r /= absrB => /RltP. *)
(* - move=> H eps He. *)
(*   move: (H (mkposreal _ He)) => {H} [_/posnumP[d] H]. *)
(*   exists d; split=>//. *)
(*   move=> h [Zh Hh]. *)
(*   apply/RltP/H. *)
(*   apply/(@sub_norm_ball_pos _ [normedModType R of R^o] x d)/RltP. *)
(*   by rewrite /ball_norm -normmB. *)
Admitted.

Lemma continuity_pt_flim (f : R -> R) (x : R) :
  continuity_pt f x <-> {for x, continuous f}.
Proof.
eapply iff_trans; first exact: continuity_pt_locally.
apply iff_sym.
have FF : Filter (f @ x) by typeclasses eauto.
case: (@flim_ballP _ (f @ x) FF (f x)) => {FF}H1 H2.
(* TODO: in need for lemmas and/or refactoring of already existing lemmas (ball vs. Rabs) *)
split => [{H2} /H1{H1} H1 eps|{H1} H].
- have {H1} [//|_/posnumP[x0] Hx0] := H1 eps%:num.
  exists x0%:num => // Hx0' /Hx0 /=.
  by rewrite ball_absE /= absrB; apply.
- apply H2 => _ /posnumP[eps]; move: (H eps) => {H} [_ /posnumP[x0] Hx0].
  exists x0%:num => // y /Hx0 /= {Hx0}Hx0.
  by rewrite ball_absE /= absrB.
Qed.

Lemma continuity_ptE (f : R -> R) (x : R) :
  continuity_pt f x <-> {for x, continuous f}.
Proof. exact: continuity_pt_flim. Qed.

Lemma continuous_withinNx {U V : uniformType} (Ueqdec : forall x y : U, x = y \/ x <> y)
  (f : U -> V) x :
  {for x, continuous f} <-> f @ locally' x --> f x.
Proof.
split=> - cfx P /= fxP.
  rewrite /locally' !near_simpl near_withinE.
  by rewrite /locally'; apply: flim_within; apply/cfx.
 (* :BUG: ssr apply: does not work,
    because the type of the filter is not infered *)
rewrite !locally_nearE !near_map !near_locally in fxP *.
have /= := cfx P fxP.
(* TODO: make things appear in canonical form i.e. {near x, ...} *)
rewrite !near_simpl => /filterP [//= Q Qx QP].
apply/filterP; exists (fun y => y <> x -> Q y) => // y Qy.
by have [->|/Qy /QP //] := Ueqdec y x; apply: locally_singleton.
Qed.

Lemma continuity_pt_flim' f x :
  continuity_pt f x <-> f @ locally' x --> f x.
Proof. by rewrite continuity_ptE continuous_withinNx //; exact: Req_dec. Qed.

Lemma continuity_pt_locally' f x :
  continuity_pt f x <->
  forall eps : R, 0 < eps -> locally' x (fun u => `|f x - f u| < eps)%R.
Proof.
by rewrite continuity_pt_flim' (@flim_normP _ [normedModType R of R^o]).
Qed.

Lemma locally_pt_comp (P : R -> Prop) (f : R -> R) (x : R) :
  locally (f x) P -> continuity_pt f x -> \near x, P (f x).
Proof. by move=> Lf /continuity_pt_flim; apply. Qed.

(** For Pierre-Yves : definition of sums *)

From mathcomp Require fintype bigop finmap.

Section totally.

Import fintype bigop finmap.
Local Open Scope fset_scope.
(* :TODO: when eventually is generalized to any lattice  by any lattice *)
(* totally can just be replaced by eventually *)
Definition totally {I : choiceType} : set (set {fset I}) :=
  filter_from setT (fun A => [set B | A `<=` B]).

Canonical totally_filter_source {I : choiceType} X :=
  @Filtered.Source X _ {fset I} (fun f => f @ totally).

Instance totally_filter {I : choiceType} : ProperFilter (@totally I).
Proof.
eapply filter_from_proper; last by move=> A _; exists A; rewrite fsubset_refl.
apply: filter_fromT_filter; first by exists fset0.
by move=> A B /=; exists (A `|` B) => P /=; rewrite fsubUset => /andP[].
Qed.

Definition partial_sum {I : choiceType} {R : zmodType}
  (x : I -> R) (A : {fset I}) : R := \sum_(i : A) x (val i).

Definition sum (I : choiceType) {K : absRingType} {R : normedModType K}
   (x : I -> R) : R := lim (partial_sum x).

End totally.
