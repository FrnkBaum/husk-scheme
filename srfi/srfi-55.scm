;;;; Reference implementation for SRFI-55
;;;; from http://srfi.schemers.org/srfi-55/srfi-55.html
;
; Requirements: SRFI-23 (error reporting)

(define available-extensions '())

(define (register-extension id action . compare)
  (set! available-extensions
    (cons (list (if (pair? compare) (car compare) equal?)
		id 
		action)
	  available-extensions)) )

(define (find-extension id)
  (define (lookup exts)
    (if (null? exts)
	  (write (list "extension not found - please contact your vendor " id))
	  (let ((ext (car exts)))
	    (if ((car ext) (cadr ext) id)
	        (caddr ext) ; Return a string instead of calling a function ((caddr ext))
	        (lookup (cdr exts)) ) ) ) )
  (lookup available-extensions) )

(define-syntax require-extension 
  (syntax-rules (srfi)
    ((_ "internal" (srfi id ...))
     (begin (find-extension '(srfi id) ...)) )
    ((_ "internal" id)
     (find-extension 'id) )
    ((_ clause ...)
     (begin (require-extension "internal" clause) ...)) ) )

; Example of registering extensions:
;
;   (register-extension '(srfi 1) (lambda () (load "/usr/local/lib/scheme/srfi-1.scm")))
(register-extension '(srfi 1) "srfi/srfi-1.scm") ; TESTING
(write "preparing...")
(write (string-append "found: " (find-extension 1)))
(write (string-append "found: " (find-extension '(srfi 1))))
(load (find-extension '(srfi 1)))
(write xcons)
;(require-extension (srfi 1))
;xcons ; should be defined now