import Data.Functor ((<$>))
import Data.Char (isSpace, isAscii)
import Data.Maybe (fromMaybe)
import Data.List (intersperse)
import System.Environment (getArgs)

type Column = Int

-- Given a string, finds the position of the last space, if any
findBreakPoint :: String -> Maybe Column
findBreakPoint line = findBreakPoint' line 0
    where
        findBreakPoint' (c:cs) n
            -- if there's no later point we produce (n + 1), not n
            -- That's because we need to insert a newline AFTER the space, not
            -- prior to it.
            | isSpace c = Just $ fromMaybe (n + 1) $ findBreakPoint' cs (n + 1)
            | otherwise = findBreakPoint' cs (n + 1)
        findBreakPoint' [] n = Nothing

-- Given a maximum length and a string of many lines, breaks overly-long lines
-- into ones which are less than the maximum length.
-- FIXME: TODO: Intelligent character counting. If we see a \BS, say, 
-- then we shouldn't consider it like an ordinary character.
wrap :: Column -> String -> String
wrap cols str = concat $ intersperse "\n" $ wrap' $ lines str
    where
        wrap' (line:lines)
            | length line <= cols   = line : (wrap' lines)
            | otherwise             = line1 : (wrap' (line2 : lines))
                where
                    -- if we can find no break point, just break it at max len
                    lineEnd = fromMaybe cols $ findBreakPoint (take cols line)
                    (line1, line2) = splitAt lineEnd line
        wrap' [] = []

data Node = Char Char
    | Bold NodeString
    | Underline NodeString
    deriving Show
type NodeString = [Node]

-- parse BBCode string into internal representation
parseBBCode :: String -> NodeString
parseBBCode ('[':'b':']':cs) = (Bold $ parseBBCode content) : parseBBCode rem
    where
        findEndTag ('[':'/':'b':']':cs) = ("", cs)
        findEndTag (c:cs)   = (c : innerContent, innerRem)
            where (innerContent, innerRem) = findEndTag cs
        findEndTag []       = error "Missing end tag for [b]"
        (content, rem) = findEndTag cs
parseBBCode ('[':'u':']':cs) = (Underline $ parseBBCode content) : parseBBCode rem
    where
        findEndTag ('[':'/':'u':']':cs) = ("", cs)
        findEndTag (c:cs)   = (c : innerContent, innerRem)
            where (innerContent, innerRem) = findEndTag cs
        findEndTag []       = error "Missing end tag for [u]"
        (content, rem) = findEndTag cs
parseBBCode (c:cs)  = Char c : parseBBCode cs
parseBBCode []      = []

-- spit out internal representation as BBCode again
-- (only really useful for debugging)
unparseBBCode :: NodeString -> String
unparseBBCode nodes = concatMap unparseNode nodes
    where
        unparseNode (Char c)            = [c]
        unparseNode (Bold content)      = "[b]" ++ unparseBBCode content ++ "[/b]"
        unparseNode (Underline content) = "[u]" ++ unparseBBCode content ++ "[/u]"

-- produce Diablo 630 control codes for formatting
toDiablo :: NodeString -> String
toDiablo nodes = concatMap devilNode nodes
    where
        devilNode (Char c)              = [c]
        devilNode (Bold content)        = "\ESCO" ++ toDiablo content ++ "\ESC&"
        devilNode (Underline content)   = "\ESCE" ++ toDiablo content ++ "\ESCR"

-- replace characters with Diablo 630 encoded versions
escape :: String -> String
-- a plain LF won't move print head back to line start, we need CR for that
escape ('\n':cs)    = '\r' : '\n' : escape cs
-- The Royal LetterMaster has a special escape sequence for the cent symbol
escape ('¢':cs)     = '\ESC' : 'Y' : ' ' : escape cs
-- On the Royal LetterMaster, the { and } ASCII chars are missing!
-- In their place, there's ¼ (quarter) and ½ (half) instead, for some reason.
-- So, we'll replace Unicode ¼ and ½ with what would be { and } in ASCII here,
-- so we're not wasting those glyphs on the LetterMaster printwheel.
escape ('¼':cs)     = '{' : escape cs
escape ('½':cs)     = '}' : escape cs
-- What if we need to print a document that uses { and }, though? Well, the
-- LetterMaster doesn't have any direct support. So we'll fudge it.
-- If we overstrike a ( with a [ and a -, it'll vaguely resemble a {, hopefully.
-- Overstriking is achieved with ASCII BS (\x08), backspace.
escape ('{':cs)     = '(' : '\BS' : '[' : '\BS' : '-' : escape cs
escape ('}':cs)     = ')' : '\BS' : ']' : '\BS' : '-' : escape cs
escape (c:cs)
    | isAscii c     = c : escape cs
-- The LetterMaster only supports ASCII, so we'll error for other characters.
-- (I could silently replace with ? or something, but implicit mangling of
-- input is far from user-friendly.)
    | otherwise     = error $ "Cannot translate non-ASCII character '" ++ c : "' to ASCII, an escape sequence, or an overstriking sequence. You will need to replace this character with one supported by BBCode630."
escape []           = []

showHelp :: IO ()
showHelp = mapM_ putStrLn [
        "Usage:"
      , "    Diablo630 <cols>"
      , "Processes BBCode from standard input, writes formatted text to standard output"
      , "Where <cols> is the number of columns to wrap to in the output, e.g.:"
      , " - 80 columns/line at 1/10\" (2.54mm) for a 6.6 inch print line width"
      , " - 66 columns/line at 1/12\" (2.12mm) for a 6.6 inch print line width"
    ]

magick :: Int -> IO ()
magick cs = do
    uncleanScroll <- getContents
    let dissectedScroll = parseBBCode uncleanScroll
    let bedeviledScroll = toDiablo dissectedScroll
    let wordbrokeScroll = wrap cs bedeviledScroll
    let completedScroll = escape wordbrokeScroll
    putStr completedScroll

main :: IO ()
main = do
    args <- getArgs
    case args of
        []          -> showHelp
        ["--help"]  -> showHelp
        _:_:_       -> (putStrLn "Too many arguments specified.") >> showHelp
        [colsText]  -> magick (read colsText :: Int)
