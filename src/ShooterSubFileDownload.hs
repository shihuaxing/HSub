module ShooterSubFileDownload
    ( downloadSubFiles
    ) where

import ShooterSubQueryResult
import Network.URL
import Network.URI
import Network.HTTP
import Network.HTTP.Headers
import Network.Stream
import Data.List
import System.IO
import Control.Monad
import Data.Maybe
import System.FilePath.Posix
import qualified Data.ByteString as DB

httpsString = "https://"

replaceHttpsWithHttp :: String -> String
replaceHttpsWithHttp s = case stripPrefix httpsString s of Just xs -> "http://" ++ xs
                                                           Nothing -> s

collectSubFiles :: [SubQueryResult] -> [SubFile]
collectSubFiles r = r >>= files

getFileName :: Response ty -> Maybe String
getFileName = stripPrefix "attachment; filename=" <=< findHeader (HdrCustom "Content-Disposition")

addFileIndexToFileName :: Int -> FilePath -> FilePath
addFileIndexToFileName idx p = dropExtension p ++ "_" ++ show idx ++ takeExtension p

saveResponseAsFile :: String -> Int ->  Response DB.ByteString -> IO ()
saveResponseAsFile dfp idx rsp = do
   let fn = fromMaybe dfp $  (dropFileName dfp </>) . addFileIndexToFileName idx <$> getFileName rsp
   DB.writeFile fn $ rspBody rsp
   putStrLn $ "Downloaded sub file: " ++ takeFileName fn

downloadSubFile :: String -> Int -> SubFile -> IO ()
downloadSubFile mfp idx f =  do
   responseResult <- (simpleHTTP . defaultGETRequest_ . fromJust . parseURI . replaceHttpsWithHttp .link) f :: IO (Result (Response DB.ByteString))
   let defaultFilePath = dropExtension mfp ++ "." ++ ext f
   case responseResult of Right rsp -> saveResponseAsFile defaultFilePath idx rsp
                          Left error -> putStrLn $ "Error downloading sub file: " ++ takeFileName defaultFilePath ++ "error: " ++ show error


downloadSubFiles :: String -> [SubQueryResult] -> IO ()
downloadSubFiles dfn qrs = do
         let subfiles = collectSubFiles qrs
         putStrLn $ "Matched " ++ (show . length) subfiles ++ " subtitles on server"
         putStrLn "downloading subtitle files..."
         mapM_ (uncurry $ downloadSubFile dfn) (zip [0,1..] subfiles)
