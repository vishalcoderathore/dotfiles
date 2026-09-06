; extends
;
; `; extends` above is load-bearing: without it this file REPLACES
; nvim-treesitter's python injections (re, printf, comment) instead of adding
; to them.
;
; Highlight raw SQL passed to SQLAlchemy's text() as SQL.

; text("SELECT ...")
((call
   function: (identifier) @_fn
   arguments: (argument_list
     (string (string_content) @injection.content)))
  (#eq? @_fn "text")
  (#set! injection.language "sql"))

; sa.text("SELECT ...") / sqlalchemy.text("SELECT ...")
((call
   function: (attribute attribute: (identifier) @_fn)
   arguments: (argument_list
     (string (string_content) @injection.content)))
  (#eq? @_fn "text")
  (#set! injection.language "sql"))
