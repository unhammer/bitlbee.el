;;; bitlbee.el --- Help get Bitlbee (http://www.bitlbee.org) up and running
;;
;; Copyright (C) 2008 pmade inc. (Peter Jones pjones@pmade.com)
;; with some changes by Kevin Brubeck Unhammer
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;;
;; Commentary:
;;
;; Start and stop bitlbee from within emacs.
;;
;; Assumes you have a ~/.bitlbee directory where the bitlbee.conf file
;; lives, along with the account information XML files.  The directory
;; can be set using the `bitlbee-user-directory' variable, and is
;; created automatically if necessary.
;;
;; You might also need to set the `bitlbee-executable' variable.
;;
;; Usage:
;;
;; (add-to-list 'load-path "~/path/to/bitlbee.el")
;; (autoload 'bitlbee-stop "bitlbee"
;;   "Stop the bitlbee server" 'interactivep)
;; (autoload 'bitlbee-start "bitlbee"
;;   "Start the bitlbee server" 'interactivep)
;; (autoload 'bitlbee-running-p "bitlbee")
;;
;; 
;; To get TAB-completion:
;;
;; (add-hook 'erc-mode-hook #'pcomplete-bitlbee-setup)
;;
;;
;; Original version by Peter Jones:
;;
;; git clone git://pmade.com/elisp

(defvar bitlbee-user-directory "~/.bitlbee"
  "The directory where user configuration goes")

(defvar bitlbee-options "-n -D -v "
  "The options passed to Bitlbee on the command line.")

(defvar bitlbee-executable "bitlbee"
  "The full path to the Bitlbee executable")

(defvar bitlbee-buffer-name "*bitlbee*"
  "The name of the bitlbee process buffer")

(defun bitlbee-running-p ()
  "Returns non-nil if bitlbee is running"
  (if (get-buffer-process bitlbee-buffer-name) t nil))

(defun bitlbee-start ()
  "Start the bitlbee server"
  (interactive)
  (if (bitlbee-running-p) (message "bitlbee is already running")
    (make-directory (expand-file-name bitlbee-user-directory) t)
    (let ((proc (start-process-shell-command "bitlbee" bitlbee-buffer-name bitlbee-executable (bitlbee-command-line))))
      (set-process-sentinel proc 'bitlbee-sentinel-proc))
      (message "started bitlbee")))

(defun bitlbee-stop ()
  "Stop the bitlbee server"
  (interactive)
  (let ((proc (get-buffer-process bitlbee-buffer-name)))
    (when proc (kill-process proc t))))

(defun bitlbee-sentinel-proc (proc msg)
  (when (memq (process-status proc) '(exit signal))
    (setq msg (replace-regexp-in-string "\n" "" (format "stopped bitlbee (%s)" msg)))
  (message msg)))

(defun bitlbee-command-line ()
  "Create the full command line necessary to run bitlbee"
  (concat bitlbee-options " -d " bitlbee-user-directory " -c " bitlbee-user-directory "/bitlbee.conf"))



;;; pcomplete functions, based off erc-pcomplete:

(defun pcomplete/erc-mode/ACCOUNT ()
  ;; TODO: subcommands
  (pcomplete-here '("add" "del" "list" "on" "off" "set")))
(defun pcomplete/erc-mode/CHANNEL ()
  ;; TODO: <account id> first
  (pcomplete-here '("del" "list" "set")))
(defun pcomplete/erc-mode/CHAT () (pcomplete-here '("add" "with")))
(defun pcomplete/erc-mode/ADD ()
  ;; TODO: <account id> first, <handle> <nick> after
  (pcomplete-here '("-tmp" "")))
(defun pcomplete/erc-mode/INFO ()
  ;; TODO: Syntax: info <connection> <handle>
  ;; DONE: Syntax: info <nick>
  (pcomplete-here (pcomplete-erc-nicks)))
(defun pcomplete/erc-mode/REMOVE () (pcomplete-here (pcomplete-erc-nicks)))
(defun pcomplete/erc-mode/BLOCK ()
  ;;  DONE: Syntax: block <nick>
  ;;  TODO: Syntax: block <connection> <handle>
  ;;  TODO: Syntax: block <connection>
  (pcomplete-here (pcomplete-erc-nicks)))
(defun pcomplete/erc-mode/ALLOW ()
  ;;  DONE: Syntax: allow <nick>
  ;;  TODO: Syntax: allow <connection> <handle>
  (pcomplete-here (pcomplete-erc-nicks)))
(defun pcomplete/erc-mode/OTR ()
  ;; TODO: subcommands
  (pcomplete-here '("connect" "disconnect" "reconnect" "smp" "smpq" "trust" "info" "keygen" "forget")))
(defun pcomplete/erc-mode/SET ()
  ;; TODO: possible values? ugh
  (pcomplete-here '("-del" "auto_connect" "auto_reconnect" "auto_reconnect_delay" "debug" "mobile_is_away" "save_on_quit" "status" "strip_html" "allow_takeover" "away_reply_timeout" "charset" "default_target" "display_namechanges" "display_timestamps" "handle_unknown" "lcnicks" "nick_format" "offline_user_quits" "ops" "paste_buffer" "paste_buffer_delay" "password" "private" "query_order" "simulate_netsplit" "timezone" "to_char" "typing_notice" "otr_color_encrypted" "otr_policy")))
(defun pcomplete/erc-mode/HELP ()
  (pcomplete-here
   (append
    '("quickstart" "quickstart2" "quickstart3" "quickstart4" "quickstart5" "quickstart5" "index" "commands" "channels" "away" "groupchats" "nick_changes" "smileys")
    ;; TODO: subcommands
    bitlbee-primary-commands)))
(defun pcomplete/erc-mode/SAVE () (pcomplete-here '()))	; no args
(defun pcomplete/erc-mode/RENAME ()
  (pcomplete-here (cons "-del" (pcomplete-erc-nicks)))
  (pcomplete-here (when (equal (pcomplete-arg 1) "-del")
		     (pcomplete-erc-nicks))))
(defun pcomplete/erc-mode/YES () (pcomplete-here '())) ; probably shouldn't complete this
(defun pcomplete/erc-mode/NO () (pcomplete-here '())) ; probably shouldn't complete this
(defun pcomplete/erc-mode/QLIST () (pcomplete-here '())) ; no args
(defun pcomplete/erc-mode/REGISTER () (pcomplete-here '())) ; definitely shouldn't complete this
(defun pcomplete/erc-mode/IDENTIFY () (pcomplete-here '("-noload" "-force" "")))
(defun pcomplete/erc-mode/DROP () (pcomplete-here '())) ; definitely shouldn't complete this
(defun pcomplete/erc-mode/BLIST () (pcomplete-here '())) ; no args
(defun pcomplete/erc-mode/GROUP () (pcomplete-here '("list")))
(defun pcomplete/erc-mode/TRANSFER ()
  ;; TODO: transfer cancel id
  (pcomplete-here '("cancel" "reject" "")))

(defvar bitlbee-primary-commands
  '("account" "channel" "chat" "add" "info" "remove" "block" "allow" "otr" "set" "help" "save" "rename" "yes" "no" "qlist" "register" "identify" "drop" "blist" "group" "transfer"))

(defun pcomplete-erc-command-name-bitlbee ()
  "Returns the command name of the first argument."
  (if (eq (elt (pcomplete-arg 'first) 0) ?/)
      (upcase (substring (pcomplete-arg 'first) 1))
    (if (member (downcase (pcomplete-arg 'first)) bitlbee-primary-commands)
	(upcase (pcomplete-arg 'first))
      "SAY")))

(defun pcomplete/erc-mode/complete-command-bitlbee ()
  (interactive)
  (pcomplete-here
   (append
    bitlbee-primary-commands
    (pcomplete-erc-commands)
    (pcomplete-erc-nicks erc-pcomplete-nick-postfix t))))

(defun pcomplete-bitlbee-setup ()
  "Add to erc-mode-hook to get some completion, runs if buffer is
named &bitlbee."
  (when (equal (buffer-name) "&bitlbee")
    (setq pcomplete-command-completion-function 'pcomplete/erc-mode/complete-command-bitlbee
	  pcomplete-command-name-function 'pcomplete-erc-command-name-bitlbee)))



(provide 'bitlbee)

