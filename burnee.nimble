# Package

version       = "0.1.0"
author        = "IDF31"
description   = "Daemon to return html responses out of gemini files"
license       = "MIT"
srcDir        = "src"
bin           = @["burnee"]


# Dependencies

requires "nim >= 1.4.4", "karax"
