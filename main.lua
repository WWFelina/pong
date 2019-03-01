--push needed for virtual resolution
-- https://github.com/Ulydev/push
push = require 'push'

--needed to make classes
-- https://github.com/vrld/hump/blob/master/class.lua
Class = require 'class'

require 'Paddle'
require 'Ball'

-- size of our actual window
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

-- size we're trying to emulate with push
VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

PADDLE_SPEED = 200

--[[
    Called just once at the beginning of the game; used to set up
    game objects, variables, etc. and prepare the game world.
]]
function love.load()
    -- we don't want the pixels to be filtered and end up looking blurry
    -- looking for a retro feel for the game
    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.window.setTitle('Pong')

    -- Setting the seed for RNG to the seconds since 1st Jan 1970
    math.randomseed(os.time())

    -- initializing fonts
    smallFont = love.graphics.newFont('font.ttf', 8)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)

    -- setting default font to small for now
    love.graphics.setFont(smallFont)

    -- making a table for all the sounds we'll need
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    -- setting up virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })

    -- initializing paddles with their starting positions and their dimensions
    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    -- place a ball in the middle of the screen
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    -- initializing score
    player1Score = 0
    player2Score = 0

    -- initializing serving player, the person who gets scored on will serve in the subsequent round
    servingPlayer = 1

    -- initializing winning player
    winningPlayer = 0

    -- The game has 4 states
    -- 1. 'start' : Games hasn't started yet
    -- 2. 'serve' : Waiting for a player to press Enter to serve
    -- 3. 'play'  : Game ongoing
    -- 4. 'done'  : Victor is being displayed on the screen
    gameState = 'start'
end

--lets us change the dimension of the window the game is being played in
--the game conserves its resolution even after resizing
function love.resize(w, h)
    push:resize(w, h)
end

--dt is time taken by one frame(in s). We want to 'update' our game everytime
--the specific machine can render a new frame
function love.update(dt)
    if gameState == 'serve' then
        -- initializing ball velocity based on last round's winner
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gameState == 'play' then
        -- if ball collides with a player, the direction of x velocity must change
        -- but the direction of y velocity need not change.
        -- *1.05 makes the game harder with every collision
        -- dy is randomised to prevent a game stuck at stalemate
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.05
            -- moving ball completely out of the paddle to prevent detection
            -- of multiple collisions on the ball's way back
            ball.x = player1.x + 5

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.05
            ball.x = player2.x - 5

            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end

        -- collisions with upper and lower boundary
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- 4 is the ball's dimension
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        -- if the ball is at the left edge of the screen, that implies player2
        -- scored and player1 will serve next
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            -- playing a 10 point game
            if player2Score == 10 then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()

            if player1Score == 10 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end
    end


    -- player 1
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    -- player 2
    if love.keyboard.isDown('up') then
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    -- only update the ball if the game is ongoing
    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

function love.keypressed(key)
    if key == 'escape' then
        -- quit
        love.event.quit()
    -- Enter is needed to transition for 'start'->'serve'; 'serve'->'play'
    -- and 'done'->'serve'(in the event of a new game)
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then

            gameState = 'serve'

            ball:reset()

            -- resetting scores
            player1Score = 0
            player2Score = 0

            -- decide serving player as the opposite of who won
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end

-- draws everything we see on the screen
-- needs to be called every frame
function love.draw()
    -- begin drawing with push, in our virtual resolution
    push:apply('start')

    -- color goes from 0-1 instead of 0-255 in love's new update
    -- the last argument is for opacity, 1 being perfectly opaque
    love.graphics.clear(40/255, 45/255, 52/255, 1)

    -- render different things depending on which part of the game we're in
    if gameState == 'start' then
        -- UI messages
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        -- UI messages
        love.graphics.setFont(smallFont)
        -- .. is used to concatinate a string and an integer here
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!",
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        -- nothing
    elseif gameState == 'done' then
        -- UI messages
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!',
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
    end

    -- show the score before ball is rendered so it can move over the text
    displayScore()

    player1:render()
    player2:render()
    ball:render()

    -- display FPS for debugging
    displayFPS()

    -- end our drawing to push
    push:apply('end')
end


function displayScore()
    -- score display
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50,
        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
        VIRTUAL_HEIGHT / 3)
end


function displayFPS()
    -- simple FPS display across all states
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end
