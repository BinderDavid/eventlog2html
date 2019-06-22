{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE MultiWayIf #-}
module Data (generateJson) where

import Prelude hiding (print, readFile)
import Data.Aeson (Value, toJSON)
import Data.Tuple (swap)

import Args (Args(..), Sort(..))
import Bands (bands)
import qualified Events as E
import qualified HeapProf as H
import Prune (prune, cmpName, cmpSize, cmpStdDev)
import Total (total)
import Vega

generateJson :: FilePath -> Args -> IO (Value, Value)
generateJson file a = do
  let chunk = if heapProfile a then H.chunk else E.chunk
      cmp = fst $ reversing' sorting'
      sorting' = case sorting a of
        Name -> cmpName
        Size -> cmpSize
        StdDev -> cmpStdDev
      reversing' = if reversing a then swap else id
  (ph, fs, traces) <- chunk file
  let (h, totals) = total ph fs
  let keeps = prune cmp 0 (bound $ nBands a) totals
  let dataJson = toJSON (bandsToVega keeps (bands h keeps fs))
      dataTraces =  toJSON (tracesToVega traces)
  return (dataJson, dataTraces)

bound :: Int -> Int
bound n
  | n <= 0 = maxBound
  | otherwise = n
