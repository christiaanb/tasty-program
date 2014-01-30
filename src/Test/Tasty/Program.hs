{-# LANGUAGE DeriveDataTypeable #-}

module Test.Tasty.Program (
   testProgram
 ) where

import Data.Typeable        ( Typeable                              )
import System.Directory     ( findExecutable                        )
import System.Exit          ( ExitCode(..)                          )
import System.Process       ( runInteractiveProcess, waitForProcess )
import Test.Tasty.Providers ( IsTest (..), Result(..), TestName,
                              TestTree, singleTest                  )

data TestProgram = TestProgram String [String] (Maybe FilePath)
     deriving (Typeable)

-- | Create test that will run a program with given options
testProgram :: TestName        -- ^ Test name
            -> String          -- ^ Program name
            -> [String]        -- ^ Program options
            -> Maybe FilePath  -- ^ Optional working directory
            -> TestTree
testProgram testName program opts workingDir =
    singleTest testName (TestProgram program opts workingDir)

instance IsTest TestProgram where
  run _ (TestProgram program opts workingDir) _ = do
    execFound <- findExecutable program
    case execFound of
      Nothing       -> return $ execNotFoundFailure program
      Just progPath -> runProgram progPath opts workingDir

  testOptions = return []

-- | Run a program with given options and optional working directory.
-- Return success if program exits with success code.
runProgram :: String          -- ^ Program name
           -> [String]        -- ^ Program options
           -> Maybe FilePath  -- ^ Optional working directory
           -> IO Result
runProgram program opts workingDir = do
  (_, _, _, pid) <- runInteractiveProcess program opts workingDir Nothing
  ecode <- waitForProcess pid
  case ecode of
    ExitSuccess      -> return success
    ExitFailure code -> return $ exitFailure program code

-- | Indicates successful test
success :: Result
success = Result True ""

-- | Indicates that program does not exist in the path
execNotFoundFailure :: String -> Result
execNotFoundFailure file = Result
  { resultSuccessful  = False
  , resultDescription = "Cannot locate program " ++ file ++ " in the PATH"
  }

-- | Indicates that program failed with an error code
exitFailure :: String -> Int -> Result
exitFailure file code = Result
  { resultSuccessful  = False
  , resultDescription = "Program " ++ file ++ " failed with code " ++ show code
  }
