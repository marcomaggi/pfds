;;; -*- coding: utf-8-unix -*-
;;;
;;;Part of: PFDS
;;;Contents: generic library tests
;;;Date: Sat Aug 10, 2013
;;;
;;;Abstract
;;;
;;;
;;;
;;;Copyright (C) 2013 Marco Maggi <marco.maggi-ipsu@poste.it>
;;;Copyright (C) 2011,2012 Ian Price <ianprice90@googlemail.com>
;;;
;;;Author: Ian Price <ianprice90@googlemail.com>
;;;
;;;This program is free software,  you can redistribute it and/or modify
;;;it under the terms of the new-style BSD license.
;;;
;;;You should  have received a copy  of the BSD license  along with this
;;;program.  If not, see <http://www.debian.org/misc/bsd.license>.
;;;


#!r6rs
(import (vicare)
  (pfds bbtrees)
  (vicare checks))

(check-set-mode! 'report-failed)
(check-display "*** testing PFDS: bbtree\n")


;;;; helpers

(define-syntax test-eqv
  (syntax-rules ()
    ((_ ?result ?body)
     (check ?body (=> eqv?) ?result))))

(define-syntax test-equal
  (syntax-rules ()
    ((_ ?result ?body)
     (check ?body => ?result))))

(define-syntax test-exn
  (syntax-rules ()
    ((_ ?predicate ?body)
     (check
	 (guard (E ((?predicate E)
		    #t)
		   (else #f))
	   ?body)
       => #t))))


(parametrise ((check-test-name	'core))

  (check
      (bbtree? (make-bbtree <))
    => #t)

  (check
      (bbtree-size (make-bbtree <))
    => 0)

;;; --------------------------------------------------------------------

  (check
      (let ((bb (alist->bbtree '(("foo" . 10)
				 ("bar" . 12))
			       string<?)))
	(bbtree-contains? bb "foo"))
    => #t)

  (check
      (let ((bb (alist->bbtree '(("foo" . 10)
				 ("bar" . 12))
			       string<?)))
	(bbtree-contains? bb "bar"))
    => #t)

  (check
      (let ((bb (alist->bbtree '(("foo" . 10)
				 ("bar" . 12))
			       string<?)))
	(bbtree-contains? bb "baz"))
    => #f)

;;; --------------------------------------------------------------------

  (test-eqv '() (bbtree->alist (make-bbtree <)))
  (test-eqv 0 (bbtree-size (alist->bbtree '() <)))
  (test-equal '(("bar" . 12) ("baz" . 7) ("foo" . 1))
	      (bbtree->alist (alist->bbtree '(("foo" . 1) ("bar" . 12) ("baz" . 7)) string<?)))
  (let ((l '(48 2 89 23 7 11 78))
	(tree-sort  (lambda (< l)
		      (map car
			(bbtree->alist
			 (alist->bbtree (map (lambda (x) (cons x 'dummy))
					  l)
					<))))))
    (test-equal (list-sort < l) (tree-sort < l)))

;;; --------------------------------------------------------------------

  (check
      (eq? < (bbtree-ordering-procedure (make-bbtree <)))
    => #t)

;;; --------------------------------------------------------------------

  (check
      (bbtree-keys (alist->bbtree '(("one" . 1) ("two" . 2))
				  string<?))
    => '("one" "two"))

  #t)


(parametrise ((check-test-name	'setters-getters))

  (let* ((tree1 (bbtree-set (make-bbtree <) 1 'a))
	 (tree2 (bbtree-set tree1 2 'b))
	 (tree3 (bbtree-set tree2 1 'c )))

    (check (bbtree-size tree1)		=> 1)

    (test-eqv 'a (bbtree-ref tree1 1))
    (test-eqv 2 (bbtree-size tree2))
    (test-eqv 'b (bbtree-ref tree2 2))
    (test-eqv 2 (bbtree-size tree3))
    (test-eqv 'c (bbtree-ref tree3 1))
    (test-eqv #f (bbtree-ref tree1 #xdeadbeef #f))
    (test-eqv 'not-in (bbtree-ref tree1 #xdeadbeef 'not-in))
    (test-exn assertion-violation? (bbtree-ref tree3 20))

    #f)

  (check
      (let* ((bb1 (alist->bbtree '(("one" . 1)) string<?))
	     (bb2 (bbtree-set bb1 "two" 2)))
	(bbtree->alist bb2))
    => '(("one" . 1) ("two" . 2)))

  #t)


(parametrise ((check-test-name	'update))

  (check
      (let* ((bb1   (alist->bbtree '(("foo" . 10)
				     ("bar" . 12))
				   string<?))
	     (dflt  0)
	     (bb2   (bbtree-update bb1 "foo" add1 dflt)))
	(bbtree->alist bb2))
    => '(("bar" . 12)
	 ("foo" . 11)))

  (check
      (let ((bb (alist->bbtree '(("foo" . 10)
  				 ("bar" . 12))
  			       string<?)))
  	(bbtree->alist (bbtree-update bb "bar" add1 0)))
    => '(("bar" . 13)
	 ("foo" . 10)))

  (check
      (let* ((bb1  (alist->bbtree '(("foo" . 10)
				    ("bar" . 12))
				  string<?))
	     (dflt 0)
	     (bb2  (bbtree-update bb1 "baz" add1 dflt)))
  	(bbtree->alist bb2))
    => '(("bar" . 12)
	 ("baz" . 1)
	 ("foo" . 10)))

  #t)


(parametrise ((check-test-name	'delete))

  (let* ((tree1 (bbtree-set (bbtree-set (bbtree-set (make-bbtree string<?) "a" 3)
					"b" 8)
			    "c" 19))
	 (tree2 (bbtree-delete tree1 "b"))
	 (tree3 (bbtree-delete tree2 "a")))
    (test-eqv 3 (bbtree-size tree1))
    (test-eqv #t (bbtree-contains? tree1 "b"))
    (test-eqv #t (bbtree-contains? tree1 "a"))
    (test-eqv 2 (bbtree-size tree2))
    (test-eqv #f (bbtree-contains? tree2 "b"))
    (test-eqv #t (bbtree-contains? tree2 "a"))
    (test-eqv 1 (bbtree-size tree3))
    (test-eqv #f (bbtree-contains? tree3 "a"))

    ;;No exception raised here.
    (check
	(bbtree? (bbtree-delete (bbtree-delete tree3 "a") "a"))
      => #t)

    #f)

  #t)


(parametrise ((check-test-name	'traversal))

  (check
      (let ((bb (alist->bbtree (map (lambda (x) (cons x x))
				 '(0 1 2 3 4 5 6 7 8 9))
			       <)))
	(define (left-first key value left right accum)
	  (right (left (cons key accum))))
	(bbtree-traverse left-first '() bb))
    => '(9 8 6 7 4 5 2 0 1 3))

  (check
      (let ((bb (alist->bbtree (map (lambda (x) (cons x x))
				 '(0 1 2 3 4 5 6 7 8 9))
			       <)))
	(define (right-first key value left right accum)
	  (left (right (cons key accum))))
	(bbtree-traverse right-first '() bb))
    => '(0 2 1 4 6 9 8 7 5 3))

;;; --------------------------------------------------------------------

  ;; empty bbtrees
  (test-eqv #t (bbtree-fold       (lambda args #f) #t (make-bbtree >)))
  (test-eqv #t (bbtree-fold-right (lambda args #f) #t (make-bbtree >)))

  (let ((bb (alist->bbtree '(("foo" . 1) ("bar" . 12) ("baz" . 7))
			   string<?)))
    ;; associative operations
    (test-eqv 20 (bbtree-fold (lambda (key value accum) (+ value accum)) 0 bb))
    (test-eqv 20 (bbtree-fold-right (lambda (key value accum) (+ value accum)) 0 bb))
    ;; non-associative operations
    (test-equal '("foo" "baz" "bar")
		(bbtree-fold (lambda (key value accum) (cons key accum)) '() bb))
    (test-equal '("bar" "baz" "foo")
		(bbtree-fold-right (lambda (key value accum) (cons key accum)) '() bb)))

  (check
      (let ((bb (alist->bbtree (map (lambda (x) (cons x x))
				 '(0 1 2 3 4 5 6 7 8 9))
			       <)))
	(bbtree-fold (lambda (key value accum)
		       (cons key accum))
		     '()
		     bb))
    => '(9 8 7 6 5 4 3 2 1 0))

  (check
      (let ((bb (alist->bbtree (map (lambda (x) (cons x x))
				 '(0 1 2 3 4 5 6 7 8 9))
			       <)))
	(bbtree-fold-right (lambda (key value accum)
			     (cons key accum))
			   '()
			   bb))
    => '(0 1 2 3 4 5 6 7 8 9))

;;; --------------------------------------------------------------------

  (let ((empty (make-bbtree <))
	(bb    (alist->bbtree '((#\a . foo) (#\b . bar) (#\c . baz) (#\d . quux))
			      char<?)))
    (test-eqv 0 (bbtree-size (bbtree-map (lambda (x) 'foo) empty)))
    (test-equal '((#\a foo . foo) (#\b bar . bar) (#\c baz . baz) (#\d quux . quux))
		(bbtree->alist (bbtree-map (lambda (x) (cons x x)) bb)))
    (test-equal '((#\a . "foo") (#\b . "bar") (#\c . "baz") (#\d . "quux"))
		(bbtree->alist (bbtree-map symbol->string bb))))

  #t)


#;(parametrise ((check-test-name	'set))



  (define-test-case bbtrees bbtree-union
    (let ([empty (make-bbtree char<?)]
	  [bbtree1 (alist->bbtree '((#\g . 103) (#\u . 117) (#\i . 105) (#\l . 108) (#\e . 101))
				  char<?)]
	  [bbtree2 (alist->bbtree '((#\l . 8) (#\i . 5) (#\s . 15) (#\p . 12))
				  char<?)])
      (test-case bbtree-union ()
		 (test-eqv 0 (bbtree-size (bbtree-union empty empty)))
		 (test-eqv (bbtree-size bbtree1)
			   (bbtree-size (bbtree-union empty bbtree1)))
		 (test-eqv (bbtree-size bbtree1)
			   (bbtree-size (bbtree-union bbtree1 empty)))
		 (test-eqv (bbtree-size bbtree1)
			   (bbtree-size (bbtree-union bbtree1 bbtree1)))
		 (test-equal '(#\e #\g #\i #\l #\p #\s #\u)
			     (bbtree-keys (bbtree-union bbtree1 bbtree2)))
		 ;; union favours values in first argument when key exists in both
		 (let ((union (bbtree-union bbtree1 bbtree2)))
		   (test-eqv 105 (bbtree-ref union #\i))
		   (test-eqv 108 (bbtree-ref union #\l)))
		 ;; check this holds on larger bbtrees
		 (let* ([l (string->list "abcdefghijlmnopqrstuvwxyz")]
			[b1 (map (lambda (x) (cons x (char->integer x))) l)]
			[b2 (map (lambda (x) (cons x #f)) l)])
		   (test-equal b1
			       (bbtree->alist (bbtree-union (alist->bbtree b1 char<?)
							    (alist->bbtree b2 char<?))))))))

  (define-test-case bbtrees bbtree-intersection
    (let ([empty (make-bbtree char<?)]
	  [bbtree1 (alist->bbtree '((#\g . 103) (#\u . 117) (#\i . 105) (#\l . 108) (#\e . 101))
				  char<?)]
	  [bbtree2 (alist->bbtree '((#\l . 8) (#\i . 5) (#\s . 15) (#\p . 12))
				  char<?)])
      (test-case bbtree-intersection ()
		 (test-eqv 0 (bbtree-size (bbtree-intersection empty empty)))
		 (test-eqv 0 (bbtree-size (bbtree-intersection bbtree1 empty)))
		 (test-eqv 0 (bbtree-size (bbtree-intersection empty bbtree1)))
		 (test-eqv (bbtree-size bbtree1)
			   (bbtree-size (bbtree-intersection bbtree1 bbtree1)))
		 ;; intersection favours values in first set
		 (test-equal '((#\i . 105) (#\l . 108))
			     (bbtree->alist (bbtree-intersection bbtree1 bbtree2)))
		 ;; check this holds on larger bbtrees
		 (let* ([l (string->list "abcdefghijlmnopqrstuvwxyz")]
			[b1 (map (lambda (x) (cons x (char->integer x))) l)]
			[b2 (map (lambda (x) (cons x #f)) l)])
		   (test-equal b1
			       (bbtree->alist (bbtree-intersection (alist->bbtree b1 char<?)
								   (alist->bbtree b2 char<?)))))
		 ;; definition of intersection is equivalent to two differences
		 (test-equal (bbtree->alist (bbtree-intersection bbtree1 bbtree2))
			     (bbtree->alist
			      (bbtree-difference bbtree1
						 (bbtree-difference bbtree1 bbtree2)))))))

  (define-test-case bbtrees bbtree-difference
    (let ([empty (make-bbtree char<?)]
	  [bbtree1 (alist->bbtree '((#\g . 103) (#\u . 117) (#\i . 105) (#\l . 108) (#\e . 101))
				  char<?)]
	  [bbtree2 (alist->bbtree '((#\l . 8) (#\i . 5) (#\s . 15) (#\p . 12))
				  char<?)])
      (test-case bbtree-difference ()
		 (test-eqv 0 (bbtree-size (bbtree-difference empty empty)))
		 (test-eqv 5 (bbtree-size (bbtree-difference bbtree1 empty)))
		 (test-eqv 0 (bbtree-size (bbtree-difference empty bbtree1)))
		 (test-eqv 0 (bbtree-size (bbtree-difference bbtree1 bbtree1)))
		 (test-equal '((#\e . 101) (#\g . 103) (#\u . 117))
			     (bbtree->alist (bbtree-difference bbtree1 bbtree2)))
		 (test-equal '((#\p . 12) (#\s . 15))
			     (bbtree->alist (bbtree-difference bbtree2 bbtree1))))))

  (define-test-case bbtrees bbtree-indexing
    (let* ([l (string->list "abcdefghijklmno")]
	   [bb (alist->bbtree (map (lambda (x) (cons x #f)) l) char<?)])
      "tnerfgxukscjmwhaod yz"
      (test-case bbtree-difference ()
		 (test-equal '(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14)
			     (map (lambda (x) (bbtree-index bb x)) l))
		 (test-exn assertion-violation? (bbtree-index bb #\z))
		 (test-equal l
			     (map (lambda (x)
				    (let-values ([(k v) (bbtree-ref/index bb x)])
				      k))
			       '(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14)))
		 (test-exn assertion-violation? (bbtree-ref/index bb -1))
		 (test-exn assertion-violation? (bbtree-ref/index bb 15)))))

  #t)


;;;; done

(check-report)

;;; end of file
