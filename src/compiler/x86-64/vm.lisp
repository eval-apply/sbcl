;;;; miscellaneous VM definition noise for the x86-64

;;;; This software is part of the SBCL system. See the README file for
;;;; more information.
;;;;
;;;; This software is derived from the CMU CL system, which was
;;;; written at Carnegie Mellon University and released into the
;;;; public domain. The software is in the public domain and is
;;;; provided with absolutely no warranty. See the COPYING and CREDITS
;;;; files for more information.

(in-package "SB-VM")

;;;; register specs

;;; Observe that [R12 + displacement] needs an extra byte of encoding in
;;; certain addressing modes, as does [R13 + index]
;;;     49895B08         MOV [R11+8], RBX
;;;     49895C2408       MOV [R12+8], RBX
;;;     49895D08         MOV [R13+8], RBX
;;;     49891C03         MOV [R11+RAX], RBX
;;;     49891C04         MOV [R12+RAX], RBX
;;;     49895C0500       MOV [R13+RAX], RBX
;;; This is because 12 and 13 are equal-mod-8 to 4 and 5, the indices of RSP
;;; and RBP respectively, which have different behaviors in the ModRegR/M byte.
;;; So due to lack of perfectly orthogonal encodings, it would be slightly
;;; beneficial to hint to the register allocator that it should pick registers
;;; 12 and 13 only when all other registers are unavailable.
;;; And you might think that it should "work" simply to list the usable offsets
;;; in the SC in the order in which they should be chosen when the register
;;; allocator needs to pick the next available register, but unfortunately
;;; it does not work to do that, because it uses bitmaps from which to pick,
;;; and not an ordered list.

;;; A register that's never used by the code generator, and can therefore
;;; be used as an assembly temporary in cases where a VOP :TEMPORARY can't
;;; be used.
;;; This is only enabled for certain build configurations that need
;;; a scratch register in various random places.
#-ubsan (defconstant global-temp-reg nil)
#+ubsan (progn (define-symbol-macro temp-reg-tn r11-tn)
               (defconstant global-temp-reg 11))

#+gs-seg
(progn
  ;; There is no permanent THREAD-TN. There are a few problems in trying
  ;; cleverly to make PSEUDO-ATOMIC agnostic of whether you're using a global
  ;; THREAD-TN or a local one (a global symbol macro vs. a let binding)
  ;; 1) ECL seems to think that it is an error to LET bind a global symbol macro.
  ;;    > (define-symbol-macro thread-tn 'wat)
  ;;    > (defun f (&optional (thread-tn thread-tn)) (format t "Hi: ~a~%" thread-tn))
  ;;    > (compile'f)
  ;;    ;;; Error:
  ;;    ;;;   * The constant THREAD-TN is being bound.
  ;; 2) It actually doesn't completely work completely anyway,
  ;;    because pseudo-atomic needs to know not to use a segment override,
  ;;    and TNs don't indicate a memory segment.
  ;; While the second problem could be solved, the first can't,
  ;; and it's not clear to me whether ECL is wrong to say it's an error,
  ;; or SBCL is remiss in choosing not to style-warn (which would annoy me
  ;; for that reason).
  ;; So we wire the thread structure to r15 within some vops when convenient.
  ;; Wiring to r15 is not strictly necessary, but I want to see if sb-aprof
  ;; can be made to work slightly easier regardless of #+gs-seg.
  ;; And with 15 being the highest register number, it is the least likely
  ;; to be picked by the register allocator for anything else.
  ;; Additionally I'd like to have an optimization pass that avoids reloading
  ;; r15 when consecutive allocation sequences occur in straight-line code.
  (define-symbol-macro thread-segment-reg :gs)
  (define-symbol-macro thread-reg nil))
#-gs-seg
(progn
  (define-symbol-macro thread-segment-reg :cs)
  ;; r13 is preferable to r12 because 12 is an alias of 4 in ModRegRM, which
  ;; implies use of a SIB byte with no index register for fixed displacement.
  (define-symbol-macro thread-reg 13)
  (define-symbol-macro thread-tn r13-tn))

;;; Kludge needed for decoding internal error args - we assume that the
;;; shadow memory is pointed to by this register (RAX).
(defconstant msan-temp-reg-number 0)

(export 'card-table-reg)
(defconstant card-table-reg 12)
(define-symbol-macro null-tn r12-tn)
(define-symbol-macro card-index-mask (make-fixup nil :card-table-index-mask))

(defconstant most-positive-fixnum-repr
  #+sb-xc #.most-positive-fixnum-repr ; or else error "SB-KERNEL:%MASK-FIELD is undefined"
  #-sb-xc (mask-field (byte 62 1) -1))

(defconstant non-negative-fixnum-mask
  (ldb (byte 64 0) (lognot most-positive-fixnum-repr)))

(defconstant-eqx +popular-raw-constants+
    `#(;; disallowed bits to match INDEX type
       ,(ldb (byte 64 0) (lognot (ash (1- sb-xc:array-dimension-limit) n-fixnum-tag-bits)))
       #x1FFFFFFFE         ; most-positive uint32_t as a fixnum
       ,most-positive-fixnum-repr
       #xFFFFFFFF00000000  ; (MASK-FIELD (BYTE 32 32) -1)
       ,non-negative-fixnum-mask
       #x100000000         ; (ASH 1 32)
       #x3243F6A88858B087  ; for SB-INT:MIX
       #x10E6D7AF34A204E2  ; "
       ,(ash 1 63))        ; bits of MOST-NEGATIVE-FIXNUM
  #'equalp)

(eval-when (:compile-toplevel)
  ;; Proper alignment of NIL depends on there being an odd number of global raw constants
  ;; and an even number of words to static-space-end
  (assert (oddp (length +popular-raw-constants+)))
  (unless (evenp n-static-trailer-constants) (error "Please check alignment of NIL"))
  #-sb-safepoint
  (unless (<= nil-cardtable-disp 127) ; > 1-byte disp to reach card table is undesirable
    (error "Consider reducing the number of elements in static-space-trailer")))

(defconstant t-nil-offset ; (- NULL-TN THIS) = tagged pointer to T
  (+ (- list-pointer-lowtag other-pointer-lowtag)
     (pad-data-block symbol-size) ; size of T in bytes
     (* (length +popular-raw-constants+) 8)
     8)) ; additive fuzz factor
(eval-when (:compile-toplevel :execute)
  (unless (typep (- t-nil-offset) '(signed-byte 8))
    (error "Too many raw constants for (&T - &NIL) to be imm8")))

(macrolet ((defreg (name offset size)
             (declare (ignore size))
             `(defconstant ,(symbolicate name "-OFFSET") ,offset))
           ;; Define general-purpose regs in a more concise way, as we seem
           ;; to (redundantly) want each register's offset for dword and qword
           ;; even though the value of the constant is the same.
           ;; We don't need constants for the byte- or word-sized offsets.
           (define-gprs (want-offsets offsets-list names array)
             `(progn
                (defconstant-eqx ,names ,array #'equalp)
                (progn
                  ,@(when want-offsets
                      (let ((i -1))
                        (map 'list
                             (lambda (x)
                               `(defconstant ,(symbolicate x "-OFFSET") ,(incf i)))
                             array))))
                (defglobal ,offsets-list
                    (remove-if (lambda (x)
                                 (member x `(,global-temp-reg ; if there is one
                                             ,thread-reg      ; if using a GPR
                                             ,card-table-reg
                                             ,rsp-offset
                                             ,rbp-offset)))
                               (loop for i below 16 collect i))))))

  (define-gprs t *qword-regs* +qword-register-names+
    #("RAX" "RCX" "RDX" "RBX" "RSP" "RBP" "RSI" "RDI"
      "R8"  "R9"  "R10" "R11" "R12" "R13" "R14" "R15"))
  (define-gprs nil *dword-regs* +dword-register-names+
    #("EAX" "ECX" "EDX"  "EBX"  "ESP"  "EBP"  "ESI"  "EDI"
      "R8D" "R9D" "R10D" "R11D" "R12D" "R13D" "R14D" "R15D"))
  (define-gprs nil *word-regs* +word-register-names+
    #("AX"  "CX"  "DX"   "BX"   "SP"   "BP"   "SI"   "DI"
      "R8W" "R9W" "R10W" "R11W" "R12W" "R13W" "R14W" "R15W"))
  ;; High-byte ("h") registers are not generally used on AMD64,
  ;; since they can't be encoded in an instruction that has a REX-prefix,
  ;; but we can sometimes use them.
  (define-gprs nil *byte-regs* +byte-register-names+
    #("AL"  "CL"  "DL"   "BL"   "SPL"  "BPL"  "SIL"  "DIL"
      "R8B" "R9B" "R10B" "R11B" "R12B" "R13B" "R14B" "R15B"
      "AH" "CH" "DH" "BH"))

  ;; floating point registers
  (defreg float0 0 :float)
  (defreg float1 1 :float)
  (defreg float2 2 :float)
  (defreg float3 3 :float)
  (defreg float4 4 :float)
  (defreg float5 5 :float)
  (defreg float6 6 :float)
  (defreg float7 7 :float)
  (defreg float8 8 :float)
  (defreg float9 9 :float)
  (defreg float10 10 :float)
  (defreg float11 11 :float)
  (defreg float12 12 :float)
  (defreg float13 13 :float)
  (defreg float14 14 :float)
  (defreg float15 15 :float)
  (defregset *float-regs* float0 float1 float2 float3 float4 float5 float6 float7
             float8 float9 float10 float11 float12 float13 float14 float15)

  ;; registers used to pass arguments
  ;;
  ;; the number of arguments/return values passed in registers
  (defconstant  register-arg-count 3)
  ;; names and offsets for registers used to pass arguments
  (defconstant-eqx register-arg-names '(rdx rdi rsi) #'equal)
  (defregset    *register-arg-offsets* rdx rdi rsi)
  #-win32
  (defregset    *c-call-register-arg-offsets* rdi rsi rdx rcx r8 r9)
  #+win32
  (defregset    *c-call-register-arg-offsets* rcx rdx r8 r9)
  (defregset *descriptor-args* rdx rdi rsi rbx rcx r8 r9 r10 r14))

;;;; SB definitions

(!define-storage-bases
(define-storage-base registers :finite :size 16)

(define-storage-base float-registers :finite :size 16)

;;; Start from 2, for the old RBP (aka OCFP) and return address
(define-storage-base stack :unbounded :size 2 :size-increment 1)
(define-storage-base constant :non-packed)
(define-storage-base immediate-constant :non-packed))

;;;; SC definitions

(eval-when (:compile-toplevel :execute)
(defparameter *storage-class-defs* '(
  ;; non-immediate constants in the constant pool
  (constant constant)

  (fp-single-zero immediate-constant)
  (fp-double-zero immediate-constant)
  (fp-complex-single-zero immediate-constant)
  (fp-complex-double-zero immediate-constant)

  (fp-single-immediate immediate-constant)
  (fp-double-immediate immediate-constant)
  (fp-complex-single-immediate immediate-constant)
  (fp-complex-double-immediate immediate-constant)

  #+sb-simd-pack (int-sse-immediate immediate-constant)
  #+sb-simd-pack (double-sse-immediate immediate-constant)
  #+sb-simd-pack (single-sse-immediate immediate-constant)
  #+sb-simd-pack-256 (int-avx2-immediate immediate-constant)
  #+sb-simd-pack-256 (double-avx2-immediate immediate-constant)
  #+sb-simd-pack-256 (single-avx2-immediate immediate-constant)
  (immediate immediate-constant)

  ;;
  ;; the stacks
  ;;

  ;; the control stack
  (control-stack stack)                 ; may be pointers, scanned by GC

  ;; the non-descriptor stacks
  (signed-stack stack)                  ; (signed-byte 64)
  (unsigned-stack stack)                ; (unsigned-byte 64)
  (character-stack stack)               ; non-descriptor characters.
  (sap-stack stack)                     ; System area pointers.
  (single-stack stack)                  ; single-floats
  (double-stack stack)
  (complex-single-stack stack)  ; complex-single-floats
  (complex-double-stack stack :element-size 2)  ; complex-double-floats
  #+sb-simd-pack
  (int-sse-stack stack :element-size 2)
  #+sb-simd-pack
  (double-sse-stack stack :element-size 2)
  #+sb-simd-pack
  (single-sse-stack stack :element-size 2)
  #+sb-simd-pack-256
  (int-avx2-stack stack :element-size 4)
  #+sb-simd-pack-256
  (double-avx2-stack stack :element-size 4)
  #+sb-simd-pack-256
  (single-avx2-stack stack :element-size 4)

  ;;
  ;; things that can go in the integer registers
  ;;

  ;; On the X86, we don't have to distinguish between descriptor and
  ;; non-descriptor registers, because of the conservative GC.
  ;; Therefore, we use different scs only to distinguish between
  ;; descriptor and non-descriptor values and to specify size.

  ;; immediate descriptor objects. Don't have to be seen by GC, but nothing
  ;; bad will happen if they are. (fixnums, characters, header values, etc).
  (any-reg registers
           :locations #.*qword-regs*
           :constant-scs (immediate)
           :save-p t
           :alternate-scs (control-stack))

  ;; pointer descriptor objects -- must be seen by GC
  (descriptor-reg registers
                  :locations #.*qword-regs*
                  :constant-scs (constant immediate)
                  :save-p t
                  :alternate-scs (control-stack))

  ;; non-descriptor characters
  (character-reg registers
                 :locations #.*qword-regs*
                 :constant-scs (immediate)
                 :save-p t
                 :alternate-scs (character-stack))

  ;; non-descriptor SAPs (arbitrary pointers into address space)
  (sap-reg registers
           :locations #.*qword-regs*
           :constant-scs (immediate)
           :save-p t
           :alternate-scs (sap-stack))

  ;; non-descriptor (signed or unsigned) numbers
  (signed-reg registers
              :locations #.*qword-regs*
              :constant-scs (immediate)
              :save-p t
              :alternate-scs (signed-stack))
  (unsigned-reg registers
                :locations #.*qword-regs*
                :constant-scs (immediate)
                :save-p t
                :alternate-scs (unsigned-stack))

  ;; non-descriptor SINGLE-FLOATs
  (single-reg float-registers
              :locations #.*float-regs*
              :constant-scs (fp-single-zero fp-single-immediate)
              :save-p t
              :alternate-scs (single-stack))

  ;; non-descriptor DOUBLE-FLOATs
  (double-reg float-registers
              :locations #.*float-regs*
              :constant-scs (fp-double-zero fp-double-immediate)
              :save-p t
              :alternate-scs (double-stack))

  (complex-single-reg float-registers
                      :locations #.*float-regs*
                      :constant-scs (fp-complex-single-zero fp-complex-single-immediate)
                      :save-p t
                      :alternate-scs (complex-single-stack))

  (complex-double-reg float-registers
                      :locations #.*float-regs*
                      :constant-scs (fp-complex-double-zero fp-complex-double-immediate)
                      :save-p t
                      :alternate-scs (complex-double-stack))

  ;; temporary only
  #+sb-simd-pack
  (sse-reg float-registers
           :locations #.*float-regs*)
  ;; regular values
  #+sb-simd-pack
  (int-sse-reg float-registers
               :locations #.*float-regs*
               :constant-scs (int-sse-immediate)
               :save-p t
               :alternate-scs (int-sse-stack))
  #+sb-simd-pack
  (double-sse-reg float-registers
                  :locations #.*float-regs*
                  :constant-scs (double-sse-immediate)
                  :save-p t
                  :alternate-scs (double-sse-stack))
  #+sb-simd-pack
  (single-sse-reg float-registers
                  :locations #.*float-regs*
                  :constant-scs (single-sse-immediate)
                  :save-p t
                  :alternate-scs (single-sse-stack))
  (ymm-reg float-registers :locations #.*float-regs*)
  ;; These next 3 should probably be named to YMM-{INT,SINGLE,DOUBLE}-REG
  ;; but I think there are 3rd-party libraries that expect these names.
  #+sb-simd-pack-256
  (int-avx2-reg float-registers
               :locations #.*float-regs*
               :constant-scs (int-avx2-immediate)
               :save-p t
               :alternate-scs (int-avx2-stack))
  #+sb-simd-pack-256
  (double-avx2-reg float-registers
                  :locations #.*float-regs*
                  :constant-scs (double-avx2-immediate)
                  :save-p t
                  :alternate-scs (double-avx2-stack))
  #+sb-simd-pack-256
  (single-avx2-reg float-registers
                  :locations #.*float-regs*
                  :constant-scs (single-avx2-immediate)
                  :save-p t
                  :alternate-scs (single-avx2-stack))

  (catch-block stack :element-size catch-block-size)
  (unwind-block stack :element-size unwind-block-size)))

(defparameter *qword-sc-names*
  '(any-reg descriptor-reg sap-reg signed-reg unsigned-reg control-stack
    signed-stack unsigned-stack sap-stack single-stack
    character-reg character-stack constant))
;;; added by jrd. I guess the right thing to do is to treat floats
;;; as a separate size...
;;;
;;; These are used to (at least) determine operand size.
(defparameter *float-sc-names* '(single-reg))
(defparameter *double-sc-names* '(double-reg double-stack))
(defparameter *complex-sc-names* '(complex-single-reg complex-single-stack
                                   complex-double-reg complex-double-stack))
#+sb-simd-pack
(defparameter *oword-sc-names* '(sse-reg int-sse-reg single-sse-reg double-sse-reg
                                 int-sse-stack single-sse-stack double-sse-stack))
#+sb-simd-pack-256
(defparameter *hword-sc-names* '(ymm-reg int-avx2-reg single-avx2-reg double-avx2-reg
                                   int-avx2-stack single-avx2-stack double-avx2-stack))
) ; EVAL-WHEN
(!define-storage-classes
  . #.(mapcar (lambda (class-spec)
                (let ((size
                        (case (car class-spec)
                          #+sb-simd-pack
                          (#.*oword-sc-names*   :oword)
                          #+sb-simd-pack-256
                          (#.*hword-sc-names*   :hword)
                          (#.*qword-sc-names*   :qword)
                          (#.*float-sc-names*   :float)
                          (#.*double-sc-names*  :double)
                          (#.*complex-sc-names* :complex))))
                  (append class-spec (if size (list :operand-size size)))))
              *storage-class-defs*))

;;;; miscellaneous TNs for the various registers

(macrolet ((def-gpr-tns (sc-name name-array &aux (i -1))
             `(progn
                ,@(map 'list
                       (lambda (reg-name)
                         `(define-load-time-global ,(symbolicate reg-name "-TN")
                              (make-random-tn (sc-or-lose ',sc-name) ,(incf i))))
                       (symbol-value name-array))))
           (def-fpr-tns (sc-name &rest reg-names)
             (collect ((forms))
               (dolist (reg-name reg-names `(progn ,@(forms)))
                 (let ((tn-name (symbolicate reg-name "-TN"))
                       (offset-name (symbolicate reg-name "-OFFSET")))
                   (forms `(define-load-time-global ,tn-name
                               (make-random-tn (sc-or-lose ',sc-name) ,offset-name))))))))
  (def-gpr-tns unsigned-reg +qword-register-names+)
  ;; RIP is not an addressable register, but this global var acts as
  ;; a moniker for it in an effective address so that the EA structure
  ;; does not need to accept a symbol (such as :RIP) for the base reg.
  ;; Because there is no :OFFSET, unanticipated use will be caught.
  (define-load-time-global rip-tn
      (make-random-tn (sc-or-lose 'unsigned-reg) nil))
  (def-fpr-tns single-reg
      float0 float1 float2 float3 float4 float5 float6 float7
      float8 float9 float10 float11 float12 float13 float14 float15))

;;; Return true if THING is a general-purpose register TN.
(defun gpr-tn-p (thing)
  (and (tn-p thing)
       (eq (sb-name (sc-sb (tn-sc thing))) 'registers)))
;;; Return true if THING is an XMM register TN.
(defun xmm-tn-p (thing)
  (and (tn-p thing)
       (eq (sb-name (sc-sb (tn-sc thing))) 'float-registers)))
;;; Return true if THING is on the stack (in whatever storage class).
(defun stack-tn-p (thing)
  (and (tn-p thing)
       (eq (sb-name (sc-sb (tn-sc thing))) 'stack)))

;;; TNs for registers used to pass arguments
;;; This can't be a DEFCONSTANT-EQX, for a similar reason to above, but worse.
;;; Among the problems, RECEIVE-UNKNOWN-VALUES uses (FIRST *REGISTER-ARG-TNS*)
;;; and so the compiler knows that the object is constant and wants to dump it
;;; as such; it has no name, so it's not even reasonable to expect it to
;;; use the corresponding object in RDX-TN.
(define-load-time-global *register-arg-tns*
  (mapcar (lambda (register-arg-name)
            (symbol-value (symbolicate register-arg-name "-TN")))
          register-arg-names))

;;; If value can be represented as an immediate constant, then return
;;; the appropriate SC number, otherwise return NIL.
(defun immediate-constant-sc (value)
  (declare (notinline sb-c::producing-fasl-file))
  (typecase value
    ((or (integer #.most-negative-fixnum #.most-positive-fixnum)
         character)
     immediate-sc-number)
    (symbol ; Symbols in static and immobile space are immediate
     (when (or (static-symbol-p value)
               ;; The cross-compiler always uses immobile-space if it exists.
               #+(and immobile-space sb-xc-host) t
               ;; With either of these two features, all interned symbols are
               ;; as-if static
               #+(or permgen immobile-symbols) (sb-xc:symbol-package value)
               #-sb-xc-host
               (if (immobile-space-obj-p value)
                   (or (= (generation-of value) +pseudo-static-generation+)
                       ;; If compiling to memory, the symbol's address alone suffices.
                       (not (sb-c::producing-fasl-file)))))
       immediate-sc-number))
    #+compact-instance-header (layout immediate-sc-number)
    (single-float
       (if (eql value 0f0) fp-single-zero-sc-number fp-single-immediate-sc-number))
    (double-float
       (if (eql value 0d0) fp-double-zero-sc-number fp-double-immediate-sc-number))
    ((complex single-float)
       (if (eql value #c(0f0 0f0))
            fp-complex-single-zero-sc-number
            fp-complex-single-immediate-sc-number))
    ((complex double-float)
       (if (eql value #c(0d0 0d0))
            fp-complex-double-zero-sc-number
            fp-complex-double-immediate-sc-number))
    ;; This case has to follow the numeric cases because proxy floating-point numbers
    ;; are host structs. Or we could implement and use something like SB-XC:TYPECASE
    (structure-object
     (when (eq value sb-lockless:+tail+)
       immediate-sc-number))
    ((simple-string 0) ; Reference static empty string only when compiling to file
     ;; or, if compiling to memory, the string is EQ to a baked-in static string,
     ;; otherwise CLHS 3.2.4 is potentially violated
     (when (or (sb-c::producing-fasl-file)
               #-sb-xc-host (and (eq (heap-allocated-p value) :static)
                                 (< (get-lisp-obj-address value)
                                    (get-lisp-obj-address sb-lockless:+tail+))))
       immediate-sc-number))
    #+(and sb-simd-pack (not sb-xc-host))
    (simd-pack
     (typecase value
       ((simd-pack double-float) double-sse-immediate-sc-number)
       ((simd-pack single-float) single-sse-immediate-sc-number)
       (t int-sse-immediate-sc-number)))
    #+(and sb-simd-pack-256 (not sb-xc-host))
    (simd-pack-256
     (typecase value
       ((simd-pack-256 double-float) double-avx2-immediate-sc-number)
       ((simd-pack-256 single-float) single-avx2-immediate-sc-number)
       (t int-avx2-immediate-sc-number)))))

(defun boxed-immediate-sc-p (sc)
  (eql sc immediate-sc-number))

(defstruct (nil-relative (:constructor nil-relative (disp)) (:copier nil))
  (disp 0 :read-only t))

(defconstant lflist-tail-value-nil-offset
  (+ (- nil-value-offset) ; go back to the start of static space
     ;; Skip over all static symbols except T which isn't in low static space
     (* (1- (length +static-symbols+)) (pad-data-block symbol-size))
     (ash 258 word-shift) ; **PRIMITIVE-OBJECT-LAYOUTS**
     (ash 6 word-shift) ; 0-length simple-base-string and simple-character-string
     instance-pointer-lowtag))

(define-symbol-macro offset-of-static-simple-base-string-0
    (+ lflist-tail-value-nil-offset (- instance-pointer-lowtag)
       (ash -4 word-shift) other-pointer-lowtag))
(define-symbol-macro offset-of-static-simple-ucs4-string-0
    (+ lflist-tail-value-nil-offset (- instance-pointer-lowtag)
       (ash -6 word-shift) other-pointer-lowtag))

;;; Return the bits (descriptor or raw as specified) representing the CPU's
;;; view of TN which is in the IMMEDIATE storage class. If the bits can only
;;; be determined at load time, as with immobile layouts and symbols,
;;; then return an absolute fixup which will get replaced by the bits.
(defun immediate-tn-repr (tn &optional (tag t))
  (let ((val (tn-value tn)))
    (etypecase val
      (integer  (if tag (fixnumize val) val))
      (symbol (cond ((not val) null-tn)
                    ((static-symbol-p val) (nil-relative (static-symbol-offset val)))
                    (t (make-fixup val :immobile-symbol))))
      #+(or immobile-space permgen)
      (layout (make-fixup val :layout))
      (character (if tag
                     (logior (ash (char-code val) n-widetag-bits)
                             character-widetag)
                     (char-code val)))
      (single-float
       (let ((bits (single-float-bits val)))
         (if tag
             (dpb bits (byte 32 32) single-float-widetag)
             bits)))
      ((simple-string 0)
       ;; objects following static symbols in memory:
       ;;    (simple-character-string 0)
       ;;    (simple-base-string 0)
       ;;    lockfree list tail
       (if (sb-xc:typep val 'base-string)
           (nil-relative offset-of-static-simple-base-string-0)
           (nil-relative offset-of-static-simple-ucs4-string-0)))
      (structure-object
       (if (eq val sb-lockless:+tail+)
           (progn (aver tag) (nil-relative lflist-tail-value-nil-offset))
           (bug "immediate structure-object ~S" val))))))

;;; Return the bits of TN's representation if it has immediate SC,
;;; otherwise return TN exactly as-is.
(defun encode-value-if-immediate (tn &optional (tag t))
  (if (sc-is tn immediate) (immediate-tn-repr tn tag) tn))

;;;; miscellaneous function call parameters

;;; Offsets of special stack frame locations relative to RBP.
;;;
;;; Consider the standard prologue PUSH RBP; MOV RBP, RSP: the return
;;; address is at RBP+8, the old control stack frame pointer is at
;;; RBP, the magic 3rd slot is at RBP-8. Then come the locals from
;;; RBP-16 on.
(defconstant return-pc-save-offset 0)
(defconstant ocfp-save-offset 1)
;;; Let SP be the stack pointer before CALLing, and FP is the frame
;;; pointer after the standard prologue. SP +
;;; FRAME-WORD-OFFSET(SP->FP-OFFSET + I) = FP + FRAME-WORD-OFFSET(I).
(defconstant sp->fp-offset 2)

(declaim (inline frame-word-offset))
(defun frame-word-offset (index)
  (- (1- index)))

(declaim (inline frame-byte-offset))
(defun frame-byte-offset (index)
  (* (frame-word-offset index) n-word-bytes))

;;; This is used by the debugger.
(defconstant single-value-return-byte-offset 0)

;;; This function is called by debug output routines that want a pretty name
;;; for a TN's location. It returns a thing that can be printed with PRINC.
(defun location-print-name (tn)
  (declare (type tn tn))
  (let* ((sc (tn-sc tn))
         (sb (sb-name (sc-sb sc)))
         (offset (tn-offset tn)))
    (ecase sb
      (registers
       (concatenate 'string
                    (reg-name (tn-reg tn))
                    (case (sc-name (tn-sc tn))
                      (descriptor-reg "(d)")
                      (any-reg "(a)")
                      (unsigned-reg "(u)")
                      (signed-reg "(s)")
                      (sap-reg "(p)")
                      (t "(?)"))))
      (float-registers (format nil "FLOAT~D" offset))
      (stack (format nil "S~D" offset))
      (constant (format nil "Const~D" offset))
      (immediate-constant "Immed")
      (noise (symbol-name (sc-name sc))))))

(defconstant nargs-offset rcx-offset)
(defconstant cfp-offset rbp-offset) ; pfw - needed by stuff in /code

(defvar *register-names* +qword-register-names+)

;;; See WRITE-FUNINSTANCE-PROLOGUE in x86-64-vm.
;;; There are 4 bytes available in the imm32 operand of a dummy MOV instruction.
;;; (It's a valid instruction on the theory that illegal opcodes might cause
;;; the decode stage in the CPU to behave suboptimally)
(defmacro compact-fsc-instance-hash (fin)
  `(sap-ref-32 (int-sap (get-lisp-obj-address ,fin))
               (+ (ash 3 word-shift) 4 (- fun-pointer-lowtag))))

(eval-when (:compile-toplevel)
  (let ((locs (sb-c::sc-locations (gethash 'any-reg sb-c:*backend-sc-names*))))
    ;; These locations are not saved by WITH-REGISTERS-PRESERVED
    ;; because Lisp can't treat them as general purpose.
    ;; By design they are also (i.e. must be) nonvolatile aross C call.
    (aver (not (logbitp card-table-reg locs)))
    #-gs-seg (aver (not (logbitp 13 locs)))))

#+sb-xc-host
(setq *backend-cross-foldable-predicates*
      '(power-of-two-p))

#+nil
(define-cond-sc 32-bit-immediate immediate
  (typep (tn-value tn) '(signed-byte 32)))

(defmacro sb-impl::symbol-allocator-macro (kind name)
  (declare (ignorable kind))
  #+permgen
  `(truly-the symbol (if (eql ,kind 0) ; uninterned
                         (sb-vm::%alloc-symbol ,name)
                         (allocate-permgen-symbol ,name)))
  #-permgen
  `(truly-the symbol
          ;; If no immobile-space, easy: all symbols go in dynamic-space
          #-immobile-space (sb-vm::%alloc-symbol ,name)
          ;; If #+immobile-symbols, then uninterned symbols go in dynamic space, but
          ;; interned symbols go in immobile space. Good luck IMPORTing an uninterned symbol-
          ;; it'll work at least superficially, but if used as a code constant, the symbol's
          ;; address may violate the assumption that it's an imm32 operand.
          #+immobile-symbols
          (if (eql ,kind 0) (sb-vm::%alloc-symbol ,name) (sb-vm::%alloc-immobile-symbol ,name))
          #+(and immobile-space (not immobile-symbols))
          (if (or (eql ,kind 1) ; keyword
                  (and (eql ,kind 2) ; random interned symbol
                       (plusp (length ,name))
                       (char= (char ,name 0) #\*)
                       (char= (char ,name (1- (length ,name))) #\*)))
              (sb-vm::%alloc-immobile-symbol ,name)
              (sb-vm::%alloc-symbol ,name))))
