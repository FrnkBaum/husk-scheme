{- TODO:
 -
 - large changes to how compile works.
 -
 - to make everything cleaner, it would be better if each HaskAst object generates its own
 - function header, instead of attempting to generate the header for the next expression.
 - This will require passing additional information around, including:
 -  - make of *this* function
 -  - whether to use value (?)
 -  - whether to use args (?)
 -
 - -}

{- |
Module      : Language.Scheme.Core
Copyright   : Justin Ethier
Licence     : MIT (see LICENSE in the distribution)

Maintainer  : github.com/justinethier
Stability   : experimental
Portability : portable

This module contains an experimental compiler of Scheme to Haskell 
-}

module Language.Scheme.Compiler where 
--import qualified Language.Scheme.Macro
import Language.Scheme.Numerical
import Language.Scheme.Parser
import Language.Scheme.Primitives
import Language.Scheme.Types
import Language.Scheme.Variables
import Control.Monad.Error
import qualified Data.List
import System.IO
import Debug.Trace

-- A type to store options passed to compile
-- eventually all of this might be able to be integrated into a Compile monad
data CompOpts = CompileOptions {
    coptsThisFunc :: String,
    coptsThisFuncUseValue :: Bool,
    coptsThisFuncUseArgs :: Bool,
    coptsNextFunc :: Maybe String
    }
--DefaultCompileOptions :: String -> CompileOpts 
defaultCompileOptions :: String -> CompOpts
defaultCompileOptions thisFunc = CompileOptions thisFunc False False Nothing

createAstFunc :: CompOpts -> [HaskAST] -> HaskAST 
createAstFunc (CompileOptions thisFunc useVal useArgs _) body = do
  let val = case useVal of
              True -> "value"
              _ -> "_"
      args = case useArgs of
               True -> "(Just args)"
               _ -> "_"
  AstFunction thisFunc (" env cont " ++ val ++ " " ++ args ++ " ") body

createAstCont (CompileOptions _ _ _ (Just nextFunc)) var = do
  AstValue $ "  continueEval env (makeCPS env cont " ++ nextFunc ++ ") " ++ var
createAstCont (CompileOptions _ _ _ Nothing) var = do
  AstValue $ "  continueEval env cont " ++ var

-- A very basic type to store a Haskell AST
-- The compiler performs the following transformations:
-- Scheme AST (LispVal) -> Haskell AST (HaskAST) -> Compiled Code (String)
data HaskAST = AstAssignM String HaskAST
  | AstFunction {astfName :: String,
--                 astfType :: String,
                 astfArgs :: String,
                 astfCode :: [HaskAST]
                } 
 | AstValue String
 | AstContinuation {astcNext :: String,
                    astcArgs :: String
                   }

showValAST :: HaskAST -> String
showValAST (AstAssignM var val) = "  " ++ var ++ " <- " ++ show val
showValAST (AstFunction name args code) = do
  let header = "\n" ++ name ++ args ++ " = do "
  let body = unwords . map (\x -> "\n" ++ x ) $ map showValAST code
  header ++ body 
showValAST (AstValue v) = v

-- TODO: this is too limiting, this is an 'internal' continuation. most should take a value and pass it along, not args
showValAST (AstContinuation nextFunc args) = "  continueEval env (makeCPSWArgs env cont " ++ nextFunc ++ " " ++ args ++ ") $ Nil \"\""

instance Show HaskAST where show = showValAST

header :: [String]
header = [
   "module Main where "
-- Currently not used: , "import Language.Scheme.Compiler.Helpers "
 , "import Language.Scheme.Core "
 , "import Language.Scheme.Numerical "
 , "import Language.Scheme.Primitives "
 , "import Language.Scheme.Types     -- Scheme data types "
 , "import Language.Scheme.Variables -- Scheme variable operations "
 , "import Control.Monad.Error "
 , "import System.IO "
 , " "
-- TODO: eventually these make func's will be moved out into their own module
 , ""
 , "--makeNormalFunc :: Env -> [LispVal] -> String -> IOThrowsError LispVal "
 , "makeHFunc ::"
 , "            (Monad m) =>"
 , "            Maybe String "
 , "         -> Env "
 , "         -> [String] "
 , "         -> (Env -> LispVal -> LispVal -> Maybe [LispVal] -> IOThrowsError LispVal) "
 , "--         -> String "
 , "         -> m LispVal"
 , "makeHFunc varargs env fparams fbody = return $ HFunc fparams varargs fbody env --(map showVal fparams) varargs fbody env"
 , "makeNormalHFunc :: (Monad m) =>"
 , "                  Env"
 , "               -> [String]"
 , "               -> (Env -> LispVal -> LispVal -> Maybe [LispVal] -> IOThrowsError LispVal)"
 , "--                -> String"
 , "               -> m LispVal"
 , "makeNormalHFunc = makeHFunc Nothing"
 , "{- TODO:"
 , "makeHVarargs :: (Monad m) => LispVal -> Env"
 , "                        -> [LispVal]"
 , "                        -> [LispVal]"
 , "                        -> m LispVal"
 , "makeHVarargs = makeFunc . Just . showVal"
 , "-}"
 , "main :: IO () "
 , "main = do "
 , "  env <- primitiveBindings "
 , "  (runIOThrows $ liftM show $ run env (makeNullContinuation env) (Nil \"\") Nothing) >>= putStr "
 , " "]
-- TODO: this is now obsolete, just pass func info to compile
-- , "run :: Env -> LispVal -> LispVal -> Maybe [LispVal] -> IOThrowsError LispVal "
-- , "run env cont _ _ = do "]

compileLisp :: Env -> String -> IOThrowsError LispVal
compileLisp env filename = do
  comp <- load filename >>= compileBlock "run" env []
  outH <- liftIO $ openFile "_tmp.hs" WriteMode
  _ <- liftIO $ writeList outH header
  _ <- liftIO $ writeList outH $ map show comp
  _ <- liftIO $ hClose outH
  return $ Nil "" -- Dummy value
{-  if not (null comp)
     then do
     else putStrLn "empty file"
-}

writeList outH (l : ls) = do
  hPutStrLn outH l
  writeList outH ls
writeList outH _ = do
  hPutStr outH ""

-- compileBlock - need to use explicit recursion to transform a block of code, because
--  later lines may depend on previous ones
compileBlock :: String -> Env -> [HaskAST] -> [LispVal] -> IOThrowsError [HaskAST]
compileBlock symThisFunc env result code@[c] = do
--  Atom symThisFunc <- _gensym "f"
  compiled <- compile env c $ defaultCompileOptions symThisFunc 
  return $ result ++ compiled
compileBlock symThisFunc env result code@(c:cs) = do
--  Atom symThisFunc <- _gensym "f"
  Atom symNextFunc <- _gensym "f"
  compiled <- compile env c $ CompileOptions symThisFunc False False (Just symNextFunc)
  compileBlock symNextFunc env (result ++ compiled) cs
compileBlock _ _ result [] = return result

-- TODO: could everything just be regular function calls except when a continuation is 'added to the stack' via a makeCPS(makeCPSWArgs ...) ?? I think this could be made more efficient

compile :: Env -> LispVal -> CompOpts -> IOThrowsError [HaskAST]
-- TODO: compile _ (Bool b) _ = return [AstValue $ "  return $ Bool " ++ (show b)]
compile _ (Number n) copts = do
  -- TODO: all scalars should be compiled like this
  f <- return $ AstAssignM "x1" $ AstValue $ "  return $ Number " ++ (show n)
  c <- return $ createAstCont copts "x1" --return $ AstValue $ "  continueEval env (makeCPS env cont " ++ nextFunc ++ ") x1"
  return [createAstFunc copts [f, c]] --, AstFunction nextFunc " env cont _ _ " []]
compile _ (Atom a) copts = do
  f <- return $ AstAssignM "x1" $ AstValue $ "  getVar env \"" ++ a ++ "\""
  c <- return $ createAstCont copts "x1"
  return [createAstFunc copts [f, c]]
-- TODO: compile env (List [Atom "quote", val]) = return [AstValue $ "  continueEval env cont -- TODO: how to get the literal val?

{-
compile env args@(List [Atom "if", predic, conseq, alt]) fForNextExpression = do
 -- TODO: think about it, these could probably be part of compileExpr
 Atom symPredicate <- _gensym "ifPredic"
 Atom symCheckPredicate <- _gensym "compiledIfPredicate"
 Atom symConsequence <- _gensym "compiledConsequence"
 Atom symAlternate <- _gensym "compiledAlternative"
 -- Entry point; ensure if is not rebound
 f <- return $ [AstValue $ "  bound <- liftIO $ isRecBound env \"if\"",
       AstValue $ "  if bound ",
       AstValue $ "     then throwError $ NotImplemented \"prepareApply env cont args\" ", -- if is bound to a variable in this scope; call into it
       AstValue $ "     else do " ++ symPredicate ++ " env (makeCPS env cont " ++ symCheckPredicate ++ ") (Nil \"\") [] "
       ]
 -- Compile expression for if's args
 compPredicate <- compileExpr env predic fForNextExpression symPredicate
 compConsequence <- compileExpr env conseq fForNextExpression symConsequence
 compAlternate <- compileExpr env alt fForNextExpression symAlternate
 -- Special case because we need to check the predicate's value
 compCheckPredicate <- return $ AstFunction symCheckPredicate " env cont result _ " [
    AstValue $ "  case result of ",
    AstValue $ "    Bool False -> " ++ symAlternate ++ " env cont (Nil \"\") [] ",
    AstValue $ "    _ -> " ++ symConsequence ++ " env cont (Nil \"\") [] "]
 -- Join compiled code together
 return $ f ++ [compPredicate, compCheckPredicate, compConsequence, compAlternate] 

compile env args@(List (Atom "lambda" : List fparams : fbody)) fForNextExpression = do
 Atom symCallfunc <- _gensym "lambdaFuncEntryPt"
 let compiledParams = "[]" -- TODO: just a temporary stopgap
-- TODO:  compiledParams <- return $ [] -- TODO: compile fparams

 compiledBody <- compileBlock env [] fbody

 -- Entry point; ensure var is not rebound
-- TODO: will probably end up creating a common function for this,
--       since it is almost the same as in "if"
 f <- return $ [AstValue $ "  bound <- liftIO $ isRecBound env \"lambda\"",
       AstValue $ "  if bound ",
       AstValue $ "     then throwError $ NotImplemented \"prepareApply env cont args\" ", -- if is bound to a variable in this scope; call into it
       AstValue $ "     else do result <- makeNormalHFunc env (" ++ compiledParams ++ ") " ++ symCallfunc,
       AstValue $ "             continueEval env cont result ",
       AstFunction symCallfunc " env cont _ _ " compiledBody
       ]
 return $ f
-}

compile env args@(List (_ : _)) copts = compileApply env args copts 

{-
-- Compile an intermediate expression (such as an arg to if) and 
-- call into the next continuation with it's value
compileExpr :: Env -> LispVal -> Maybe String -> String -> IOThrowsError HaskAST
compileExpr env expr fForNextExpr symThisFunc = do
 compiled <- compile env expr fForNextExpr
 case compiled of
   [comp] -> return $ AstFunction symThisFunc " env cont _ _ " 
                         [AstAssignM "x1" $ comp,
                          AstValue $ "  continueEval env cont x1 "]
   _ -> return $ AstFunction symThisFunc " env cont _ _ " compiled
-}

-- |Compiles each argument to a function call, and then uses apply to call the function
compileApply :: Env -> LispVal -> CompOpts -> IOThrowsError [HaskAST]
compileApply env args@(List (func : params)) copts@(CompileOptions coptsThis _ _ coptsNext) = do
  Atom stubFunc <- _gensym "applyStubF"
  Atom wrapperFunc <- _gensym "applyWrapper"
  Atom nextFunc <- _gensym "applyNextF"

  c <- return $ AstFunction coptsThis " env cont _ _ " [AstValue $ "  continueEval env (makeCPS env (makeCPS env cont " ++ wrapperFunc ++ ") " ++ stubFunc ++ ") $ Nil\"\""]  
  -- Use wrapper to pass high-order function (func) as an argument to apply
  wrapper <- return $ AstFunction wrapperFunc " env cont value _ " [AstValue $ "  continueEval env (makeCPSWArgs env cont " ++ nextFunc ++ " [value]) $ Nil \"\""]
  _comp <- compile env func $ CompileOptions stubFunc False False Nothing
-- TODO:  rest <- compileArgs nextFunc True params

  return $ [c, wrapper ] ++ _comp -- TODO: ++ rest
  {- TODO:
 where 
  -- TODO: this pattern may need to be extracted into a common place for use in other similar
  --       situations, such as params to a lambda expression
  compileArgs :: String -> Bool -> [LispVal] -> IOThrowsError [HaskAST]
  compileArgs thisFunc thisFuncUseValue args = do
    case args of
      [] -> do
           -- The basic idea is that if there is a next expression, call into it as a new continuation
           -- instead of calling into cont
           case coptsNext of
             Nothing -> return $ [
               AstFunction thisFunc 
                " env cont (Nil _) (Just (a:as)) " [AstValue "  apply cont a as "],
               AstFunction thisFunc 
                " env cont value (Just (a:as)) " [AstValue "  apply cont a $ as ++ [value] "]]
             Just fnextExpr -> return $ [
               AstFunction thisFunc 
                " env cont (Nil _) (Just (a:as)) " [AstValue $ "  apply (makeCPS env cont " ++ fnextExpr ++ ") a as "],
               AstFunction thisFunc 
                " env cont value (Just (a:as)) " [AstValue $ "  apply (makeCPS env cont " ++ fnextExpr ++ ") a $ as ++ [value] "],
               AstFunction fnextExpr " env cont _ _ " []]
      (a:as) -> do
        _comp <- compile env a Nothing
        -- Use this below to splice in a call to another function      
        case _comp of
          [comp] -> do
            let nfArgs = if thisFuncUseValue
                            then "(args ++ [value] ++ [x1])"
                            else "(args ++ [x1])"
            Atom nextFunc <- _gensym "f"
            rest <- compileArgs nextFunc False as 
            return $ [AstFunction thisFunc " env cont value (Just args) " 
                                  [AstAssignM "x1" $ comp,
                                   AstContinuation nextFunc nfArgs]
                     ] ++ rest
          code@(_ : _) -> do
            -- If another func is being called, we detect and splice it in...
            Atom stubFunc <- _gensym "f"
            Atom nextFunc <- _gensym "f"

            -- Flag below means that the expression's value matters, add it to args
            f <- if thisFuncUseValue
                    then return $ AstValue $ thisFunc ++ " env cont value (Just args) = do "
                    else return $ AstValue $ thisFunc ++ " env cont _ (Just args) = do "
            c <- if thisFuncUseValue
                    then return $ AstValue $ "  continueEval env (makeCPS env (makeCPSWArgs env cont " ++ nextFunc ++ " $ args ++ [value]) " ++ stubFunc ++ ") $ Nil\"\""  
                    else return $ AstValue $ "  continueEval env (makeCPS env (makeCPSWArgs env cont " ++ nextFunc ++ " args) " ++ stubFunc ++ ") $ Nil\"\""  

            -- True indicates nextFunc needs to use value arg passed into it
            rest <- compileArgs nextFunc True as
            return $ [ f, c, 
                       AstFunction stubFunc " env cont _ _ " []
                     ] ++ code ++ rest
-}
