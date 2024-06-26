#lang racket/base
(require "env.rkt"
         "../common/module-path.rkt"
         "../syntax/module-binding.rkt"
         "../namespace/namespace.rkt"
         "../namespace/module.rkt"
         "../namespace/provided.rkt")

(provide binding-for-transformer?)

;; Determine whether `b`, which is the binding of `id` at `at-phase`,
;; refers to a variable or transformer binding; also, check taints
;; (for bindings other than for-label)
(define (binding-for-transformer? b id at-phase ns)
  (cond
   [(not at-phase)
    ;; The binding is either imported or a portal binding. If it's
    ;; imported, determine whether it's syntax by consulting the
    ;; exporting module. If we can't find the exporting module, assume
    ;; that it's a portal binding.
    (cond
      [(non-self-module-path-index? (module-binding-nominal-module b))
       (define m (namespace->module ns (module-path-index-resolve
                                        (module-binding-nominal-module b))))
       (define b/p (hash-ref (hash-ref (module-provides m) (module-binding-nominal-phase+space b) #hasheq())
                             (module-binding-nominal-sym b)
                             #f))
       (provided-as-transformer? b/p)]
      [else
       ;; self modix => portal binding
       #t])]
   [else
    ;; Use `binding-lookup` to both check for taints and determine whether the
    ;; binding is a transformer or variable binding
    (namespace-visit-available-modules! ns (+ at-phase (module-binding-phase b)))
    (define-values (val primitive? insp protected?)
      (binding-lookup b empty-env null ns at-phase id #:check-access? #f))
    (not (variable? val))]))
