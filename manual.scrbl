#lang scribble/manual
@(require planet/scribble
          scribble/eval
          (for-label (this-package-in main)
                     racket/base
                     racket/sequence))

@(define myeval (make-base-eval))
@(myeval '(require racket/sequence))
@(myeval '(require racket/list))

@title{python-tokenizer: a translation of Python's @tt{tokenize.py} library for Racket}
@author+email["Danny Yoo" "hashcollision.org"]

This is a fairly close translation of the
@link["http://hg.python.org/cpython/file/2.7/Lib/tokenize.py"]{@tt{tokenize.py}}
library from @link["http://python.org"]{Python}.

The main function, @racket[generate-tokens], consumes an input port
and produces a @tech{sequence} of tokens.

For example:

@interaction[#:eval myeval
(require (planet dyoo/python-tokenizer))
(define sample-input (open-input-string "def d22(a, b, c=2, d=2, *k): pass"))
(define tokens 
  (generate-tokens sample-input))
(for ([t tokens])
  (printf "~s ~s ~s ~s\n" (first t) (second t) (third t) (fourth t)))
]

@section{API}
@defmodule/this-package[main]

@defproc[(generate-tokens [inp input-port]) (sequenceof (list/c symbol? string? (list/c number? number?) (list/c number? number?) string?))]{
Consumes an input port and produces a sequence of tokens.

Each token is a 5-tuple consisting of:
@itemize[#:style 'ordered

@item{token-type: one of the following symbols: 
@racket['NAME], @racket['NUMBER], @racket['STRING],
@racket['OP], @racket['COMMENT], @racket['NL],
@racket['NEWLINE], @racket['DEDENT], @racket['INDENT],
@racket['ERRORTOKEN], or @racket['ENDMARKER].  The only difference between
@racket['NEWLINE] and @racket['NL] is that @racket['NEWLINE] will only occurs
if the indentation level is at @racket[0].}

@item{text: the string content of the token.}

@item{start-pos: the line and column as a list of two numbers}

@item{end-pos: the line and column as a list of two numbers}

@item{current-line: the current line that the tokenizer is on}
]


If a recoverable error occurs, @racket[generate-tokens] will produce
single-character tokens with the @racket['ERRORTOKEN] type until it
can recover.

Unrecoverable errors occurs when the tokenizer encounters @racket[eof]
in the middle of a multi-line string or statement, or if an
indentation level is inconsistent.  On an unrecoverable error, an
@racket[exn:fail:token] or @racket[exn:fail:indentation] error
will be raised.

}




@section{Translator Comments}

The translation is a fairly direct one; I wrote an
@link["https://github.com/dyoo/while-loop"]{auxiliary package} to deal
with the @racket[while] loops, which proved invaluable during the
translation of the code.  It may be instructive to compare the
@link["https://github.com/dyoo/python-tokenizer/blob/master/python-tokenizer.rkt"]{source}
here to that of
@link["http://hg.python.org/cpython/file/2.7/Lib/tokenize.py"]{tokenize.py}.


Here are some points I observed while doing the translation:

@itemize[

@item{Mutation is pervasive within the main loop of the tokenizer.
The main reason is because @racket[while] has no return type and
doesn't carry variables around, as opposed to Racket's preferred
iteration forms like @racket[for].  The code that uses @racket[while]
loops communicate values from one part of the code to the other
through mutation, often in wildly distant parts.}


@link{It's a little more easy to see what variables are intended to be
locally-scoped temporary variables in Racket because there's a
difference between @racket[define] and @racket[set!].  I've had to
induce which variables were intended to be temporaries, and hopefully
I haven't induced any errors along the way.}

@item{In some cases, Racket has finer-grained type distinctions than Python.
Python has no type to represent individual characters, and instead
uses a length-1 string.  In this translation, I've used characters
where I think they're appropriate.}

@item{Most uses of raw strings in Python can be translated to
uses of the
@link["http://docs.racket-lang.org/scribble/reader-internals.html#(mod-path._at-exp)"]{at-exp}
reader.}

@item{The @tt{in} operator in Python is heavily overloaded.  Its
expressivity makes it easy to write code with it.  On the flip side,
its flexibility makes it a little harder to know what it actually
means.}

@item{Regular expressions are slightly different, but on the whole
match well between the two languages.  Minor differences in the syntax
are potholes: Racket's regular expression matcher does not have an
implicit @emph{begin} anchor, and Racket's regexps are more sensitive
to escape characters.

One distinction is that Python includes a single match value that
supports different operators, whereas Racket requires the user to
select between getting the position of the match, with
@racket[regexp-match-positions], or getting the textual content with
@racket[regexp-match].  The Racket API, in this respect, is a little
harder to use because it requires this up-front choice.}


;; Comments and issues while translating the code:
;;
;; Racket considers characters different from length-1 strings, as a separate
;; character type.
;;
;; Regexps in Racket are different than in Python in a few particulars.
;; In character sets, particularly, control characters are significant
;; in Racket's regexp engine.
;;
;; Most uses of raw strings can be substituted with uses of the @-reader.
;; 
;; The 'in' operator in Python is extra-flexible.  It's hard to tell sometimes
;; what is being intended.
;;
;; Code that uses 'while' loops communicate values from one part of the code
;; to the other through mutation, often in wildly distant part of the code.
;;
;; variable declaration in Python is nonexistant, making it difficult to see
;; if some name is meant to be globally accessible within the tokenizer loop,
;; or is only for temporary use.  I've tried to determine where temporaries
;; are intended.
]