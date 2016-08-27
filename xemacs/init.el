;
;; don't have millions of *~ files around
(require 'backup-dir)
(setq bkup-backup-directory-info
        '(
	  ("~/.*" . ("/~/.backups/"  ok-create full-path prepend-name))
          (t      . ("~/.backups/"  ok-create full-path  prepend-name))
	  )
	)

;;; Load units
(load "dired")
;(require 'ecb-util)

;; to make a new library:
;; get your new .el file
;; cd to xemacs/lib
;; mkdir <yournewlib>
;; cp <yournewlib.el> xemacs/lib/<yournewlib><yournewlib.el>
;; cd pkginfo
;; copy one of the MANIFEST.<pakagename> files then edit and rename appropriatly
;; restart xemacs
;;

;
;; General Startup stuff
(font-lock-mode)
(line-number-mode t)


;(setq compilation-search-path (cons compilation-search-path (pwd)))

;(if (string-equal system-type "cygwin32")
;      (setq file (mswindows-cygwin-to-win32-path file)))

;(rs-c-setup)
;
;; work with dos and unix text files seemlessly
;( doesn't seem to work too well!)
; docs of comint-strip-ctrl-m and comint-output-filter-functions seem to make sense though...
(add-hook 'comint-output-filter-functions
	  'comint-strip-ctrl-m)

;;Autoloaded packages
 (autoload 'ansi-color-for-comint-mode-on "ansi-color" nil t)
 (add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)
 (autoload 'cvs-commit "cvs-commit" nil t)

;; Add auto mode entry for common file types
(push '("\\.cpp$" . c++-mode) auto-mode-alist)
(push '("rules\\.in" . makefile-mode) auto-mode-alist) ;uHAL makefiles use both
(push '("\\.make$" . makefile-mode) auto-mode-alist)   ;of these all the time
(push '("\\.pro$" . ksh-mode) auto-mode-alist)        ; tmake .pro files are shell-eqsue
(push '("\\.pro$" . font-lock-mode) auto-mode-alist) 
(push '("Doxyfile$" . perl-mode) auto-mode-alist)      ; doxygen config files are perlesque
(push '("\\.java$" . java-mode) auto-mode-alist)


; 
;; Try and use the network copies of .emacs info with all the real meat
;(if (string-match "win32" emacs-version)
;      (setq load-path (cons (expand-file-name "d:/rsanders/xemacs/") load-path))
;  ;;else	
;  nil)

;(load-library "xemacs-general")
;(load-library "xemacs-keys")

(defun rs-no-tabs-chars-please ()
"Keeps modes from inserting the dreaded tab character with auto indent"
(interactive)
(setf indent-tabs-mode nil)
 (message "making it so tabs won't be inserted"))


;
;;Custom functions authored by yours truly
(defun switch-to-scratch ()
  (interactive)
  (switch-to-buffer-other-window "*scratch*"))

(defun c-safe-header-wrapper-create ()
  "Write the #ifndef SOMEHEADER_H wrapper for safe c/c++ headers.  Assumes you're calling from the .h buffer"
  (interactive)
  (setf theName (format "__%s_H__" (upcase (dired-file-name-base (buffer-file-name)))))
  (insert "#ifndef " theName "\n")
  (insert "#define " theName "\n")
  (goto-char (point-max))
  (insert "#endif // " theName "\n"))

(defun insert-file-name()
  "Write the current buffer's file name at the point." 
  (interactive)
  (insert (file-name-nondirectory (buffer-file-name))))

(defun header-impl-switch () 
  "opens up the corresponding header/(c/cpp) file into the other window. 
   Globals:
           impl-ext
           header-ext
  Would 
  nice if it used some of the c/c++ mode vars instead of hard coded extensions 
  or even if it took two args...
  or if it used alists to keep track of corresponding headers/impls... "  
  (interactive) 
  (if (or (equal (dired-file-name-extension (buffer-file-name)) ".cpp")  
	  (equal (dired-file-name-extension (buffer-file-name)) ".c")) 
      ;;then 
      (find-file-other-window (format "%s.h" (dired-file-name-base (buffer-file-name)))) 
    ;;else  
    ;;switch to c or cpp file depending on which one exists.  Otherwise default to cpp
    (if (file-exists-p (format "%s.c" (dired-file-name-base (buffer-file-name))))  
	;;then 
	(find-file-other-window (format "%s.c" (dired-file-name-base (buffer-file-name))))
      ;;else  
    (find-file-other-window (format "%s.cpp" (dired-file-name-base (buffer-file-name)))))))

(defun rs-java-unit-test-switch ()
  (interactive)
  (setq buf-name (buffer-file-name))
  (if (string-match "UnitTest.java" buf-name)
      ;;then
      (find-file-other-window  (format "%s.java"(substring buf-name 0 (match-beginning 0))))
;      (message  (format "%s.java"(substring buf-name 0 (match-beginning 0))))
    ;;else if
    (if (string-match ".java$" buf-name)
	;;then
	(find-file-other-window (format "%sUnitTest.java" (substring buf-name 0 (match-beginning 0)))))))


(defun co (comment)
  "Use cleartool to checkout the file you're currently looking at"
  (interactive "scheckout comment:")
  (setq fileToCheckout (buffer-file-name))
  (setq lineInFile (line-number))
  (kill-buffer nil)
  (setq coCommand (format "cleartool checkout -c \"%s\" %s" comment fileToCheckout)) 
  (shell-command coCommand)
  (find-file fileToCheckout)
  (goto-line lineInFile))

;;
;;; Setup my c/c++ styles 
(setq rs-basic-indent 2)
;(setq rs-c-style "k&r")
(setq rs-c-style "bsd")
(defun rs-c-setup ()
  "Set my prefered c style"
  (interactive)
  (c-set-style rs-c-style)
  (setq c-basic-offset rs-basic-indent)
  (setf indent-tabs-mode nil) ; don't insert tabs with auto indent
;  (defalias 'com
;    (read-kbd-macro "/*! RET * RET */ <up> 2*SPC"))
  (message "Using %s style with indent of %d" rs-c-style rs-basic-indent))
(add-hook 'c-mode-hook
	  'rs-c-setup)
(add-hook 'c++-mode-hook
   'rs-c-setup)
(add-hook 'java-mode-hook
   'rs-c-setup)
(add-hook 'java-mode-hook
   'rs-java-setup)

;
;; java specific stuff
(defun rs-java-setup ()
  "Setup for java. [f4] open unit test in other tab, [f5] refresh, [f9] compile"
  (interactive)
  (setq compile-command "ant")
  (global-set-key [f4] 'rs-java-unit-test-switch)
  (global-set-key [f9] 'compile)
  (defalias 'com
    (read-kbd-macro "TAB /** RET * RET */ <up> SPC"))
  (defalias 'log
    (read-kbd-macro "TAB logger.info(\"\"); 3*<left>"))
  ;(global-set-key [(control f9)] 'rs-vcc-run)
  )


;
;; Visual C++ specific stuff
(defun rs-vcc-setup ()
  " Setup for using MS Visual C++ compiler 
    binding keys local to cpp buffers would be better but this works for now
    (local-set-key [f9] 'rs-vcc-run)
    see pp389 of _learning_emacs_ for more info"
  (interactive)
  (setq compile-command "nmake")
  (global-set-key [f9] 'compile)
  (global-set-key [(control f9)] 'rs-vcc-run)
(global-set-key [f6] 'rs-mapi-header-in-top-window)
(global-set-key [f4] 'header-impl-switch))

;
;;Comment this out when not working in msvcc
(add-hook 'c-mode-hook
   'rs-c-setup)
(add-hook 'c++-mode-hook
   'rs-vcc-setup)

;
;; Unix/gcc development stuff
(defun rs-gcc-setup ()
" Setup for using gnu toolchain on a unix system."
  (interactive)
  (setq compile-command "make")
  (global-set-key [f9] 'rs-vcc-run))

;
;; I'm usually in MSVCC so do this setup automatically
;(add-hook 'c-mode-hook
;   'rs-vcc-setup)
;(add-hook 'c++-mode-hook
;   'rs-vcc-setup)
(add-hook 'c-mode-hook
   'rs-gcc-setup)
(add-hook 'c++-mode-hook
   'rs-gcc-setup)


(defun rs-vcc-run ()
  "Running the program from the shell command (M-!) freezes Xemacs under Win32 
   untill the program ends.  The compile command is smart enough to run jobs in 
   the background.  I leverage this by adding a run target in makefiles.  This 
   function just calls nmake run"
  (interactive)
  (nt-shell-setup)
  (setq old-compile-command compile-command)
  (setq compile-command "nmake run")
  (compile compile-command) 
  (setq compile-command old-compile-command ))

(defun rs-gcc-run ()
  "Running the program from the shell command (M-!) freezes Xemacs under Win32 
   untill the program ends.  The compile command is smart enough to run jobs in 
   the background.  I leverage this by adding a run target in makefiles.  This 
   function just calls nmake run"
  (interactive)
;  (cygwin-shell-setup)
  (setq old-compile-command compile-command)
  (setq compile-command "make run")
  (compile compile-command) 
  (setq compile-command old-compile-command ))

;
;; TI Code Composer Stuff
(defun rs-cc-arm-setup ()  
  "Sets up the environment for ti code composer ARM  friendliness"
  (interactive)
  (setq compile-command "timake /NOLOGO")
  (global-set-key [f9] 'compile)
  (message "CodeComposer ARM environment setup."))

;
;; Shell Setup
;;these used to be in the cygwin-shell-setup but since I switch between nt and cygwin shells
;;I didnt' want them being re added all the time
(setq exec-path (cons "C:/cygwin/bin" exec-path))
(setenv "PATH" (concat "C:\\cygwin\\bin;" (getenv "PATH")))
(defun cygwin-shell-setup ()
  "Cygwin setup This assumes that Cygwin is installed in C:\cygwin (the default)
   and that C:\cygwin\bin is not already in your Windows Path (it generally 
   should not be)."
  (interactive)
  ;;
  ;; find a way to exec this at start: PS1='[34m\u@\h[0m [01m\w[0m\n$ '
  ;;
  ;; NT-emacs assumes a Windows command shell, which you change
  ;; here.
  ;;
  (setq process-coding-system-alist '(("bash" . undecided-unix)))
  (setq w32-quote-process-args ?\")
  (setq shell-file-name "c:\\cygwin\\cygwin.bat")
  (setenv "SHELL" shell-file-name) 
  (setq explicit-shell-file-name shell-file-name) 
  ;;
  ;; This removes unsightly ^M characters that would otherwise
  ;; appear in the output of java applications.
  ;;
  (add-hook 'comint-output-filter-functions
	    'comint-strip-ctrl-m))

(defun nt-shell-setup ()
  " sets up regular nt shell.  Usefull when switching between nt shell and cygwin shell."
  (interactive)
  ; should pop bash of the alist but we won't worry about that right now
  ;(setq process-coding-system-alist '(("bash" . undecided-unix)))
  ; should set to void, not nil
  (setq w32-quote-process-args ())
  (setq shell-file-name "C:\\windows\\system32\\cmd.exe")
  (setenv "SHELL" "cmd") 
  (setq explicit-shell-file-name shell-file-name))

;;;;;;;;;;;; Macros ;;;;;;;;;;;;;;;

;;A little keyboard macro for inserting a blank doxygen style function comment


;;Change a #define for a mapi ht error into a case statement entry
(setq last-kbd-macro (read-kbd-macro
"ESC d TAB case SPC C-s ( RET <left> : C-k TAB C-r case RET 5*<right> 3*<C-right> <right> C-SPC C-e <C-left> <C-right> ESC w C-a <down> RET <up> TAB result+= SPC \" C-y \"; C-r \" RET 2*<C-r> RET <right> C-SPC C-e ESC x downcase TAB re TAB RET 4*<C-r> RET 3*<C-s> RET C-SPC C-e ESC % _ RET SPC RET ! C-e RET TAB break; C-a <down>"))


;; would be nice to have a fcn that sucked in a std file comment box
;; then you could make a really neat-o fcn that took a header file, 
;; created the impl file, sucked in the std file comment box, and  
;; created all the stub fcns


;; Working on class completion
;class \(.*\): ; works in lisp buffer
;class\b\(\w+\)\b ; should work 
;class[ \t]+\(\w+[ \t\n]+\) ; does work
;(match-string 1)
;"tfrmWView"


(defun rs-insert-c++-class-name ()
"Returns the current class name guessing from the base of current buffer name"
(interactive)
  (setf root-file-name (dired-file-name-base (buffer-file-name)))
  (insert root-file-name)
  (insert "::"))

;
;; when put at the beginning of a line with a member function pasted from
;; a header it inserts the class name and braces, then places the point appropriately 
(defalias 'rs-cpp-member-declaration (read-kbd-macro
"C-a 2*<C-right> <C-left> ESC x rs-insert-c++-class-name RET C-e <backspace> RET { 2*RET } <up> TAB"))

(defun rs-strip-ctrl-m-from-buffer () 
"Strips all the ^M (windows linefeeds) from the buffer"
 (interactive)
 (beginning-of-buffer)
 (while (re-search-forward "" nil t)
      (replace-match "" nil nil))
 (exchange-point-and-mark t)
(message "Stripped all ^M chars from buffer."))

(defun rs-refresh-file-in-buffer()
"reopens the file currently displayed in buffer.  Usefull when viewing a file that you want to checkout"
  (interactive)
  (find-file (buffer-file-name)))

(defun rs-open-mapi-header ()
  "Open the oft needed mapi header in another buffer.  Might be better to make an rs-open which looks
   thru a list of possible dirs for a file if it can't find it in the current dir."
  (interactive)
  (find-file-other-window  (format "%s\\SR_Automation_Libraries\\Libraries\\include\\tnetw_mapi.h" (getenv "RC_VIEW_PATH"))))


;
;; Comment a region without relying on any special modes
;(defun rs-set-line-comment-string (&optional comment-string)
;  if (comment-string
; (defalias 'rs-comment-line
;  (read-kbd-macro (format "%s <down> C-a" rs-line-comment-string)))

;
;; Changes a line like #define REG_NAME   REGISTER(0xffff0000)
;; into name assoc list structure entry {"REG_NAME", (0xfff0000)},
(defalias 'rs-reg-define-to-assoc-list-entry (read-kbd-macro
"ESC d C-d {\" C-s REGISTER RET 2*<C-left> <C-right> \", C-s REGISTER RET ESC <backspace> C-e }, C-a <down>"))

;
;; split the current buffer, open mapi in the top buffer, and 
;; bring the point back to the lower window.
(defalias 'rs-mapi-header-in-top-window
  (read-kbd-macro "C-x 2 C-x o ESC x rs- open- mapi- header RET C-x o"))

;
;;Key Redefines for a more refined environment
(define-key global-map [(control down)] 'find-tag)
(define-key global-map [(control up)] 'pop-tag-mark)
(global-set-key [(meta s)] 'switch-to-scratch)
(global-set-key [f5] 'rs-refresh-file-in-buffer)


(defun xemacs-p ()
  "is this xemacs?"
  (string-match "XEmacs" (emacs-version)))
(defun win32-p ()
  "are we on a Windows system?"
  (string-match "win32" (emacs-version)))