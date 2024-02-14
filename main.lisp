(defpackage :github-markdown-preview
  (:use :cl)
  (:export :preview-string
           :preview-file))
(in-package :github-markdown-preview)

(defvar *access-token*)

(define-condition github-markdown-preview-error (error) ())

(define-condition unbound-access-token (github-markdown-preview-error)
  ()
  (:report "The variable *access-token* is unbound."))

(defun ask-token ()
  (trivial-open-browser:open-browser "https://github.com/settings/tokens?type=beta")
  (format t "Please enter your token: ")
  (force-output)
  (list (read-line)))

(defun access-token ()
  (unless (boundp '*access-token*)
    (restart-case (error 'unbound-access-token)
      (set-access-token (v)
        :report "Enter your token: "
        :interactive ask-token
        (setf *access-token* v))))
  *access-token*)

(defun render (text)
  (let ((html (dex:post "https://api.github.com/markdown"
                        :headers `(("Accept" . "application/vnd.github+json")
                                   ("Authorization" . ,(format nil "Bearer ~A" (access-token)))
                                   ("X-GitHub-Api-Version" . "2022-11-28"))
                        :content (jojo:to-json `(("text" . ,text)) :from :alist))))
    (lisp-preprocessor:run-template-into-string
     (lisp-preprocessor:compile-template
      (asdf:system-relative-pathname :github-markdown-preview "./index.html") :arguments '($text))
     html)))

(defun preview-string (text)
  (let ((html (render text)))
    (uiop:with-temporary-file (:pathname pathname
                               :stream stream
                               :keep t
                               :directory (asdf:system-relative-pathname :github-markdown-preview "tmp/"))
      (write-string html stream)
      :close-stream
      (trivial-open-browser:open-browser (namestring pathname)))))

(defun preview-file (file)
  (preview-string (uiop:read-file-string file)))
