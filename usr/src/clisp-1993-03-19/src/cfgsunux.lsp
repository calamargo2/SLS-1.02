;;; ENGLISH: Site specific definitions, to be modified on installation
;;; DEUTSCH: Funktionen, die beim Transportieren zu �ndern sind
;;; FRANCAIS: Fonctions d�pendantes de l'installation

(in-package "LISP")
(mapcar #'fmakunbound '(short-site-name long-site-name
                        edit-file editor-tempfile))

(defun short-site-name () "Uni Karlsruhe")
(defun long-site-name () "Mathematisches Institut II, Universit�t Karlsruhe, Englerstra�e 2, D - W 7500 Karlsruhe 1")

;; ENGLISH: The name of the editor:
;; DEUTSCH: Der Name des Editors:
;; FRANCAIS: Nom de l'�diteur :
(defparameter *editor* "vi")

;; ENGLISH: (edit-file file) edits a file.
;; DEUTSCH: (edit-file file) editiert eine Datei.
;; FRANCAIS: (edit-file file) permet l'�dition d'un fichier.
(defun edit-file (file)
  (shell
    (format nil "~A ~A"
                (if (sys::getenv "WINDOW_PARENT") ; Suntools aktiv?
                  "textedit"
                  (or (sys::getenv "EDITOR") ; Benutzer-Pr�ferenz?
                      *editor*               ; sonst: Default-Editor
                ) )
                (truename file)
) ) )

;; ENGLISH: The temporary file LISP creates for editing:
;; DEUTSCH: Das tempor�re File, das LISP beim Editieren anlegt:
;; FRANCAIS: Fichier temporaire cr�� par LISP pour l'�dition :
(defun editor-tempfile ()
  (merge-pathnames "lisptemp.lsp" (user-homedir-pathname))
)

;; ENGLISH: The list of directories where programs are searched on LOAD etc.:
;; DEUTSCH: Die Liste von Directories, in denen Programme bei LOAD etc. gesucht
;;          werden:
;; FRANCAIS: Liste de r�pertoires o� chercher un fichier programme:
(defparameter *load-paths* '(#"./" #"./**/" #"~/**/"))

