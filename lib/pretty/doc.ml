module Style = Style

type t =
  | Str of Style.t * string
  | Horizontal_fill of string
  | Vertical of t list
  | Horizontal of t list

let str string = Str ([], string)
let fmt styles string = Str (styles, string)
let horizontal cols = Horizontal cols
let vertical rows = Vertical rows
let horizontal_fill filler = Horizontal_fill filler

type prerender =
  | Rendered of Layout.t
  | Fill of string

let ( += ) ref x = ref := !ref + x

let rec render ~width ~height = function
  | Str (styles, string) -> Layout.fmt styles string
  | Horizontal_fill filler -> horizontal_fill_to_layout ~width filler
  | Vertical rows -> vertical_to_layout ~width ~height rows
  | Horizontal cols -> horizontal_to_layout ~width ~height cols

and horizontal_fill_to_layout ~width filler =
  filler |> Extra.String.repeat_txt width |> Layout.str

and vertical_to_layout ~width ~height rows =
  let render_row row height =
    (* While traversing vertically, width doesn't change but the heigh decreases. *)
    let row_layout = render ~width ~height row in
    let remaining_height = height - Layout.height row_layout in
    (row_layout, remaining_height)
  in
  rows |> Extra.List.map_with_fold ~f:render_row ~init:height |> Layout.vertical

and horizontal_to_layout ~width ~height cols =
  (* Step [prerender]. Check if there's Horizontal_fill, render everything else
     and calculate rendered size. *)
  let len = List.length cols in
  let size_taken = ref 0 in
  let prerendered = Array.make len (Fill "") in

  ListLabels.iteri cols ~f:(fun i col ->
      match col with
      | Horizontal_fill filler -> prerendered.(i) <- Fill filler
      | other ->
          (* WARNING: The leftmost horizontal fill will consume all the remaining width *)
          let remaining_width = width - !size_taken in
          let layout = render ~width:remaining_width ~height other in
          size_taken += Layout.width layout;
          prerendered.(i) <- Rendered layout);

  (* Step [fill_size]. Calculate the size of remaining fill *)
  let fill_width = width - !size_taken in

  (* Step [combine]. Extract rendered layouts and fill the missing part. *)
  prerendered
  |> Array.to_list
  |> List.map (function
       | Rendered layout -> layout
       | Fill filler ->
           filler |> Extra.String.repeat_txt fill_width |> Layout.str)
  |> Layout.horizontal
