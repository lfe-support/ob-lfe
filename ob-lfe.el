;;; ob-lfe.el --- org-babel functions for lfe evaluation

;; Copyright (C) 2015 ZHOU Feng
;; Copyright (C) 2016 Eric Bailey

;; Author: ZHOU Feng <zf.pascal@gmail.com>
;; URL: http://github.com/zweifisch/ob-lfe
;; Keywords: org babel lfe lisp erlang
;; Version: 0.0.1
;; Created: 1st July 2015
;; Package-Requires: ((org "8"))

;;; Commentary:
;;
;; org-babel functions for lfe evaluation
;;

;;; Code:
(require 'ob)
(require 'comint)

(defvar org-babel-lfe-eoe "org-babel-lfe-eoe")

(defun org-babel-execute:lfe (body params)
  (let ((session (cdr (assoc :session params))))
    (ob-lfe-eval session body)))

(defun ob-lfe-eval (session body)
  (ob-lfe-ensure-session session)
  (let ((result (ob-lfe-eval-in-repl session body))
        (num-lines (length (split-string body "[\r\n]"))))
    ;; (message (prin1-to-string result))
    (if (stringp result) (message result)
      (replace-regexp-in-string
       "\r\n" "\n"
       (mapconcat 'identity (nthcdr (+ 1 num-lines) (ob-lfe-trim-eoe result)) "")))))

(defun ob-lfe-trim-eoe (lines)
  (while (not (string-match "^> \"org-babel-lfe-eoe\"" (car (last lines))))
    (setq lines (butlast lines)))
  (butlast lines))

(defun ob-lfe-eval-in-repl (session body)
  (let ((buffer (format "*lfe-%s*" session))
        (eoe (format "%S" org-babel-lfe-eoe)))
    (with-timeout (3 "comint timeout")
      (org-babel-comint-with-output
          (buffer eoe)
        (dolist (line (list body eoe))
          (insert (org-babel-chomp line))
          (comint-send-input nil t)
          (sleep-for 0 5))))))

(defun ob-lfe-ensure-session (session)
  (unless (org-babel-comint-buffer-livep (format "*lfe-%s*" session))
    (with-current-buffer (apply 'make-comint (format "lfe-%s" session) "env" nil
                                "lfe" "-env" "TERM" "vt100"
                                "-pa" (file-expand-wildcards
                                       "_build/default/lib/*/ebin"))
      (setq comint-process-echoes t))
    (ob-lfe-eval-in-repl session "")
    (sleep-for 0 500)))

(provide 'ob-lfe)
;;; ob-lfe.el ends here
