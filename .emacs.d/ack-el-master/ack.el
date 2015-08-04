;;; ack.el --- interface to ack-like tools           -*- lexical-binding: t; -*-

;; Copyright (C) 2012-2013  Free Software Foundation, Inc.

;; Author: Leo Liu <sdl.web@gmail.com>
;; Version: 1.4
;; Keywords: tools, processes, convenience
;; Created: 2012-03-24
;; URL: https://github.com/leoliu/ack-el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides an interface to ack http://beyondgrep.com --
;; a tool like grep, designed for programmers with large trees of
;; heterogeneous source code. It builds on standard packages
;; `compile.el' and `ansi-color.el' and lets you seamlessly run `ack'
;; with its large set of options.
;;
;; Ack-like tools such as the silver search (ag) and git/hg/bzr grep
;; are well supported too.

;;; Usage:

;; +  Type `M-x ack' and provide a pattern to search.
;; +  Type `C-u M-x ack' to search from current project root.
;; +  Type `C-u C-u M-x ack' to interactively choose a directory to
;;    search.
;;
;; Note: use `ack-default-directory-function' for customised
;; behaviour.
;;
;; When in the minibuffer the following key bindings may be useful:
;;
;; +  `M-I' inserts a template for case-insensitive file name search
;; +  `M-G' inserts a template for `git grep', `hg grep' or `bzr grep'
;; +  `M-Y' inserts the symbol at point from the window before entering
;;    the minibuffer
;; +  `TAB' completes ack options

;;; Supported tools:

;; + ack
;; + grep
;; + the_silver_search
;; + git/hg/bzr grep

;;; Bugs: https://github.com/leoliu/ack-el/issues

;;; Code:

(require 'compile)
(require 'ansi-color)
(autoload 'shell-completion-vars "shell")

(eval-when-compile
  (unless (fboundp 'setq-local)
    (defmacro setq-local (var val)
      (list 'set (list 'make-local-variable (list 'quote var)) val))))

(defgroup ack nil
  "Run `ack' and display the results."
  :group 'tools
  :group 'processes)

;; Used implicitly by `define-compilation-mode'
(defcustom ack-scroll-output nil
  "Similar to `compilation-scroll-output' but for the *Ack* buffer."
  :type 'boolean
  :group 'ack)

(defcustom ack-command
  ;; Note: on GNU/Linux ack may be renamed to ack-grep
  (concat (file-name-nondirectory (or (executable-find "ack-grep")
                                      (executable-find "ack")
                                      (executable-find "ag")
                                      "ack")) " ")
  "The default command for \\[ack].

Note also options to ack can be specified in ACK_OPTIONS
environment variable and .ackrc, which you can disable by the
--noenv switch."
  :type 'string
  :safe 'stringp
  :group 'ack)

(defcustom ack-buffer-name-function nil
  "If non-nil, a function to compute the name of an ack buffer.
See `compilation-buffer-name-function' for details."
  :type '(choice function (const nil))
  :group 'ack)

(defcustom ack-vc-grep-commands
  '((".git" . "git --no-pager grep --color -n -i")
    (".hg" . "hg grep -n -i")
    ;; Plugin bzr-grep required for bzr < 2.6
    (".bzr" . "bzr grep --color=always -n -i"))
  "An alist of vc grep commands for `ack-skel-vc-grep'.
Each element is of the form (VC_DIR . CMD)."
  :type '(repeat (cons string string))
  :group 'ack)

(defcustom ack-default-directory-function 'ack-default-directory
  "A function to return the default directory for `ack'.
It is called with one arg, the prefix arg to `ack'."
  :type 'function
  :group 'ack)

(defcustom ack-project-root-patterns
  (list (concat "\\`" (regexp-quote dir-locals-file) "\\'")
        "\\`Project\\.ede\\'"
        "\\.xcodeproj\\'"               ; xcode
        "\\`\\.ropeproject\\'"          ; python rope
        "\\`\\.\\(?:CVS\\|bzr\\|git\\|hg\\|svn\\)\\'")
  "A list of regexps to match files in a project root.
Used by `ack-guess-project-root'."
  :type '(repeat string)
  :group 'ack)

(defcustom ack-minibuffer-setup-hook nil
  "Ack-specific hook for `minibuffer-setup-hook'."
  :type 'hook
  :group 'ack)

;;; ======== END of USER OPTIONS ========

(defvar ack-history nil "History list for ack.")

(defvar ack-first-column 0
  "Value to use for `compilation-first-column' in ack buffers.")

(defvar ack-error-screen-columns nil
  "Value to use for `compilation-error-screen-columns' in ack buffers.")

(defvar ack-error "ack match"
  "Stem of message to print when no matches are found.")

(defun ack-filter ()
  "Handle match highlighting escape sequences inserted by the ack process.
This function is called from `compilation-filter-hook'."
  (save-excursion
    (let ((ansi-color-apply-face-function
           (lambda (beg end face)
             (when face
               (ansi-color-apply-overlay-face beg end face)
               (put-text-property beg end 'ack-color t)))))
      (ansi-color-apply-on-region compilation-filter-start (point)))))

(defvar ack-mode-font-lock-keywords
  '(("^--$" 0 'shadow)
    ;; Command output lines.
    (": \\(.+\\): \\(?:Permission denied\\|No such \\(?:file or directory\\|device or address\\)\\)$"
     1 'compilation-error)
    ("^Ack \\(exited abnormally\\|interrupt\\|killed\\|terminated\\)\\(?:.*with code \\([0-9]+\\)\\)?.*"
     (1 'compilation-error)
     (2 'compilation-error nil t)))
  "Additional things to highlight in ack output.
This gets tacked on the end of the generated expressions.")

(defun ack--column-start ()
  (or (let* ((beg (match-end 0))
             (end (save-excursion
                    (goto-char beg)
                    (line-end-position)))
             (mbeg (text-property-any beg end 'ack-color t)))
        (when mbeg (- mbeg beg)))
      ;; Use column number from `ack' itself if available
      (when (match-string 4)
        (1- (string-to-number (match-string 4))))))

(defun ack--column-end ()
  (let* ((beg (match-end 0))
         (end (save-excursion
                (goto-char beg)
                (line-end-position)))
         (mbeg (text-property-any beg end 'ack-color t))
         (mend (and mbeg (next-single-property-change
                          mbeg 'ack-color nil end))))
    (when mend (- mend beg))))

(defun ack--file ()
  (let (file)
    (save-excursion
      (while (progn
               (forward-line -1)
               (looking-at-p "^--$")))
      (setq file (or (get-text-property (line-beginning-position) 'ack-file)
                     (progn
                       (put-text-property (line-beginning-position)
                                          (line-end-position)
                                          'font-lock-face compilation-info-face)
                       (buffer-substring-no-properties
                        (line-beginning-position) (line-end-position))))))
    (put-text-property (line-beginning-position)
                       (min (1+ (line-end-position)) (point-max)) 'ack-file file)
    (list file)))

;;; `compilation-mode-font-lock-keywords' ->
;;; `compilation--ensure-parse' -> `compilation--parse-region' ->
;;; `compilation-parse-errors' -> `compilation-error-properties'.
;;; `compilation-error-properties' returns nil if a previous pattern
;;; in the regexp alist has already been applied in a region.

(defconst ack-error-regexp-alist
  `(;; Grouping line (--group or --heading).
    ("^\\([1-9][0-9]*\\)\\(:\\|-\\)\\(?:\\(?4:[1-9][0-9]*\\)\\2\\)?"
     ack--file 1 (ack--column-start . ack--column-end)
     nil nil (4 compilation-column-face nil t))
    ;; None grouping line (--nogroup or --noheading). Avoid matching
    ;; 'Ack started at Thu Jun 6 12:27:53'.
    ("^\\(.+?\\)\\(:\\|-\\)\\([1-9][0-9]*\\)\\2\\(?:\\(?:\\(?4:[1-9][0-9]*\\)\\2\\)\\|[^0-9\n]\\|[0-9][^0-9\n]\\|...\\)"
     1 3 (ack--column-start . ack--column-end)
     nil 1 (4 compilation-column-face nil t))
    ("^Binary file \\(.+\\) matches$" 1 nil nil 0 1))
  "Ack version of `compilation-error-regexp-alist' (which see).")

(defvar ack-process-setup-function 'ack-process-setup)

(defun ack-process-setup ()
  ;; Handle `hg grep' output
  (when (string-match-p "^[ \t]*hg[ \t]" (car compilation-arguments))
    (setq compilation-error-regexp-alist
          '(("^\\(.+?:[0-9]+:\\)\\(?:\\([0-9]+\\):\\)?" 1 2)))
    (setq-local compilation-parse-errors-filename-function
                (lambda (file)
                  (save-match-data
                    (if (string-match "\\(.+\\):\\([0-9]+\\):" file)
                        (match-string 1 file)
                      file)))))
  ;; Handle `bzr grep' output
  (when (string-match-p "^[ \t]*bzr[ \t]" (car compilation-arguments))
    (setq-local compilation-parse-errors-filename-function
                (lambda (file)
                  (save-match-data
                    ;; 'bzr grep -r' has files like `termcolor.py~147'
                    (if (string-match "\\(.+\\)~\\([0-9]+\\)" file)
                        (match-string 1 file)
                      file))))))

(define-compilation-mode ack-mode "Ack"
  "A compilation mode tailored for ack."
  (setq-local compilation-disable-input t)
  (setq-local compilation-error-face 'compilation-info)
  (add-hook 'compilation-filter-hook 'ack-filter nil t))

;;; `compilation-display-error' is introduced in 24.4
(unless (fboundp 'compilation-display-error)
  (defun ack-mode-display-match ()
    "Display in another window the match in current line."
    (interactive)
    (setq compilation-current-error (point))
    (next-error-no-select 0))
  (define-key ack-mode-map "\C-o" #'ack-mode-display-match))



(defun ack-skel-no-pager () 
	"insert template for use without pager"
	(interactive)
	(delete-minibuffer-contents)
	(let ((ack (or (car (split-string ack-command nil t )) "ack" )))
    	(skeleton-insert `(nil ,ack " --nopager '" _ "'")))
)





(defun ack-skel-file ()
  "Insert a template for case-insensitive file name search."
  (interactive)
  (delete-minibuffer-contents)
  (let ((ack (or (car (split-string ack-command nil t)) "ack")))
    (if (equal ack "ag")
        (skeleton-insert `(nil ,ack " -ig '" _ "'"))
      (skeleton-insert `(nil ,ack " -g '(?i:" _ ")'")))))

;; Work around bug http://debbugs.gnu.org/13811
(defvar ack--project-root nil)          ; dynamically bound in `ack'

(defun ack-skel-vc-grep ()
  "Insert a template for vc grep search."
  (interactive)
  (let* ((regexp (concat "\\`" (regexp-opt
                                (mapcar 'car ack-vc-grep-commands))
                         "\\'"))
         (root (or (ack-guess-project-root default-directory regexp)
                   (error "Cannot locate vc project root")))
         (which (car (directory-files root nil regexp)))
         (backend (downcase (substring which 1)))
         (cmd (or (cdr (assoc which ack-vc-grep-commands))
                  (error "No command provided for `%s grep'" backend))))
    (setq ack--project-root root)
    (delete-minibuffer-contents)
    (skeleton-insert `(nil ,cmd " '" _ "'"))))

(defun ack-yank-symbol-at-point ()
  "Yank the symbol from the window before entering the minibuffer."
  (interactive)
  (let ((symbol (and (minibuffer-selected-window)
                     (with-current-buffer
                         (window-buffer (minibuffer-selected-window))
                       (thing-at-point 'symbol)))))
    (if symbol (insert symbol)
      (minibuffer-message "No symbol found"))))

(defvar ack-minibuffer-local-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map minibuffer-local-map)
    (define-key map "\t" 'completion-at-point)
    (define-key map "\M-I" 'ack-skel-file)
    (define-key map "\M-G" 'ack-skel-vc-grep)
    (define-key map "\M-P" 'ack-skel-no-pager)
    (define-key map "\M-Y" 'ack-yank-symbol-at-point)
    (define-key map "'" 'skeleton-pair-insert-maybe)
    map)
  "Keymap used for reading `ack' command and args in minibuffer.")

(defun ack-guess-project-root (start-directory &optional regexp)
  (let ((regexp (or regexp
                    (mapconcat 'identity ack-project-root-patterns "\\|")))
        (parent (file-name-directory
                 (directory-file-name (expand-file-name start-directory)))))
    (if (directory-files start-directory nil regexp)
        start-directory
      (unless (equal parent start-directory)
        (ack-guess-project-root parent regexp)))))

(defun ack-default-directory (arg)
  "A function for `ack-default-directory-function'.
With no \\[universal-argument], return `default-directory';
With one \\[universal-argument], find the project root according to
`ack-project-root-patterns';
Otherwise, interactively choose a directory."
  (cond
   ((not arg) default-directory)
   ((= (prefix-numeric-value arg) 4)
    (or (ack-guess-project-root default-directory)
        (ack-default-directory '(16))))
   (t (read-directory-name "In directory: " nil nil t))))

(defun ack-update-minibuffer-prompt (&optional _beg _end _len)
  (when (minibufferp)
    (let ((inhibit-read-only t))
      (save-excursion
        (goto-char (minibuffer-prompt-end))
        (when (looking-at "\\(\\w+\\)\\s-")
          (put-text-property
           (point-min) (minibuffer-prompt-end)
           'display
           (format "Run %s in `%s': "
                   (match-string-no-properties 1)
                   (file-name-nondirectory
                    (directory-file-name ack--project-root)))))))))

(defun ack-minibuffer-setup-function ()
  (shell-completion-vars)
  (add-hook 'after-change-functions
            #'ack-update-minibuffer-prompt nil t)
  (ack-update-minibuffer-prompt)
  (run-hooks 'ack-minibuffer-setup-hook))

;;;###autoload
(defun ack (command-args &optional directory)
  "Run ack using COMMAND-ARGS and collect output in a buffer.
When called interactively, the value of DIRECTORY is provided by
`ack-default-directory-function'.

The following keys are available while reading from the
minibuffer:

\\{ack-minibuffer-local-map}"
  (interactive
   (let ((ack--project-root (or (funcall ack-default-directory-function
                                    current-prefix-arg)
                           default-directory))
         ;; Disable completion cycling; see http://debbugs.gnu.org/12221
         (completion-cycle-threshold nil))
     (list (minibuffer-with-setup-hook 'ack-minibuffer-setup-function
             (read-from-minibuffer "Ack: "
                                   ack-command
                                   ack-minibuffer-local-map
                                   nil 'ack-history))
           ack--project-root)))
  (let ((default-directory (expand-file-name
                            (or directory default-directory))))
    ;; Change to the compilation buffer so that `ack-buffer-name-function' can
    ;; make use of `compilation-arguments'.
    (with-current-buffer (compilation-start command-args 'ack-mode)
      (when ack-buffer-name-function
        (rename-buffer (funcall ack-buffer-name-function "ack")))
      (current-buffer))))

(provide 'ack)
;;; ack.el ends here
