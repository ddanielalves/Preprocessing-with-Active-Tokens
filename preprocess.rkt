#lang racket
(provide add-active-token def-active-token process-string)


(define tokens-hsh (make-hash))
(define tokens-lst '())
(define text-changed? #f)


(define-syntax def-active-token
  (syntax-rules ()
    [(def-active-token token (str)
       body)
     (begin
       (define (lambda str)
         body)
       (add-active-token token lambda))
     ]))


(define (add-active-token token function)
  (hash-set! tokens-hsh token function)
  (set! tokens-lst (append tokens-lst (list token))))


;;; Last level of processing
;; Transfers control to the token function
(define (parse-token text token)
  (let ([pos (regexp-match-positions token text)])
    (if (false? pos)
        text
        (let ([new-text ((hash-ref tokens-hsh token) (substring text (cdar pos)))]) ; Call function
          (begin
            (set! text-changed? #t)
            (string-append (substring text 0 (caar pos)) (parse-token  new-text  token)))))))


;;; Second level of processing
(define (single-pass text lst)
  (if (null? lst)
      text
      (let ([new-text (parse-token text (car lst))]) ; Mind the order
        (single-pass new-text (cdr lst)))))


;;; Main process
(define (process-string text)
  (set! text-changed? #f)
  (let ([new-text (single-pass text tokens-lst)])
    (if text-changed?
        (process-string new-text)
        (regexp-replace #rx"\n$" new-text ""))))



;;; Private comment
(define (string-after-newline str)
  (or (for/or ((c (in-string str))
               (i (in-naturals)))
        (and (char=? c #\newline)
             (substring str (+ i 1))))
      ""))


;;; Local type inference
(define (local-type-inference text)
  (let ([str (regexp-match #px"new\\s+[^\\(]+(?=\\()" text)])
    (if str
        (let ([type (regexp-replace #px"new\\s+" (car str) "")])
          (string-append type text))
        text)))


;; For each pattern in the text, replaces each part with its new-part
(define (regexp-infix-parts2* pattern text part1 new-part1 part2 new-part2)
  (let ([pos (regexp-match-positions pattern text)])
    (if (false? pos)
        text
        (let* ([found (substring text (caar pos) (cdar pos))]
               [new-found (regexp-replace part2 (regexp-replace part1 found new-part1) new-part2)]
               [text1 (substring text 0 (caar pos))]
               [text2 (substring text (cdar pos))])
          (regexp-infix-parts2* pattern (string-append text1 new-found text2) part1 new-part1 part2 new-part2)))))


;;; String interpolation
(define (string-interpolation text)
  (let* ([pos (regexp-match-positions "\"[^\"]*\"" text)]
         [str (substring text (caar pos) (cdar pos))]
         [text1 (substring text 0 (caar pos))]
         [text2 (substring text (cdar pos))])
    (string-append text1
                   (regexp-infix-parts2* #rx"#{[^{}]+}" str "#{" (string-append "\"" " + (") "}" (string-append ") + " "\""))
                   text2)))


;;; Type alias
(def-active-token "alias " (str)
  (let ([keyword (regexp-match #px"\\w+\\b" str)]
        [toreplace (regexp-match #px"(?<== ?).+" (car (regexp-match #px"=[^;]+(?=;)" str)))]
        [restofstring (substring str (cdar (regexp-match-positions ";" str)))])
    (regexp-replace* (pregexp (string-append "\\b" (string-append (car keyword) "\\b"))) restofstring (car toreplace))))


;;; Generate Getters and Setters
(def-active-token "\\$SG " (str)
  (let* ([aux-string (car (regexp-match #px"[^;]+;" str))]
         [var-type (car (regexp-match #px"\\s*\\w+" aux-string))]
         [var-name (car (regexp-match #px"\\w+(?=\\s*=|;)" aux-string))]
         [setter (string-append "\tpublic void set" (regexp-replace #rx"^." var-name string-upcase) "(" var-type " aux){ this." var-name " = aux; }")]
         [getter (string-append "\tpublic get" (regexp-replace #rx"^." var-name string-upcase) "(){ return this." var-name "; }")]
         [return-value (string-append "private " aux-string "\n" setter "\n"getter)]
         )
    (regexp-replace aux-string str return-value)   
    ))

;;; Do-while for Python
(def-active-token "\\$WD\n" (str)
  (let* ([condi (car(regexp-match #px"(?<=while )[^:]+" str))]
         [indentation (car (regexp-match #px"(?<=:\n)[^\n]*(?!\\b|\\w)" str))]
         [body-begin (caar(regexp-match-positions #px"(?<=:\n)[^\n]*(?!\\b|\\w)" str))]
       
         ;[replace-loop (string-append)]
         [body-end (regexp-match-positions (pregexp (string-append "\n" indentation "(?=\\S)")) str)]
         [body (substring str body-begin (caar body-end))])
    (string-append "while True:\n" body "\n" indentation "\t if not " condi ":\n" indentation "\t\tbreak" (substring (cdar body-end)))))



(add-active-token ";;" string-after-newline)
(add-active-token #px"var(?=\\s+\\w+\\s*=\\s*new\\s+[^\\(]+\\()" local-type-inference)
(add-active-token #px"#(?=\\s*\"[^\"]*\")" string-interpolation)
(with-output-to-file "out.txt"
  (lambda () (display (process-string (file->string "in.txt")))))


