;;; ENGLISH: Site specific definitions, to be modified on installation
;;; DEUTSCH: Funktionen, die beim Transportieren zu �ndern sind
;;; FRANCAIS: Fonctions d�pendantes de l'installation

(in-package "LISP")
(mapcar #'fmakunbound '(machine-type machine-version machine-instance
                        short-site-name long-site-name editor-tempfile))

(defun machine-type () "PC/486")
(defun machine-version () "486/33")
(defun machine-instance () "Heimger�t Bruno Haible")

(defun short-site-name () "Karlsruhe")
(defun long-site-name () "Augartenstra�e 40, W7500 Karlsruhe 1, Deutschland")

;; ENGLISH: The name of the editor:
;; DEUTSCH: Der Name des Editors:
;; FRANCAIS: Nom de l'�diteur :
(defparameter *editor* "C:\\UTIL\\PRODIT.EXE")

;; ENGLISH: The temporary file LISP creates for editing:
;; DEUTSCH: Das tempor�re File, das LISP beim Editieren anlegt:
;; FRANCAIS: Fichier temporaire cr�� par LISP pour l'�dition :
(defun editor-tempfile ()
  #+DOS "LISPTEMP.LSP"
  #+OS/2 "lisptemp.lsp"
)

;; ENGLISH: The list of directories where programs are searched on LOAD etc.
;;          if device and directory are unspecified:
;; DEUTSCH: Die Liste von Directories, in denen Programme bei LOAD etc. gesucht
;;          werden, wenn dabei Laufwerk und Directory nicht angegeben ist:
;; FRANCAIS: Liste de r�pertoires o� chercher un fichier lorsqu'un r�pertoire
;;           particulier n'est pas indiqu� :
(defparameter *load-paths*
  '(#"C:"               ; erst im Current-Directory von Laufwerk C:
    #"C:\\CLISP\\...\\" ; dann in allen Directories unterhalb C:\CLISP
   )
)

;; ENGLISH: Also set the variable *default-time-zone* in DEFS1.LSP according
;;          to your time zone.
;; DEUTSCH: Setzen Sie auch die Variable *default-time-zone* in DEFS1.LSP
;;          auf die bei Ihnen g�ltige Zeitzone.
;; FRANCAIS: Dans DEFS1.LSP, affectez � *default-time-zone* la valeur
;;           correspondante � votre fuseau horaire.

