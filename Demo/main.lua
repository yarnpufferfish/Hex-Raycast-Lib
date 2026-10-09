-- demo for raycast library

--- Taj Clark
--- Oct 8, 2026

local hex = require("raycast")
local x1,y1,x2,y2 = nil,nil,nil,nil
local hexes = {}

-- UPDATE
function love.update(dt)
    -- creates raycast between center of screen and mouse pointer
    x1 = love.graphics.getWidth() * 0.5
    y1 = love.graphics.getHeight() * 0.5
    x2,y2 = love.mouse.getPosition()

    -- returns the list of found hexes
    hexes = hex.raycast(x1,y1,x2,y2)
end

-- DRAW
function love.draw()
    -- reset the graphics
    love.graphics.clear({1,1,1,1})
    x1 = love.graphics.getWidth() * 0.5
    y1 = love.graphics.getHeight() * 0.5
    x2,y2 = love.mouse.getPosition()
    
    -- draw hexes
    love.graphics.setColor({0.4,0.4,0.4,1})
    hex.draw_buffer(hexes)

    -- draw line
    love.graphics.setColor({0,0,0,1})
    love.graphics.line(x1,y1,x2,y2)

    -- draw end points
    love.graphics.setColor({1,0,0,1})
    love.graphics.circle("fill",x1,y1,10)
    love.graphics.circle("fill",x2,y2,10)

end
