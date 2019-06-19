--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll

import           Control.Applicative
import           Control.Monad
import           Data.List           (delete)
import           Data.List.Split
import           Data.Maybe
import           System.Directory    (createDirectoryIfMissing, doesFileExist, removeFile, renameFile)
import           System.Exit         (ExitCode (..))
import           System.FilePath     ((<.>), (</>), pathSeparator)
import           System.IO           (hPutStrLn, stderr)
import           System.Process
import           Text.Pandoc.Generic
import           Text.Pandoc.JSON
import           Data
import           Args
import           VegaTemplate
import           HtmlTemplate
import           Text.Blaze.Html.Renderer.String
import           Options.Applicative

--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match (fromList ["about.rst", "contact.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "index.md" $ do
        route $ setExtension "html"
        compile $ pandocCompilerWithTransformM defaultHakyllReaderOptions defaultHakyllWriterOptions eventlogTransformer
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler

eventlogTransformer :: Pandoc -> Compiler Pandoc
eventlogTransformer pandoc = unsafeCompiler $ renderEventlog pandoc


data Echo = Above | Below
   deriving (Read, Show)

renderEventlog :: Pandoc -> IO Pandoc
renderEventlog p = bottomUpM insertEventlogs p

insertEventlogs :: Block -> IO Block
insertEventlogs block@(CodeBlock (ident, classes, attrs) code) | "eventlog" `elem` classes = do
   let file = case lookup "file" attrs of
                Just fn -> fn
                Nothing -> error "Missing filepath"
   d <- drawEventlog file
   return (RawBlock (Format "html") d)
insertEventlogs block = print block >> return block

drawEventlog :: FilePath -> IO String
drawEventlog fp = do
  as <- handleParseResult (execParserPure defaultPrefs argsInfo [fp])
  dat <- generateJson fp as
  return $ renderHtml $ renderChart dat vegaJsonText

