;;; ENGLISH: Site specific definitions, to be modified on installation
;;; DEUTSCH: Funktionen, die beim Transportieren zu �ndern sind
;;; FRANCAIS: Fonctions d�pendantes de l'installation

(in-package "LISP")
(mapcar #'fmakunbound '(machine-type machine-version machine-instance
                        short-site-name long-site-name editor-tempfile))

(defun machine-type () "Amiga")
(defun machine-version () "Amiga 2000, OS 1.3")
(defun machine-instance () "Heinrich Mustermanns Amiga")
                          ;"Smith's Amiga"
                          ;"Amiga de M. Henri Dupondt"

(defun short-site-name () "Pfefferhofen")
                         ;"Farawaycity"
                         ;"Village-le-Petit"
(defun long-site-name () "Haus Nr. 71, W3456 Pfefferhofen, Deutschland")
                        ;"4 Down Street #382, Farawaycity, TX 86754, USA"
                        ;"5, Grande Rue, 34567 Village-le-Petit, France"

;; ENGLISH: The name of the editor:
;; DEUTSCH: Der Name des Editors:
;; FRANCAIS: Nom de l'�diteur :
(defparameter *editor* "ed")

;; ENGLISH: The temporary file LISP creates for editing:
;; DEUTSCH: Das tempor�re File, das LISP beim Editieren anlegt:
;; FRANCAIS: Fichier temporaire cr�� par LISP pour l'�dition :
(defun editor-tempfile () "T:lisptemp.lsp")

;; ENGLISH: The list of directories where programs are searched on LOAD etc.
;;          if device and directory are unspecified:
;; DEUTSCH: Die Liste von Directories, in denen Programme bei LOAD etc. gesucht
;;          werden, wenn dabei Laufwerk und Directory nicht angegeben ist:
;; FRANCAIS: Liste de r�pertoires o� chercher un fichier lorsqu'un r�pertoire
;;           particulier n'est pas indiqu� :
(defparameter *load-paths*
  '(#"**/"      ; erst in allen Directories unterhalb von hier
    #"LIBS:**/" ; dann in allen Directories unterhalb von LIBS:
   )
)

;; ENGLISH: Also set the variable *default-time-zone* in DEFS1.LSP according
;;          to your time zone.
;; DEUTSCH: Setzen Sie auch die Variable *default-time-zone* in DEFS1.LSP
;;          auf die bei Ihnen g�ltige Zeitzone.
;; FRANCAIS: Dans DEFS1.LSP, affectez � *default-time-zone* la valeur
;;           correspondante � votre fuseau horaire.

;; This makes screen output both faster and prettier:
(setq *print-pretty* t)

