module Codec.Archive.Monad ( handle
                           , ignore
                           , runArchiveM
                           -- * Bracketed resources within 'ArchiveM'
                           , withCStringArchiveM
                           , useAsCStringLenArchiveM
                           , ArchiveM
                           ) where

import           Codec.Archive.Types
import           Control.Monad          (void)
import           Control.Monad.Except   (ExceptT, runExceptT, throwError)
import           Control.Monad.IO.Class
import           Data.ByteString        (useAsCStringLen)
import qualified Data.ByteString        as BS
import           Foreign.C.String
import           Foreign.Marshal.Alloc  (allocaBytes)
import           Foreign.Ptr            (Ptr)

type ArchiveM = ExceptT ArchiveResult IO

-- for stuff we think isn't going to fail
ignore :: IO ArchiveError -> ArchiveM ()
ignore = void . liftIO

runArchiveM :: ArchiveM a -> IO (Either ArchiveResult a)
runArchiveM = runExceptT

handle :: IO ArchiveResult -> ArchiveM ()
handle act = do
    res <- liftIO act
    case res of
        ArchiveOk    -> pure ()
        ArchiveRetry -> pure ()
        x            -> throwError x

flipExceptIO :: IO (Either a b) -> ExceptT a IO b
flipExceptIO act = do
    res <- liftIO act
    case res of
        Right x -> pure x
        Left y  -> throwError y

genBracket :: (a -> (b -> IO (Either c d)) -> IO (Either c d)) -- ^ Function like 'withCString' we are trying to life
           -> a -- ^ Fed to @b@
           -> (b -> ExceptT c IO d) -- ^ Actual action
           -> ExceptT c IO d
genBracket f x = flipExceptIO . f x . (runExceptT .)

allocaBytesArchiveM :: Int -> (Ptr a -> ExceptT b IO c) -> ExceptT b IO c
allocaBytesArchiveM = genBracket allocaBytes

withCStringArchiveM :: String -> (CString -> ExceptT a IO b) -> ExceptT a IO b
withCStringArchiveM = genBracket withCString

useAsCStringLenArchiveM :: BS.ByteString -> (CStringLen -> ExceptT a IO b) -> ExceptT a IO b
useAsCStringLenArchiveM = genBracket useAsCStringLen