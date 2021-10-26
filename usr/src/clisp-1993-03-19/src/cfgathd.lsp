;;; ENGLISH: Site specific definitions, to be modified on installation
;;; DEUTSCH: Funktionen, die beim Transportieren zu �ndern sind
;;; FRANCAIS: Fonctions d�pendantes de l'installation

(in-package "LISP")
(mapcar #'fmakunbound '(machine-type machine-version machine-instance
                        short-site-name long-site-name editor-tempfile))

(defun machine-type () "Atari ST")
(defun machine-version () "Mega ST 4")
(defun machine-instance () "Instituts-Maschine Math. Institut II")

(defun short-site-name () "Karlsruhe")
(defun long-site-name () "Zimmer 320, Mathe-Bau, Universit�t Karlsruhe, W7500 Karlsruhe 1, Deutschland")

;; ENGLISH: The name of the editor:
;; DEUTSCH: Der Name des Editors:
;; FRANCAIS: Nom de l'�diteur :
(defparameter *editor* "E:\\LISP\\TEMPUS.PRG")

;; ENGLISH: The temporary file LISP creates for editing:
;; DEUTSCH: Das tempor�re File, das LISP beim Editieren anlegt:
;; FRANCAIS: Fichier temporaire cr�� par LISP pour l'�dition :
(defun editor-tempfile () "LISPTEMP.LSP")

;; ENGLISH: The list of directories where programs are searched on LOAD etc.
;;          if device and directory are unspecified:
;; DEUTSCH: Die Liste von Directories, in denen Programme bei LOAD etc. gesucht
;;          werden, wenn dabei Laufwerk und Directory nicht angegeben ist:
;; FRANCAIS: Liste de r�pertoires o� chercher un fichier lorsqu'un r�pertoire
;;           particulier n'est pas indiqu� :
(defparameter *load-paths*
  '(#"E:\\LISP\\...\\" ; in allen Directories unterhalb von E:\LISP
    #"A:"        ; erst im Current-Directory von Laufwerk A:
    #"A:\\"      ; dann im Root-Directory von Laufwerk A:
    #"A:\\...\\" ; dann in allen Directories von Laufwerk A:
   )
)

;; ENGLISH: Also set the variable *default-time-zone* in DEFS1.LSP according
;;          to your time zone.
;; DEUTSCH: Setzen Sie auch die Variable *default-time-zone* in DEFS1.LSP
;;          auf die bei Ihnen g�ltige Zeitzone.
;; FRANCAIS: Dans DEFS1.LSP, affectez � *default-time-zone* la valeur
;;           correspondante � votre fuseau horaire.

