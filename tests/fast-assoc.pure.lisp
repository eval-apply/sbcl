
;; This is supposed to be representative of an alien enum.
(defvar *symbols*
'(:UNSPECIFIED-AIRCRAFT :|_123| :|_100| :|_141| :|_142| :|_143| :|_146| :|-14-F|
 :|-14-X| :|-14-Y| :|-14-Z| :|_219| :|_220| :|_221| :|_223| :|_275| :|_290|
 :|_295| :|_310| :|_312| :|_313| :|_318| :|_319| :|-31-A| :|-31-B| :|-31-F|
 :|-31-N| :|-31-X| :|-31-Y| :|_320| :|_321| :|-32-A| :|-32-B| :|-32-F| :|-32-N|
 :|-32-Q| :|-32-S| :|-32-X| :|_330| :|_332| :|_333| :|_338| :|_339| :|-33-B|
 :|-33-F| :|-33-X| :|-33-Y| :|_340| :|_342| :|_343| :|_345| :|_346| :|_350|
 :|_351| :|_358| :|_359| :|_377| :|-37-F| :|_380| :|_388| :|-38-F| :|_703|
 :|_707| :|-70-F| :|-70-M| :|_717| :|_721| :|_722| :|_727| :|-72-A| :|-72-B|
 :|-72-C| :|-72-F| :|-72-M| :|-72-S| :|-72-W| :|-72-X| :|-72-Y| :|_731| :|_732|
 :|_733| :|_734| :|_735| :|_736| :|_737| :|_738| :|_739| :|-73-A| :|-73-C|
 :|-73-E| :|-73-F| :|-73-G| :|-73-H| :|-73-J| :|-73-K| :|-73-L| :|-73-M|
 :|-73-N| :|-73-P| :|-73-Q| :|-73-R| :|-73-S| :|-73-T| :|-73-U| :|-73-W|
 :|-73-X| :|-73-Y| :|_741| :|_742| :|_743| :|_744| :|_747| :|-74-B| :|-74-C|
 :|-74-D| :|-74-E| :|-74-F| :|-74-H| :|-74-J| :|-74-L| :|-74-M| :|-74-N|
 :|-74-R| :|-74-T| :|-74-U| :|-74-V| :|-74-X| :|-74-Y| :|_752| :|_753| :|_757|
 :|-75-C| :|-75-E| :|-75-F| :|-75-M| :|-75-T| :|-75-V| :|-75-W| :|_762| :|_763|
 :|_764| :|_767| :|-76-F| :|-76-V| :|-76-W| :|-76-X| :|-76-Y| :|_772| :|_773|
 :|_777| :|_779| :|-77-F| :|-77-L| :|-77-W| :|-77-X| :|_781| :|_783| :|_787|
 :|_788| :|_789| :|-7-F8| :|-7-M1| :|-7-M7| :|-7-M8| :|-7-M9| :|-7-S7| :|-7-S8|
 :|-7-S9| :|_919| :A22 :A26 :A28 :A30 :A32 :A38 :A40 :A58 :A78 :A81 :AB3 :AB4
 :AB6 :ABB :ABF :ABX :ABY :ACD :ACP :ACT :AGH :AI4 :AN4 :AN6 :AN7 :ANF :APF
 :APH :AR1 :AR7 :AR8 :ARJ :ARX :AT3 :AT4 :AT5 :AT7 :ATD :ATF :ATP :ATR :ATZ
 :AW6 :AW8 :AWH :AX1 :AX8 :B11 :B12 :B13 :B14 :B15 :B72 :BE1 :BE2 :BE4 :BE9
 :BEC :BEF :BEH :BEP :BES :BET :BH2 :BNI :BNT :BTA :BUS :C17 :C19 :C21 :C27
 :C75 :CC6 :CC7 :CCJ :CCX :CD2 :CJ1 :CJ2 :CJ5 :CJ6 :CJ7 :CJ8 :CJL :CJM :CJS
 :CJT :CJX :CL3 :CL4 :CL5 :CN1 :CN2 :CN7 :CNA :CNC :CNF :CNJ :CNT :CR1 :CR2
 :CR5 :CR7 :CR9 :CRA :CRF :CRJ :CRK :CRV :CS1 :CS2 :CS3 :CS4 :CS5 :CS9 :CSB
 :CV2 :CV4 :CV5 :CVF :CVR :CVV :CVX :CVY :CWC :D10 :D11 :D14 :D1-C :D1-F :D1-M
 :D1-X :D1-Y :D20 :D28 :D2-L :D38 :D3-F :D3-X :D42 :D4-X :D62 :D6-F :D8-F :D8-L
 :D8-M :D8-Q :D8-T :D8-X :D8-Y :D91 :D92 :D93 :D94 :D95 :D9-C :D9-D :D9-F :D9-L
 :D9-S :D9-X :DAM :DC3 :DC4 :DC6 :DC8 :DC9 :DF1 :DF2 :DF3 :DF5 :DF7 :DF8 :DF9
 :DFL :DH1 :DH2 :DH3 :DH4 :DH7 :DH8 :DHB :DHC :DHD :DHF :DHH :DHL :DHO :DHP
 :DHR :DHS :DHT :E70 :E75 :E7-W :E90 :E95 :EA5 :EAC :EC3 :EC4 :EC5 :EC7 :EM2
 :EM3 :EM4 :EM5 :EM7 :EM9 :EMB :EMJ :EML :EP1 :EP3 :EPH :EQV :ER3 :ER4 :ERD
 :ERJ :ET5 :ET6 :ETR :EV5 :F21 :F22 :F23 :F24 :F27 :F28 :F50 :F5-F :F70 :FA7
 :FK7 :FRJ :G2-B :G2-S :GA1 :GA5 :GA6 :GA8 :GJ2 :GJ3 :GJ4 :GJ5 :GJ6 :GJ7 :GR1
 :GR2 :GR3 :GRG :GRJ :GRM :GRS :H16 :H20 :H21 :H24 :H25 :H28 :H29 :HBA :HEC
 :HHJ :HOV :HPH :HS7 :HSF :I14 :I4-F :I9-F :ICE :IL4 :IL6 :IL7 :IL8 :IL9 :ILW
 :J31 :J32 :J41 :JET :JST :JU5 :L10 :L11 :L12 :L15 :L1-A :L1-F :L49 :L4-F :L4-T
 :LCH :LHP :LJ2 :LJ3 :LJ4 :LJ6 :LJ7 :LJ8 :LMO :LOE :LOF :LOH :LOM :LRJ :M11
 :M1-F :M1-M :M2-F :M3-F :M6-F :M80 :M81 :M82 :M83 :M87 :M88 :M8-F :M90 :M95
 :MA6 :MBH :MD9 :MIH :MTL :MU2 :ND2 :NDC :NDE :NDH :P18 :PA1 :PA2 :PAG :PAT
 :PIG :PL2 :PL4 :PL6 :PN6 :PR1 :RFS :S20 :S58 :S61 :S76 :S9-S :SF3 :SF5 :SFA
 :SFB :SFF :SH3 :SH6 :SHB :SHS :SSC :SU1 :SU7 :SU9 :SWF :SWM :SY8 :T12 :T20
 :T2-F :T34 :TAT :TBM :TCM :TEE :TGV :THS :THT :TIC :TPT :TRD :TRN :TRS :TSL
 :TU3 :TU5 :VCV :VGF :WWP :YK2 :YK4 :YM3 :YMC :YN2 :YN5 :YN7 :YS1)
  )

(defun f (x)
  (gethash x #.(let ((h (make-hash-table :size (length *symbols*)))
                     (val -100))
                 (dolist (sym *symbols* h)
                   (setf (gethash sym h) (incf val))))))

;;; See https://bugs.launchpad.net/sbcl/+bug/1980460
;;; We could add an expansion for CASE into ASSOC
;;; if the values of the case are constant.

(defun g (x)
  (cdr (assoc x '#.(loop for x in *symbols* for i from -99 collect (cons x i)))))

(defun way1 (n syms)
  (loop repeat (the fixnum n) sum (loop for x in syms sum (f x) fixnum)))
(defun way2 (n syms)
  (loop repeat (the fixnum n) sum (loop for x in syms sum (g x) fixnum)))

(with-test (:name :fast-assoc :skipped-on :interpreter)
  (let* ((inputs (append (shuffle *symbols*)
                         (reverse *symbols*)
                         (shuffle *symbols*)
                         *symbols*))
         (begin-time (get-internal-real-time))
         (answer1 (way1 10000 inputs))
         (end-time-1 (get-internal-real-time))
         (answer2 (way2 10000 inputs))
         (end-time-2 (get-internal-real-time))
         (elapsed1 (- end-time-1 begin-time))
         (elapsed2 (- end-time-2 end-time-1)))
    (assert (= answer1 answer2))
    ;; There isn't anything to assert about the speedup,
    ;; it's just an interesting number to see
    (format t "Speedup=~F~%" (/ elapsed1 elapsed2))
    (let* ((constants (ctu:find-code-constants #'g))
           (key-vector (find-if #'simple-vector-p constants))
           (data-vector
            (find-if (lambda (x)
                       (and (vectorp x)
                            (not (eq x key-vector))
                            (= (length x) (length key-vector))))
                     constants)))
      ;; DATA are in a specialized vector. The perfect hash generator would
      ;; never use a signed-byte vector, so this has to be the data vector.
      (assert (typep data-vector `(simple-array (signed-byte 16) (*)))))))

(with-test (:name :unoptimized-bad-code) ; lp#2054857
  (flet ((try (expr)
           (let ((f (compile nil `(lambda (a b)
                                    (declare (muffle-conditions warning))
                                    ,expr))))
             (assert-error (funcall f 1 'z)))))
    (try '(cdr a (assoc b '((x) (y) (z)))))
    (try '(cdr (assoc b '((x) (y) (z))) 1))))

(defglobal *my-alist* '((#\a . c) (#\b . :b) (#\c . see)
                        (#\d . d) (1 . foo) (foo . 32) (-4 . hello)))
(defun assoc-mixed-keytypes (x) (cdr (assoc x '#.*my-alist*)))
(defun rassoc-mixed-keytypes (x) (car (rassoc x '#.*my-alist*)))
(compile 'assoc-mixed-keytypes)
(compile 'rassoc-mixed-keytypes)

(with-test (:name :assoc-mixed-keytypes)
  (let ((c (ctu:find-code-constants #'assoc-mixed-keytypes)))
    (assert (typep (car c) '(simple-vector 7)))
    (assert (typep (cadr c) '(simple-vector 7)))
    (assert (not (cddr c))))

  (let ((c (ctu:find-code-constants #'rassoc-mixed-keytypes)))
    (assert (typep (car c) '(simple-vector 7)))
    (assert (typep (cadr c) '(simple-vector 7)))
    (assert (not (cddr c))))

  (dolist (pair *my-alist*)
    (assert (eql (assoc-mixed-keytypes (car pair)) (cdr pair)))
    (assert (eql (rassoc-mixed-keytypes (cdr pair)) (car pair)))))

(defglobal *my-pos-testvector*
    #(a #\_ :cmonkey nil :key 2 #\z #\space :zook -1 2 500))
(defun fast-rpos-mixed-keytypes (x)
  (position x #.*my-pos-testvector* :from-end t))
(compile 'fast-rpos-mixed-keytypes)
(with-test (:name :pos-mixed-keytypes)
  (let ((c (delete-if (lambda (x) (typep x '(vector * 8)))
                      (ctu:find-code-constants #'fast-rpos-mixed-keytypes))))
    (assert (typep (car c) '(simple-vector 11)))
    (assert (typep (cadr c) '(vector (unsigned-byte 8) 11)))
    (assert (not (cddr c))))
  (dotimes (i (length *my-pos-testvector*))
    (let* ((k (aref *my-pos-testvector* i))
           (p (fast-rpos-mixed-keytypes k)))
      (if (eql k 2) ; duplicated
          (assert (= p 10))
          (assert (= p i))))))

(sb-int:defconstant-eqx +averylongstring+
    (map 'base-string 'code-char
          '(94 44 61 78 122 124 90 68 104 113 63 90 111 49 101 89 96 106 116 39 81 82 54
            52 66 100 123 78 95 51 55 124 111 83 124 110 40 39 124 115 94 42 105 102 102
            78 56 126 81 10 94 117 103 53 40 88 119 104 90 48 75 48 68 88 78 50 65 41 115
            117 120 51 63 72 63 96 33 32 112 70 106 43 94 96 50 101 88 66 87 88 60 76 99
            91 90 45 87 89 90 102 10 85 115 102 57 51 107 54 125 81 44 57 38 66 91 64 71
            119 101 103 51 42 34 125 55 122 42 65 36 66 85 92 65 58 46 84 41 98 53 101 95
            104 40 71 78 108 105 126 54 116 93 59 108 61 60 37 43 111 72 85 108 109 90 65
            73 50 97 45 103 62 102 49 52 90 56 119 77 107 93 111 69 114 125 64 55 96 122
            119 108 69 92 106 65 73 55 67 122 87 74 111 46 36 103 109 103 115 75 106 74
            113 62 63 86 55 89 69 84 35 115 49 67 106 54 68 110 47 114 95 44 90 41 59 88
            94 34 33 63 10 56 109 103 60 105 40 53 125 40 51 42 91 100 47 67 46 96 89 118))
  #'equal)

(with-test (:name :position-in-very-long-string)
  ;; This function should not crash the compiler.
  ;; The element type for the output array was getting choosen too restrictively.
  ;; Due to dup chars in the string, the vector of possible answers is only
  ;; as long as (length (remove-duplicates +averylongstring+)) but the element
  ;; is as large as (1- (length +averylongstring+)) inclusive.
  (let ((f (compile nil '(lambda (c) (position c +averylongstring+)))))
    (declare (notinline position))
    ;; the function should work
    (dotimes (i (or #+sb-unicode 1000 256))
      (assert (eql (position (code-char i) +averylongstring+)
                   (funcall f (code-char i)))))))
