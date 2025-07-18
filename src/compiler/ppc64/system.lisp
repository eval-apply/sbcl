;;;; PPC VM definitions of various system hacking operations

;;;; This software is part of the SBCL system. See the README file for
;;;; more information.
;;;;
;;;; This software is derived from the CMU CL system, which was
;;;; written at Carnegie Mellon University and released into the
;;;; public domain. The software is in the public domain and is
;;;; provided with absolutely no warranty. See the COPYING and CREDITS
;;;; files for more information.

(in-package "SB-VM")

;;;; Type frobbing VOPs

(define-vop (descriptor-hash32)
  (:translate descriptor-hash32)
  (:args (arg :scs (any-reg descriptor-reg)))
  (:results (res :scs (any-reg)))
  (:result-types positive-fixnum)
  (:policy :fast-safe)
  (:generator 1
    (inst clrrdi res arg n-fixnum-tag-bits) ; clear rightmost 3 bits
    (inst rldicl res res 0 29))) ; clear left 29 = (- 64 32 n-fixnum-tag-bits)

(define-vop (widetag-of)
  (:translate widetag-of)
  (:policy :fast-safe)
  (:args (object :scs (descriptor-reg) :to (:eval 1)))
  (:results (result :scs (unsigned-reg) :from (:eval 0)))
  (:result-types positive-fixnum)
  (:generator 6
    ;; Grab the lowtag.
    (inst andi. result object lowtag-mask)
    ;; Check for various pointer types.
    (inst cmpwi result list-pointer-lowtag)
    (inst beq done)
    (inst cmpwi result other-pointer-lowtag)
    (inst beq other-pointer)
    (inst cmpwi result fun-pointer-lowtag)
    (inst beq function-pointer)
    (inst cmpwi result instance-pointer-lowtag)
    (inst beq done)
    ;; Okay, it is an immediate.  If fixnum, we want zero.  Otherwise,
    ;; we want the low 8 bits.
    (inst andi. result object fixnum-tag-mask)
    (inst beq done)
    ;; It wasn't a fixnum, so get the low 8 bits.
    (inst andi. result object widetag-mask)
    (inst b done)

    FUNCTION-POINTER
    (load-type result object (- fun-pointer-lowtag))
    (inst b done)

    OTHER-POINTER
    (load-type result object (- other-pointer-lowtag))

    DONE))

(define-vop (layout-depthoid)
  (:translate layout-depthoid)
  (:policy :fast-safe)
  (:args (object :scs (descriptor-reg)))
  (:results (res :scs (any-reg)))
  (:result-types fixnum)
  (:temporary (:scs (non-descriptor-reg)) temp)
  (:generator 1
    (inst lr temp (- (+ #+little-endian 4
                        (ash (+ instance-slots-offset
                                (get-dsd-index layout sb-kernel::flags))
                             word-shift))
                     instance-pointer-lowtag))
    (inst lwax res object temp)))

(define-vop ()
  (:translate sb-c::%structure-is-a)
  (:args (x :scs (descriptor-reg)))
  (:arg-types * (:constant t))
  (:policy :fast-safe)
  (:conditional)
  ;; "extra" info in conditional vops follows the 2 super-magical info args
  (:info target not-p test-layout)
  (:temporary (:scs (non-descriptor-reg)) this-id)
  (:generator 4
    (let ((test-id (layout-id test-layout))
          (offset (+ (id-bits-offset)
                     (ash (- (layout-depthoid test-layout) 2) 2)
                     (- instance-pointer-lowtag))))
      (inst lwa this-id x offset)
      ;; Always prefer 'cmpwi' if compiling to memory.
      ;; 8-bit IDs are permanently assigned, so no fixup ever needed for those.
      (cond ((or (typep test-id '(and (signed-byte 8) (not (eql 0))))
                 (and (not (sb-c::producing-fasl-file))
                      (typep test-id '(signed-byte 16))))
             (inst cmpwi this-id test-id))
            (t
             (inst lwa temp-reg-tn code-tn
                   (register-inline-constant `(:layout-id . ,test-layout) :word))
             (inst cmpw this-id temp-reg-tn))))
    (inst b? (if not-p :ne :eq) target)))

(define-vop (%other-pointer-widetag)
  (:translate %other-pointer-widetag)
  (:policy :fast-safe)
  (:args (object :scs (descriptor-reg)))
  (:results (result :scs (unsigned-reg)))
  (:result-types positive-fixnum)
  (:generator 6
    (load-type result object (- other-pointer-lowtag))))

(define-vop ()
  (:translate %fun-pointer-widetag)
  (:policy :fast-safe)
  (:args (function :scs (descriptor-reg)))
  (:results (result :scs (unsigned-reg)))
  (:result-types positive-fixnum)
  (:generator 6
    (load-type result function (- fun-pointer-lowtag))))

(define-vop (get-header-data)
  (:translate get-header-data)
  (:policy :fast-safe)
  (:args (x :scs (descriptor-reg)))
  (:results (res :scs (unsigned-reg)))
  (:result-types positive-fixnum)
  (:generator 6
    (loadw res x 0 other-pointer-lowtag)
    (inst srdi res res n-widetag-bits)))

(define-vop (set-header-data)
  (:translate set-header-data)
  (:policy :fast-safe)
  (:args (x :scs (descriptor-reg))
         (data :scs (any-reg)))
  (:arg-types * positive-fixnum)
  (:temporary (:scs (non-descriptor-reg)) t1 t2)
  (:generator 6
    (load-type t1 x (- other-pointer-lowtag))
    (inst sldi t2 data (- n-widetag-bits n-fixnum-tag-bits))
    (inst or t1 t1 t2)
    (storew t1 x 0 other-pointer-lowtag)))

(define-vop (%closure-fun)
  (:policy :fast-safe)
  (:translate %closure-fun)
  (:args (function :scs (descriptor-reg)))
  (:results (result :scs (descriptor-reg)))
  (:generator 3
    ;; Compute tagged pointer to simple-fun underlying this closure
    (loadw result function closure-fun-slot fun-pointer-lowtag)
    (inst subi result result (- (* simple-fun-insts-offset n-word-bytes) fun-pointer-lowtag))))

;;;; Allocation

(define-vop (binding-stack-pointer-sap)
  (:results (int :scs (sap-reg)))
  (:result-types system-area-pointer)
  (:translate binding-stack-pointer-sap)
  (:policy :fast-safe)
  (:generator 1
    (move int bsp-tn)))

(define-vop (control-stack-pointer-sap)
  (:results (int :scs (sap-reg)))
  (:result-types system-area-pointer)
  (:translate control-stack-pointer-sap)
  (:policy :fast-safe)
  (:generator 1
    (move int csp-tn)))


;;;; Code object frobbing.

(define-vop (code-instructions)
  (:translate code-instructions)
  (:policy :fast-safe)
  (:args (code :scs (descriptor-reg)))
  (:temporary (:scs (non-descriptor-reg)) ndescr)
  (:results (sap :scs (sap-reg)))
  (:result-types system-area-pointer)
  (:generator 10
    (inst lwz ndescr code
          (- (+ (ash code-boxed-size-slot word-shift) #+big-endian 4)
             other-pointer-lowtag))
    (inst subi ndescr ndescr other-pointer-lowtag)
    (inst add sap code ndescr)))

(define-vop (compute-fun)
  (:args (code :scs (descriptor-reg))
         (offset :scs (signed-reg unsigned-reg)))
  (:arg-types * positive-fixnum)
  (:results (func :scs (descriptor-reg)))
  (:temporary (:scs (non-descriptor-reg)) ndescr)
  (:generator 10
    (inst lwz ndescr code
          (- (+ (ash code-boxed-size-slot word-shift) #+big-endian 4)
             other-pointer-lowtag))
    (inst add ndescr ndescr offset)
    (inst addi ndescr ndescr (- fun-pointer-lowtag other-pointer-lowtag))
    (inst add func code ndescr)))



;;;; Other random VOPs.


(defknown sb-unix::receive-pending-interrupt () (values))
(define-vop (sb-unix::receive-pending-interrupt)
  (:policy :fast-safe)
  (:translate sb-unix::receive-pending-interrupt)
  (:generator 1
    (inst unimp pending-interrupt-trap)))

(define-vop (current-thread-offset-sap)
  (:results (sap :scs (sap-reg)))
  (:result-types system-area-pointer)
  (:translate current-thread-offset-sap)
  (:args (n :scs (signed-reg) :target sap))
  (:arg-types signed-num)
  (:policy :fast-safe)
  (:generator 2
    (inst sldi n n word-shift)
    (inst ldx sap thread-base-tn n)))

(define-vop (halt)
  (:generator 1
    (inst unimp halt-trap)))

;;;; Dynamic vop count collection support

(define-vop (count-me)
  (:args (count-vector :scs (descriptor-reg)))
  (:info index)
  (:temporary (:scs (non-descriptor-reg)) count)
  (:generator 1
    (let ((offset
           (- (* (+ index vector-data-offset) n-word-bytes) other-pointer-lowtag)))
      (aver (typep offset '(signed-byte 16)))
      (inst lwz count count-vector offset)
      (inst addi count count 1)
      (inst stw count count-vector offset))))

;;;; Memory barrier support

(define-vop (%compiler-barrier)
  (:policy :fast-safe)
  (:translate %compiler-barrier)
  (:generator 3))

(define-vop (%memory-barrier)
  (:policy :fast-safe)
  (:translate %memory-barrier)
  (:generator 3
     (inst sync)))

(define-vop (%read-barrier)
  (:policy :fast-safe)
  (:translate %read-barrier)
  (:generator 3
     (inst sync)))

(define-vop (%write-barrier)
  (:policy :fast-safe)
  (:translate %write-barrier)
  (:generator 3
    (inst sync)))

(define-vop (%data-dependency-barrier)
  (:policy :fast-safe)
  (:translate %data-dependency-barrier)
  (:generator 3))

;;;; Dummy definition for a spin-loop hint VOP
(define-vop ()
  (:translate spin-loop-hint)
  (:policy :fast-safe)
  (:generator 0))

(define-vop (sb-c::mark-covered)
 (:info index)
 (:temporary (:sc unsigned-reg) tmp)
 (:generator 4
   ;; Can't convert index to a code-relative index until the boxed header length
   ;; has been determined.
   (inst store-coverage-mark index tmp)))
