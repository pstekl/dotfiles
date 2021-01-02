
;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)

(message "My emacs config loading.")

(add-to-list 'custom-theme-load-path "~/.emacs.d/themes/")
(load-theme 'zenburn t)



;; ;; (setq load-path (cons "~/packages/emacs-org-mode/lisp" load-path))
;; ;; (setq load-path (cons "~/packages/emacs-org-mode/contrib/lisp" load-path))
;; ;; (require 'org)

;; ;; global TODO-list
;; ;; (setq org-agenda-files (list "~/tasks.org"))

;; ;; ;; global org contact file
;; ;; (require 'org-contacts)
;; ;; (setq org-contact-files '("~/contacts.org"))
;; ;; (global-set-key "\C-cc" 'org-capture)
;; ;; (global-set-key "\C-cf" 'org-contacts)
;; ;; (setq org-contacts-completion-ignore-case t)
;; ;; ;; (add-to-list 'org-capture-templates
;; ;; ;;              '("c" "Contacts" entry (file "~/test_contacts.org")
;; ;; ;;                "* %(org-contacts-template-name)
;; ;; ;;                   :PROPERTIES:
;; ;; ;;                   :EMAIL: %(org-contacts-template-email)
;; ;; ;;                   :END:"))

;; ;; ;; The following lines are always needed.  Choose your own keys.
;; ;; (add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode)) ; not needed since Emacs 22.2
;; ;; (add-hook 'org-mode-hook 'turn-on-font-lock) ; not needed when global-font-lock-mode is on
;; ;; (global-set-key "\C-cl" 'org-store-link)
;; ;; (global-set-key "\C-ca" 'org-agenda)
;; ;; (global-set-key "\C-cb" 'org-iswitchb)
;; ;; (setq org-log-done t)


;; ;; ;; load custom markers in emacs org-mode
;; ;; (setq org-todo-keyword-faces
;; ;;       '(
;; ;;         ("NEXT" . (:foreground "purple" :weight bold))
;; ;;         ("CANCELLED" . (:forground "lime green" :weight bold))
;; ;;         ))

;; ;; ;; set new sequence
;; ;; (setq org-todo-keywords
;; ;;       '((sequence "TODO"
;; ;;                   "NEXT"
;; ;;                   "|"
;; ;;                   "DONE"
;; ;;                   "CANCELLED")))



;; ack the silver searcher
(add-to-list 'load-path "~/.emacs.d/ack-el-master")
(require 'ack)
(require 'pcmpl-ack)




(defun remove-dos-eol ()
  "Do not show ^M in files containing mixed UNIX and DOS line endings."
  (interactive)
  (setq buffer-display-table (make-display-table))
  (aset buffer-display-table ?\^M []))

(add-hook 'text-mode-hook' remove-dos-eol)
(add-hook 'c-mode-hook' remove-dos-eol)

(global-linum-mode 1)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages (quote (auctex)))
 '(x-gtk-show-hidden-files t))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )


;;cscope
;;(require 'xcscope)

;;speedbar in emacs window
(load-file "~/.emacs.d/sr-speedbar.el")
(require 'sr-speedbar)
(global-set-key (kbd "C-<f5>") 'sr-speedbar-toggle)


(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)
(defvaralias 'c-basic-offset 'tab-width)

(show-paren-mode 1)
(line-number-mode 1)
(add-hook 'before-save-hook 'delete-trailing-whitespace)



(add-hook 'LaTeX-mode-hook 'turn-on-font-lock)
(add-hook 'tex-mode-hook 'turn-on-font-lock)
(add-hook 'LaTeX-mode-hook 'flyspell-mode)
(setq ispell-dictionary "english")
(add-hook 'tex-mode-hook '(lambda () (local-unset-key "\"")))
(setq-default TeX-master nil) ; Query for master file.
(setq-default transient-mark-mode t)
(setq-default latex-run-command "pdflatex")
					;(show-paren-mode t)




(setq load-path (cons "/usr/share/emacs/site-lisp/auctex" load-path))
(require 'tex-site)
;Wenn gewollt, kann automatisch nach 72 Zeichen umgebrochen werden
;(add-hook 'text-mode-hook 'turn-on-auto-fill)
;(setq-default fill-column 140)
(setq reftex-plug-into-AUCTeX t)
(add-hook 'LaTeX-mode-hook (function turn-on-reftex))
(add-hook 'LaTeX-mode-hook 'turn-on-reftex)
(setq reftex-default-bibliography '("/home/philipp/Documents/uni/thesis/thesis_template/stekl.bib"))


(message "Finished loading my emacs config.")
