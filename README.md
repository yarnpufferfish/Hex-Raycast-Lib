# Hex-Raycast-Lib

This library is used for finding the hexagonal tiles that a ray passes through on a pointy-top axial hexagonal grid.
<img width="400" height="400" alt="SquareDemo" src="https://github.com/user-attachments/assets/f7e2b64a-7564-4c45-bbda-1068f101c43f" />

It also includes utilities for converting from cartesian coordinates to axial q,r coordinates.
This library includes drawing features compatable only with LOVE2D to draw the list of hexes.

When implementing raycasting, it is important to adjust the size of the grid.
This defines the minimum diameter of the hexagons. It's defined in raycast.lua as "size".

-- How to call hex.raycast()
hex = require("raycast")
-- then
hexes = hex.raycast(x1,y1.x2,y2,seen,max_iterations)

INPUT : x1,y1 (the start point of the ray)
        x2,y2 (the end point of the ray)
        seen (array of previously seen q,r hexes)
        max_iterations (max number of checks the raycast can do)

RETURNS : TABLE seen
            such that seen[q] = { [r] = true, ... }

RUNNING THE DEMO
Drag the Demo folder onto the love2d executable to open the folder and run the demo.
