(** Pretty-printing of expressions with the Ocaml [Format] library. *)

(** Print an expression, possibly placing parentheses around it. We always
    print things at a given "level" [at_level]. If the level exceeds the
    maximum allowed level [max_level] then the expression should be parenthesized.

    Let us consider an example. When printing a left-associative operation, we should print [Op
    (Op (e1, e2), e3)] as ["e1 * e2 * e3"] and [Op(e1, Op(e2, e3))] as ["e1 * (e2 * e3)"]. So
    if we assign level 1 to applications, then during printing of [Op (e1, e2)] we should
    print [e1] at [max_level] 1 and [e2] at [max_level] 0.
*)
let print ?(max_level=9999) ?(at_level=0) ppf =
  if max_level < at_level then
    begin
      Format.fprintf ppf "(@[" ;
      Format.kfprintf (fun ppf -> Format.fprintf ppf "@])") ppf
    end
  else
    begin
      Format.fprintf ppf "@[" ;
      Format.kfprintf (fun ppf -> Format.fprintf ppf "@]") ppf
    end

(** Print the given source code position. *)
let print_position loc ppf =
  match loc with
  | Common.Nowhere ->
      Format.fprintf ppf "unknown position"
  | Common.Position (begin_pos, end_pos) ->
      let begin_char = begin_pos.Lexing.pos_cnum - begin_pos.Lexing.pos_bol in
      let end_char = end_pos.Lexing.pos_cnum - begin_pos.Lexing.pos_bol in
      let begin_line = begin_pos.Lexing.pos_lnum in
      let filename = begin_pos.Lexing.pos_fname in

      if String.length filename != 0 then
        Format.fprintf ppf "file %S, line %d, charaters %d-%d"
                             filename (begin_line+1) begin_char end_char
      else
        Format.fprintf ppf "line %d, characters %d-%d" (begin_line-1) begin_char end_char

(** Print a sequence of things with the given (optional) separator. *)
let print_sequence ?(sep="") f lst ppf =
  let rec seq = function
    | [] -> print ppf ""
    | [x] -> print ppf "%t" (f x)
    | x :: xs -> print ppf "%t%s@ " (f x) sep ; seq xs
  in
    seq lst

(** Support for printing of errors at various levels of verbosity. *)

let verbosity = ref 2

(** Print a message at a given location [loc] of message type [msg_type] and
    verbosity level [v]. *)
let print_message ?(loc=Common.Nowhere) msg_type v =
  if v <= !verbosity then
    begin
      match loc with
        | Common.Nowhere ->
          Format.eprintf "%s:@\n@[" msg_type ;
          Format.kfprintf (fun ppf -> Format.fprintf ppf "@]@.") Format.err_formatter
        | Common.Position _ ->
          Format.eprintf "%s at %t:@\n@[" msg_type (print_position loc) ;
          Format.kfprintf (fun ppf -> Format.fprintf ppf "@]@.") Format.err_formatter
    end
  else
    Format.ifprintf Format.err_formatter


(** Print an error. *)
let error (loc, err_type, msg) = print_message ~loc err_type 1 "%s" msg
