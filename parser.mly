%{
(* Copyright International Digital Economy Academy, all rights reserved *)
open Syntax



let i = Loc.of_menhir
let make_Pexpr_constant ~loc_ c = Pexpr_constant { c; loc_ }
let make_Pexpr_apply ~loc_ (func, args) = Pexpr_apply { func; args; loc_ }
let make_Pexpr_ident ~loc_ id = Pexpr_ident { id; loc_ }
let make_Pexpr_constraint ~loc_ (expr, ty) = Pexpr_constraint { expr; ty; loc_ }
let make_Pexpr_constr ~loc_ (constr, arg) = Pexpr_constr { constr; arg; loc_ }
let make_Pexpr_tuple ~loc_ exprs = Pexpr_tuple { exprs; loc_ }
let make_Pexpr_array ~loc_ exprs = Pexpr_array { exprs; loc_ }
let make_Pexpr_match ~loc_ (expr, cases) = Pexpr_match { expr; cases; loc_ }
let make_Pexpr_while ~loc_ (loop_cond, loop_body) = Pexpr_while { loop_cond; loop_body; loc_ }
let make_Pexpr_if ~loc_ (cond, ifso, ifnot) = Pexpr_if { cond; ifso; ifnot; loc_ }
let make_Pexpr_record ~loc_ fs = Pexpr_record { fields=fs; loc_ }




let make_Ppat_alias ~loc_ (pat, alias) = Ppat_alias { pat; alias; loc_ }
let make_Ppat_array ~loc_ pats = Ppat_array { pats; loc_ }
let make_Ppat_constant ~loc_ c = Ppat_constant { c; loc_ }
let make_Ppat_constraint ~loc_ (pat, ty) = Ppat_constraint { pat; ty; loc_ }
let make_Ppat_or ~loc_ (pat1, pat2) = Ppat_or { pat1; pat2; loc_ }
let make_Ppat_tuple ~loc_ pats = Ppat_tuple { pats; loc_ }
let make_Ppat_constr ~loc_ (constr, args) = 
    let f xs = 
      match xs with
      | [x] -> x
      | _ -> make_Ppat_tuple ~loc_ xs
    in
    Ppat_constr { constr; arg=Option.map f args; loc_ }  

let make_Ppat_var ~loc_ binder = Ppat_var { binder; loc_ }

let make_Ppat_record ~loc_ fields = Ppat_record { fields; loc_ }

let make_Ptype_var ~loc_ var_name = Ptype_var { var_name; loc_}

let make_Ptype_tuple ~loc_ tys = Ptype_tuple { tys; loc_}
let make_Ptype_constr ~loc_ (constr_id, tys) = Ptype_constr { constr_id; tys; loc_}

let make_uplus ~loc_ name arg =
  match name, arg with
  | "+", Pexpr_constant({c = Const_int _; _}) ->
      arg
  | ("+"|"+."), Pexpr_constant({ c = Const_float _; _}) ->
      arg
  | _ ->
      (make_Pexpr_apply ~loc_ (
        (make_Pexpr_ident ~loc_ ({ var_name = Lident "~+"; loc_ } )),
        [arg]))

let make_uminus ~loc_ name arg =
  match name, arg with
  | "-", Pexpr_constant({ c = Const_int x }) ->
      (make_Pexpr_constant ~loc_ (Const_int (-x)))
  | ("-"|"-."), Pexpr_constant({ c = Const_float x }) ->
      (make_Pexpr_constant ~loc_ (Const_float (-.x)))
  | _ ->
      (make_Pexpr_apply ~loc_ (
        (make_Pexpr_ident ~loc_ ({ var_name = Lident "~-"; loc_ })),
        [arg]))

let make_apply ~loc_ e1 e2 =
  match e1 with
  | Pexpr_constr{ constr = c; arg = None; _ } ->
     (match e2 with
     | [] -> failwith "Syntax error: constructor can't take unit as argument"
     | [ e ] -> make_Pexpr_constr ~loc_ (c, Some e)
     | _ -> make_Pexpr_constr ~loc_ (c, Some (make_Pexpr_tuple ~loc_ e2)))
  | _ ->
      make_Pexpr_apply ~loc_ (e1, e2)

%}

%token <char> CHAR
%token <int> INT
%token <float> FLOAT
%token <string> STRING
%token <string> LIDENT
%token <string> UIDENT
%token <string > COMMENT
%token NEWLINE
%token <string> InFIX1
%token LT "<"
%token GT ">"
%token <string> INFIX2
%token <string> INFIX3
%token <string> INFIX4

%token EOF
%token FALSE
%token TRUE
%token BREAK           "break"
%token CONTINUE        "continue" 
%token STRUCT          "struct"
%token ENUM            "enum" 
%token EQUAL           "=" 
%token EQUALEQUAL      "==" 
%token LPAREN          "(" 
%token RPAREN          ")"
%token STAR            "*" 
%token COMMA          "," 
%token MINUS           "-" 
%token MINUSDOT        "-." 
// %token MINUSGREATER    "->" 
// %token DOT            "."
%token <string>DOT_LIDENT            
%token COLON           ":" 
// %token COLONCOLON     "::" 
// %token COLONEQUAL     /* ":=" */
%token SEMI           
%token LBRACKET        "[" 
// %token LBRACKETBAR     "[|"
// %token LESSMINUS       "<-" 
%token <string> PLUS           "+" 
%token <string> PLUSDOT        "+." 
%token RBRACKET       "]" 
// %token QUOTE          "'" 
%token UNDERSCORE      "_" 
%token BAR             "|" 
// %token BARRBRACKET    "|]" 
%token LBRACE          "{"
%token RBRACE          "}" 
%token AMPERSAND       "&" 
%token AMPERAMPER     "&&" 
%token BARBAR          "||" 
%token <string>PACKAGE_NAME
/* Keywords */

%token AS              "as" 
%token ELSE            "else" 
%token FN            "fn"
%token TOPLEVEL_FN   "func"
%token IF             "if" 
%token LET            "let"
%token VAR            "var" 
%token MATCH          "match" 
%token MUTABLE        "mut" 
%token OR             "or" 
%token TYPE            "type" 
%token FAT_ARROW     "=>" 
%token SLASH          "/"
%token WHILE           "while" 
%nonassoc EQUAL
%nonassoc "as"
%right "|"

%right OR BARBAR
%right AMPERSAND AMPERAMPER


%left InFIX1 "<"  ">" EQUALEQUAL 
%left INFIX2 PLUS PLUSDOT MINUS MINUSDOT
%left INFIX3 STAR SLASH
%right INFIX4
%nonassoc prec_unary_minus
%start    structure


%type <Syntax.impls> structure
%type <Compact.semi_expr_prop > semi_single_bind
%%


non_empty_list_commas( X):
  | x = X ioption(",") { [x] }
  | x = X "," xs = non_empty_list_commas( X) { x :: xs }

%inline list_commas( X):
  | x = option(non_empty_list_commas( X)) {Option.value ~default:[] x}

non_empty_list_semis( X):
  x = X; ioption(SEMI)
    { [ x ] }
| x = X; SEMI; xs = non_empty_list_semis(X)
    { x :: xs }

%inline list_semis(X): x= option(non_empty_list_semis(X)) {Option.value ~default:[] x}

%inline id(x): x {$1}
%inline opt_annot: option(":" t=type_ {t}) {$1}
%inline parameters : delimited("(",separated_list(",",id(b=binder t=opt_annot {b,t})), ")") {$1}

fun_header:
  "func"
    f=binder
    /* TODO: move the quants before self */
    quants=option(delimited("<",separated_nonempty_list(",",UIDENT), ">"))
    ps=option(parameters)
    ts=opt_annot
    {
      f, Option.value quants ~default:[], Option.value ps ~default:[], ts
    }


%inline block_expr: "{" ls=list_semis(semi_single_bind) "}" {Compact.compact ls (i $sloc)}
%inline error_block: error {Compact.compact [] (i $sloc)}
val_header : mut=id("let" {false}| "var"{true}) binder=binder t=opt_annot {mut, binder,t}
structure : list_semis(structure_item) EOF {$1}
structure_item:
  | type_header=type_header components=type_def {
      let tycon, params = type_header in   
      Pimpl_typedef {loc_ = i $sloc ; type_decl = {tycon; params = Option.value params ~default:[]; components}}
    }
  | val_header=val_header  "=" expr = expr {
    let mut,binder,t = val_header in   
    match mut with 
    | false -> 
      let loc_ = i $sloc in   
      Pimpl_letdef {loc_ ; pat = Ppat_var {loc_ = binder.loc_ ; binder }; expr = 
        match t with 
        | None -> expr 
        | Some t -> Pexpr_constraint {loc_; ty = t ; expr} 
      } 
    | true -> Pimpl_letmut { binder; ty = t; expr; loc_ = i $sloc } 
  }
  | t=fun_header body=block_expr {
      let (name, quantifiers, parameters, return_type) = t in
      Pimpl_funcdef {
        loc_ = (i $sloc);
        fun_decl = {
          name;
          func = { parameters; body };
          quantifiers;
          return_type
        }
      }
    }
type_header: "type" tycon=LIDENT params=option(delimited("<", separated_nonempty_list(",",UIDENT) ,">") ) {
  tycon , params 
}    


qual_ident:
  | i=LIDENT { Lident(i) }
  | ps=PACKAGE_NAME id = DOT_LIDENT { Ldot({ pkg = ps; id}) }



%inline semi_expr_semi_opt: ls=non_empty_list_semis(semi_single_bind)  {
  Compact.compact ls (i $sloc)
}

semi_single_bind:
  | a=expr  { 
    (*TODO: the loc field seems to be redundant *)  
    Prop_expr {expr=a;loc=(i $sloc)} }
  | "break" { 
    let loc_ =  (i $sloc) in  
    Prop_expr {expr= Pexpr_break {loc_};loc = loc_} }
  | "continue" {
    let loc_ = i $sloc in 
    Prop_expr {expr = Pexpr_continue {loc_}; loc = loc_ } 
  }  
  | "let" pat=pattern ty=opt_annot "=" expr=expr
    { Prop_let {pat; ty_opt=ty; expr;loc=(i $sloc); pat_loc=(i $loc(pat)); ty_loc=(i $loc(ty))} }
  | "var" binder=binder ty=opt_annot "=" expr=expr 
    { Prop_letmut {binder; ty_opt=ty; expr; loc=(i $sloc)} }           
  | "fn" name=LIDENT params=parameters ty=opt_annot block = block_expr
    { Compact.Prop_letrec {name; name_loc=i $loc(name); params; ty_opt=ty; block; loc=(i $sloc)} }


expr:
  | simple_expr { $1 }  
  | op=id(PLUS {"+"} |PLUSDOT{"+."}) e=expr %prec prec_unary_minus { make_uplus  ~loc_:(i $sloc) op e }
  | op=id(MINUS{"-"}|MINUSDOT{"-."}) e=expr %prec prec_unary_minus { make_uminus  ~loc_:(i $sloc) op e }
  | expr infixop expr {
    let (name, infixloc) = $2 in 
    Pexpr_apply{ func = Pexpr_ident {id = { var_name = Lident name; loc_ = i(infixloc) } ; loc_ = i(infixloc)}; args = [$1; $3]; loc_ = i($sloc)}
  }
  | obj=simple_expr  "[" ind=expr "]" "=" value=expr {
      (make_Pexpr_apply ~loc_:(i $sloc) ((make_Pexpr_ident ~loc_:(i $sloc) { var_name = (Lident "array_set"); loc_ = i $sloc }),
        [obj; ind ; value])) }
  | "if" b=expr ifso=block_expr "else" ifnot=block_expr { (make_Pexpr_if ~loc_:(i $sloc) (b, ifso, Some ifnot)) }
  | "if" b=expr ifso=block_expr   { (make_Pexpr_if ~loc_:(i $sloc) (b, ifso, None)) }
  | "if" b=expr ifso=error_block   { (make_Pexpr_if ~loc_:(i $sloc) (b, ifso, None)) }
  | "while" cond=expr b=block_expr
    { (make_Pexpr_while ~loc_:(i $sloc) (cond, b)) }
  | "while" cond=expr b=error_block  
    { (make_Pexpr_while ~loc_:(i $sloc) (cond, b)) }
  | var=var "=" e=expr { Pexpr_assign { var; expr =e ; loc_ = (i $sloc) } }
  
  | "fn" ps=parameters f = block_expr  { Pexpr_function {loc_=i $sloc; func = {parameters = ps; body = f}} }
  // | "fn" LIDENT f = block_expr  { Pexpr_function {loc_=i $sloc; func = {parameters = [assert false]; body = f}} }
  | "match" e=expr "{" "|"?  mat=separated_nonempty_list("|", pattern "=>" semi_expr_semi_opt {($1,$3)})  "}"  {  (make_Pexpr_match ~loc_:(i $sloc) (e, mat)) }
  | "match" e=expr error {  (make_Pexpr_match ~loc_:(i $sloc) (e, [])) }
  | "{" fs=list_commas( l=label ":" e=expr {(l,e)}) "}" { make_Pexpr_record ~loc_:(i $sloc) (fs) }
  | record=simple_expr  name=DOT_LIDENT "=" field=expr
    { 
      let loc_ =  (i $sloc) in  
      let label_loc = i ($loc(name)) in    
      Pexpr_mutate {record; label = { label_name = name ; loc_ = label_loc}; field ; loc_}
      }
  
simple_expr:
  | e = atomic_expr {e}
  | "_" { Pexpr_hole { loc_ = (i $sloc) ; synthesized = false} }
  | v=var { (make_Pexpr_ident ~loc_:(i $sloc) v) }
  | c=constr { make_Pexpr_constr ~loc_:(i $sloc) (c, None) }
  // | constr_longident_expr { ( ($1, None)) } 
  | obj=simple_expr  "[" index=expr "]" {
      (make_Pexpr_apply
         ~loc_:(i $sloc)
         ((make_Pexpr_ident ~loc_:(i $sloc) ( { var_name = (Lident "array_get"); loc_ = i $sloc })),
          [obj; index])) }
  | f=simple_expr "(" args=list_commas(expr) ")" { make_apply  ~loc_:(i $sloc) f args }
  | record=simple_expr  name=DOT_LIDENT { 
    let loc_ = i $sloc in 
    let label_loc = i($loc(name)) in    
    Pexpr_field {record ; label = { label_name = name ; loc_ = label_loc} ; loc_}}
  | "("  bs=list_commas(semi_expr_semi_opt) ")" { 
    match bs with 
    | [] ->   Pexpr_unit {loc_ = i $sloc}
    | [b] -> b 
    | _ -> make_Pexpr_tuple ~loc_:(i $sloc) bs }  
  | "(" semi_expr_semi_opt ":" type_ ")" { (make_Pexpr_constraint ~loc_:(i $sloc) ($2, $4)) }
  | "[" es = list_commas(expr) "]" { (make_Pexpr_array ~loc_:(i $sloc) es) }  

%inline label:
  name = LIDENT { { label_name = name; loc_=(i $loc) } }
%inline binder:
  name = LIDENT { { binder_name = name; loc_=(i $loc) } }
%inline var:
  name = qual_ident { { var_name = name; loc_=(i $loc) } }

%inline atomic_expr:
  | TRUE { (make_Pexpr_constant ~loc_:(i $sloc) (Const_bool true)) }
  | FALSE { (make_Pexpr_constant ~loc_:(i $sloc) (Const_bool false)) }
  | CHAR { (make_Pexpr_constant ~loc_:(i $sloc) (Const_char $1)) }
  | INT { (make_Pexpr_constant ~loc_:(i $sloc) (Const_int $1)) }
  | FLOAT { (make_Pexpr_constant ~loc_:(i $sloc) (Const_float $1)) }
  | STRING { (make_Pexpr_constant ~loc_:(i $sloc) (Const_string ( $1))) }


 %inline infixop:
  | INFIX4
  | INFIX3  
  | INFIX2
  | InFIX1 {$1, $sloc}
  | "<" {"<", $sloc}
  | ">" {">", $sloc}
  | STAR {"*", $sloc}
  | SLASH {"/", $sloc}
  | PLUS {"+", $sloc}
  | PLUSDOT  {"+.", $sloc}
  | MINUS {"-",$sloc}
  | MINUSDOT {"-.",$sloc}  
  | EQUALEQUAL {"==", $sloc}
  | AMPERSAND {"&", $sloc}
  | AMPERAMPER {"&&", $sloc}
  | OR {"or", $sloc}
  | BARBAR {"||",$sloc}

%inline constr:
  name = UIDENT { { constr_name = name; loc_=(i $loc) } }

pattern:
  | simple_pattern { $1 }
  | b=binder "as" p=pattern { (make_Ppat_alias ~loc_:(i $sloc) (p, b)) }
  | pattern "|" pattern { (make_Ppat_or ~loc_:(i $sloc) ($1, $3)) }
  

simple_pattern:
  | TRUE { (make_Ppat_constant  ~loc_:(i $sloc) (Const_bool true)) }
  | FALSE { (make_Ppat_constant ~loc_:(i $sloc) (Const_bool false)) }
  | CHAR { (make_Ppat_constant ~loc_:(i $sloc) (Const_char $1)) }
  | INT { (make_Ppat_constant ~loc_:(i $sloc) (Const_int $1)) }
  | FLOAT { (make_Ppat_constant ~loc_:(i $sloc) (Const_float $1)) }
  | STRING { (make_Ppat_constant ~loc_:(i $sloc) (Const_string ($1))) }
  | UNDERSCORE { Ppat_any {loc_ = i $sloc } }
  | b=binder  { make_Ppat_var ~loc_:(i $sloc) b }
  | constr=constr ps=option("(" t=separated_nonempty_list(",",pattern) ")" {t}){ make_Ppat_constr ~loc_:(i $sloc) (constr, ps) }
  | "(" pattern ")" { $2 }
  | "(" p = pattern "," ps=separated_nonempty_list(",",pattern) ")"  {make_Ppat_tuple ~loc_:(i $sloc) (p::ps)}     
  | "(" pattern ":" type_ ")" { (make_Ppat_constraint ~loc_:(i $sloc) ($2, $4)) }
  // | "#" "[" pat = pat_list "]" {let ps,tail = pat in  make_pat_list ~loc_:(i $sloc) ps tail}
  | "[" lst=separated_list(",",pattern) "]" { (make_Ppat_array  ~loc_:(i $sloc) lst) }
  | "{" p=separated_list(",", l=label ":" p=pattern { (l, p) }) "}" { (make_Ppat_record ~loc_:(i $sloc) (p)) }
  
type_:
  | "(" t=type_ "," ts=separated_nonempty_list(",", type_)")" { (make_Ptype_tuple ~loc_:(i $sloc) (t::ts)) }
  | "(" t=type_ "," ts=separated_nonempty_list(",",type_) ")" "=>" rty=type_ {
    Ptype_arrow{loc_ = i $sloc ; ty_arg = t::ts ; ty_res = rty}
  }
  | "(" ")" "=>" rty=type_ { Ptype_arrow{loc_ = i $sloc ; ty_arg = [] ; ty_res = rty}}
  | "(" t=type_ ")" rty=option("=>" t2=type_{t2})
      { 
        match rty with
        | None -> t
        | Some rty -> Ptype_arrow{loc_=i($sloc); ty_arg=[t]; ty_res=rty}
      } 
  | UIDENT { (make_Ptype_var  ~loc_:(i $sloc) $1) }  
  // | "(" type_ ")" { $2 }
  | id=qual_ident params=option(delimited("<" ,separated_nonempty_list(",",type_), ">"))  {
    (make_Ptype_constr ~loc_:(i $sloc) (id, (match params with None -> [] | Some params -> params))) }
  | "_" { Ptype_any {loc_ = i $sloc } }
/* type declaration */


type_def:
  | /* empty */ { Ptd_abstract }
  | "struct" "{" fs=non_empty_list_semis(record_decl_field) "}"  {Ptd_record fs}
  | "enum" "{" fs=non_empty_list_semis(id=UIDENT opt=option("("  ts=separated_nonempty_list(",",type_)")"{
    match ts with [t] -> t | _ -> make_Ptype_tuple ~loc_:(i $sloc) ts }) {id,opt}) "}" {Ptd_variant fs}

record_decl_field:
  | mutflag = option("mut") name=LIDENT ":" ty=type_ { {field_name = name; ty; mut = mutflag <> None} }
