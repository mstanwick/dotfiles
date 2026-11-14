;;; early-init.el --- Early initialization -*- lexical-binding: t -*-
;; Loaded before the package system and GUI; changes here take effect
;; before any package or frame is initialized.

;; Maximize GC threshold during startup to reduce collection pauses.
;; Reset to a practical value after init via emacs-startup-hook.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Skip file-handler dispatch for all files during startup (regex matching
;; is expensive when loading hundreds of .el files).
(defvar my/file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'emacs-startup-hook
  (lambda ()
    (setq file-name-handler-alist my/file-name-handler-alist)))

;; Disable JIT native compilation to prevent async subprocesses from
;; regenerating broken .eln files when compat-31 macros (static-when etc.)
;; are not available in the compiler environment.
(setq native-comp-jit-compilation nil)

;; Disable UI elements before the first frame is drawn to prevent flicker.
;; Using default-frame-alist is faster than calling the mode functions later.
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; Prevent package.el from auto-initializing before init.el runs.
;; We call (package-initialize) explicitly after configuring archives.
(setq package-enable-at-startup nil)

;; EMMS rewrites its cache file without a lexical-binding cookie, so
;; Emacs 31 warns every time it loads it. Silence that one file only;
;; the warning still appears for any other file missing a cookie.
;; warnings.el only loads when the first warning is shown, so add the
;; entry once it loads (it runs before that warning is displayed).
(with-eval-after-load 'warnings
  (add-to-list 'warning-suppress-log-types
               `(files missing-lexbind-cookie
                       ,(abbreviate-file-name (locate-user-emacs-file "emms/cache")))))
