-- Animates the cursor as a short smear trail when it jumps, like Neovide does.

return {
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      -- Smear across buffer and window switches too, not just in-buffer moves.
      smear_between_buffers = true,
      -- Small horizontal and vertical moves (j/k, w/b) also leave a trail.
      smear_between_neighbor_lines = true,
      -- Draw with block characters so the trail stays smooth in fonts without
      -- legacy-computing glyphs.
      legacy_computing_symbols_support = false,
    },
  },
}
