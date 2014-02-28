--
-- This file was automatically generated by the husk scheme compiler (huskc)
--
--  http://justinethier.github.io/husk-scheme 
--  (c) 2010 Justin Ethier 
--  Version 3.16
--
module Main where 
import Language.Scheme.Core  
import Language.Scheme.Numerical  
import Language.Scheme.Primitives  
import Language.Scheme.Types     -- Scheme data types  
import Language.Scheme.Variables -- Scheme variable operations  
import Control.Monad.Error  
import Data.Array  
import  qualified Data.ByteString as BS  
import Data.Complex  
import  qualified Data.Map  
import Data.Ratio  
import Data.Word  
import System.IO  
import Debug.Trace
 
-- |Get variable at runtime 
getRTVar env var = do 
  v <- getVar env var 
  return $ case v of 
    List _ -> Pointer var env 
    DottedList _ _ -> Pointer var env 
    String _ -> Pointer var env 
    Vector _ -> Pointer var env 
    ByteVector _ -> Pointer var env 
    HashTable _ -> Pointer var env 
    _ -> v 
 
applyWrapper env cont (Nil _) (Just (a:as))  = do 
  apply cont a as 
 
applyWrapper env cont value (Just (a:as))  = do 
  apply cont a $ as ++ [value] 
 
getDataFileName' :: FilePath -> IO FilePath 
getDataFileName' name = return $ "/home/justin/.cabal/share/husk-scheme-3.16/" ++ name 
 
exec55_3 env cont _ _ = do 
  liftIO $ registerExtensions env getDataFileName' 
  continueEval env (makeCPSWArgs env cont exec []) (Nil "")
 
main :: IO () 
main = do 
  env <- r5rsEnv 
  result <- (runIOThrows $ liftM show $ hsInit env (makeNullContinuation env) (Nil "") Nothing) 
  case result of 
    Just errMsg -> putStrLn errMsg 
    _ -> return () 
 
hsInit env cont _ _ = do 
  _ <- defineVar env " modules " $ HashTable $ Data.Map.fromList [] 
  run env cont (Nil "") (Just [])
 
exec _ _ _ _ = return $ Nil ""

run :: Env -> LispVal -> LispVal -> Maybe [LispVal] -> IOThrowsError LispVal 
run env cont _ _  = do 
  result <- makeNormalHFunc env (["obj","alist"]) defineFuncEntryPt480 
  _ <- defineVar env "assv" result  
  (trace ("run") continueEval) env (makeCPSWArgs env cont f479 []) result
defineFuncEntryPt480 env cont value (Just args) = do 
  value <- getRTVar env "foldl"
  (trace ("defineFuncEntryPt480 " ++ (show value) ++ " " ++ (show args)) continueEval) env (makeCPSWArgs env (makeCPSWArgs env cont applyNextArg482 $ args ++ [value] ++ [Bool False]) applyFirstArg481 []) (Nil "") 
applyFirstArg481 env cont value (Just args) = do 
  value <- getRTVar env "mem-helper"
  (trace ("applyFirstArg481 " ++ (show value) ++ " " ++ (show args)) continueEval) env (makeCPSWArgs env (makeCPSWArgs env cont applyNextArg484 $ args ++ [value] ++ []) applyFirstArg483 []) (Nil "") 

applyFirstArg483 :: Env -> LispVal -> LispVal -> Maybe [LispVal] -> IOThrowsError LispVal 
applyFirstArg483 env cont _ _  = do 
  (trace ("applyFirstArg483 ") continueEval) env (makeCPSWArgs env (makeCPSWArgs env cont applyNextF486 []) applyStubF485 []) $ Nil""

applyStubF485 :: Env -> LispVal -> LispVal -> Maybe [LispVal] -> IOThrowsError LispVal 
applyStubF485 env cont _ _  = do 
  val <- getRTVar env "curry"
  (trace ("applyStubF485 ") continueEval) env cont val

applyNextF486 :: Env -> LispVal -> LispVal -> Maybe [LispVal] -> IOThrowsError LispVal 
applyNextF486 env cont value _  = do 
  v0 <- getRTVar env "eqv?" 
  v1 <- getRTVar env "obj" 
  (trace ("apply" ++ (show value) ++ (show "[]")) apply) cont value [v0,v1]
applyNextArg484 env cont value (Just args) = do 

  (trace ("applyNextArg484 " ++ (show value) ++ " " ++ (show args)) continueEval) env (makeCPSWArgs env (makeCPSWArgs env cont applyWrapper $ args ++ [value] ++ []) applyFirstArg487 []) (Nil "") 

applyFirstArg487 :: Env -> LispVal -> LispVal -> Maybe [LispVal] -> IOThrowsError LispVal 
applyFirstArg487 env cont value _  = do 
  val <- getRTVar env "car"
  (trace ("applyFirstArg487 " ++ (show value) ++ " " ++ (show "[]")) continueEval) env cont val
applyNextArg482 env cont value (Just args) = do 

  (trace ("applyNextArg482 " ++ (show value) ++ " " ++ (show args)) continueEval) env (makeCPSWArgs env (makeCPSWArgs env cont applyWrapper $ args ++ [value] ++ []) applyFirstArg488 []) (Nil "") 

applyFirstArg488 :: Env -> LispVal -> LispVal -> Maybe [LispVal] -> IOThrowsError LispVal 
applyFirstArg488 env cont value _  = do 
  val <- getRTVar env "alist"
  (trace ("applyFirstArg488 " ++ (show value) ++ " " ++ (show "[]")) continueEval) env cont val
f479 env cont value (Just args) = do 
  value <- getRTVar env "assv"
  (trace ("f479 " ++ (show value) ++ " " ++ (show args)) continueEval) env (makeCPSWArgs env (makeCPSWArgs env cont applyNextArg490 $ args ++ [value] ++ []) applyFirstArg489 []) (Nil "") 

applyFirstArg489 :: Env -> LispVal -> LispVal -> Maybe [LispVal] -> IOThrowsError LispVal 
applyFirstArg489 env cont value _  = do 
  x1 <-  return $ Atom "b" 
  (trace ("applyFirstArg489 " ++ (show value) ++ " " ++ (show "[]")) continueEval) env cont x1
applyNextArg490 env cont value (Just args) = do 

  (trace ("applyNextArg490 " ++ (show value) ++ " " ++ (show args)) continueEval) env (makeCPSWArgs env (makeCPSWArgs env cont applyWrapper $ args ++ [value] ++ []) applyFirstArg491 []) (Nil "") 

applyFirstArg491 :: Env -> LispVal -> LispVal -> Maybe [LispVal] -> IOThrowsError LispVal 
applyFirstArg491 env cont value _  = do 
  x1 <-  return $ List [List [Atom "a",Number (1)]] 
  (trace ("applyFirstArg491 " ++ (show value) ++ " " ++ (show "[]")) continueEval) env cont x1