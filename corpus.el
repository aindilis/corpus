(defun corpus-segment-region ()
 "Insert segmentation tags into corpus, and comment out other matches"
 (interactive)
 (let*
  ((mystart (mark))
   (myend (point))
   (start (if (> mystart myend)
	   myend
	   mystart))
   (end (if (> mystart myend)
	 mystart
	 myend)))
  (progn
   (goto-char end)
   (insert "</item>")
   (goto-char start)
   (insert "<item>"))))

(defun corpus-segment-region-prompt ()
 "Insert segmentation tags into corpus, and comment out other matches"
 (interactive)
 (let*
  ((mystart (mark))
   (tag (read-from-minibuffer "TAG: " nil nil nil nil "item"))
   (myend (point))
   (start (if (> mystart myend)
	   myend
	   mystart))
   (end (if (> mystart myend)
	 mystart
	 myend)))
  (progn
   (goto-char end)
   (insert (concat "</" tag ">"))
   (goto-char start)
   (insert (concat "<" tag ">")))))

; (global-set-key "\C-cre" 'corpus-segment-region-prompt)
