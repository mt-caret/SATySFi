open Types

(* -- for test -- *)
(* untyped_abstract_tree -> string *)
let rec string_of_utast (_, utast) =
  match utast with
  | UTStringEmpty         -> "{}"
  | UTNumericConstant(nc) -> string_of_int nc
  | UTBooleanConstant(bc) -> string_of_bool bc
  | UTStringConstant(sc)  -> "{" ^ sc ^ "}"
  | UTUnitConstant        -> "()"
  | UTContentOf(varnm)    -> varnm
  | UTConcat(ut1, ut2)    -> "(" ^ (string_of_utast ut1) ^ " ^ " ^ (string_of_utast ut2) ^ ")"
  | UTApply(ut1, ut2)     -> "(" ^ (string_of_utast ut1) ^ " " ^ (string_of_utast ut2) ^ ")"
  | UTListCons(hd, tl)    -> "(" ^ (string_of_utast hd) ^ " :: " ^ (string_of_utast tl) ^ ")" 
  | UTEndOfList           -> "[]"
  | UTTupleCons(hd, tl)   -> "(" ^ (string_of_utast hd) ^ ", " ^ (string_of_utast tl) ^ ")"
  | UTEndOfTuple          -> "$"
  | UTBreakAndIndent      -> "break"
  | UTLetIn(umlc, ut)     -> "(let ... in " ^ (string_of_utast ut) ^ ")"
  | UTIfThenElse(ut1, ut2, ut3)
      -> "(if " ^ (string_of_utast ut1) ^ " then " ^ (string_of_utast ut2) ^ " else " ^ (string_of_utast ut3) ^ ")"
  | UTLambdaAbstract(_, varnm, ut) -> "(" ^ varnm ^ " -> " ^ (string_of_utast ut) ^ ")"
  | UTFinishHeaderFile    -> "finish"
  | UTPatternMatch(ut, pmcons) -> "(match " ^ (string_of_utast ut) ^ " with" ^ (string_of_pmcons pmcons) ^ ")"
(*  | UTDeclareVariantIn() *)
  | _ -> "?"

and string_of_pmcons (_, pmcons) =
  match pmcons with
  | UTEndOfPatternMatch -> ""
  | UTPatternMatchCons(pat, ut, tail)
      -> " | " ^ (string_of_pat pat) ^ " -> " ^ (string_of_utast ut) ^ (string_of_pmcons tail)
  | UTPatternMatchConsWhen(pat, utb, ut, tail)
      -> " | " ^ (string_of_pat pat) ^ " when " ^ (string_of_utast utb)
          ^ " -> " ^ (string_of_utast ut) ^ (string_of_pmcons tail)

and string_of_pat (_, pat) =
  match pat with
  | UTPNumericConstant(nc)  -> string_of_int nc
  | UTPBooleanConstant(bc)  -> string_of_bool bc
  | UTPStringConstant(ut)   -> string_of_utast ut
  | UTPUnitConstant         -> "()"
  | UTPListCons(hd, tl)     -> (string_of_pat hd) ^ " :: " ^ (string_of_pat tl)
  | UTPEndOfList            ->  "[]"
  | UTPTupleCons(hd, tl)    -> "(" ^ (string_of_pat hd) ^ ", " ^ (string_of_pat tl) ^ ")"
  | UTPEndOfTuple           -> "$"
  | UTPWildCard             -> "_"
  | UTPVariable(varnm)      -> varnm
  | UTPAsVariable(varnm, p) -> "(" ^ (string_of_pat p) ^ " as " ^ varnm ^ ")"
  | UTPConstructor(cnm,p)   -> "(" ^ cnm ^ " " ^ (string_of_pat p) ^ ")"


(* abstract_tree -> string *)
let rec string_of_ast ast =
  match ast with
  | LambdaAbstract(x, m)         -> "(" ^ x ^ " -> " ^ (string_of_ast m) ^ ")"
  | FuncWithEnvironment(x, m, _) -> "(" ^ x ^ " *-> " ^ (string_of_ast m) ^ ")"
  | ContentOf(v)           -> v
  | Apply(m, n)            -> "(" ^ (string_of_ast m) ^ " " ^ (string_of_ast n) ^ ")"
  | Concat(s, t)           -> (string_of_ast s) ^ (string_of_ast t)
  | StringEmpty            -> ""
  | StringConstant(sc)     -> "{" ^ sc ^ "}"
  | NumericConstant(nc)    -> string_of_int nc
  | BooleanConstant(bc)    -> string_of_bool bc
  | IfThenElse(b, t, f)    ->
      "(if " ^ (string_of_ast b) ^ " then " ^ (string_of_ast t) ^ " else " ^ (string_of_ast f) ^ ")"
  | IfClassIsValid(t, f)   -> "(if-class-is-valid " ^ (string_of_ast t) ^ " else " ^ (string_of_ast f) ^ ")"
  | Reference(a)           -> "!" ^ (string_of_ast a)
  | ReferenceFinal(a)      -> "!!" ^ (string_of_ast a)
  | Overwrite(vn, n)       -> "(" ^ vn ^ " <- " ^ (string_of_ast n) ^ ")"
  | MutableValue(mv)       -> "(mutable " ^ (string_of_ast mv) ^ ")"
  | UnitConstant           -> "()"
  | LetMutableIn(vn, d, f) -> "(let-mutable " ^ vn ^ " <- " ^ (string_of_ast d) ^ " in " ^ (string_of_ast f) ^ ")"
  | ListCons(a, cons)      -> "(" ^ (string_of_ast a) ^ " :: " ^ (string_of_ast cons) ^ ")"
  | EndOfList              -> "[]"
  | TupleCons(a, cons)     -> "(" ^ (string_of_ast a) ^ ", " ^ (string_of_ast cons) ^ ")"
  | EndOfTuple             -> "$"
  | BreakAndIndent         -> "break"
  | EvaluatedEnvironment(_)-> "finish"
  | _ -> "?"


(* code_range -> string *)
let describe_position (sttln, sttpos, endln, endpos) =
  if sttln = endln then
    "line " ^ (string_of_int sttln) ^ ", characters " ^ (string_of_int sttpos)
      ^ "-" ^ (string_of_int endpos)
  else
    "line " ^ (string_of_int sttln) ^ ", character " ^ (string_of_int sttpos)
      ^ " to line " ^ (string_of_int endln) ^ ", character " ^ (string_of_int endpos)


let error_reporting rng errmsg = "at " ^ (describe_position rng) ^ ":\n    " ^ errmsg

let bug_reporting rng errmsg = "at " ^ (describe_position rng) ^ ":\n     this cannot happen; " ^ errmsg


(* -- for debug -- *)
let rec string_of_type_struct_basic tystr =
  let (sttln, _, _, _) = Typeenv.get_range_from_type tystr in
    match tystr with
    | StringType(_)                -> if sttln <= 0 then "string" else "string+"
    | IntType(_)                   -> if sttln <= 0 then "int"    else "int+"
    | BoolType(_)                  -> if sttln <= 0 then "bool"   else "bool+"
    | UnitType(_)                  -> if sttln <= 0 then "unit"   else "unit+"
    | VariantType(_, varntnm)      -> if sttln <= 0 then varntnm else varntnm ^ "+"

    | FuncType(_, tydom, tycod)    ->
        let strdom = string_of_type_struct_basic tydom in
        let strcod = string_of_type_struct_basic tycod in
          begin match tydom with
          | FuncType(_, _, _) -> "(" ^ strdom ^ ")"
          | ProductType(_, _) -> "(" ^ strdom ^ ")"
          | _                 -> strdom
          end ^ " ->" ^ (if sttln <= 0 then "+ " else " ") ^ strcod

    | ListType(_, tycont)          ->
        let strcont = string_of_type_struct_basic tycont in
          begin match tycont with
          | FuncType(_, _, _) -> "(" ^ strcont ^ ")"
          | ProductType(_, _) -> "(" ^ strcont ^ ")"
          | _                 -> strcont
          end ^ " list" ^ (if sttln <= 0 then "+" else "")

    | RefType(_, tycont)           ->
        let strcont = string_of_type_struct_basic tycont in
          begin match tycont with
          | FuncType(_, _, _) -> "(" ^ strcont ^ ")"
          | ProductType(_, _) -> "(" ^ strcont ^ ")"
          | _                 -> strcont
          end ^ " ref" ^ (if sttln <= 0 then "+" else "")

    | ProductType(_, tylist)       -> string_of_type_struct_list_basic tylist
    | TypeVariable(_, tvid)        -> "'" ^ (string_of_int tvid) ^ (if sttln <= 0 then "+" else "")
    | TypeSynonym(_, tynm, tycont) -> tynm ^ "(= " ^ (string_of_type_struct_basic tycont) ^ ")"
    | ForallType(tvid, tycont)     ->
        "('" ^ (string_of_int tvid) ^ ". " ^ (string_of_type_struct_basic tycont) ^ ")" ^ (if sttln <= 0 then "+" else "")

and string_of_type_struct_list_basic tylist =
  match tylist with
  | []           -> ""
  | head :: []   ->
      let strhd = string_of_type_struct_basic head in
      ( match head with
        | ProductType(_, _) -> "(" ^ strhd ^ ")"
        | _                 -> strhd
      )
  | head :: tail ->
      let strhd = string_of_type_struct_basic head in
      let strtl = string_of_type_struct_list_basic tail in
        begin match head with
        | ProductType(_, _) -> "(" ^ strhd ^ ")"
        | _                 -> strhd
        end ^ " * " ^ strtl


let meta_max    : type_variable_id ref = ref 0
let unbound_max : type_variable_id ref = ref 0
let unbound_type_valiable_name_list : (type_variable_id * string ) list ref = ref []

(* int -> string *)
let rec variable_name_of_int n =
  ( if n >= 26 then
      variable_name_of_int ((n - n mod 26) / 26 - 1)
    else
      ""
  ) ^ (String.make 1 (Char.chr ((Char.code 'a') + n mod 26)))

(* unit -> string *)
let new_meta_type_variable_name () =
  let res = variable_name_of_int (!meta_max) in
    begin meta_max := !meta_max + 1 ; res end

(* (type_variable_id * string) list -> type_variable_id -> string *)
let rec find_meta_type_variable lst tvid =
  match lst with
  | []             -> raise Not_found
  | (k, v) :: tail -> if k = tvid then v else find_meta_type_variable tail tvid

(* type_variable_id -> string *)
let new_unbound_type_variable_name tvid =
  let res = variable_name_of_int (!unbound_max) in
    begin
      unbound_max := !unbound_max + 1 ;
      unbound_type_valiable_name_list := (tvid, res) :: (!unbound_type_valiable_name_list) ;
      res
    end

(* type_variable_id -> string *)
let find_unbound_type_variable tvid =
  find_meta_type_variable (!unbound_type_valiable_name_list) tvid

(* type_struct -> string *)
let rec string_of_type_struct tystr =
  begin
    meta_max := 0 ;
    unbound_max := 0 ;
    unbound_type_valiable_name_list := [] ;
    string_of_type_struct_sub tystr []
  end

and string_of_type_struct_double tystr1 tystr2 =
  begin
    meta_max := 0 ;
    unbound_max := 0 ;
    unbound_type_valiable_name_list := [] ;
    let strty1 = string_of_type_struct_sub tystr1 [] in
    let strty2 = string_of_type_struct_sub tystr2 [] in
      (strty1, strty2)
  end

(* type_struct -> (type_variable_id * string) list -> string *)
and string_of_type_struct_sub tystr lst =
  match tystr with
  | StringType(_)                -> "string"
  | IntType(_)                   -> "int"
  | BoolType(_)                  -> "bool"
  | UnitType(_)                  -> "unit"
  | VariantType(_, varntnm)      -> varntnm

  | FuncType(_, tydom, tycod)    ->
      let strdom = string_of_type_struct_sub tydom lst in
      let strcod = string_of_type_struct_sub tycod lst in
        begin match tydom with
        | FuncType(_, _, _) -> "(" ^ strdom ^ ")"
        | _                 -> strdom
        end ^ " -> " ^ strcod

  | ListType(_, tycont)          ->
      let strcont = string_of_type_struct_sub tycont lst in
        begin match tycont with
        | FuncType(_, _, _) -> "(" ^ strcont ^ ")"
        | ProductType(_, _) -> "(" ^ strcont ^ ")"
        | _                 -> strcont
        end ^ " list"

  | RefType(_, tycont)           ->
      let strcont = string_of_type_struct_sub tycont lst in
        begin match tycont with
        | FuncType(_, _, _) -> "(" ^ strcont ^ ")"
        | ProductType(_, _) -> "(" ^ strcont ^ ")"
        | _                 -> strcont
        end ^ " ref"

  | ProductType(_, tylist)       -> string_of_type_struct_list tylist lst

  | TypeVariable(_, tvid)        ->
      begin try "'" ^ (find_meta_type_variable lst tvid) with
      | Not_found ->
          "'" ^
            begin try find_unbound_type_variable tvid with
            | Not_found -> new_unbound_type_variable_name tvid
            end
      end

  | TypeSynonym(_, tynm, tycont) -> tynm ^ " (= " ^ (string_of_type_struct_sub tycont lst) ^ ")"

  | ForallType(tvid, tycont)     ->
      let meta = new_meta_type_variable_name () in
        (string_of_type_struct_sub tycont ((tvid, meta) :: lst))


and string_of_type_struct_list tylist lst =
  match tylist with
  | []           -> ""
  | head :: tail ->
      let strhead = string_of_type_struct_sub head lst in
      let strtail = string_of_type_struct_list tail lst in
        begin match head with
        | FuncType(_, _, _) -> "(" ^ strhead ^ ")"
        | ProductType(_, _) -> "(" ^ strhead ^ ")"
        | _                 -> strhead
        end ^
        begin match tail with
        | [] -> ""
        | _  -> " * " ^ strtail
        end