(defsystem "github-markdown-preview"
  :depends-on ("dexador"
               "jonathan"
               "lisp-preprocessor"
               "trivial-open-browser")
  :serial t
  :components ((:file "main")))
