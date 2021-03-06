module Main where

import System.Environment
import ShooterFileHash
import ShooterSubQuery
import ShooterSubFileDownload
import Control.Monad
import System.FilePath.Posix
import Data.Char

mediaFileExtensions = [".mkv", ".mp4", ".avi"]

lowercase :: String -> String
lowercase = map toLower

isMediaFile :: FilePath -> Bool
isMediaFile fp = elem (lowercase $ takeExtension fp) mediaFileExtensions

downloadSubFilesForMediaFile :: FilePath -> IO ()
downloadSubFilesForMediaFile fp = do
   putStrLn $ "Start to retrieve subtitles for media file: " ++ takeFileName fp
   hashString <- fileHash fp
   rets <- requestSubResult hashString fp
   case rets of Right queryResults -> downloadSubFiles fp queryResults
                Left errorMessage -> putStrLn errorMessage

downloadSubFilesForFile :: FilePath -> IO ()
downloadSubFilesForFile fp = if isMediaFile fp then downloadSubFilesForMediaFile fp
                                               else putStrLn "Skip downloading non-media files"


main = do
   paths <- getArgs
   if null paths then putStrLn "No input media files"
                  else mapM_ downloadSubFilesForMediaFile paths
