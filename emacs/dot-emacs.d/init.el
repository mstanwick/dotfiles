;;; init.el --- Main Emacs config (stowed to ~/.emacs.d/init.el) -*- lexical-binding: t -*-

;;; Package Bootstrap
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("elpa" . "https://elpa.gnu.org/packages/") t)
(require 'epa-file)
(epa-file-enable)
(package-initialize)
(require 'use-package)
(setq use-package-always-ensure t
      use-package-always-defer t)
;; Packages that only live in git repos use use-package's :vc keyword
;; (built in since Emacs 30), so no second package manager is needed.

(setq custom-file (locate-user-emacs-file "emacs-custom.el"))
(load custom-file 'noerror)

;;; Core Settings

;; Reset GC to a practical post-startup value and report startup time.
;; early-init.el maximized gc-cons-threshold to reduce pauses during loading.
(add-hook 'emacs-startup-hook
  (lambda ()
    (setq gc-cons-threshold (* 16 1024 1024)  ; 16 MB
          gc-cons-percentage 0.1)
    (message "Emacs loaded in %.2fs with %d GCs."
             (float-time (time-subtract after-init-time before-init-time))
             gcs-done)))

(setq-default fill-column 80)
(setq history-length 25
      use-dialog-box nil
      sentence-end-double-space nil
      save-interprogram-paste-before-kill t
      isearch-allow-motion t
      help-window-select t
      ring-bell-function 'ignore)

(recentf-mode 1)
(save-place-mode 1)
(global-auto-revert-mode 1)
(setq auto-revert-verbose nil
      global-auto-revert-non-file-buffers t)

(electric-pair-mode 1)
(setq electric-pair-inhibit-predicate 'electric-pair-conservative-inhibit)
;; Prevent electric-pair from inserting a closing `>' when using
;; the `< s RET' org-tempo shortcut for src blocks.
(add-hook 'org-mode-hook
  (lambda ()
    (setq-local electric-pair-inhibit-predicate
                `(lambda (c)
                   (if (char-equal c ?<) t
                     (,electric-pair-inhibit-predicate c))))))

(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)

;;; macOS Settings
;; Use system-type rather than window-system so these settings don't
;; accidentally trigger on WSL, which reports window-system 'x when
;; running under WSLg or any X server.
(when (eq system-type 'darwin)
  (use-package exec-path-from-shell
    :demand t
    :config (exec-path-from-shell-initialize))
  ;; macOS ships BSD ls; use Homebrew's GNU ls (brew install coreutils).
  (setq insert-directory-program "gls"
        dired-use-ls-dired t)
  ;; Transparent title bar (macOS native frames only)
  (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
  (use-package add-node-modules-path
    :ensure t
    :hook ((js-mode
            js-ts-mode
            javascript-mode
            javascript-ts-mode
            typescript-mode
            typescript-ts-mode
            web-mode
            rjsx-mode) . add-node-modules-path)))

;;; WSL Settings
(defun my/wsl-p ()
  "Return non-nil when Emacs is running under Windows Subsystem for Linux."
  ;; WSL kernels report a release such as "5.15.167.4-microsoft-standard-WSL2".
  ;; `operating-system-release' holds that string, so no `uname' process is needed.
  (and (eq system-type 'gnu/linux)
       (string-match-p "microsoft" (downcase (or operating-system-release "")))
       t))

(when (my/wsl-p)
  ;; Copy kills to the Windows clipboard.
  (setq interprogram-cut-function
        (lambda (text)
          (let* ((process-connection-type nil) ; use a pipe, not a pty
                 (proc (start-process "clip" nil "clip.exe")))
            (process-send-string proc text)
            (process-send-eof proc))))
  ;; WSLg asynchronously syncs the Windows clipboard back to the X clipboard.
  ;; Emacs sets interprogram-paste-function to x-selection-value under X11,
  ;; so current-kill reads the X clipboard instead of the Emacs kill ring.
  ;; By the second org-refile, the X clipboard has the previous heading
  ;; (synced from Windows), causing org-paste-subtree to insert the wrong
  ;; content.  Nil this out so current-kill always uses the kill ring.
  (setq interprogram-paste-function nil)
  ;; Open links in the Windows default browser. `start-process' passes the
  ;; URL as one argument, so it needs no shell quoting and doesn't block.
  (setq browse-url-browser-function
        (lambda (url &rest _)
          (start-process "explorer" nil "explorer.exe" url)))
  ;; WSL's inotify integration fires spurious change notifications, causing
  ;; auto-revert to replace org buffers mid-operation (e.g. during refile),
  ;; which invalidates saved markers and refiles the wrong heading.  Fall
  ;; back to polling instead.
  (setq auto-revert-use-notify nil)
  ;; org-refile does not auto-save buffers after a refile.  With polling
  ;; auto-revert, the on-disk file still has the original heading, so the
  ;; next poll reverts the buffer and undoes the refile.  Force a save of
  ;; all org buffers after every refile to keep disk state in sync.
  (with-eval-after-load 'org
    (advice-add 'org-refile :after
      (lambda (&rest _) (org-save-all-org-buffers)))))

(with-eval-after-load 'ert
  (ert-deftest my/wsl-p-test ()
    (let ((system-type 'gnu/linux))
      (let ((operating-system-release "5.15.167.4-microsoft-standard-WSL2"))
        (should (my/wsl-p)))
      (let ((operating-system-release "4.4.0-19041-Microsoft")) ; WSL1
        (should (my/wsl-p)))
      (let ((operating-system-release "6.17.4-300.fc45.x86_64"))
        (should-not (my/wsl-p)))
      (let ((operating-system-release nil))
        (should-not (my/wsl-p))))
    ;; A macOS kernel string never counts, whatever it contains.
    (let ((system-type 'darwin)
          (operating-system-release "microsoft"))
      (should-not (my/wsl-p)))))

;;; UI & Display
(setq-default frame-title-format ""
              truncate-lines t)
(setq inhibit-splash-screen t
      window-combination-resize t
      tab-bar-show nil)

(column-number-mode 1)
(tab-bar-mode -1)

;; Line numbers in code/text/config modes, suppressed in terminals
(dolist (mode '(text-mode-hook prog-mode-hook conf-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 1))))
(dolist (mode '(org-mode-hook term-mode-hook shell-mode-hook eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

;; Suppress the title bar only when the frame is maximized
(add-hook 'window-size-change-functions #'frame-hide-title-bar-when-maximized)

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1))

(use-package spacious-padding
  :init
  (setq spacious-padding-subtle-frame-lines
        '(:mode-line-active default
          :mode-line-inactive vertical-border)
        spacious-padding-widths
        '(:internal-border-width 5))
  (spacious-padding-mode 1))

;;; Window Management
(winner-mode 1)
(tab-bar-history-mode 1)
(global-set-key (kbd "M-[") #'tab-bar-history-back)
(global-set-key (kbd "M-]") #'tab-bar-history-forward)

(defun toggle-delete-other-windows ()
  "Delete other windows in frame if any, or restore previous window config."
  (interactive)
  (if (and winner-mode
           (equal (selected-window) (next-window)))
      (winner-undo)
    (delete-other-windows)))
(global-set-key (kbd "C-x 1") #'toggle-delete-other-windows)

(use-package repeat
  :ensure nil
  :config
  (repeat-mode 1)
  (setq set-mark-command-repeat-pop t)
  (defvar-keymap buffer-navigation-repeat-map
    :doc "Repeat map for next-buffer/previous-buffer via C-x <arrow>."
    "<right>" #'next-buffer
    "<left>"  #'previous-buffer)
  (put 'next-buffer     'repeat-map 'buffer-navigation-repeat-map)
  (put 'previous-buffer 'repeat-map 'buffer-navigation-repeat-map))

;;; Minibuffer & Completion Foundation

;; This block must come before vertico/consult/embark are initialized.
(use-package emacs
  :ensure nil
  :custom
  ;; Allow opening new minibuffers from inside existing ones.
  (enable-recursive-minibuffers t)
  ;; Hide M-x commands that don't work in the current mode.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; TAB indents first, then completes.
  (tab-always-indent 'complete)
  ;; Disable Ispell completion in text-mode (use cape-dict instead).
  (text-mode-ispell-word-completion nil)
  :init
  ;; Show active separator in completing-read-multiple prompt, e.g. [CRM,].
  (defun crm-indicator (args)
    (cons (format "[CRM%s] %s"
                  (replace-regexp-in-string
                   "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
                   crm-separator)
                  (car args))
          (cdr args)))
  (advice-add #'completing-read-multiple :filter-args #'crm-indicator)
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode))

;;; Completion Framework

(use-package vertico
  :ensure t
  :bind
  (:map vertico-map
   ("C-j" . vertico-next)
   ("C-k" . vertico-previous)
   ("C-f" . vertico-exit)
   :map minibuffer-local-map
   ("M-h" . backward-kill-word))
  :custom
  (vertico-cycle t)
  :init
  (vertico-mode 1))

(add-hook 'rfn-eshadow-update-overlay-hook #'vertico-directory-tidy)

(use-package savehist
  :ensure nil
  :init
  (savehist-mode 1)
  :config
  (setq savehist-additional-variables '(search-ring regexp-search-ring kill-ring))
  (add-hook 'savehist-save-hook
    (lambda ()
      (setq kill-ring
            (mapcar #'substring-no-properties
                    (cl-remove-if-not #'stringp kill-ring))))))

(use-package marginalia
  :after vertico
  :ensure t
  :init
  (marginalia-mode 1))

;; Workaround: marginalia calls seconds-to-string with extra args that older
;; Emacs builds don't support. Remove after upgrading marginalia.
(with-eval-after-load 'marginalia
  (when (and (fboundp 'seconds-to-string)
             (= 1 (cdr (func-arity 'seconds-to-string))))
    (advice-add 'seconds-to-string :around
      (lambda (orig secs &rest _) (funcall orig secs)))))

(use-package all-the-icons-completion
  :hook (marginalia-mode . all-the-icons-completion-marginalia-setup)
  :init (all-the-icons-completion-mode 1))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion))
                                   (eglot (styles orderless))
                                   (eglot-capf (styles orderless)))))

(use-package consult
  :ensure t
  :hook (completion-list-mode . consult-preview-at-point-mode)
  :bind
  (("C-s-j"   . consult-buffer)
   ("C-c M-x" . consult-mode-command)
   ("C-c h"   . consult-history)
   ("C-c k"   . consult-kmacro)
   ("C-c m"   . consult-man)
   ("C-c i"   . consult-info)
   ([remap Info-search] . consult-info)
   ("C-x M-:" . consult-complex-command)
   ("C-x b"   . consult-buffer)
   ("C-x 4 b" . consult-buffer-other-window)
   ("C-x 5 b" . consult-buffer-other-frame)
   ("C-x t b" . consult-buffer-other-tab)
   ("C-x r b" . consult-bookmark)
   ("C-x p b" . consult-project-buffer)
   ("M-#"     . consult-register-load)
   ("M-'"     . consult-register-store)
   ("C-M-#"   . consult-register)
   ("M-y"     . consult-yank-pop)
   ("M-g e"   . consult-compile-error)
   ("M-g f"   . consult-flycheck)
   ("M-g g"   . consult-goto-line)
   ("M-g M-g" . consult-goto-line)
   ("M-g o"   . consult-outline)
   ("M-g h"   . consult-org-heading)
   ("M-g m"   . consult-mark)
   ("M-g k"   . consult-global-mark)
   ("M-g i"   . consult-imenu)
   ("M-g I"   . consult-imenu-multi)
   ("M-s d"   . consult-find)
   ("M-s c"   . consult-locate)
   ("M-s g"   . consult-grep)
   ("M-s G"   . consult-git-grep)
   ("M-s r"   . consult-ripgrep)
   ("M-s l"   . consult-line)
   ("M-s L"   . consult-line-multi)
   ("M-s k"   . consult-keep-lines)
   ("M-s u"   . consult-focus-lines)
   ("M-s e"   . consult-isearch-history)
   ("C-s-l"   . consult-line)
   :map isearch-mode-map
   ("M-e"   . consult-isearch-history)
   ("M-s e" . consult-isearch-history)
   ("M-s l" . consult-line)
   ("M-s L" . consult-line-multi)
   :map minibuffer-local-map
   ("C-r" . consult-history)
   ("M-s" . consult-history)
   ("M-r" . consult-history))
  :init
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)
  (advice-add #'register-preview :override #'consult-register-window)
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :config
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   :preview-key '(:debounce 0.4 any))
  (setq consult-narrow-key "<"))

;; isearch display: show match count and treat spaces as wildcards
(setq isearch-lazy-count t
      lazy-count-prefix-format "(%s/%s) "
      lazy-count-suffix-format nil
      search-whitespace-regexp ".*?")

(use-package embark
  :ensure t
  :bind
  (("C-."   . embark-act)
   ("C-;"   . embark-dwim)
   ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package embark-consult
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; NOTE: cape was previously bound to C-c p, which conflicts with projectile.
;; Changed to C-c C-p to resolve the conflict.
(use-package cape
  :bind ("C-c C-p" . cape-prefix-map)
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)
  (add-hook 'completion-at-point-functions #'cape-history)
  (add-hook 'completion-at-point-functions #'cape-keyword))

;; Completion Preview (built-in, Emacs 30+)
(add-hook 'prog-mode-hook #'completion-preview-mode)
(add-hook 'text-mode-hook #'completion-preview-mode)
(with-eval-after-load 'comint
  (add-hook 'comint-mode-hook #'completion-preview-mode))
(with-eval-after-load 'completion-preview
  (setq completion-preview-minimum-symbol-length 3)
  (push 'org-self-insert-command completion-preview-commands)
  (push 'paredit-backward-delete completion-preview-commands)
  (keymap-set completion-preview-active-mode-map "M-n" #'completion-preview-next-candidate)
  (keymap-set completion-preview-active-mode-map "M-p" #'completion-preview-prev-candidate)
  (keymap-set completion-preview-active-mode-map "M-i" #'completion-preview-insert))

;;; Org Mode

(defun my/org-mode-setup ()
  ;; variable-pitch-mode must be 0 for org-tables to format correctly.
  (variable-pitch-mode 0)
  (auto-fill-mode 0)
  (visual-line-mode 1))

;; Org Babel languages that don't ship with Org: ob-ledger is in
;; org-contrib, ob-restclient is its own package. Declared so a fresh
;; machine installs them before org's :config loads them.
(use-package org-contrib)
(use-package ob-restclient)

(use-package org
  :ensure nil
  :hook (org-mode . my/org-mode-setup)
  :bind
  (("C-c l"   . org-store-link)
   ("C-c a"   . org-agenda)
   ("C-c c"   . org-capture)
   ("C-c j r" . org-refile-goto-last-stored)
   ("C-c /"   . org-sparse-tree)
   ("C-c M-." . org-timestamp-inactive))
  :config
  (setq org-ellipsis "…"
        org-goto-auto-isearch nil
        org-hide-emphasis-markers t
        org-pretty-entities t
        org-auto-align-tags nil
        org-tags-column 0
        org-agenda-tags-column 0
        org-agenda-include-diary t
        org-agenda-diary-file "~/git/org/diary.org"
        org-directory "~/git/org/"
        org-todo-keywords
        '((sequence "TODO(t@/!)" "NEXT(n/!)" "WAITING(w@/!)"
                    "SCHEDULED(k/!)" "PROJ(p)" "SOMEDAY(s)"
                    "|" "DONE(d/!)" "CANCELLED(c@/!)"))
        org-agenda-files '("~/git/org/")
        org-global-properties
        '(("Effort_ALL" . "0:15 0:30 1:00 2:00 3:00 4:00 5:00 6:00 7:00 8:00"))
        org-archive-location "~/git/org/archive/%s_archive::"
        org-clock-continuously nil
        org-clock-into-drawer "CLOCKING"
        org-clock-out-remove-zero-time-clocks t
        org-clock-rounding-minutes 1
        org-clock-sound t
        org-clock-report-include-clocking-task t
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
        org-catch-invisible-edits 'show-and-error
        org-fold-catch-invisible-edits 'error
        org-show-notification-handler nil
        org-stuck-projects
        '("/+PROJ-DONE" ("NEXT" "TODO" "SCHEDULED" "WAITING") () "\\<IGNORE\\>")
        org-yank-folded-subtrees nil
        org-special-ctrl-a/e t
        org-special-ctrl-k t
        org-insert-heading-respect-content nil
        org-hierarchical-todo-statistics nil
        org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id
        org-use-sub-superscripts nil)

  (org-babel-do-load-languages 'org-babel-load-languages
    '((shell      . t)
      (python     . t)
      (restclient . t)
      (ledger     . t)
      (R          . t)
      (ditaa      . t)
      (dot        . t)
      (emacs-lisp . t)
      (gnuplot    . t)
      (latex      . t)
      (octave     . t)
      (ruby       . t)
      (sqlite     . t)))

  (require 'org-protocol)
  (require 'org-tempo)
  (require 'org-indent))

(add-hook 'org-agenda-mode-hook (lambda () (hl-line-mode 1)) 'append)
(add-hook 'org-mode-hook #'turn-on-flyspell 'append)

;; Fix window-divider face colors for org-modern (must run after frame init).
;; Guards against "unspecified-bg" which appears in terminal/daemon sessions.
(let ((bg (face-attribute 'default :background)))
  (unless (member bg '("unspecified-bg" "unspecified" nil))
    (dolist (face '(window-divider window-divider-first-pixel window-divider-last-pixel))
      (face-spec-reset-face face)
      (set-face-foreground face bg))
    (set-face-background 'fringe bg)))

(use-package org-modern
  :init (global-org-modern-mode 1))

(use-package org-modern-indent
  :vc (:url "https://github.com/jdtsmith/org-modern-indent" :rev :newest)
  :config
  (add-hook 'org-mode-hook #'org-modern-indent-mode 90))

;; org-modern handles heading bullets globally; org-bullets is not needed.

;; Replace list hyphens with bullet dots
(font-lock-add-keywords 'org-mode
  '(("^ *\\([-]\\) "
     (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

;; Scale org heading fonts progressively
(dolist (face '((org-level-1 . 1.21)
                (org-level-2 . 1.13)
                (org-level-3 . 1.08)
                (org-level-4 . 1.05)
                (org-level-5 . 1.03)
                (org-level-6 . 1.02)
                (org-level-7 . 1.01)
                (org-level-8 . 1.0)))
  (set-face-attribute (car face) nil
                      :font "IBM Plex Sans Medium"
                      :weight 'regular
                      :height (cdr face)))

;; Fixed-pitch faces within org buffers.
;; Deferred until org loads because these faces aren't defined until then
;; (org-indent lives in org-indent.el, the rest in org-faces.el).
(with-eval-after-load 'org
  (set-face-attribute 'org-block           nil :foreground 'unspecified :inherit 'fixed-pitch)
  (set-face-attribute 'org-code            nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim        nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line       nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox        nil :inherit 'fixed-pitch))
(with-eval-after-load 'org-indent
  (set-face-attribute 'org-indent          nil :inherit '(org-hide fixed-pitch)))

(defun my/org-mode-visual-fill ()
  (setq visual-fill-column-width 110
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1))

(use-package visual-fill-column
  :hook (org-mode . my/org-mode-visual-fill))

(use-package org-alert
  :ensure t
  :config
  ;; Pick the right notification backend per platform.
  ;; WSL reports gnu/linux but usually has no notification service, so it
  ;; is checked first and falls back to the echo area.
  (setq alert-default-style
        (cond ((eq system-type 'darwin) 'osx-notifier) ; requires terminal-notifier (brew install)
              ((my/wsl-p) 'message)
              ((eq system-type 'gnu/linux) 'notifications) ; requires libnotify / notify-send
              (t 'message))
        org-alert-interval 300
        org-alert-notify-after-event-cutoff 10
        org-alert-notification-title "Org Alert Reminder")
  (org-alert-enable))

(use-package org-download
  :after org
  :bind
  (:map org-mode-map
        ("s-Y" . org-download-screenshot)
        ("s-y" . org-download-yank)))

(use-package org-chef)

;;; Note-Taking: Denote

(use-package denote
  :ensure t
  :hook
  ((text-mode  . denote-fontify-links-mode-maybe)
   (dired-mode . denote-dired-mode))
  :bind
  (:map global-map
   ("C-c n n" . denote)
   ("C-c n d" . denote-sort-dired)
   ("C-c n l" . denote-link)
   ("C-c n L" . denote-add-links)
   ("C-c n b" . denote-backlinks)
   ("C-c n r" . denote-rename-file)
   ("C-c n R" . denote-rename-file-using-front-matter)
   ("C-c n f" . denote-open-or-create)
   :map dired-mode-map
   ("C-c C-d C-i" . denote-dired-link-marked-notes)
   ("C-c C-d C-r" . denote-dired-rename-files)
   ("C-c C-d C-k" . denote-dired-rename-marked-files-with-keywords)
   ("C-c C-d C-R" . denote-dired-rename-marked-files-using-front-matter))
  :config
  (setq denote-directory              (expand-file-name "~/git/denote/")
        denote-save-buffers           nil
        denote-infer-keywords         t
        denote-sort-keywords          t
        denote-prompts                '(title keywords)
        denote-excluded-directories-regexp nil
        denote-excluded-keywords-regexp    nil
        denote-rename-confirmations   '(rewrite-front-matter modify-file-name)
        denote-date-prompt-use-org-read-date t
        denote-backlinks-show-context t)
  (denote-rename-buffer-mode 1))

(use-package denote-journal
  :ensure t
  :commands (denote-journal-new-entry
             denote-journal-new-or-existing-entry
             denote-journal-link-or-create-entry)
  :config
  (setq denote-journal-directory
        (expand-file-name "journal" denote-directory)
        denote-journal-keyword      "journal"
        denote-journal-title-format 'day-date-month-year))

(use-package consult-denote
  :ensure t
  :bind
  (("C-c n e" . consult-denote-find)
   ("C-c n g" . consult-denote-grep))
  :config
  (consult-denote-mode 1))

;;; Software Development

;; treesit-auto manages grammar installation and picks versions compatible
;; with the current Emacs tree-sitter ABI automatically. This avoids
;; version-mismatch errors when grammars bump their ABI (e.g. 14 -> 15)
;; before the system libtree-sitter catches up.
(use-package treesit-auto
  :demand t
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

;; major-mode-remap-alist is managed by treesit-auto, which only remaps
;; when the grammar is actually available. No manual list needed.

(setq treesit-font-lock-level 4
      js2-basic-offset 2)

;; LSP via Eglot (built-in since Emacs 29)
(use-package eglot
  :ensure nil
  :bind ("C-c e n" . eglot-rename)
  :config
  (setq eglot-ignored-server-capabilities '(:codeActionProvider)
        eglot-report-progress nil)
  (add-to-list 'eglot-server-programs '(python-mode . ("pylsp")))
  (add-to-list 'eglot-server-programs
               '(typescript-ts-mode . ("typescript-language-server" "--stdio"))))

;; Ensure eglot completions use Orderless; force fresh candidates from server
(advice-add 'eglot-completion-at-point :around #'cape-wrap-buster)
(defun my/eglot-capf ()
  (setq-local completion-at-point-functions
              (list (cape-capf-super #'eglot-completion-at-point #'cape-file))))
(add-hook 'eglot-managed-mode-hook #'my/eglot-capf)

(use-package python
  :ensure nil
  :mode ("\\.py\\'" . python-ts-mode)
  :hook (python-ts-mode . eglot-ensure)
  :custom
  (python-shell-interpreter "python3"))

(use-package typescript-mode
  :ensure t
  :mode (("\\.tsx?\\'" . typescript-ts-mode)
         ("\\.ts\\'"   . typescript-ts-mode))
  :hook
  ((typescript-ts-mode . eglot-ensure)
   (typescript-ts-mode . subword-mode)
   (typescript-ts-mode . hs-minor-mode)))

(with-eval-after-load 'flycheck
  (add-to-list 'flycheck-checkers 'typescript-eslint))
(use-package flycheck
  :hook ((emacs-lisp-mode typescript-mode) . flycheck-mode))

;; js-mode is remapped to typescript-ts-mode via major-mode-remap-alist,
;; so js-mode-hook never fires. All JS/TS hooks go on typescript-ts-mode-hook.
(use-package js2-mode
  :hook (typescript-ts-mode . js2-minor-mode))
(use-package prettier-js
  :hook ((typescript-ts-mode web-mode) . prettier-js-mode))

(use-package combobulate
  ;; Loaded from a local clone; skip it on machines that don't have one.
  :when (file-directory-p (expand-file-name "~/git/combobulate/"))
  :custom (combobulate-key-prefix "C-c o")
  :hook (prog-mode . combobulate-mode)
  :load-path ("~/git/combobulate/"))

;; General prog-mode enhancements
;; auto-fill with comment-auto-fill-only-comments limits hard-wrapping to
;; comment text, leaving code lines untouched.
(add-hook 'prog-mode-hook
  (lambda ()
    (setq-local comment-auto-fill-only-comments t)
    (auto-fill-mode 1)))
(add-hook 'prog-mode-hook #'hl-line-mode)
(use-package breadcrumb
  :ensure nil
  :vc (:url "https://github.com/joaotavora/breadcrumb" :rev :newest)
  :hook (prog-mode . breadcrumb-local-mode))

;; Highlight TODO/FIXME/BUG/NOTE in source code
(defvar highlight-codetags-keywords
  '(("\\<\\(TODO\\|FIXME\\|BUG\\|XXX\\)\\>"  1 font-lock-warning-face prepend)
    ("\\<\\(NOTE\\|HACK\\)\\>"               1 font-lock-doc-face    prepend)))

(define-minor-mode highlight-codetags-local-mode
  "Highlight codetags like TODO, FIXME, NOTE, BUG in the current buffer."
  :global nil
  (if highlight-codetags-local-mode
      (font-lock-add-keywords nil highlight-codetags-keywords)
    (font-lock-remove-keywords nil highlight-codetags-keywords))
  (when (bound-and-true-p font-lock-mode)
    (if (fboundp 'font-lock-flush)
        (font-lock-flush)
      (with-no-warnings (font-lock-fontify-buffer)))))
(add-hook 'prog-mode-hook #'highlight-codetags-local-mode)

(use-package treemacs
  :config (setq treemacs-text-scale -0.5))

(use-package treemacs-nerd-icons
  :config (treemacs-load-theme "nerd-icons"))

(use-package dape
  :config (setq dape-cwd-function 'dape--default-cwd))

(use-package projectile
  :diminish projectile-mode
  :config (projectile-mode 1)
  :bind-keymap ("C-c p" . projectile-command-map)
  :init
  (setq projectile-switch-project-action #'projectile-dired))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

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
  (setopt magit-format-file-function #'magit-format-file-all-the-icons)
  (add-hook 'after-save-hook #'magit-after-save-refresh-status t)
  :bind
  (("C-x g" . magit-status)
   ("C-c g"  . magit-dispatch)
   ("C-c f"  . magit-file-dispatch)))

(setq ediff-split-window-function 'split-window-horizontally
      ediff-window-setup-function 'ediff-setup-windows-plain)

(use-package markdown-mode
  :ensure t
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "multimarkdown"))

(use-package pdf-tools
  :magic ("%PDF" . pdf-view-mode)
  :config (pdf-tools-install 'no-query))

(use-package docker
  :bind ("C-c d" . docker))

(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind ("C-x C-j" . dired-jump)
  :config
  ;; --group-directories-first requires GNU ls.
  ;; On macOS, insert-directory-program is set to gls in the darwin block.
  ;; On Linux/WSL, GNU ls is the default. The flags are safe on all three.
  (setq dired-listing-switches "-agho --group-directories-first")
  (require 'dired-x))

(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

(use-package auth-source
  :ensure nil
  :custom
  (auth-sources '("~/.authinfo.gpg")))

;;; Applications

(use-package ace-window)  ; used by hkey-ace-window-setup below
(use-package hyperbole
  :demand t
  :config
  ;; Several hyperbole files (hui-select.el, hactypes.el, hmouse-drv.el, …) use
  ;; treesit macros inside eval-and-compile blocks that eagerly load grammars at
  ;; macro-expansion time.  Any missing grammar (e.g. CSS on a fresh WSL machine)
  ;; raises treesit-load-language-error and crashes Emacs startup before the
  ;; treesit-auto filter has a chance to run.  Wrap all hyperbole setup in one
  ;; condition-case so Emacs can still start; then run
  ;; M-x treesit-auto-install-all to install missing grammars permanently.
  (condition-case err
      (progn
        (hyperbole-mode 1)
        ;; On WSL, hywiki-mode causes cursor flicker when typing capital
        ;; letters due to overlay manipulation in the WSL display pipeline.
        ;; Disable it entirely on WSL.
        (unless (my/wsl-p)
          (hywiki-mode :all))
        ;; HyWiki's completion runs grep with a file glob through the user's
        ;; shell.  Under zsh a no-match glob fails with "no matches found"; sh
        ;; gives the "No such file or directory" error HyWiki expects.
        (define-advice hywiki-completion-at-point (:around (fn &rest args) use-sh)
          (let ((shell-file-name "/bin/sh"))
            (apply fn args)))
        ;; hyrolo-file-list is set in private.el: it names personal folders, and
        ;; HyRolo raises an error (stopping init) if a listed folder is missing.
        (hkey-ace-window-setup "\M-o"))
    (error (message "Warning: hyperbole setup failed (missing treesit grammar?): %S" err))))

(use-package avy
  :bind
  (("C-:"   . avy-goto-char)
   ("M-g w" . avy-goto-word-1)
   ("M-g e" . avy-goto-word-0))
  :bind*
  ("C-'" . avy-goto-char-2))
(avy-setup-default)
(global-set-key (kbd "C-c C-j") #'avy-resume)

(use-package elfeed-org)  ; called from elfeed's :config
(use-package elfeed
  :bind ("C-c w" . elfeed)
  :config
  (elfeed-org)
  (add-hook 'elfeed-new-entry-hook
            (elfeed-make-tagger :feed-url "youtube\\.com"
                                :add '(video youtube))))

(use-package elfeed-tube
  :ensure t
  :after elfeed
  :demand t
  :config (elfeed-tube-setup)
  :bind
  (:map elfeed-show-mode-map
   ("F" . elfeed-tube-fetch)
   ([remap save-buffer] . elfeed-tube-save)
   :map elfeed-search-mode-map
   ("F" . elfeed-tube-fetch)
   ([remap save-buffer] . elfeed-tube-save)))

(use-package elfeed-tube-mpv
  :ensure t
  :bind
  (:map elfeed-show-mode-map
   ("C-c C-f" . elfeed-tube-mpv-follow-mode)
   ("C-c C-w" . elfeed-tube-mpv-where)))

(use-package emms
  :config
  (emms-all)
  (setq emms-player-list    '(emms-player-mpv)
        emms-info-functions '(emms-info-native))
  :bind
  (("C-c e p" . emms-play-url)
   ("C-c e q" . emms-add-url)
   ("C-c e >" . emms-next)))

(use-package time-zones :ensure t)

(use-package display-wttr
  ;; display-wttr-locations is set in private.el.
  :config (display-wttr-mode 1))

(use-package eat
  :ensure t
  :config
  (setf eshell-visual-commands nil
        eat-term-name "xterm-256color")
  :bind ("C-c V" . eat)
  :hook
  ((eshell-mode . eat-eshell-mode)
   (eshell-mode . eat-eshell-visual-command-mode)
   (eat-mode    . (lambda () (visual-line-mode -1)))))

(use-package pyvenv
  :ensure t
  :config (pyvenv-mode 1))

(use-package eshell-prompt-extras)
(with-eval-after-load "esh-opt"
  (autoload 'epe-theme-lambda "eshell-prompt-extras")
  (setq eshell-highlight-prompt nil
        eshell-prompt-function  'epe-theme-lambda))

(defun eshell-current-directory (&optional directory)
  "Open eshell in `default-directory' or DIRECTORY."
  (interactive)
  (let ((current-dir (or directory default-directory))
        (eshell-buffer (or (get-buffer "*eshell*") (eshell))))
    (switch-to-buffer eshell-buffer)
    (eshell/cd current-dir)
    (eshell-next-prompt)
    (if (eobp)
        (eshell-send-input nil nil nil)
      (move-end-of-line nil)
      (eshell-kill-input)
      (eshell-send-input nil nil nil)
      (yank))))

(use-package ghostel :ensure t)

(use-package yasnippet
  :config (yas-global-mode 1))

(use-package ledger-mode)
(add-hook 'ledger-mode-hook
  (lambda ()
    (setq-local tab-always-indent      'complete
                completion-cycle-threshold t
                ledger-complete-in-steps   t)))
(add-hook 'ledger-report-mode-hook #'compilation-minor-mode)
(add-hook 'ledger-mode-hook         #'hl-line-mode)

(use-package emojify
  :ensure t
  :hook (erc-mode . emojify-mode)
  :commands emojify-mode)

(use-package which-key
  :ensure nil  ; built-in since Emacs 30.1
  :init (which-key-mode 1)
  :diminish which-key-mode
  :config (setq which-key-idle-delay 1))

(use-package helpful
  :bind
  ([remap describe-command] . helpful-command)
  ([remap describe-key]     . helpful-key))

;;; Global Keybindings
(global-set-key (kbd "C-c u")        #'duplicate-dwim)
(global-set-key (kbd "M-i")          #'consult-imenu)
(global-set-key (kbd "C-c r")        #'revert-buffer)
(global-set-key (kbd "C-c s")        #'eshell-current-directory)
(global-set-key [remap list-buffers] #'ibuffer)
(global-set-key (kbd "M-C")          #'upcase-char)

(use-package org-cliplink
  :bind ("C-x p i" . org-cliplink))
(use-package expand-region
  :bind ("C-c ;" . er/expand-region))

;;; AI Shell
(defun my/nvm-newest-bin (&optional root)
  "Return the bin dir of the newest Node under ROOT (default ~/.nvm), or nil."
  (let* ((dir (expand-file-name "versions/node/" (or root "~/.nvm")))
         (vers (and (file-directory-p dir)
                    (directory-files dir nil "\\`v[0-9]")))
         ;; Compare as version numbers so v9 sorts below v24.
         (newest (car (sort vers (lambda (a b)
                                   (version< (substring b 1) (substring a 1)))))))
    (when newest
      (let ((bin (expand-file-name (concat newest "/bin/") dir)))
        (and (file-directory-p bin) bin)))))

;; agent-shell needs node in exec-path (to find claude-agent-acp) and in
;; PATH (for the script's "#!/usr/bin/env node" line). Works on Linux,
;; macOS and WSL without per-platform paths.
(when-let* ((bin (my/nvm-newest-bin)))
  (add-to-list 'exec-path bin)
  (setenv "PATH" (concat bin path-separator (getenv "PATH"))))

(with-eval-after-load 'ert
  (ert-deftest my/nvm-newest-bin-test ()
    (let ((root (make-temp-file "nvm" t)))
      (unwind-protect
          (progn
            ;; No versions folder at all -> nil
            (should-not (my/nvm-newest-bin root))
            ;; v9 vs v24: version order, not alphabetical order
            (dolist (v '("v9.0.0" "v24.11.1" "v18.2.0"))
              (make-directory (format "%s/versions/node/%s/bin" root v) t))
            (should (string-suffix-p "v24.11.1/bin/" (my/nvm-newest-bin root)))
            ;; Stray non-version entries are ignored
            (make-directory (concat root "/versions/node/.cache") t)
            (should (string-suffix-p "v24.11.1/bin/" (my/nvm-newest-bin root))))
        (delete-directory root t)))))

(use-package agent-shell
  :ensure t
  :config
  (setq agent-shell-anthropic-authentication
        (agent-shell-anthropic-make-authentication :login t)
        agent-shell-prefer-viewport-interaction t))
(setopt agent-shell-show-cost-indicator t)

;;; Private, Work and Local Configuration
;; Optional layers, loaded last so they can override anything above:
;;   private.el - personal settings (private-dots repo, personal machines only)
;;   work.el    - work settings (work-dots repo, work machines only)
;;   local.el   - this machine only, not in any repo
;; Missing files are skipped, so the same init.el works on every machine.
(dolist (file '("private.el" "work.el" "local.el"))
  (load (locate-user-emacs-file file) 'noerror 'nomessage))

;; `server-running-p' is not autoloaded, so server.el must be loaded first.
;; A daemon starts its own server right after init, so only do this otherwise.
(require 'server)
(unless (or (daemonp) (server-running-p))
  (server-start))

;; Local Variables:
;; flycheck-disabled-checkers: (emacs-lisp-checkdoc)
;; eval: (flycheck-mode -1)
;; End:
