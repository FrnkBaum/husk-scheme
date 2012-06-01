-- Testing integration with Text.JSON

module Language.Scheme.Plugins.Json where 

import Control.Monad.Error
import Data.Array
import Data.Ratio
import Text.JSON
import Text.JSON.Generic
import qualified Language.Scheme.Numerical
import Language.Scheme.Types

-- ideas from http://therning.org/magnus/archives/719
instance JSON LispVal where
  showJSON (List []) = JSNull
  showJSON (String s) = JSString $ toJSString s
  showJSON (Atom s) = JSString $ toJSString s
  showJSON (Bool b) = JSBool b
  showJSON (Number n) = JSRational True $ fromInteger n 
  showJSON (Float n) = JSRational False $ toRational n 
  showJSON (List l) = showJSONs l
  showJSON (Vector v) = do
    let ls = elems v
        f (List [Atom x, y]) = do
            (x, showJSON y)
    -- Take ls as an association list
    -- The alist is then changed into the form [(String, x)]
    -- and packaged into a JSObject
    JSObject $ toJSObject $ map f ls
  showJSON a = JSNull -- TODO (?): fail $ "Unable to convert to JSON: " ++ show a

  readJSON (JSNull) = return $ List []
  readJSON (JSString str) = return $ String $ fromJSString str
  readJSON (JSBool b) = return $ Bool b
  readJSON (JSRational _ num) = do
    let numer = numerator num
    let denom = denominator num
    case (numer >= denom) && ((mod numer denom) == 0) of
        True -> return $ Number $ numerator num
        _ -> return $ Float $ fromRational num
  readJSON (JSArray a) = do
    result <- mapM readJSON a
    return $ List $ result
  readJSON (JSObject o) = do
    let f (x,y) = do 
        y' <- readJSON y
        return $ List [Atom x, y']

    ls <- mapM f (fromJSObject o)
    return $ Vector $ (listArray (0, length ls - 1)) ls

-- |Wrapper for Text.JSON.decode
jsDecode, 
  -- |Wrapper for Text.JSON.decodeStrict
  jsDecodeStrict :: [LispVal] -> IOThrowsError LispVal
jsDecode [String json] = do
    let r = decode json :: Result LispVal
    case r of
        Ok result -> return result
        Error msg -> throwError $ Default msg
jsDecode invalid = throwError $ TypeMismatch "string" $ List invalid
jsDecodeStrict [String json] = do
    let r = decodeStrict json :: Result LispVal
    case r of
        Ok result -> return result
        Error msg -> throwError $ Default msg
jsDecodeStrict invalid = jsDecode invalid

-- |Wrapper for Text.JSON.encode
jsEncode, 
  -- |Wrapper for Text.JSON.encodeStrict
  jsEncodeStrict :: [LispVal] -> IOThrowsError LispVal
jsEncode [val] = return $ String $ encode val
jsEncodeStrict [val] = return $ String $ encodeStrict val

_test :: IO ()
_test = do
    _testDecodeEncode "\"test\""
    _testDecodeEncode "true"
    _testDecodeEncode "null"
    _testDecodeEncode "1"
    _testDecodeEncode "1.5"
    _testDecodeEncode "[1.1, 2, 3, 1.5]"
    _testDecodeEncode "[1.1, 2, {\"a\": 3}, 1.5]"

_testDecodeEncode :: String -> IO ()
_testDecodeEncode str = do
    let x = decode  str :: Result LispVal
    case x of
        Ok x -> putStrLn $ encode x
        Error msg -> putStrLn $ "An error occurred: " ++ msg

