;; helm-org-roam.el -- fksdfkshgle

(require 'helm)
(require 'org-roam)
(require 'dash)

(defun helm-org-roam-find-file(&optional require-match)
  (interactive)
  (helm :sources (helm-build-sync-source "Roam: "
                   :fuzzy-match t
                   :candidates (org-roam--get-title-path-completions)
                   :filtered-candidate-transformer
                            (and (not require-match)
                                 #'org-roam-completion--helm-candidate-transformer)
                   :action
                   '(("Find File" . helm-org-roam-find-file-1)
                     ("Tag Add" . helm-org-roam-find-file-add-tags)
                     ("Tag Delete" . helm-org-roam-find-file-remove-tags)
                     ("Remove Files" . helm-org-roam-remove-files)
                     ;; ("Move to Slipbox" .
                     ;;  (lambda(candidate)
                     ;;    (let* ((org-roam-current-directory org-roam-directory)
                     ;;           (org-roam-other-directory (completing-read "Slipbox: " (org-roam-databases)))
                     ;;           (files (delete-dups (mapcar (lambda (a) (plist-get a :path)) (helm-marked-candidates))))
                     ;;           (org-roam-directory org-roam-other-directory)
                     ;;           (org-roamd-db-location (concat org-roam-other-directory "/DB"))
                     ;;           )
                     ;;      (if (not (string-match-p "/" org-roam-other-directory))
                     ;;          (setq org-roam-other-directory (concat org-roam-root-directory "/" org-roam-other-directory)))
                     ;;      (if (not (file-directory-p org-roam-other-directory))
                     ;;          (make-directory org-roam-other-directory))
                     ;;    (mapcar
                     ;;     #'(lambda(a) 
                     ;;         (rename-file (expand-file-name a)
                     ;;                      (concat (expand-file-name org-roam-other-directory)
                     ;;                              (string-remove-prefix (expand-file-name org-roam-current-directory) (expand-file-name a)))
                     ;;                      )) files)
                        
                     ;;    )
                     ;;    ))
                     ))))
;;;###autoload
(defun helm-org-roam-find-file-1 (candidate)
    "Find File. Candidate"
    (mapcar
     #'(lambda(a)
         (if (plist-get a :path)
             (find-file (plist-get a :path))
           (let ((org-roam-capture--info `((title . ,a)
                                           (slug  . ,(funcall org-roam-title-to-slug-function a))))
                 (org-roam-capture--context 'title))
             (setq org-roam-capture-additional-template-props (list :finalize 'find-file))
             (org-roam-capture--capture))
           )) (helm-marked-candidates)))

(defun helm-org-roam-multi-tag-add(tags files)
  "Hello.  TAGS.   FILES."
  (dolist (file files)
    (when (not (equal file nil))
           (with-current-buffer (find-file-noselect file)
             (org-roam--set-global-prop
              "roam_tags"
              (combine-and-quote-strings (seq-uniq (append tags (org-roam--extract-tags-prop file)))))
             (save-buffer))))
           (org-roam-db--insert-tags 'update))

(defun helm-org-roam-multi-tag-delete(tags files)
  "Something"
  (dolist (file files)
    (when (not (equal file nil))
           (with-current-buffer (find-file-noselect file)
             (org-roam--set-global-prop
              "roam_tags"
              (combine-and-quote-strings (-difference (org-roam--extract-tags-prop file) tags)))
             (save-buffer))))
  (org-roam-db--insert-tags 'update))

(defun helm-org-roam-find-file-add-tags (candidate &optional require-match)
                        (let* ((files  (helm-marked-candidates))
                               (tags-to-add  (helm :sources (helm-build-sync-source "Tags"
                                                              :candidates (org-roam-db--get-tags)
                                                              :filtered-candidate-transformer
                                                              (and (not require-match)
                                                                   #'org-roam-completion--helm-candidate-transformer)
                                                              :action
                                                              '(("Identity" . (lambda (candidate) (helm-marked-candidates))))))
                                                              ))
                          (helm-org-roam-multi-tag-add tags-to-add (mapcar #'(lambda (a) (plist-get a :path)) files))))

(defun helm-org-roam-find-file-remove-tags (candidate &optional require-match)
                        (let* ((files  (helm-marked-candidates))
                               (tags-to-delete  (helm :sources (helm-build-sync-source "Tags" :candidates (org-roam-db--get-tags)
                                                              :filtered-candidate-transformer
                                                              (and (not require-match)
                                                                   #'org-roam-completion--helm-candidate-transformer)
                                                              :action
                                                              '(("Identity" . (lambda (candidate) (helm-marked-candidates))))))
                                                                                       ))
                          
                          (helm-org-roam-multi-tag-delete tags-to-delete (mapcar #'(lambda (a) (plist-get a :path)) files))))

(defun helm-org-roam-remove-files (candidate)
  "Remove Files"
    (mapcar
     #'(lambda(a)
         (message "%s"
                  (delete-file
                   (plist-get a :path)))) (helm-marked-candidates))
  )
(provide 'helm-org-roam)
