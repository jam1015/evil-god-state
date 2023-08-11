;;; evil-god-state.el --- use god-mode keybindings in evil-mode

;; Copyright (C) 2014 by Eric Seidel
;; Author: Eric Seidel
;; URL: https://github.com/gridaphobe/evil-god-state
;; Filename: evil-god-state.el
;; Description: use god-mode keybindings in evil-mode
;; Version: 0.1
;; Keywords: evil leader god-mode
;; Package-Requires: ((evil "1.0.8") (god-mode "2.12.0"))

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;; This is an evil-mode state for using god-mode.

;; It provides a command `evil-execute-in-god-state' that switches to
;; `god-local-mode' for the next command. I bind it to ","
;;
;;     (evil-define-key 'normal global-map "," 'evil-execute-in-god-state)
;;
;; for an automatically-configured leader key.
;;
;; Since `evil-god-state' includes an indicator in the mode-line, you may want
;; to use `diminish' to keep your mode-line uncluttered, e.g.
;;
;;     (add-hook 'evil-god-state-entry-hook (lambda () (diminish 'god-local-mode)))
;;     (add-hook 'evil-god-state-exit-hook (lambda () (diminish-undo 'god-local-mode)))

;; It's handy to be able to abort a `evil-god-state' command.  The following
;; will make the <ESC> key unconditionally exit evil-god-state.
;;     (evil-define-key 'god global-map [escape] 'evil-god-state-bail)



;;; Code:
(require 'evil)
(require 'god-mode)

(evil-define-state god
  "God state."
  :tag " <G> "
  :message "-- GOD MODE --"
  :entry-hook (evil-god-start-hook)
  :exit-hook (evil-god-stop-hook)
  :input-method t
  :intercept-esc nil)

(defvar evil-visual-state-map-backup nil)

(defun evil-god-start-hook ()
  "Run before entering `evil-god-state'."
  (remove-hook 'activate-mark-hook 'evil-visual-activate-hook t)
  (remove-hook 'deactivate-mark-hook 'evil-visual-deactivate-hook t)
  (god-local-mode 1))

(defun evil-god-stop-hook ()
  "Run before exiting `evil-god-state'."
  (add-hook 'deactivate-mark-hook #'evil-visual-deactivate-hook nil t)
  (add-hook 'activate-mark-hook #'evil-visual-activate-hook nil t)
  (unless persist_visual (deactivate-mark))
  (if mark-active
	(evil-visual-activate-hook)
	)

  ;;(deactivate-mark)
  (god-local-mode -1)
  ) ; Restore the keymap


(defvar evil-execute-in-god-state-buffer nil) ;just in case I need it for further development
(defvar evil-god-last-command nil) ; command before entering evil-god-state
(defvar ran-first-evil-command nil)

( defun evil-god-fix-last-command ()
  "Change `last-command' to be the command before `evil-execute-in-god-state'."
  (if (not ran-first-evil-command)
      (progn
	(setq last-command evil-god-last-command)
	(setq ran-first-evil-command t)
	) 
    (remove-hook 'pre-command-hook 'evil-god-fix-last-command)
    )
  )

;;;###autoload
(defun evil-execute-in-god-state ()
  "Go into god state, as if it is normal mode"
  (interactive)

  (setq ran-first-evil-command nil)
  (add-hook 'pre-command-hook  #'evil-god-fix-last-command      t) ; (setq last-command evil-god-last-command))
  (setq evil-execute-in-god-state-buffer (current-buffer))
  (setq evil-god-last-command last-command)
  (cond
   ((and (evil-visual-state-p) persist_visual)
    (let ((mrk (mark))
      (pnt (point)))
      (evil-god-state 1)
      (set-mark mrk)
      (goto-char pnt))

    )
   (t
    (evil-god-state 1)))
  )


(defun evil-stop-execute-in-god-state (bail)
  (interactive)
  "Switch back to previous evil state."
  (unless (or (eq this-command #'evil-execute-in-god-state)
	      (eq this-command #'universal-argument)
	      (eq this-command #'universal-argument-minus)
	      (eq this-command #'universal-argument-more)
	      (eq this-command #'universal-argument-other-key)
	      (eq this-command #'digit-argument)
	      (eq this-command #'negative-argument)
	      (minibufferp))
    (remove-hook 'pre-command-hook 'evil-god-fix-last-command)
	   (if bail
		 (evil-normal-state 1)
	     (evil-insert-state 1))
    (setq evil-execute-in-god-state-buffer nil)
    )

  )



(defun god-toggle (append)
  (interactive)
  (if god-local-mode
      (progn
	(evil-echo "Switching out of evil-god-mode")
	(evil-stop-execute-in-god-state nil)
	(if append (forward-char)); like pressing 'a' in normal mode in vim

	)
    (progn
      (evil-echo "Switching into evil-god-mode")
      (unless (eq evil-state 'normal)


	(cond
	 ((string-equal god_entry_strategy "same")
	  (unless append
	    (backward-char)
	    )
	  )
	 ((string-equal god_entry_strategy "toggle")

	  (if append
	      (backward-char)
	    )
	  )
	 ((string-equal god_entry_strategy "reverse")
	  ;; doing nothing does the opposite of what vim normally does 
	  )

	 (t
	  ;; Do something for "default" or anything else here
	  (backward-char)
	  )
	 )
	)
      (evil-execute-in-god-state )

      )))


(provide 'evil-god-state)
;;; evil-god-state.el ends here
