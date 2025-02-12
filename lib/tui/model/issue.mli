(** Model types and functions for the issue tab. *)

(** Main issue tab. Fields:

    - [all_issues]: Lazily fetched all issues
    - [filter]: Filter for currently selected issues
    - [issues]: Filtered issues from [all_issues] using [filter]
    - [offset]: Offset for currently selected issue from [issues] *)
type t = {
  all_issues : Gh.Issue.t Render.t list Lazy.t;
  filter : filter;
  issues : Gh.Issue.t Render.t array Lazy.t;
  offset : int;
  scroll_start : int;
  error : Gh.Client.error option Lazy.t;
}

and filter =
  | State of Gh.Issue.state
  | All

val filter_all : filter
val filter_open : filter
val filter_closed : filter
val make : owner:string -> repo:string -> t

(** Change the filter to a new one and update currently selected issues. *)
val apply_filter : filter -> t -> t

(** Usage: [move 1 tab] or [move (-1) tab]:

    Moves [offset] while also moving [scroll_start] if [offset] is out of
    boundaries. *)
val move : int -> t -> t

(** Total number of issues to display per scroll span.

    Ideally, this constant should be dynamically calculated based on available
    height. For simplicity, hardcoding for now. *)
val max_issues : int
