
-- the distance between the centers of two hexes, (hexagon minimal diameter)
local size = 25

-- table to call functions etc...
local hex = {}

-- Precompute constants for converting between units more efficiently
local EPSILON = 1e-9
local SQRT3   = math.sqrt(3)
local INV_SIZE = 1 / size
local A = (SQRT3 / 3) * INV_SIZE
local B = (-1 / 3)    * INV_SIZE
local C = (2 / 3)     * INV_SIZE
local D = SQRT3 * size
local E = (SQRT3 / 2) * size
local F = 1.5 * size
local Z = SQRT3 / 2
local Z_size = Z * size
local half_size = size * 0.5

-- scratch table for drawing hexes
local scratch = {0,0,0,0,0,0,0,0,0,0,0,0}

-- UTILITIES --
-- Basis Vectors for the Hex Borders
local Q1 = {x = Z * size,       y = 0           }
local R1 = {x = 0.5 * Z * size, y = Z * Z * size}
local S1 = {x = Q1.x - R1.x,    y = Q1.y - R1.y }

local Q1Invert = 1/(Q1.x * Q1.x + Q1.y * Q1.y)
local R1Invert = 1/(R1.x * R1.x + R1.y * R1.y)
local S1Invert = 1/(S1.x * S1.x + S1.y * S1.y)

-- load global lua functions
local floor, abs = math.floor, math.abs

-- return the sign of the value
function hex.sign(n)
    return n > 0 and 1
    or n < 0 and -1
    or 0
end

-- converts cartesion coordinates to rounded axial q,r coords
function hex.pixel_to_axial(x, y)
    local q = A * x + B * y
    local r = C * y

    -- Cube rounding: round q, r, s together and up the
    -- component with the largest rounding error so we always
    -- land on the true nearest hex, not just a per-axis nearest.
    local s = -q - r
    local rq = floor(q + 0.5)
    local rr = floor(r + 0.5)
    local rs = floor(s + 0.5)

    local dq = abs(rq - q)
    local dr = abs(rr - r)
    local ds = abs(rs - s)

    if dq > dr and dq > ds then
        rq = -rr - rs
    elseif dr > ds then
        rr = -rq - rs
    end

    return rq, rr
end

-- converts cartesion coordinates to axial q,r coords
function hex.pixel_to_axial_frac(x, y)
    return A * x + B * y, C * y
end

-- converts axial q,r coords to cartesion coords
function hex.axial_to_pixel(q, r)
    return D * q + E * r, F * r
end

-- returns the oblique scalar projection of x1,y1 onto x2,y2
function hex.project_oblique_scale(x1,y1,x2,y2)
    local denom = x1 * x2 + y1 * y2
    if abs(denom) < EPSILON then
        return 0
    end
    return (x1 * x1 + y1 * y1) / denom
end

--[[converts cartestion coords into scalar projection values
 on the hex basis vectors Q,R,S
]]
function hex.pixel_to_Q1R1S1_frac(x,y)
    local Q = (x * Q1.x + y * Q1.y) * Q1Invert
    local R = (x * R1.x + y * R1.y) * R1Invert
    local S = (x * S1.x + y * S1.y) * S1Invert
    return Q, R, S
end

--[[converts cartestion coords into scalar projection values
 on the hex basis vectors Q,R,S, rounded to the nearest hex.
]]
function hex.pixel_to_Q1R1S1_round(x,y)
    local q, r = hex.pixel_to_axial(x,y)
    local realx,realy = hex.axial_to_pixel(q,r)
    local Q, R, S = hex.pixel_to_Q1R1S1_frac(realx,realy)
    return Q , R , S
end

-- converts basis coords in cartesion
function hex.Q1R1S1_to_pixel(dQ,dR,dS)
    local Qx = dQ * Q1.x
    local Qy = dQ * Q1.y
    local Rx = dR * R1.x
    local Ry = dR * R1.y
    local Sx = dS * S1.x
    local Sy = dS * S1.y
    return Qx,Qy,Rx,Ry,Sx,Sy
end

-- DRAWING UTILITIES -- (only compatable with love2D)
function hex.draw(q,r)
    -- append points in the hex_mesh
    local x,y = hex.axial_to_pixel(q,r)
    scratch[1]=x;      scratch[2]=y+size
    scratch[3]=x+Z_size; scratch[4]=y+half_size
    scratch[5]=x+Z_size; scratch[6]=y-half_size
    scratch[7]=x;         scratch[8]=y-size
    scratch[9]=x-Z_size;  scratch[10]=y-half_size
    scratch[11]=x-Z_size; scratch[12]=y+half_size
    love.graphics.polygon("fill", scratch)
end

function hex.draw_buffer(hexes)
    for q, rTable in pairs(hexes) do
        for r in pairs(rTable) do
            hex.draw(q, r)
        end
    end
end


--[[
    HOW IT WORKS (black magic)

    INPUT : x1,y1 (the start point of the ray)
            x2,y2 (the end point of the ray)
            seen (array of previously seen values)
    
    RETURNS : TABLE seen
                such that seen[q] = { [r] = true, ... }
]]
function hex.raycast(x1,y1,x2,y2,seen,max_iterations)
    -- checks if there is a table of seen hexes(useful if calling repeatedly)
    if not seen then
        seen = {}
    end
    -- limits the max iterations if no max iterations are set
    if not max_iterations then
        max_iterations = 100
    end

    -- prevents nill values of x1,y1, x2,y2
    if not x1 or not y1 or not x2 or not y2 then
        return seen
    end

    --find the target vector
    local tx = x2 - x1
    local ty = y2 - y1

    --initiate marching counts and count buffer
    local Q_count = 0.001
    local R_count = 0.001
    local S_count = 0.001
    -- adds the starting point to the count buffer
    local count_buffer = {0}
    local idx = 1

    -- find the Q,R,S Vals(x1,y1)
    local hQ,hR,hS = hex.pixel_to_Q1R1S1_round(x1,y1)
    local sQ,sR,sS = hex.pixel_to_Q1R1S1_frac(x1,y1)
    local eQ,eR,eS = hex.pixel_to_Q1R1S1_frac(x2,y2)
    local dQ,dR,dS = sQ - hQ, sR - hR, sS - hS
    local Q_sign = hex.sign(eQ - sQ)
    local R_sign = hex.sign(eR - sR)
    local S_sign = hex.sign(eS - sS)

    -- find the starting dQ, dR, dS values
    if (dQ > 0) == (Q_sign > 0) then
        dQ = -dQ + (dQ > 0 and 1 or -1)
    else
        dQ = -dQ
    end

    if (dR > 0) == (R_sign > 0) then
        dR = -dR + (dR > 0 and 1 or -1)
    else
        dR = -dR
    end

    if (dS > 0) == (S_sign > 0) then
        dS = -dS + (dS > 0 and 1 or -1)
    else
        dS = -dS
    end

    local Qx,Qy,Rx,Ry,Sx,Sy = hex.Q1R1S1_to_pixel(dQ,dR,dS)

    -- project starting values onto the target vector
    local Q_start = hex.project_oblique_scale(Qx,Qy,tx,ty)
    Q_count = Q_count + Q_start
    local R_start = hex.project_oblique_scale(Rx,Ry,tx,ty)
    R_count = R_count + R_start
    local S_start = hex.project_oblique_scale(Sx,Sy,tx,ty)
    S_count = S_count + S_start

    -- project the basis Q,R,S vectors onto the target vectors and save their scale for later
    local Q_scale = hex.project_oblique_scale(Q_sign * Q1.x,Q_sign * Q1.y,tx,ty)
    local R_scale = hex.project_oblique_scale(R_sign * R1.x,R_sign * R1.y,tx,ty)
    local S_scale = hex.project_oblique_scale(S_sign * S1.x,S_sign * S1.y,tx,ty)

    -- begin marching
    for _ = 1,max_iterations do
        -- if the scale of the Q,R,S count exceeds the ray, the march has ended
        if Q_count > 1 and R_count > 1 and S_count > 1 then
            break
        end
        
        -- try to advance the Q_count
        if Q_count <= R_count and Q_count <= S_count then
            idx = idx + 1
            count_buffer[idx] = Q_count
            Q_count = Q_count + Q_scale
        -- try to advance the R_count
        elseif R_count <= S_count then
            idx = idx + 1
            count_buffer[idx] = R_count
            R_count = R_count + R_scale
        -- try to advance the S_count
        else
            idx = idx + 1
            count_buffer[idx] = S_count
            S_count = S_count + S_scale
        end
    end
    
    -- adds the end point to the count buffer
    idx = idx + 1
    count_buffer[idx] = 1

    -- seen[q] = { [r] = true, ... }
    for _,t in ipairs(count_buffer) do
        -- finds the axial coord of the collision point
        local x , y = x1 + t * tx , y1 + t * ty
        local q, r = hex.pixel_to_axial(x,y)

        -- adds the point to the seen buffer (does not write over already seen values)
        local row = seen[q]
        if not row then
            row = {}
            seen[q] = row
        end
        if not row[r] then
            row[r] = true
        end
    end

    -- returns the table of seen values such that
    -- seen[q] = { [r] = true, ... }
    return seen
end

return hex