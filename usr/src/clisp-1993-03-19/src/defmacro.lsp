;;;; File DEFMACRO.LSP
;;; Macro DEFMACRO und einige Hilfsfunktionen f?r komplizierte Macros.
;;; 1. 9. 1988
;;; Adaptiert an DEFTYPE am 10.6.1989

(in-package "SYSTEM")

;; Import aus CONTROL.Q:

#| (SYSTEM::PARSE-BODY body &optional docstring-allowed env)
   expandiert die ersten Formen in der Formenliste body (im Function-
   Environment env), entdeckt dabei auftretende Deklarationen (und falls
   docstring-allowed=T, auch einen Docstring) und liefert drei Werte:
   1. body-rest, die restlichen Formen,
   2. declspec-list, eine Liste der aufgetretenen Decl-Specs,
   3. docstring, ein aufgetretener Docstring oder NIL.
|#
#| (SYSTEM::KEYWORD-TEST arglist kwlist)
   testet, ob arglist (eine paarige Keyword/Value-Liste) nur Keywords
   enth?lt, die auch in der Liste kwlist vorkommen, oder aber ein
   Keyword/Value-Paar :ALLOW-OTHER-KEYS mit Value /= NIL enth?lt.
   Wenn nein, wird ein Error ausgel?st.
|#
#| (keyword-test arglist kwlist) ?berpr?ft, ob in arglist (eine Liste
von Keyword/Value-Paaren) nur Keywords vorkommen, die in kwlist vorkommen,
oder ein Keyword/Value-Paar mit Keyword = :ALLOW-OTHER-KEYS und Value /= NIL
vorkommt. Sollte dies nicht der Fall sein, wird eine Errormeldung ausgegeben.

(defun keyword-test (arglist kwlist)
  (let ((unallowed-arglistr nil)
        (allow-other-keys-flag nil))
    (do ((arglistr arglist (cddr arglistr)))
        ((null arglistr))
      (if (eq (first arglistr) ':ALLOW-OTHER-KEYS)
          (if (second arglistr) (setq allow-other-keys-flag t))
          (do ((kw (first arglistr))
               (kwlistr kwlist (cdr kwlistr)))
              ((or (null kwlistr) (eq kw (first kwlistr)))
               (if (and (null kwlistr) (null unallowed-arglistr))
                   (setq unallowed-arglistr arglistr)
    ) )   )   ))
    (unless allow-other-keys-flag
      (if unallowed-arglistr
        (cerror #+DEUTSCH "Beide werden ?bergangen."
                #+ENGLISH "It will be ignored."
                #+FRANCAIS "Ignorer les deux."
                #+DEUTSCH "Unzul?ssiges Keyword ~S mit Wert ~S"
                #+ENGLISH "Invalid keyword-value-pair: ~S ~S"
                #+FRANCAIS "Mot-cl? ill?gal ~S, valeur ~S"
                (first unallowed-arglistr) (second unallowed-arglistr)
    ) ) )
) )
; Definition in Assembler siehe CONTROL.Q
|#

(defun macro-call-error (macro-form)
  (error #+DEUTSCH "Der Macro ~S kann nicht mit ~S Argumenten aufgerufen werden: ~S"
         #+ENGLISH "The macro ~S may not be called with ~S arguments"
         #+FRANCAIS "Le macro ~S ne peut pas ?tre appel? avec ~S arguments : ~S"
         (car macro-form) (1- (length macro-form)) macro-form
) )

(proclaim '(special
        %restp ; gibt an, ob &REST/&BODY/&KEY angegeben wurde,
               ; also ob die Argumentanzahl unbeschr?nkt ist.

        %min-args ; gibt die Anzahl der notwendigen Argumente an

        %arg-count ; gibt die Anzahl der Einzelargumente an
                   ; (notwendige und optionale Argumente, zusammengez?hlt)

        %let-list ; umgedrehte Liste der Bindungen, die mit LET* zu machen sind

        %keyword-tests ; Liste der KEYWORD-TEST - Aufrufe, die einzubinden sind

        %default-form ; Default-Form f?r optionale und Keyword-Argumente,
                   ; bei denen keine Default-Form angegeben ist.
                   ; =NIL normalerweise, = (QUOTE *) f?r DEFTYPE.
)          )
#|
(ANALYZE1 lambdalist accessexp name wholevar)
analysiert eine Macro-Lambdaliste (ohne &ENVIRONMENT). accessexp ist der
Ausdruck, der die Argumente liefert, die mit dieser Lambdaliste zu matchen
sind.

(ANALYZE-REST lambdalistr restexp name)
analysiert den Teil einer Macro-Lambdaliste, der nach &REST/&BODY kommt.
restexp ist der Ausdruck, der die Argumente liefert, die mit diesem
Listenrest zu matchen sind.

(ANALYZE-KEY lambdalistr restvar name)
analysiert den Teil einer Macro-Lambdaliste, der nach &KEY kommt.
restvar ist das Symbol, das die restlichen Argumente enthalten wird.

(ANALYZE-AUX lambdalistr name) 
analysiert den Teil einer Macro-Lambdaliste, der nach &AUX kommt.

(REMOVE-ENV-ARG lambdalist name)
entfernt das Paar &ENVIRONMENT/Symbol aus einer Macro-Lambdaliste,
liefert zwei Werte: die verk?rzte Lambdaliste und das als Environment zu
verwendende Symbol (oder die Lambdaliste selbst und NIL, falls &ENVIRONMENT
nicht auftritt).

(MAKE-LENGTH-TEST symbol)
kreiert aus %restp, %min-args, %arg-count eine Testform, die bei Auswertung
anzeigt, ob der Inhalt der Variablen symbol als Aufruferform zum Macro
dienen kann.

(MAKE-MACRO-EXPANSION macrodef)
liefert zu einer Macrodefinition macrodef = (name lambdalist . body)
1. den Macro-Expander als Programmtext (FUNCTION ... (LAMBDA ...)),
2. name, ein Symbol,
3. lambdalist,
4. docstring (oder NIL, wenn keiner da).
|#

(%proclaim-constant 'macro-missing-value (list 'macro-missing-value))
; einmaliges Objekt

(%putd 'analyze-aux
  (function analyze-aux
    (lambda (lambdalistr name)
      (do ((listr lambdalistr (cdr listr)))
          ((atom listr)
           (if listr
             (cerror #+DEUTSCH "Der Teil danach wird ignoriert."
                     #+ENGLISH "The rest of the lambda list will be ignored."
                     #+FRANCAIS "Ignorer ce qui suit."
                     #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt einen Punkt nach &AUX."
                     #+ENGLISH "The lambda list of macro ~S contains a dot after &AUX."
                     #+FRANCAIS "La liste lambda du macro ~S contient un point apr?s &AUX."
                     name
          )) )
        (cond ((symbolp (car listr)) (setq %let-list (cons `(,(car listr) nil) %let-list)))
              ((atom (car listr))
               (error #+DEUTSCH "Im Macro ~S ist als &AUX-Variable nicht verwendbar: ~S"
                      #+ENGLISH "in macro ~S: ~S may not be used as &AUX variable."
                      #+FRANCAIS "Dans le macro ~S, l'utilisation de ~S n'est pas possible comme variable &AUX."
                      name (car listr)
              ))
              (t (setq %let-list
                   (cons `(,(caar listr) ,(cadar listr)) %let-list)
  ) ) ) )     )  )
)

(%putd 'analyze-key
  (function analyze-key
    (lambda (lambdalistr restvar name &aux (otherkeysforbidden t) (kwlist nil))
      (do ((listr lambdalistr (cdr listr))
           (next)
           (kw)
           (svar)
           (g))
          ((atom listr)
           (if listr
             (cerror #+DEUTSCH "Der Teil danach wird ignoriert."
                     #+ENGLISH "The rest of the lambda list will be ignored."
                     #+FRANCAIS "Ignorer ce qui suit."
                     #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt einen Punkt nach &KEY."
                     #+ENGLISH "The lambda list of macro ~S contains a dot after &KEY."
                     #+FRANCAIS "La liste lambda du macro ~S contient un point apr?s &KEY."
                     name
          )) )
        (setq next (car listr))
        (cond ((eq next '&ALLOW-OTHER-KEYS) (setq otherkeysforbidden nil))
              ((eq next '&AUX) (return-from nil (analyze-aux (cdr listr) name)))
              ((or (eq next '&ENVIRONMENT) (eq next '&WHOLE) (eq next '&OPTIONAL)
                   (eq next '&REST) (eq next '&BODY) (eq next '&KEY)
               )
               (cerror #+DEUTSCH "Es wird ignoriert."
                       #+ENGLISH "It will be ignored."
                       #+FRANCAIS "Ignorer ce qui suit."
                       #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt ein ~S an falscher Stelle."
                       #+ENGLISH "The lambda list of macro ~S contains a badly placed ~S."
                       #+FRANCAIS "La liste lambda du macro ~S contient un ~S mal plac?."
                       name next
              ))
              (t
                (if %default-form
                  (cond ((symbolp next) (setq next (list next %default-form)))
                        ((and (consp next) (eql (length next) 1))
                         (setq next (list (car next) %default-form))
                ) )     )
                (cond ((symbolp next)
                       (setq kw (intern (symbol-name next) *keyword-package*))
                       (setq %let-list
                         (cons `(,next (GETF ,restvar ,kw NIL)) %let-list)
                       )
                       (setq kwlist (cons kw kwlist))
                      )
                      ((atom next)
                       (cerror #+DEUTSCH "Es wird ignoriert."
                               #+ENGLISH "It will be ignored."
                               #+FRANCAIS "Il sera ignor?."
                               #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt folgendes unpassende Element: ~S"
                               #+ENGLISH "The lambda list of macro ~S contains the invalid element ~S"
                               #+FRANCAIS "La liste lambda du macro ~S contient cet ?l?ment inadmissible : ~S"
                               name next
                      ))
                      ((symbolp (car next))
                       (setq kw (intern (symbol-name (car next)) *keyword-package*))
                       (setq %let-list
                         (cons `(,(car next) (GETF ,restvar ,kw MACRO-MISSING-VALUE))
                               %let-list
                       ) )
                       (setq svar (if (and (cddr next) (symbolp (third next)))
                                    (third next)
                                    nil
                       )          )
                       (setq %let-list
                         (cons
                           (if svar
                             `(,svar (IF (EQ ,(car next) MACRO-MISSING-VALUE)
                                       (PROGN (SETQ ,(car next) ,(cadr next)) NIL)
                                       T
                              )      )
                             `(,(car next) (IF (EQ ,(car next) MACRO-MISSING-VALUE)
                                             ,(cadr next)
                                             ,(car next)
                              )            )
                           )
                           %let-list
                       ) )
                       (setq kwlist (cons kw kwlist))
                      )
                      ((not (and (consp (car next)) (keywordp (caar next)) (consp (cdar next))))
                       (cerror #+DEUTSCH "Es wird ignoriert."
                               #+ENGLISH "It will be ignored."
                               #+FRANCAIS "Elle sera ignor?e."
                               #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt eine unzul?ssige Keywordspezifikation: ~S"
                               #+ENGLISH "The lambda list of macro ~S contains an invalid keyword specification ~S"
                               #+FRANCAIS "La liste lambda du macro ~S contient une sp?cification de mot-cl? inadmissible : ~S"
                               name (car next)
                      ))
                      ((symbolp (cadar next))
                       (setq kw (caar next))
                       (setq %let-list
                         (cons `(,(cadar next) (GETF ,restvar ,kw MACRO-MISSING-VALUE))
                           %let-list
                       ) )
                       (setq svar (if (and (cddr next) (symbolp (third next)))
                                    (third next)
                                    nil
                       )          )
                       (setq %let-list
                         (cons
                           (if svar
                             `(,svar (IF (EQ ,(cadar next) MACRO-MISSING-VALUE)
                                       (PROGN (SETQ ,(cadar next) ,(cadr next)) NIL)
                                       T
                              )      )
                             `(,(cadar next) (IF (EQ ,(cadar next) MACRO-MISSING-VALUE)
                                             ,(cadr next)
                                             ,(cadar next)
                              )            )
                           )
                           %let-list
                       ) )
                       (setq kwlist (cons kw kwlist))
                      )
                      (t
                       (setq kw (caar next))
                       (setq g (gensym))
                       (setq %let-list
                         (cons `(,g (GETF ,restvar ,kw MACRO-MISSING-VALUE)) %let-list)
                       )
                       (setq svar (if (and (cddr next) (symbolp (third next)))
                                    (third next)
                                    nil
                       )          )
                       (setq %let-list
                         (cons
                           (if svar
                             `(,svar (IF (EQ ,g MACRO-MISSING-VALUE)
                                       (PROGN (SETQ ,g ,(cadr next)) NIL)
                                       T
                              )      )
                             `(,g (IF (EQ ,g MACRO-MISSING-VALUE)
                                    ,(cadr next)
                                    ,(cadar next)
                              )   )
                           )
                           %let-list
                       ) )
                       (setq kwlist (cons kw kwlist))
                       (let ((%min-args 0) (%arg-count 0) (%restp nil) (%default-form nil))
                         (analyze1 (cadar next) g name g)
                      ))
              ) )
      ) )
      (if otherkeysforbidden
        (setq %keyword-tests
          (cons `(KEYWORD-TEST ,restvar ',kwlist) %keyword-tests)
      ) )
  ) )
)

(%putd 'analyze-rest
  (function analyze-rest
    (lambda (lambdalistr restexp name)
      (if (atom lambdalistr)
        (error #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt keine Variable nach &REST/&BODY."
               #+ENGLISH "The lambda list of macro ~S is missing a variable after &REST/&BODY."
               #+FRANCAIS "Il manque une variable apr?s &REST/BODY dans la liste lambda du macro ~S."
               name
      ) )
      (unless (symbolp (car lambdalistr))
        (error #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt eine unzul?ssige Variable nach &REST/&BODY: ~S"
               #+ENGLISH "The lambda list of macro ~S contains an illegal variable after &REST/&BODY: ~S"
               #+FRANCAIS "La liste lambda du macro ~S contient une variable indamissible apr?s &REST/BODY : ~S"
               name (car lambdalistr)
      ) )
      (let ((restvar (car lambdalistr))
            (listr (cdr lambdalistr)))
        (setq %restp t)
        (setq %let-list (cons `(,restvar ,restexp) %let-list))
        (cond ((null listr))
              ((atom listr)
               (cerror #+DEUTSCH "Der Teil danach wird ignoriert."
                       #+ENGLISH "The rest of the lambda list will be ignored."
                       #+FRANCAIS "Ignorer ce qui suit."
                       #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt einen Punkt an falscher Stelle."
                       #+ENGLISH "The lambda list of macro ~S contains a misplaced dot."
                       #+FRANCAIS "La liste lambda du macro ~S contient un point mal plac?."
                       name
              ))
              ((eq (car listr) '&KEY) (analyze-key (cdr listr) restvar name))
              ((eq (car listr) '&AUX) (analyze-aux (cdr listr) name))
              (t (cerror #+DEUTSCH "Dieser ganze Teil wird ignoriert."
                         #+ENGLISH "They will be ignored."
                         #+FRANCAIS "Ignorer cette partie."
                         #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt ?berfl?ssige Elemente: ~S"
                         #+ENGLISH "The lambda list of macro ~S contains superfluous elements: ~S"
                         #+FRANCAIS "La liste lambda du macro ~S contient des ?l?ments superflus : ~S"
                         name listr
  ) ) ) )     )  )
)

(%putd 'cons-car
  (function cons-car
    (lambda (exp &aux h)
      (if
        (and
          (consp exp)
          (setq h
            (assoc (car exp)
              '((car . caar) (cdr . cadr)
                (caar . caaar) (cadr . caadr) (cdar . cadar) (cddr . caddr)
                (caaar . caaaar) (caadr . caaadr) (cadar . caadar) (caddr . caaddr)
                (cdaar . cadaar) (cdadr . cadadr) (cddar . caddar) (cdddr . cadddr)
                (cddddr . fifth)
        ) ) )  )
        (cons (cdr h) (cdr exp))
        (list 'car exp)
  ) ) )
)

(%putd 'cons-cdr
  (function cons-cdr
    (lambda (exp &aux h)
      (if
        (and
          (consp exp)
          (setq h
            (assoc (car exp)
              '((car . cdar) (cdr . cddr)
                (caar . cdaar) (cadr . cdadr) (cdar . cddar) (cddr . cdddr)
                (caaar . cdaaar) (caadr . cdaadr) (cadar . cdadar) (caddr . cdaddr)
                (cdaar . cddaar) (cdadr . cddadr) (cddar . cdddar) (cdddr . cddddr)
        ) ) )  )
        (cons (cdr h) (cdr exp))
        (list 'cdr exp)
  ) ) )
)

(%putd 'analyze1
  (function analyze1
    (lambda (lambdalist accessexp name wholevar)
      (do ((listr lambdalist (cdr listr))
           (withinoptional nil)
           (item)
           (g))
          ((atom listr)
           (when listr
             (unless (symbolp listr)
               (error #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt eine unzul?ssige &REST-Variable: ~S"
                      #+ENGLISH "The lambda list of macro ~S contains an illegal &REST variable: ~S"
                      #+FRANCAIS "La liste lambda du macro ~S contient une variable &REST inadmissible : ~S"
                      name listr
             ) )
             (setq %let-list (cons `(,listr ,accessexp) %let-list))
             (setq %restp t)
          ))
        (setq item (car listr))
        (cond ((eq item '&WHOLE)
               (if (and wholevar (cdr listr) (symbolp (cadr listr)))
                 (progn
                   (setq %let-list (cons `(,(cadr listr) ,wholevar) %let-list))
                   (setq listr (cdr listr))
                 )
                 (error #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt ein unzul?ssiges &WHOLE: ~S"
                        #+ENGLISH "The lambda list of macro ~S contains an invalid &WHOLE: ~S"
                        #+FRANCAIS "La liste lambda du macro ~S contient un &WHOLE inadmissible : ~S"
                        name listr
              )) )
              ((eq item '&OPTIONAL)
               (if withinoptional
                 (cerror #+DEUTSCH "Es wird ignoriert."
                         #+ENGLISH "It will be ignored."
                         #+FRANCAIS "L'ignorer."
                         #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt ein ?berfl?ssiges ~S."
                         #+ENGLISH "The lambda list of macro ~S contains a superfluous ~S."
                         #+FRANCAIS "La liste lambda du macro ~S contient un ~S superflu."
                         name item
               ) )
               (setq withinoptional t)
              )
              ((or (eq item '&REST) (eq item '&BODY))
               (return-from nil (analyze-rest (cdr listr) accessexp name))
              )
              ((eq item '&KEY)
               (setq g (gensym))
               (setq %restp t)
               (setq %let-list (cons `(,g ,accessexp) %let-list))
               (return-from nil (analyze-key (cdr listr) g name))
              )
              ((eq item '&ALLOW-OTHER-KEYS)
               (cerror #+DEUTSCH "Es wird ignoriert."
                       #+ENGLISH "It will be ignored."
                       #+FRANCAIS "L'ignorer."
                       #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt ~S vor &KEY."
                       #+ENGLISH "The lambda list of macro ~S contains ~S before &KEY."
                       #+FRANCAIS "La liste lambda du macro ~S contient ~S avant &KEY."
                       name item
              ))
              ((eq item '&ENVIRONMENT)
               (cerror #+DEUTSCH "Es wird ignoriert."
                       #+ENGLISH "It will be ignored."
                       #+FRANCAIS "L'ignorer."
                       #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt ~S, was hier unzul?ssig ist."
                       #+ENGLISH "The lambda list of macro ~S contains ~S which is illegal here."
                       #+FRANCAIS "La liste lambda du macro ~S contient ~S qui est inadmissible ici."
                       name item
              ))
              ((eq item '&AUX)
               (return-from nil (analyze-aux (cdr listr) name))
              )
              (withinoptional
               (setq %arg-count (1+ %arg-count))
               (if %default-form
                 (cond ((symbolp item) (setq item (list item %default-form)))
                       ((and (consp item) (eql (length item) 1))
                        (setq item (list (car item) %default-form))
               ) )     )
               (cond ((symbolp item)
                      (setq %let-list (cons `(,item ,(cons-car accessexp)) %let-list))
                     )
                     ((atom item)
                      #1=
                      (error #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt ein unzul?ssiges Element: ~S"
                             #+ENGLISH "The lambda list of macro ~S contains an invalid element ~S"
                             #+FRANCAIS "La liste lambda du macro ~S contient un ?l?ment inadmissible : ~S"
                             name item
                     ))
                     ((symbolp (car item))
                      (setq %let-list
                        (cons `(,(car item) (IF ,accessexp
                                              ,(cons-car accessexp)
                                              ,(if (consp (cdr item)) (cadr item) 'NIL)
                               )            )
                          %let-list
                      ) )
                      (when (and (consp (cdr item)) (consp (cddr item)))
                        (unless (symbolp (caddr item))
                          (error #+DEUTSCH "Die Lambdaliste des Macros ~S enth?lt eine unzul?ssige supplied-Variable: ~S"
                                 #+ENGLISH "The lambda list of macro ~S contains an invalid supplied-variable ~S"
                                 #+FRANCAIS "La liste lambda du macro ~S contient une ?supplied-variable? indamissible : ~S"
                                 name (caddr item)
                        ) )
                        (setq %let-list
                          (cons `(,(caddr item) (NOT (NULL ,accessexp))) %let-list)
                     )) )
                     (t
                      (setq g (gensym))
                      (setq %let-list
                        (cons `(,g ,(if (consp (cdr item))
                                      `(IF ,accessexp
                                         ,(cons-car accessexp)
                                         ,(cadr item)
                                       )
                                      (cons-car accessexp)
                               )    )
                          %let-list
                      ) )
                      (let ((%min-args 0) (%arg-count 0) (%restp nil))
                        (analyze1 (car item) g name g)
                      )
                      (if (consp (cddr item))
                        (setq %let-list
                          (cons `(,(caddr item) (NOT (NULL ,accessexp))) %let-list)
               )     )) )
               (setq accessexp (cons-cdr accessexp))
              )
              (t ; notwendige Argumente
               (setq %min-args (1+ %min-args))
               (setq %arg-count (1+ %arg-count))
               (cond ((symbolp item)
                      (setq %let-list (cons `(,item ,(cons-car accessexp)) %let-list))
                     )
                     ((atom item)
                      #1# ; (error ... name item), s.o.
                     )
                     (t
                      (let ((%min-args 0) (%arg-count 0) (%restp nil))
                        (analyze1 item (cons-car accessexp) name (cons-car accessexp))
               )     ))
               (setq accessexp (cons-cdr accessexp))
  ) ) ) )     )
)

(%putd 'remove-env-arg
  (function remove-env-arg
    (lambda (lambdalist name)
      (do ((listr lambdalist (cdr listr)))
          ((atom listr) (values lambdalist nil))
        (if (eq (car listr) '&ENVIRONMENT)
          (if (and (consp (cdr listr)) (symbolp (cadr listr)) (cadr listr))
            ; &ENVIRONMENT gefunden
            (return
              (values
                (do ((l1 lambdalist (cdr l1)) ; lambdalist ohne &ENVIRONMENT/Symbol
                     (l2 nil (cons (car l1) l2)))
                    ((eq (car l1) '&ENVIRONMENT)
                     (nreconc l2 (cddr l1))
                )   )
                (cadr listr)
            ) )
            (error #+DEUTSCH "In der Lambdaliste des Macros ~S mu? nach &ENVIRONMENT ein Symbol (nicht NIL) folgen: ~S"
                   #+ENGLISH "In the lambda list of macro ~S, &ENVIRONMENT must be followed by a non-NIL symbol: ~S"
                   #+FRANCAIS "Dans la liste lambda du macro ~S, &ENVIRONMENT doit ?tre suivi par un symbole autre que NIL : ~S"
                   name lambdalist
          ) )
  ) ) ) )
)

(%putd 'make-length-test
  (function make-length-test
    (lambda (var)
      (cond ((and (zerop %min-args) %restp) NIL)
            ((zerop %min-args) `(> (LENGTH ,var) ,(1+ %arg-count)))
            (%restp `(< (LENGTH ,var) ,(1+ %min-args)))
            ((= %min-args %arg-count) `(/= (LENGTH ,var) ,(1+ %min-args)))
            (t `(NOT (<= ,(1+ %min-args) (LENGTH ,var) ,(1+ %arg-count))))
  ) ) )
)

(%putd 'make-macro-expansion
  (function make-macro-expansion
    (lambda (macrodef)
      (if (atom macrodef)
        (error #+DEUTSCH "Daraus kann kein Macro definiert werden: ~S"
               #+ENGLISH "Cannot define a macro from that: ~S"
               #+FRANCAIS "Aucun macro n'est d?finissable ? partir de ~S"
               macrodef
      ) )
      (unless (symbolp (car macrodef))
        (error #+DEUTSCH "Der Name eines Macros mu? ein Symbol sein, nicht: ~S"
               #+ENGLISH "The name of a macro must be a symbol, not ~S"
               #+FRANCAIS "Le nom d'un macro doit ?tre un symbole et non ~S"
               (car macrodef)
      ) )
      (if (atom (cdr macrodef))
        (error #+DEUTSCH "Der Macro ~S hat keine Lambdaliste."
               #+ENGLISH "Macro ~S is missing a lambda list."
               #+FRANCAIS "Le macro ~S ne poss?de pas de liste lambda."
               (car macrodef)
      ) )
      (let ((name (car macrodef))
            (lambdalist (cadr macrodef))
            (body (cddr macrodef))
           )
        (multiple-value-bind (body-rest declarations docstring)
                             (parse-body body t nil) ; globales Environment!
          (if declarations (setq declarations (list (cons 'DECLARE declarations))))
          (multiple-value-bind (newlambdalist envvar)
                               (remove-env-arg lambdalist name)
            (let ((%arg-count 0) (%min-args 0) (%restp nil)
                  (%let-list nil) (%keyword-tests nil) (%default-form nil))
              (analyze1 newlambdalist '(CDR <MACRO-FORM>) name '<MACRO-FORM>)
              (let ((lengthtest (make-length-test '<MACRO-FORM>))
                    (mainform `(LET* ,(nreverse %let-list)
                                 ,@declarations
                                 ,@(nreverse %keyword-tests)
                                 ,@body-rest
                   ))          )
                (if lengthtest
                  (setq mainform
                    `(IF ,lengthtest
                       (MACRO-CALL-ERROR <MACRO-FORM>)
                       ,mainform
                ) )  )
                (values
                  `(FUNCTION ,name
                     (LAMBDA (<MACRO-FORM> &OPTIONAL ,(or envvar '<ENV-ARG>))
                       (DECLARE (CONS <MACRO-FORM>))
                       ,@(unless envvar '((DECLARE (IGNORE <ENV-ARG>))))
                       ,@(if docstring (list docstring))
                       (BLOCK ,name ,mainform)
                   ) )
                  name
                  lambdalist
                  docstring
  ) ) ) ) ) ) ) )
)

