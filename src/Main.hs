module Main where

import Data.Map           (Map)
import Data.Maybe         (fromMaybe)
import Data.Monoid        (All, Endo)
import System.Environment (lookupEnv)

import Data.Map                            qualified as Map
import XMonad qualified
import XMonad                              (Choose (..), Event, Full (..), Mirror (..), Query, WindowSet, X, XConfig,
                                            (.|.), (|||))
import XMonad.Actions.Navigation2D         qualified as Navigation2D
import XMonad.Core                         qualified as Core
import XMonad.Hooks.EwmhDesktops           qualified as Hooks
import XMonad.Hooks.InsertPosition         qualified as InsertPosition
import XMonad.Hooks.ManageDocks            qualified as ManageDocks
import XMonad.Hooks.ManageHelpers          qualified as ManageHelpers
import XMonad.Hooks.Place                  qualified as Place
import XMonad.Layout.LayoutHints           as LayoutHints
import XMonad.Layout.LayoutModifier        (ModifiedLayout)
import XMonad.Layout.ResizableThreeColumns (ResizableThreeCol (..))
import XMonad.Layout.ResizableTile         (MirrorResize (MirrorExpand, MirrorShrink), ResizableTall (..))
import XMonad.Main                         qualified as Main
import XMonad.Operations                   qualified as Operations
-- import XMonad.Layout.ThreeColumns (ThreeCol(ThreeColMid, ThreeCol, threeColFrac, threeColDelta, threeColNMaster))
import XMonad.ManageHook ((-->), (=?))
import XMonad.StackSet   qualified as StackSet

data Keybind = MkKeyBind
  { mask   :: XMonad.KeyMask
  , sym    :: XMonad.KeySym
  , action :: X ()
  }

keys :: XConfig XMonad.Layout -> Map (XMonad.KeyMask, XMonad.KeySym) (X ())
keys config = Map.fromList $ map (\ key -> ((key.mask, key.sym), key.action)) $
  [ MkKeyBind
      do config.modMask
      do XMonad.xK_q
      do Operations.restart "xmonad-config" True

  , MkKeyBind
      do config.modMask
      do XMonad.xK_b
      do XMonad.sendMessage ManageDocks.ToggleStruts

  , MkKeyBind
      do config.modMask .|. XMonad.shiftMask
      do XMonad.xK_c
      do XMonad.kill

  , MkKeyBind
      do config.modMask
      do XMonad.xK_n
      do XMonad.spawn config.terminal

  , MkKeyBind
      do config.modMask
      do XMonad.xK_space
      do XMonad.sendMessage XMonad.NextLayout

  , MkKeyBind
      do config.modMask .|. XMonad.shiftMask
      do XMonad.xK_space
      do XMonad.setLayout config.layoutHook

  , MkKeyBind
      do config.modMask
      do XMonad.xK_r
      do XMonad.refresh

  , MkKeyBind
      do config.modMask
      do XMonad.xK_Tab
      do XMonad.windows StackSet.focusDown

  , MkKeyBind
      do config.modMask .|. XMonad.shiftMask
      do XMonad.xK_Tab
      do XMonad.windows StackSet.focusUp

  , MkKeyBind
      do config.modMask
      do XMonad.xK_m
      do XMonad.windows StackSet.focusMaster

  , MkKeyBind
      do config.modMask
      do XMonad.xK_Return
      do XMonad.windows StackSet.swapMaster

  , MkKeyBind
      do config.modMask
      do XMonad.xK_u
      do XMonad.sendMessage XMonad.Shrink

  , MkKeyBind
      do config.modMask
      do XMonad.xK_i
      do XMonad.sendMessage XMonad.Expand

  , MkKeyBind
      do config.modMask .|. XMonad.shiftMask
      do XMonad.xK_u
      do XMonad.sendMessage MirrorShrink

  , MkKeyBind
      do config.modMask .|. XMonad.shiftMask
      do XMonad.xK_i
      do XMonad.sendMessage MirrorExpand

  , MkKeyBind
      do config.modMask
      do XMonad.xK_t
      do XMonad.withFocused $ XMonad.windows . StackSet.sink

  , MkKeyBind
      do config.modMask
      do XMonad.xK_comma
      do XMonad.sendMessage (XMonad.IncMasterN 1)

  , MkKeyBind
      do config.modMask
      do XMonad.xK_period
      do XMonad.sendMessage (XMonad.IncMasterN -1)

  , MkKeyBind
      do config.modMask
      do XMonad.xK_h
      do Navigation2D.windowGo Navigation2D.L False

  , MkKeyBind
      do config.modMask
      do XMonad.xK_j
      do Navigation2D.windowGo Navigation2D.D False

  , MkKeyBind
      do config.modMask
      do XMonad.xK_k
      do Navigation2D.windowGo Navigation2D.U False

  , MkKeyBind
      do config.modMask
      do XMonad.xK_l
      do Navigation2D.windowGo Navigation2D.R False

  , MkKeyBind
      do config.modMask .|. XMonad.shiftMask
      do XMonad.xK_h
      do Navigation2D.windowSwap Navigation2D.L False

  , MkKeyBind
      do config.modMask .|. XMonad.shiftMask
      do XMonad.xK_j
      do Navigation2D.windowSwap Navigation2D.D False

  , MkKeyBind
      do config.modMask .|. XMonad.shiftMask
      do XMonad.xK_k
      do Navigation2D.windowSwap Navigation2D.U False

  , MkKeyBind
      do config.modMask .|. XMonad.shiftMask
      do XMonad.xK_l
      do Navigation2D.windowSwap Navigation2D.R False
  ] ++

  [ MkKeyBind
      do config.modMask .|. mask
      do key
      do XMonad.windows (f workspace)
  | (workspace, key) <- zip config.workspaces [XMonad.xK_1 .. XMonad.xK_9]
  , (f, mask) <- [(StackSet.greedyView, 0), (StackSet.shift, XMonad.shiftMask)]
  ] ++

  [ MkKeyBind
      do config.modMask .|. mask
      do key
      do XMonad.screenWorkspace screen >>= flip XMonad.whenJust (XMonad.windows . f)
  | (key, screen) <- zip [XMonad.xK_w, XMonad.xK_e, XMonad.xK_r] [0..]
  , (f, mask) <- [(StackSet.view, 0), (StackSet.shift, XMonad.shiftMask)]
  ]

smartInsert :: Query (Endo WindowSet)
smartInsert = XMonad.willFloat >>= \float ->
  InsertPosition.insertPosition
    do if float then InsertPosition.Master else InsertPosition.End
    do InsertPosition.Newer

manageHook :: Query (Endo WindowSet)
manageHook = XMonad.composeAll
 [ smartInsert
 , Place.placeHook $ Place.smart (1/2, 1/2)
 , ManageHelpers.isDialog --> XMonad.doFloat
 , XMonad.className =? "Vulkan" --> XMonad.doFloat
 , XMonad.className =? "Com.cisco.secureclient.gui" --> XMonad.doShift "9"
 , XMonad.className =? "Slack" --> XMonad.doShift "9"
 ]

handleEventHook :: Event -> X All
handleEventHook = LayoutHints.hintsEventHook

type Layout = Choose ResizableTall (Choose (Mirror ResizableTall) (Choose ResizableThreeCol Full))

layout :: Layout a
layout = tiled ||| Mirror tiled ||| threeCol ||| Full
  where
  tiled = ResizableTall 1 (3 / 100) (1 / 2) []

  threeCol = ResizableThreeColMid
    { threeColNMaster= 1
    , threeColDelta = 3 / 100
    , threeColFrac=1 / 2
    , threeColSlaves = []
    }

type LayoutModifier a =
  ModifiedLayout LayoutHints.LayoutHintsToCenter
    (ModifiedLayout ManageDocks.AvoidStruts a)

layoutModifier ::
  XMonad.LayoutClass l a =>
  l a ->
  LayoutModifier l a
layoutModifier = LayoutHints.layoutHintsToCenter . ManageDocks.avoidStruts

config :: XConfig (LayoutModifier Layout)
config = XMonad.def
  { XMonad.workspaces         = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
  , XMonad.modMask            = XMonad.mod4Mask
  , XMonad.focusFollowsMouse  = False
  , XMonad.keys               = keys
  , XMonad.layoutHook         = layoutModifier layout
  , XMonad.focusedBorderColor = "#5E81AC"
  , XMonad.normalBorderColor  = "#000000" -- "#eeeeee"
  , XMonad.manageHook         = manageHook
  , XMonad.handleEventHook    = handleEventHook
  , XMonad.borderWidth        = 0
  }

navigationConfig :: Navigation2D.Navigation2DConfig
navigationConfig = Navigation2D.def
  { Navigation2D.layoutNavigation   = [("Full", Navigation2D.centerNavigation)]
  , Navigation2D.unmappedWindowRect = [("Full", Navigation2D.singleWindowRect)]
  }

main :: IO ()
main = do
  terminalCommand <- fromMaybe "ghostty" <$> lookupEnv "XDG_TERMINAL"
  directories <- Core.getDirectories

  Main.launch
    ( Navigation2D.withNavigation2DConfig navigationConfig
    $ Hooks.ewmhFullscreen
    $ Hooks.ewmh
    $ ManageDocks.docks
    $ config { XMonad.terminal = terminalCommand }
    )
    directories
