#!r6rs
;; Copyright (C) 2011 Ian Price <ianprice90@googlemail.com>

;; Author: Ian Price <ianprice90@googlemail.com>

;; This program is free software, you can redistribute it and/or
;; modify it under the terms of the new-style BSD license.

;; You should have received a copy of the BSD license along with this
;; program. If not, see <http://www.debian.org/misc/bsd.license>.

;;; Code:
(import (rnrs)
        (pfds queues)
        (pfds deques)
        (wak trc-testing))

(define (foldl kons knil list)
  (if (null? list)
      knil
      (foldl kons (kons (car list) knil) (cdr list))))

(define-test-suite pfds
  "Test suite for libraries under the (pfds) namespace")

(define-test-suite (queues pfds)
  "Tests for the functional queue implementation")

(define-test-case queues empty-queue ()
  (test-predicate queue? (make-queue))
  (test-predicate queue-empty? (make-queue))
  (test-eqv 0 (queue-length (make-queue))))

(define-test-case queues enqueue ()
  (let ((queue (enqueue (make-queue) 'foo)))
    (test-predicate queue? queue)
    (test-eqv #t (not (queue-empty? queue)))
    (test-eqv 1 (queue-length queue))
    (test-eqv 10 (queue-length
                  (foldl (lambda (val queue)
                           (enqueue queue val))
                         (make-queue)
                         '(0 1 2 3 4 5 6 7 8 9))))))

(define-test-case queues dequeue ()
  (let ((empty (make-queue))
        (queue1 (enqueue (make-queue) 'foo))
        (queue2 (enqueue (enqueue (make-queue) 'foo) 'bar)))
    (let-values (((item queue) (dequeue queue1)))
      (test-eqv 'foo item)
      (test-predicate queue? queue)
      (test-predicate queue-empty? queue))
    (let*-values (((first queue*) (dequeue queue2))
                  ((second queue) (dequeue queue*)))
                 (test-eqv 'foo first)
                 (test-eqv 'bar second)
                 (test-eqv 1 (queue-length queue*))
                 (test-eqv 0 (queue-length queue)))
    (test-eqv #t
              (guard (exn ((queue-empty-condition? exn) #t)
                          (else #f))
                (dequeue empty)
                #f))))


(define-test-case queues queue-ordering ()
  (let* ((list '(bar quux foo zot baz))
         (queue (foldl (lambda (val queue)
                          (enqueue queue val))
                        (make-queue)
                        list)))
    (test-eqv 5 (queue-length queue))
    (let loop ((queue queue) (list list))
      (unless (null? list)
        (let-values (((item queue) (dequeue queue)))
          (test-eqv (car list) item)
          (loop queue (cdr list)))))))


(define-test-suite (deques pfds)
  "Tests for the functional deque implementation")

(define-test-case deques empty-deque ()
  (test-predicate deque? (make-deque))
  (test-predicate deque-empty? (make-deque))
  (test-eqv 0 (deque-length (make-deque))))

(define-test-case deques deque-insert ()
  (let ((deq (insert-front (make-deque) 'foo)))
    (test-predicate deque? deq)
    (test-eqv 1 (deque-length deq)))
  (let ((deq (insert-rear (make-deque) 'foo)))
    (test-predicate deque? deq)
    (test-eqv 1 (deque-length deq)))
  (test-eqv 5 (deque-length
               (foldl (lambda (pair deque)
                        ((car pair) deque (cdr pair)))
                      (make-deque)
                      `((,insert-front . 0)
                        (,insert-rear  . 1)
                        (,insert-front . 2)
                        (,insert-rear  . 3)
                        (,insert-front . 4))))))

(define-test-case deques deque-remove ()
  (let ((deq (insert-front (make-deque) 'foo)))
    (let-values (((item0 deque0) (remove-front deq))
                 ((item1 deque1) (remove-rear deq)))
      (test-eqv 'foo item0)
      (test-eqv 'foo item1)
      (test-predicate deque-empty? deque0)
      (test-predicate deque-empty? deque1)))
  (let ((deq (foldl (lambda (item deque)
                      (insert-rear deque item))
                    (make-deque)
                    '(0 1 2 3 4 5))))
    (let*-values (((item0 deque0) (remove-front deq))
                  ((item1 deque1) (remove-front deque0))
                  ((item2 deque2) (remove-front deque1)))
      (test-eqv 0 item0)
      (test-eqv 1 item1)
      (test-eqv 2 item2)
      (test-eqv 3 (deque-length deque2))))
  (let ((deq (foldl (lambda (item deque)
                      (insert-rear deque item))
                    (make-deque)
                    '(0 1 2 3 4 5))))
    (let*-values (((item0 deque0) (remove-rear deq))
                  ((item1 deque1) (remove-rear deque0))
                  ((item2 deque2) (remove-rear deque1)))
      (test-eqv 5 item0)
      (test-eqv 4 item1)
      (test-eqv 3 item2)
      (test-eqv 3 (deque-length deque2))))
  (let ((empty (make-deque)))
    (test-eqv #t
              (guard (exn ((deque-empty-condition? exn) #t)
                          (else #f))
                (remove-front empty)
                #f))
    (test-eqv #t
              (guard (exn ((deque-empty-condition? exn) #t)
                          (else #f))
                (remove-rear empty)
                #f))))


(define-test-case deques mixed-operations ()
  (let ((deque (foldl (lambda (pair deque)
                        ((car pair) deque (cdr pair)))
                      (make-deque)
                      `((,insert-front . 0)
                        (,insert-rear  . 1)
                        (,insert-front . 2)
                        (,insert-rear  . 3)
                        (,insert-front . 4)))))
    (let*-values (((item0 deque) (remove-front deque))
                  ((item1 deque) (remove-front deque))
                  ((item2 deque) (remove-front deque))
                  ((item3 deque) (remove-front deque))
                  ((item4 deque) (remove-front deque)))
      (test-eqv 4 item0)
      (test-eqv 2 item1)
      (test-eqv 0 item2)
      (test-eqv 1 item3)
      (test-eqv 3 item4)))
  (let ((deq (foldl (lambda (item deque)
                      (insert-rear deque item))
                    (make-deque)
                    '(0 1 2))))
    (let*-values (((item0 deque0) (remove-rear deq))
                  ((item1 deque1) (remove-front deque0))
                  ((item2 deque2) (remove-rear deque1)))
      (test-eqv 2 item0)
      (test-eqv 0 item1)
      (test-eqv 1 item2)
      (test-predicate deque-empty? deque2))))


(run-test pfds)