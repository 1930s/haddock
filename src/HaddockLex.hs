--
-- Haddock - A Haskell Documentation Tool
--
-- (c) Simon Marlow 2002
--

module HaddockLex ( 
	Token(..), 
	tokenise 
 ) where

import Char

special = '`' : '\'' : '\"' : '@' : []

data Token
  = TokPara
  | TokNumber
  | TokBullet
  | TokSpecial Char
  | TokString String
  | TokURL String
  | TokBirdTrack
  deriving Show

-- simple finite-state machine for tokenising the doc string

tokenise :: String -> [Token]
tokenise "" = []
tokenise str = case str of
  '<':cs  -> tokenise_url cs
  '\n':cs -> tokenise_newline cs
  c:cs | c `elem` special -> TokSpecial c : tokenise cs
  _other  -> tokenise_string "" str

tokenise_url cs =
  let (url,rest) = break (=='>') cs in
  TokURL url : case rest of
		 '>':rest -> tokenise rest
		 _ -> tokenise rest

tokenise_newline cs =
 case dropWhile nonNewlineSpace cs of
   '\n':cs -> TokPara : tokenise_para cs -- paragraph break
   '>':cs  -> TokBirdTrack : tokenise cs -- bird track
   _other  -> tokenise_string "\n" cs

tokenise_para cs =
  case dropWhile nonNewlineSpace cs of   
	-- bullet:  '*'
   '*':cs  -> TokBullet  : tokenise cs
	-- bullet: '-'
   '-':cs  -> TokBullet  : tokenise cs
	-- enumerated item: '1.'
   '>':cs  -> TokBirdTrack : tokenise cs
	-- bird track
   str | (ds,'.':cs) <- span isDigit str, not (null ds)
		-> TokNumber : tokenise cs
	-- enumerated item: '(1)'
   '(':cs | (ds,')':cs') <- span isDigit cs, not (null ds)
		-> TokNumber : tokenise cs'
   other -> tokenise cs

nonNewlineSpace c = isSpace c && c /= '\n'

tokenise_string str cs = 
  case cs of
    [] -> [TokString (reverse str)]
    '\\':c:cs -> tokenise_string (c:str) cs
    '\n':cs   -> tokenise_string_newline str cs
    c:cs | c == '<' || c `elem` special
		-> TokString (reverse str) : tokenise (c:cs)
         | otherwise
	        -> tokenise_string (c:str) cs

tokenise_string_newline str cs =
  case dropWhile nonNewlineSpace cs  of
   '\n':cs -> TokString (reverse str) : TokPara : tokenise_para cs
   '>':cs  -> TokString (reverse ('\n':str)) : TokBirdTrack : tokenise cs
		 -- bird track
   _other  -> tokenise_string ('\n':str) cs  -- don't throw away whitespace

