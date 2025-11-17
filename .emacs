;;; Startup Settings
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("org" . "https://orgmode.org/elpa/") t)
(add-to-list 'package-archives '("elpa" . "https://elpa.gnu.org/packages/") t)
(require 'epa-file)
(epa-file-enable)
(package-initialize)
(require 'use-package)
(setq use-package-always-ensure t)
(setq use-package-always-defer t)

;; Initialize straight.el
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(setq custom-file "~/.emacs.d/emacs-custom.el")
(load custom-file)

;;; macOS Settings
(when (memq window-system '(mac ns x))
  (exec-path-from-shell-initialize)
  (setq insert-directory-program "gls"
	dired-use-ls-dired t)
  (use-package add-node-modules-path
    :ensure t
    :hook ((js-mode
            js-ts-mode
            javascript-mode
            javascript-ts-mode
            typescript-mode
            typescript-ts-mode
            web-mode
            rjsx-mode) . add-node-modules-path))
  (set-frame-parameter nil 'ns-transparent-titlebar t)
  (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t)))

(server-start)

;;; UI Adjustments & other initialization settings
(setq-default frame-title-format "")
(setq inhibit-splash-screen t)
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1) 
(column-number-mode)
(tab-bar-mode -1)
(setq tab-bar-show 'nil)
(setq truncate-lines t)
;; Enable line numbers for some modes
(dolist (mode '(text-mode-hook
                prog-mode-hook
                conf-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 1))))

;; Override some modes which derive from the above
(dolist (mode '(org-mode-hook
		term-mode-hook
		shell-mode-hook
		eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(setq ring-bell-function 'ignore)

(require 'all-the-icons)

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1))

(setq spacious-padding-subtle-frame-lines
      `( :mode-line-active 'default
         :mode-line-inactive vertical-border))

(setq spacious-padding-subtle-mode-line
      `( :mode-line-active 'default
         :mode-line-inactive vertical-border)
      spacious-padding-widths
      `( :internal-border-width 5))

(spacious-padding-mode 1)

;;; Other misc settings
(setq gc-cons-threshold (* 2 1000 1000))
(setq-default fill-column 80)
(setq isearch-allow-motion t)
(setq sentence-end-double-space 'nil)
(recentf-mode 1) ; Remember recently added files
;; Limit history to 25, a reasonable length that maintains emacs startup performance
(setq history-length 25)
(save-place-mode 1) ;; Remember and restore the last cursor location of opened files
(setq use-dialog-box nil) ;; Don't pop up UI dialogs when prompting
;;Revert buffers when the underlying file has changed
(global-auto-revert-mode 1)
(setq auto-revert-verbose nil) ;; Disable message when a buffer is auto reverted
(setq global-auto-revert-non-file-buffers t) ; Also revert Dired and other buffers
(electric-pair-mode 1)
;; Prevent it from closing a pair if the point is at the beginning or in the
;; middle of a word. 
(setq electric-pair-inhibit-predicate 'electric-pair-conservative-inhibit)
;; This fixes an issue with a closing bracket being added when using the 
;; `< s RET' shortcut for org blocks
(add-hook 'org-mode-hook (lambda ()
			   (setq-local electric-pair-inhibit-predicate
				       `(lambda (c)
					  (if (char-equal c ?<) t (,electric-pair-inhibit-predicate c))))))
(put 'downcase-region 'disabled nil)
(setq sentence-end-double-space nil)

;;; Window Management
(winner-mode)
(tab-bar-mode -1)
(setq tab-bar-show 'nil)
(tab-bar-history-mode)
(global-set-key (kbd "M-[") 'tab-bar-history-back)
(global-set-key (kbd "M-]") 'tab-bar-history-forward)

(pdf-tools-install)

(emms-all)
(setq emms-player-list '(emms-player-mpv)
      emms-info-functions '(emms-info-native))
(global-set-key (kbd "C-c e p") 'emms-play-url)
(global-set-key (kbd "C-c e q") 'emms-add-url)
(global-set-key (kbd "C-c e >") 'emms-next)

(elfeed-org)
;; Tag all YouTube entries as "video" and "youtube"
(add-hook 'elfeed-new-entry-hook
          (elfeed-make-tagger :feed-url "youtube\\.com"
                              :add '(video youtube)))
(global-set-key (kbd "C-c w") 'elfeed)

(use-package elfeed-tube
  :ensure t ;; or :straight t
  :after elfeed
  :demand t
  :config
  ;; (setq elfeed-tube-auto-save-p nil) ; default value
  ;; (setq elfeed-tube-auto-fetch-p t)  ; default value
  (elfeed-tube-setup)
  :bind (:map elfeed-show-mode-map
              ("F" . elfeed-tube-fetch)
              ([remap save-buffer] . elfeed-tube-save)
              :map elfeed-search-mode-map
              ("F" . elfeed-tube-fetch)
              ([remap save-buffer] . elfeed-tube-save)))

(use-package elfeed-tube-mpv
  :ensure t ;; or :straight t
  :bind (:map elfeed-show-mode-map
              ("C-c C-f" . elfeed-tube-mpv-follow-mode)
              ("C-c C-w" . elfeed-tube-mpv-where)))

(use-package hyperbole)
(hyperbole-mode 1)
(hkey-ace-window-setup "\M-o")

(use-package which-key
  :init (which-key-mode)
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 1))

(use-package helpful
  :bind
  ([remap describe-command] . helpful-command)
  ([remap describe-key] . helpful-key))

;;; Org Mode
;; Additional org-mode settings from SystemCrafters
(defun my/org-mode-setup ()
  ;; variable-pitch-mode has to be 0 for org-tables to format correctly.
  (variable-pitch-mode 0)
  (auto-fill-mode 0)
  (visual-line-mode 1))

(use-package org
  :hook (org-mode . my/org-mode-setup)
  :bind
  (("C-c l" . org-store-link)
   ("C-c a" . org-agenda)                   
   ("C-c c" . org-capture)                  
   ("C-c j r" . 'org-refile-goto-last-stored)
   ("C-c /" . 'org-sparse-tree)
   ("C-c M-." . org-timestamp-inactive))
  :config
  (setq org-ellipsis " ▾"
	org-indent-mode t
	org-goto-auto-isearch nil
	org-hide-emphasis-markers t
	org-agenda-include-diary t
	org-agenda-diary-file "~/git/org/diary.org"
	org-directory "~/git/org/"
	org-tag-alist '((:startgrouptag)
			("GTD")
			("Control")
			("Persp")
			(:endgrouptag)
			(:startgrouptag)
			("Control")
			(:grouptags)
			("Context")
			("Task")
			(:endgrouptag)
			(:startgrouptag)
			("Persp")
			(:grouptags)
			("Vision")
			("Goal")
			("AOF")
			("Project")
			(:endgrouptag)
			(:startgrouptag)
			("Context")
			(:grouptags)
			("@home" . ?h) ("@phone" . ?o) ("@computer" . ?c)
			("@anywhere" . ?a) ("@errands" . ?e)
			("@business_hours" . ?b)
			(:endgrouptag)
			(:startgrouptag)
			("Vision")
			(:grouptags)
			("{V@.+}")
			(:endgrouptag)
			(:startgrouptag)
			("Goal")
			(:grouptags)
			("{G@.+}")
			(:endgrouptag)
			(:startgrouptag)
			("AOF")
			(:grouptags)
			("{AOF@.+}")
			(:endgrouptag)
			(:startgrouptag)
			("Project")
			(:grouptags)
			("{P@.+}")
			(:endgrouptag))
	org-todo-keywords '((sequence "TODO(t@/!)" "NEXT(n/!)" "WAITING(w@/!)" "SCHEDULED(k/!)" "PROJ(p)" "SOMEDAY(s)" "|" "DONE(d/!)" "CANCELLED(c@/!)"))
	org-capture-templates (quote (("t" "TODO" entry (file "~/git/org/inbox.org")
				       (file "~/git/org/templates/tpl-todo.txt"))
				      ("s" "Store item" entry (file "~/git/org/inbox.org")
				       "* %a \n %i") 
				      ("k" "Cliplink capture task" entry (file "~/git/org/inbox.org")
				       "* TODO %(org-cliplink-capture)"
				       :empty-lines 1)
				      ("p" "Personal Journal" entry (file+olp+datetree "~/git/org/journal.gpg")
				       (file "~/git/org/templates/tpl-journal.txt") :time-prompt t)
				      ("n" "New note (with Denote)" plain
				       (file denote-last-path)
				       #'denote-org-capture
				       :no-save t
				       :immediate-finish nil
				       :kill-buffer t
				       :jump-to-captured t)
				      ("j" "Journal" entry
				       (file denote-journal-path-to-new-or-existing-entry)
				       "* %U %?\n%i\n%a"
				       :kill-buffer t
				       :empty-lines 1)
				      ("l" "Org Protocol" entry
				       (file "~/git/org/inbox.org")
				       "* [[%:link][%:description]]\nCaptured On: %U\n\n%:initial")
				      ("m" "Media")
				      ("mb" "Book to Read" entry (file+olp "~/git/org/entertainment.org" "Books" "To Read")
				       (file "~/git/org/templates/tpl-books.txt"))
				      ("mm" "Movie to Watch" entry
				       (file+olp "~/git/org/entertainment.org" "Movies & Television" "Movies" "Movies to Watch")
				       (file "~/git/org/templates/tpl-movies.txt"))
				      ("mw" "Movie Watched" entry
				       (file+olp "~/git/org/entertainment.org"
						 "Movies & Television" "Movies" "Movies Watched")
				       (file "~/git/org/templates/tpl-movies_watched.txt"))
				      ("mt" "Television to Watch" entry (file+olp "~/git/org/entertainment.org" "Movies & Television" "Television" "Television to Watch")
				       (file "~/git/org/templates/tpl-series_to_watch.txt"))
				      ("me" "Television Enjoyed" entry (file+olp "~/git/org/entertainment.org" "Movies & Television" "Television" "Television Watched")
				       (file "~/git/org/templates/tpl-series_watched.txt"))
				      ("ml" "Music to Listen to" entry (file+olp "~/git/org/entertainment.org" "Music" "Music to Listen to")
				       (file "~/git/org/templates/tpl-music.txt"))
				      ("mh" "Music Heard" entry (file+olp "~/git/org/entertainment.org" "Music" "Music Listened to")
				       (file "~/git/org/templates/tpl-music_listened.txt"))
				      ("o" "Cookbook" entry (file "~/git/org/cookbook.org")
				       "%(org-chef-get-recipe-from-url)"
				       :empty-lines 1)
				      ("b" "Protocol Cookbook" entry (file "~/git/org/cookbook.org")
				       "%(org-chef-get-recipe-string-from-url \"%:link\")"
				       :empty-lines 1)
				      ("a" "Manual Cookbook" entry (file "~/git/org/cookbook.org")
				       "* %^{Recipe title: }\n  :PROPERTIES:\n  :source-url:\n  :servings:\n  :prep-time:\n  :cook-time:\n  :ready-in:\n  :END:\n** Ingredients\n   %?\n** Directions\n\n")
				      ("w" "Weekly Review" entry (file+olp+datetree "~/git/org/weekly_review.org")
				       (file "~/git/org/templates/tpl-weekly-review.txt") :jump-to-captured t)
				      ("r" "Travel Templates")
				      ("rl" "Travel Project Plan" entry (file+headline "~/git/org/travel.org" "Active Trips")
				       (file "~/git/org/templates/tpl-travel-planning.txt") :jump-to-captured t)
				      ("rp" "Packing Lists")
				      ("rpp" "Personal Trip Packing List" entry (file "~/git/org/inbox.org")
				       (file "~/git/org/templates/tpl-packing-list-personal.txt") :jump-to-captured t)
				      ("rpw" "Work Trip Packing List" entry (file "~/git/org/inbox.org")
				       (file
					"~/git/org/templates/tpl-packing-list-work.txt") :jump-to-captured
				       t)
				      ("c" "Checklists")
				      ("ce" "Visiting El Paso" entry (file "~/git/org/inbox.org")
				       (file
					"~/git/org/templates/tpl-el-paso-checklist.txt")
				       :jump-to-captured t)))
	org-agenda-files '("~/git/org/"
			   "~/git/org/travel/"
			   "~/git/org/travel/202510-Great_Britain/")
	org-agenda-custom-commands
	'(("n" "Agenda and all TODOs"
	   ((agenda "" nil)
	    (alltodo "" nil))
	   nil)
	  ("d" "Today (no recurring)"
	   ((agenda ""
		    ((org-agenda-overriding-header "Today (No recurring)")
		     (org-agenda-span 'day))))
	   ((org-agenda-tag-filter-preset
	     '("-recurring"))))
	  ("r" "Today (Recurring only)" agenda "+recurring"
	   ((org-agenda-overriding-header "Today (Recurring only)")
	    (org-agenda-tag-filter-preset
	     '("+recurring"))))
	  ("c" . "Contexts")
	  ("cc" "@computer" todo "TODO"
	   ((org-agenda-overriding-header "@computer")
	    (org-agenda-tag-filter-preset
	     '("+@computer"))))
	  ("ch" "@home" todo "TODO"
	   ((org-agenda-overriding-header "@home")
	    (org-agenda-tag-filter-preset
	     '("+@home"))))
	  ("cb" "@business_hours" todo "TODO"
	   ((org-agenda-tag-filter-preset
	     '("+@business_hours"))))
	  ("ca" "@anywhere" todo "TODO"
	   ((org-agenda-overriding-header "@anywhere")
	    (org-agenda-tag-filter-preset
	     '("+@anywhere"))))
	  ("v" "Read/Review" tags "+read_review"
	   ((org-agenda-overriding-header "Read/Review")
	    (org-agenda-category-filter-preset '("+Read/Review"))
	    (org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done)))))
	org-global-properties
	'(("Effort_ALL" . "0:15 0:30 1:00 2:00 3:00 4:00 5:00 6:00 7:00 8:00"))
	org-archive-location "~/git/org/archive/%s_archive::"
	org-clock-continuously nil
	org-clock-into-drawer "CLOCKING"
	org-clock-out-remove-zero-time-clocks t
	org-clock-rounding-minutes 1
	org-clock-sound t
	org-enforce-todo-checkbox-dependencies t
	org-enforce-todo-dependencies t
	org-export-preserve-breaks t
	org-log-done 'time
	org-log-into-drawer t
	org-log-reschedule 'note
	org-refile-targets '((org-agenda-files :maxlevel . 100))
	org-refile-use-outline-path 'file
	org-startup-folded t
	org-startup-indented t
	org-startup-with-inline-images t
	org-track-ordered-property-with-tag t
	org-outline-path-complete-in-steps nil
	org-agenda-ignore-properties nil
	org-agenda-skip-scheduled-if-done t
	org-agenda-use-tag-inheritance t
	org-agenda-span 'day
	org-cycle-separator-lines 0
	org-enforce-todo-dependencies t
	org-enforce-todo-checkbox-dependencies t
	org-fold-catch-invisible-edits 'error
	org-log-done 'time
	org-log-reschedule 'note
	org-show-notification-handler nil
	org-track-ordered-property-with-tag t
	org-stuck-projects '("/+PROJ-DONE" ("NEXT" "TODO" "SCHEDULED" "WAITING") () "\\<IGNORE\\>")
	org-clock-report-include-clocking-task t
	org-yank-folded-subtrees nil
	org-special-ctrl-a/e t
	org-special-ctrl-k t
	org-hierarchical-todo-statistics nil
	org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id
	org-use-sub-superscripts nil))

(setq org-agenda-category-icon-alist
      `(("Amateur Radio" ,(list (nerd-icons-codicon
				 "nf-cod-radio_tower")) nil nil :ascent center)
	("Birthdays/Anniversaries" ,(list (nerd-icons-mdicon "nf-md-cake")) nil nil
	 :ascent center)
	("Cooking" ,(list (nerd-icons-mdicon "nf-md-pot_steam")) nil
	 nil :ascent center)
	("Crafts" ,(list (nerd-icons-faicon
			  "nf-fa-paintbrush")) nil nil :ascent center)
	("Diary" ,(list (nerd-icons-faicon "nf-fa-calendar")) nil nil
	 :ascent center)
	("Entertainment" ,(list (all-the-icons-faicon "film")) nil nil :ascent center)
	("Community" ,(list (all-the-icons-material "people")) nil nil :ascent center)
	("Financial" ,(list (all-the-icons-faicon "money")) nil nil :ascent
	 center)
	("Gardening" ,(list (nerd-icons-faicon "nf-fae-plant")) nil
	 nil :ascent center)
	("Genealogy" ,(list (nerd-icons-mdicon "nf-md-family_tree")) nil nil
	 :ascent center)
	("Health" ,(list (nerd-icons-faicon "nf-fa-heartbeat")) nil
	 nil :ascent center)
	("Hobbies" ,(list (nerd-icons-mdicon "nf-md-gamepad_square")) nil
	 nil :ascent center)
	("Home" ,(list (nerd-icons-faicon "nf-fa-house")) nil nil
	 :ascent center)
	("inbox" ,(list (nerd-icons-mdicon "nf-md-inbox")) nil nil
	 :ascent center)
	("Intellectual" ,(list (nerd-icons-faicon "nf-fae-brain")) nil
	 nil :ascent center)
	("main" ,(list (nerd-icons-sucicon "nf-seti-todo")) nil nil
	 :ascent center)
	("Mental Health" ,(list (nerd-icons-mdicon "nf-md-head_heart")) nil
	 nil :ascent center)
	("Physical Health" ,(list (nerd-icons-mdicon
				   "nf-md-dumbbell")) nil nil :ascent center)
	("Professional" ,(list (all-the-icons-faicon "briefcase")) nil
	 nil :ascent center)
	("Software Dev" ,(list (nerd-icons-faicon "nf-fa-code")) nil
	 nil :ascent center)
	("Sleep" ,(list (nerd-icons-mdicon "nf-md-bed")) nil nil :ascent center)
	("Star Wars" ,(list (nerd-icons-mdicon "nf-md-death_star"))
	 nil nil :ascent center)
	("Technology" ,(list (nerd-icons-faicon "nf-fa-laptop")) nil
	 nil :ascent center)
	("Spiritual" ,(list (nerd-icons-mdicon "nf-md-meditation"))
	 nil nil :ascent center)
	("Travel" ,(list (nerd-icons-mdicon "nf-md-airplane")) nil nil
	 :ascent center)
	))

(require 'org-protocol)

;; Always highlight the current agenda line
(add-hook 'org-agenda-mode-hook
          '(lambda () (hl-line-mode 1))
          'append)

;; Turn on flyspell-mode for org documents
(add-hook 'org-mode-hook 'turn-on-flyspell 'append)

(org-babel-do-load-languages 'org-babel-load-languages '((shell . t)
							 (python . t)
							 (restclient . t)
							 (ledger . t)
							 (R . t)
							 (ditaa . t)
							 (dot . t)
							 (emacs-lisp . t)
							 (gnuplot . t)
							 (haskell . nil)
							 (latex . t)
							 (ocaml . nil)
							 (octave . t)
							 (ruby . t)
							 (screen . nil)
							 (sql . nil)
							 (sqlite . t)))

;; Recommended settings for org-modern-mode
(dolist (face '(window-divider
                window-divider-first-pixel
                window-divider-last-pixel))
  (face-spec-reset-face face)
  (set-face-foreground face (face-attribute 'default :background)))
(set-face-background 'fringe (face-attribute 'default :background))

(setq org-auto-align-tags nil
      org-tags-column 0
      org-catch-invisible-edits 'show-and-error
      org-special-ctrl-a/e t
      org-insert-heading-respect-content nil

      ;; Org styling, hide markup etc.
      org-hide-emphasis-markers t
      org-pretty-entities t
      org-agenda-tags-column 0
      org-ellipsis "…")

(global-org-modern-mode)

(use-package org-modern-indent
  :straight (org-modern-indent :type git :host github :repo "jdtsmith/org-modern-indent")
  :config ; add late to hook
  (add-hook 'org-mode-hook #'org-modern-indent-mode 90))

(use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉" "○" "●" "○" "●" "○" "●")))

;; Replace list hyphen with dot
(font-lock-add-keywords 'org-mode
                        '(("^ *\\([-]\\) "
                           (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

(dolist (face '((org-level-1 . 1.21)
                (org-level-2 . 1.13)
                (org-level-3 . 1.08)
                (org-level-4 . 1.05)
                (org-level-5 . 1.03)
                (org-level-6 . 1.02)
                (org-level-7 . 1.01)
                (org-level-8 . 1.0)))
  (set-face-attribute (car face) nil :font "IBM Plex Sans Medium" :weight 'regular :height (cdr face)))

;; Make sure org-indent face is available
(require 'org-indent)

(use-package org-alert
  :ensure t
  :custom (alert-default-style 'notifications)
  :config
  (setq org-alert-interval 300
	org-alert-notify-after-event-cutoff 10
	org-alert-notification-title "Org Alert Reminder")
  (org-alert-enable))

;; Ensure that anything that should be fixed-pitch in Org files appears that way
(set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
(set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
(set-face-attribute 'org-indent nil :inherit '(org-hide fixed-pitch))
(set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
(set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
(set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
(set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch)

;; More settings recommended by SystemCrafters
(defun my/org-mode-visual-fill ()
  (setq visual-fill-column-width 110
	visual-fill-column-center-text t
	visual-fill-column-mode 1))

(require 'org-tempo)

(use-package visual-fill-column
  :hook (org-mode . my/org-mode-visual-fill))

(use-package denote
  :ensure t
  :hook
  ( ;; If you use Markdown or plain text files, then you want to make
   ;; the Denote links clickable (Org renders links as buttons right
   ;; away)
   (text-mode . denote-fontify-links-mode-maybe)
   ;; Apply colours to Denote names in Dired.  This applies to all
   ;; directories.  Check `denote-dired-directories' for the specific
   ;; directories you may prefer instead.  Then, instead of
   ;; `denote-dired-mode', use `denote-dired-mode-in-directories'.
   (dired-mode . denote-dired-mode))
  :bind
  ( :map global-map
    ("C-c n n" . denote)
    ("C-c n d" . denote-sort-dired)
    ;; If you intend to use Denote with a variety of file types, it is
    ;; easier to bind the link-related commands to the `global-map', as
    ;; shown here.  Otherwise follow the same pattern for `org-mode-map',
    ;; `markdown-mode-map', and/or `text-mode-map'.
    ("C-c n l" . denote-link)
    ("C-c n L" . denote-add-links)
    ("C-c n b" . denote-backlinks)
    ;; Note that `denote-rename-file' can work from any context, not just
    ;; Dired bufffers.  That is why we bind it here to the `global-map'.
    ("C-c n r" . denote-rename-file)
    ("C-c n R" . denote-rename-file-using-front-matter)
    ("C-c n f" . denote-open-or-create)

    ;; Key bindings specifically for Dired.
    :map dired-mode-map
    ("C-c C-d C-i" . denote-dired-link-marked-notes)
    ("C-c C-d C-r" . denote-dired-rename-files)
    ("C-c C-d C-k" . denote-dired-rename-marked-files-with-keywords)
    ("C-c C-d C-R" . denote-dired-rename-marked-files-using-front-matter))

  :config
  (setq denote-directory (expand-file-name "~/git/denote/"))
  (setq denote-save-buffers nil)
  (setq denote-infer-keywords t)
  (setq denote-sort-keywords t)
  (setq denote-prompts '(title keywords))
  (setq denote-excluded-directories-regexp nil)
  (setq denote-excluded-keywords-regexp nil)
  (setq denote-rename-confirmations '(rewrite-front-matter modify-file-name))

  ;; Pick dates, where relevant, with Org's advanced interface:
  (setq denote-date-prompt-use-org-read-date t)

  ;; By default, we do not show the context of links.  We just display
  ;; file names.  This provides a more informative view.
  (setq denote-backlinks-show-context t)

  ;; Automatically rename Denote buffers using the `denote-rename-buffer-format'.
  (denote-rename-buffer-mode 1))

(use-package denote-journal
  :ensure t
  :commands ( denote-journal-new-entry
              denote-journal-new-or-existing-entry
              denote-journal-link-or-create-entry )
  :config
  ;; Use the "journal" subdirectory of the `denote-directory'.  Set this
  ;; to nil to use the `denote-directory' instead.
  (setq denote-journal-directory
        (expand-file-name "journal" denote-directory))
  ;; Default keyword for new journal entries. It can also be a list of
  ;; strings.
  (setq denote-journal-keyword "journal")
  ;; Read the doc string of `denote-journal-title-format'.
  (setq denote-journal-title-format 'day-date-month-year))

(use-package consult-denote
  :ensure t
  :bind
  (("C-c n e" . consult-denote-find)
   ("C-c n g" . consult-denote-grep))
  :config
  (consult-denote-mode 1))

(use-package org-download
  :after org
  :bind
  (:map org-mode-map
        (("s-Y" . org-download-screenshot)
         ("s-y" . org-download-yank))))

(use-package org-chef)

;;; Software Development
(use-package treemacs
  :config (setq treemacs-text-scale -.5))

(use-package treemacs-nerd-icons
  :config
  (treemacs-load-theme "nerd-icons"))

(use-package eglot
  :ensure t
  :bind ("C-c e n" . eglot-rename)
  :config
  (add-to-list 'eglot-server-programs '(python-mode . ("pylsp")))
  :hook
  ((python-mode . eglot-ensure)
   (js-mode . eglot-ensure)
   (typescript-ts-mode . eglot-ensure)))

(with-eval-after-load 'eglot
  (setq eglot-ignored-server-capabilities '(:codeActionProvider)))

(add-hook 'prog-mode-hook #'auto-fill-mode)
(add-hook 'prog-mode-hook #'hl-line-mode)

(use-package docker
  :bind ("C-c d" . docker))

;; Completion
;; From https://eshelyaron.com/posts/2023-11-17-completion-preview-in-emacs.html
;; Enable Completion Preview mode in code buffers
(add-hook 'prog-mode-hook #'completion-preview-mode)
;; also in text buffers
(add-hook 'text-mode-hook #'completion-preview-mode)
;; and in \\[shell] and friends
(with-eval-after-load 'comint
  (add-hook 'comint-mode-hook #'completion-preview-mode))

(with-eval-after-load 'completion-preview
  ;; Show the preview already after three symbol characters
  (setq completion-preview-minimum-symbol-length 3)

  ;; Non-standard commands to that should show the preview:
  ;; Org mode has a custom `self-insert-command'
  (push 'org-self-insert-command completion-preview-commands)
  ;; Paredit has a custom `delete-backward-char' command
  (push 'paredit-backward-delete completion-preview-commands)

  ;; Bindings that take effect when the preview is shown:
  ;; Cycle the completion candidate that the preview shows
  (keymap-set completion-preview-active-mode-map "M-n" #'completion-preview-next-candidate)
  (keymap-set completion-preview-active-mode-map "M-p" #'completion-preview-prev-candidate)
  ;; Convenient alternative to C-i after typing one of the above
  (keymap-set completion-preview-active-mode-map "M-i" #'completion-preview-insert))

(use-package dape
  :preface
  ;; By default dape shares the same keybinding prefix as `gud'
  ;; If you do not want to use any prefix, set it to nil.
  ;; (setq dape-key-prefix "\C-x\C-a")
  :config (setq dape-cwd-function 'dape--default-cwd))

;; Enable repeat mode for more ergonomic `dape' use
(use-package repeat
  :config
  (repeat-mode))

(use-package python
  :ensure nil
  :hook (python-ts-mode . eglot-ensure)
  :mode (("\\.py\\'" . python-ts-mode))
  :config
  (setq eglot-report-progress nil)
  :custom
  (python-shell-interpreter "python3")
  )

(use-package typescript-mode
  :ensure t
  :hook
  (typescript-ts-mode . eglot-ensure)
  (typescript-ts-mode . subword-mode)
  (typescript-ts-mode . hs-minor-mode)
  :mode
  ("\\.tsx?\\'" . typescript-ts-mode)
  ("\\.ts\\'" . typescript-ts-mode)
  :config
  (add-to-list 'eglot-server-programs '(typescript-ts-mode .
							   ("typescript-language-server" "--stdio")))
  (setq typescript-indent-level 2)
  (add-hook 'after-save-hook #'prettier-js-mode)) ; format file with prettier on save)

(add-hook 'after-init-hook #'global-flycheck-mode)

(add-hook 'typescript-mode-hook #'flycheck-mode)
(eval-after-load 'flycheck
  '(add-to-list 'flycheck-checkers
                'typescript-eslint))

(setq treesit-language-source-alist
      '((bash "https://github.com/tree-sitter/tree-sitter-bash")
	(cmake "https://github.com/uyha/tree-sitter-cmake")
	(css "https://github.com/tree-sitter/tree-sitter-css")
	(elisp "https://github.com/Wilfred/tree-sitter-elisp")
	(go "https://github.com/tree-sitter/tree-sitter-go")
	(html "https://github.com/tree-sitter/tree-sitter-html")
	(javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
	(json "https://github.com/tree-sitter/tree-sitter-json")
	(make "https://github.com/alemuller/tree-sitter-make")
	(markdown "https://github.com/ikatyang/tree-sitter-markdown")
	(python "https://github.com/tree-sitter/tree-sitter-python")
	(toml "https://github.com/tree-sitter/tree-sitter-toml")
	(tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
	(typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
	(yaml "https://github.com/ikatyang/tree-sitter-yaml")))

(add-to-list 'major-mode-remap-alist '((python-mode . python-ts-mode)
				       (css-mode . css-ts-mode)
				       (typescript-mode . typescript-ts-mode)
				       (js-mode . typescript-ts-mode)
				       (js2-mode . typescript-ts-mode)
				       (c-mode . c-ts-mode)
				       (c++-mode . c++-ts-mode)
				       (c-or-c++-mode . c-or-c++-ts-mode)
				       (bash-mode . bash-ts-mode)
				       (css-mode . css-ts-mode)
				       (json-mode . json-ts-mode)
				       (js-json-mode . json-ts-mode)
				       (sh-mode . bash-ts-mode)
				       (sh-base-mode . bash-ts-mode)))

(add-hook 'js-mode-hook 'js2-minor-mode)
(setq js2-highlight-level 3)

(use-package combobulate
   :custom
   ;; You can customize Combobulate's key prefix here.
   ;; Note that you may have to restart Emacs for this to take effect!
   (combobulate-key-prefix "C-c o")
   :hook ((prog-mode . combobulate-mode))
   ;; Amend this to the directory where you keep Combobulate's source
   ;; code.
   :load-path ("~/git/combobulate/"))

(require 'prettier)
(require 'prettier-js)
(add-hook 'js-mode-hook 'prettier-js-mode)
(add-hook 'web-mode-hook 'prettier-js-mode)
(add-hook 'typescript-ts-mode-hook 'prettier-js-mode)

;; (setenv "NODE_PATH" "/usr/local/lib/node_modules")

(add-to-list 'auto-mode-alist '("\\.tsx?\\'" . typescript-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))

(use-package projectile
  :diminish projectile-mode
  :config (projectile-mode)
  :bind-keymap
  ("C-c p" . projectile-command-map)
  :init
  (setq projectile-switch-project-action #'projectile-dired))

(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode))
;; (add-hook 'prog-mode #'rainbow-delimiters-mode)

(defun indent-whole-buffer ()
  "Indent the entire buffer without affecting point or mark."
  (interactive)
  (save-excursion
    (save-restriction
      (indent-region (point-min) (point-max)))))

(use-package magit
  :ensure t
  :config
  (setq magit-define-global-key-bindings "recommended")
  :bind
  (("C-x g" . magit-status)
   ("C-c g" . magit-dispatch)
   ("C-c f" . magit-file-dispatch)))
(setopt magit-format-file-function #'magit-format-file-all-the-icons)

(with-eval-after-load 'magit-mode
  (add-hook 'after-save-hook 'magit-after-save-refresh-status t))

(setq ediff-split-window-function 'split-window-horizontally)
(setq ediff-window-setup-function 'ediff-setup-windows-plain)

(require 'dired-x)

(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind ("C-x C-j" . dired-jump)
  :custom (dired-listing-switches "-agho --group-directories-first"))

(use-package nerd-icons-dired
  :hook
  (dired-mode . nerd-icons-dired-mode))

(use-package auth-source
  :ensure nil
  :custom
  (auth-sources '("~/.authinfo.gpg")))

(use-package emojify
  :ensure t
  :hook (erc-mode . emojify-mode)
  :commands emojify-mode)

;; Enable vertico
(use-package vertico
  :ensure t
  :bind (:map vertico-map
              ("C-j" . vertico-next)
              ("C-k" . vertico-previous)
              ("C-f" . vertico-exit)
              :map minibuffer-local-map
              ("M-h" . backward-kill-word))
  :custom
  (vertico-cycle t) ;; Enable cycling for `vertico-next/previous'
  :init
  (vertico-mode))

(add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy)

;; Persist history over Emacs restarts. Vertico sorts by history position.
(use-package savehist
  :init
  (savehist-mode))

(use-package marginalia
  :after vertico
  :ensure t
  :init
  (marginalia-mode))

(all-the-icons-completion-mode)
(add-hook 'marginalia-mode-hook #'all-the-icons-completion-marginalia-setup)

;; Another set of optional settings recommended by Vertico dev
(use-package emacs
  :custom
  ;; Support opening new minibuffers from inside existing minibuffers.
  (enable-recursive-minibuffers t)
  ;; Hide commands in M-x which do not work in the current mode.  Vertico
  ;; commands are hidden in normal buffers. This setting is useful beyond
  ;; Vertico.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Enable indentation+completion using the TAB key.
  ;; `completion-at-point' is often bound to M-TAB.
  (tab-always-indent 'complete)

  ;; Emacs 30 and newer: Disable Ispell completion function. As an alternative,
  ;; try `cape-dict'.
  (text-mode-ispell-word-completion nil)

  ;; Hide commands in M-x which do not apply to the current mode.  Corfu
  ;; commands are hidden, since they are not used via M-x. This setting is
  ;; useful beyond Corfu.
  (read-extended-command-predicate #'command-completion-default-include-p)
  :init
  ;; Add prompt indicator to `completing-read-multiple'.
  ;; We display [CRM<separator>], e.g., [CRM,] if the separator is a comma.
  (defun crm-indicator (args)
    (cons (format "[CRM%s] %s"
                  (replace-regexp-in-string
                   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
                   crm-separator)
                  (car args))
          (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)

  ;; Do not allow the cursor in the minibuffer prompt
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode))

;; Configuration from https://github.com/minad/consult
(use-package consult
  :ensure t
  :hook (completion-list-mode . consult-preview-at-point-mode)
  :init     (setq register-preview-delay 0.5
		  register-preview-function #'consult-register-format)
  (advice-add #'register-preview :override #'consult-register-window)
  (setq xref-show-xrefs-function #'consult-xref
	xref-show-definitions-function #'consult-xref)
  ;; Replace bindings. Lazily loaded by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
	 ("C-s-j" . consult-buffer)
         ("C-c M-x" . consult-mode-command)
         ("C-c h" . consult-history)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x t b" . consult-buffer-other-tab)    ;; orig. switch-to-buffer-other-tab
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flycheck)               ;; Alternative: consult-flymake
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
	 ("M-g h" . consult-org-heading)
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-find)                  ;; Alternative: consult-fd
         ("M-s c" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)                 ;; orig. next-matching-history-element
         ("M-r" . consult-history))                ;; orig. previous-matching-history-element
  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)
  ;; The :init configuration is always executed (Not lazy)
  :init
  ;; Optionally configure the register formatting. This improves the register
  ;; preview for `consult-register', `consult-register-load',
  ;; `consult-register-store' and the Emacs built-ins.
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)
  ;; Optionally tweak the register preview window.
  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)
  ;; Use to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config
  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key "M-.")
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; "C-+"

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (keymap-set consult-narrow-map (concat consult-narrow-key " ?") #'consult-narrow-help)
  )
(keymap-global-set "C-s-l" 'consult-line)
(keymap-set minibuffer-local-map "C-r" 'consult-history)

;; isearch recommended by Prot:
;; https://protesilaos.com/codelog/2023-06-10-emacs-search-replace-basics/
;; Display a counter showing the number of the current and the other
;; matches.  Place it before the prompt, though it can be after it.
(setq isearch-lazy-count t)
(setq lazy-count-prefix-format "(%s/%s) ")
(setq lazy-count-suffix-format nil)

;; Make regular Isearch interpret the empty space as a regular expression that
;; matches any character between the words you give it.
(setq search-whitespace-regexp ".*?")

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package embark
  :ensure t
  :bind
  (("C-." . embark-act)         
   ("C-;" . embark-dwim)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'
  :init
  ;; Replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)
  :config
  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package embark-consult
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package cape
  ;; Bind prefix keymap providing all Cape commands under a mnemonic key.
  ;; Press C-c p ? to for help.
  :bind ("C-c p" . cape-prefix-map) 
  :init
  ;; ;; Add to the global default value of `completion-at-point-functions' which is
  ;; ;; used by `completion-at-point'.  The order of the functions matters, the
  ;; ;; first function returning a result wins.  Note that the list of buffer-local
  ;; ;; completion functions takes precedence over the global list.
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  (add-hook 'completion-at-point-functions #'cape-history)
  (add-hook 'completion-at-point-functions #'cape-keyword)
  )

;; From https://github.com/minad/corfu/wiki - specify explicitly to use
;; Orderless for Eglot
(setq completion-category-overrides '((eglot (styles orderless))
                                      (eglot-capf (styles orderless))))

;; Ensures that the completion table is refreshed such that the
;; candidates are always obtained again from the server.
(advice-add 'eglot-completion-at-point :around #'cape-wrap-buster)

(defun my/eglot-capf ()
  (setq-local completion-at-point-functions
              (list (cape-capf-super
                     #'eglot-completion-at-point
		     ;; Commenting out tempel since I don't have the
		     ;; package installed, but I'll probably come back to it in
		     ;; lieu of yasnippet
                     ;; #'tempel-expand
                     #'cape-file))))

(add-hook 'eglot-managed-mode-hook #'my/eglot-capf)

;; From
;; https://www.jamescherti.com/emacs-highlight-keywords-like-todo-fixme-note/
;; Highlighting keywords such as TODO, FIXME, NOTE, BUG in prog-modes
(defvar highlight-codetags-keywords
  '(("\\<\\(TODO\\|FIXME\\|BUG\\|XXX\\)\\>" 1 font-lock-warning-face prepend)
    ("\\<\\(NOTE\\|HACK\\)\\>" 1 font-lock-doc-face prepend)))

(define-minor-mode highlight-codetags-local-mode
  "Highlight codetags like TODO, FIXME..."
  :global nil
  (if highlight-codetags-local-mode
      (font-lock-add-keywords nil highlight-codetags-keywords)
    (font-lock-remove-keywords nil highlight-codetags-keywords))

  ;; Fontify the current buffer
  (when (bound-and-true-p font-lock-mode)
    (if (fboundp 'font-lock-flush)
        (font-lock-flush)
      (with-no-warnings (font-lock-fontify-buffer)))))
(add-hook 'prog-mode-hook #'highlight-codetags-local-mode)

(require 'company)
(setq-local completion-at-point-functions
	    (mapcar #'cape-company-to-capf
		    (list #'company-files #'company-keywords
			  #'company-dabbrev)))

(with-eval-after-load 'company
  (add-to-list 'company-backends '(company-capf :with company-yasnippet)))

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown"))

;; Taken from https://thanosapollo.org/posts/emacs-shells-video/
;; Use eat shell to extend capabilities of eshell
(use-package eat
  :ensure t
  :config
  (setf eshell-visual-commands nil
        eat-term-name "xterm-256color")
  :bind (("C-c V" . eat))
  :hook ((eshell-mode . eat-eshell-mode)
         (eshell-mode . eat-eshell-visual-command-mode)
         (eat-mode . (lambda () (visual-line-mode -1)))))

(with-eval-after-load "esh-opt"
  (autoload 'epe-theme-lambda "eshell-prompt-extras")
  (setq eshell-highlight-prompt nil
        eshell-prompt-function 'epe-theme-lambda))

(with-eval-after-load "esh-opt"
  (require 'virtualenvwrapper)
  (venv-initialize-eshell)
  (autoload 'epe-theme-lambda "eshell-prompt-extras")
  (setq eshell-highlight-prompt nil
        eshell-prompt-function 'epe-theme-lambda))

(yas-global-mode 1)

(use-package ledger-mode
  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((ledger . t))))

(add-hook 'ledger-mode-hook
          (lambda ()
            (setq-local tab-always-indent 'complete)
            (setq-local completion-cycle-threshold t)
            (setq-local ledger-complete-in-steps t)))
(add-hook 'ledger-report-mode-hook 'compilation-minor-mode)
(add-hook 'ledger-mode-hook #'hl-line-mode)

;; meal-planner
(use-package meal-planner
  :straight (meal-planner :type git :host github :repo
			  "captainflasmr/meal-planner")
  :config
  (setq meal-planner-data-directory "~/git/org/meal_planning/meals/"
	meal-planner-history-file "~/git/org/meal_planning/my-meal-history.el"))
(require 'meal-planner)

(use-package display-wttr
  :config
  (display-wttr-mode))

;;; Other keybindings
(global-set-key (kbd "C-c u") 'duplicate-dwim)
(global-set-key (kbd "M-i") 'consult-imenu)
(global-set-key (kbd "C-c r") #'revert-buffer)
(global-set-key (kbd "C-c s") #'eshell)
(global-set-key [remap list-buffers] 'ibuffer)
(global-set-key (kbd "C-x p i") 'org-cliplink)
(global-set-key (kbd "C-c ;") 'er/expand-region)

(load "~/git/private-dots/private-emacs.el")

;; Local Variables:
;; flycheck-disabled-checkers: emacs-lisp-checkdoc
;; End:
