Option Explicit
Dim fntGame, bgmMainTheme, sndFood, sndDeath, imgRedApple
Const CELL_SIZE = 15
Const GRID_WIDTH = 50
Const GRID_HEIGHT = 36
Const MOVE_INTERVAL = 0.15

Dim snake, snakeDirection, food, score, gameOver, moveTimer

Sub Initialize()
    AppMain.Instance.SetWindowSize 800, 600
    Set bgmMainTheme = MusicAsset.Create("main_theme")
    Set fntGame = FontAsset.Create("game_font")
    Set sndFood = SoundAsset.Create("food")
    Set sndDeath = SoundAsset.Create("death")
    Set imgRedApple = ImageAsset.Create("red_apple")
    ResetGame
End Sub

Sub ResetGame()
    bgmMainTheme.PlayLooping
    snake = Collections.CreateArrayList
    snakeDirection = Vec2i.Create(1, 0)
    score = 0
    gameOver = False
    moveTimer = 0
    
    Dim startX, startY, i
    startX = GRID_WIDTH \ 2
    startY = GRID_HEIGHT \ 2
    
    For i = 0 To 2
        snake.Add Vec2i.Create(startX - i, startY)
    Next
    
    SpawnFood
End Sub

Sub SpawnFood()
    Dim newFoodX, newFoodY, isOnSnake, i
    Do
        newFoodX = Convert.ToInt32(VBMath.Rnd() * (GRID_WIDTH - 1))
        newFoodY = Convert.ToInt32(VBMath.Rnd() * (GRID_HEIGHT - 1))
        isOnSnake = False
        
        For i = 0 To snake.Count - 1
            Dim segment
            Set segment = snake(i)
            If segment.X = newFoodX And segment.Y = newFoodY Then
                isOnSnake = True
                Exit For
            End If
        Next
    Loop While isOnSnake
    
    Set food = Vec2i.Create(newFoodX, newFoodY)
End Sub

Sub Update(dt)
    Dim i, head, newHead
    If gameOver Then
        If AppMain.Instance.IsKeyHeld(Keys.Space) Then ResetGame
        Exit Sub
    End If
    HandleInput
    moveTimer = moveTimer + dt
    If moveTimer >= MOVE_INTERVAL Then
        moveTimer = moveTimer - MOVE_INTERVAL
        
        Set head = snake(0)
        Set newHead = Vec2i.Create(head.X + snakeDirection.X, head.Y + snakeDirection.Y)
        If newHead.X < 0 Or newHead.X >= GRID_WIDTH Or _
           newHead.Y < 0 Or newHead.Y >= GRID_HEIGHT Then
            TriggerGameOver
            Exit Sub
        End If
        For i = 0 To snake.Count - 1
            Dim segment
            Set segment = snake(i)
            If segment.X = newHead.X And segment.Y = newHead.Y Then
                TriggerGameOver
                Exit Sub
            End If
        Next
        
        snake.Insert 0, newHead
        If newHead.X = food.X And newHead.Y = food.Y Then
            score = score + 10
            sndFood.Play
            SpawnFood
        Else
            snake.RemoveAt snake.Count - 1
        End If
    End If
End Sub

Sub HandleInput()
    Dim newDir
    Set newDir = snakeDirection
    
    With AppMain.Instance
        If .IsKeyHeld(Keys.Left) Or .IsKeyHeld(Keys.A) Then
            Set newDir = Vec2i.Create(-1, 0)
        ElseIf .IsKeyHeld(Keys.Right) Or .IsKeyHeld(Keys.D) Then
            Set newDir = Vec2i.Create(1, 0)
        ElseIf .IsKeyHeld(Keys.Up) Or .IsKeyHeld(Keys.W) Then
            Set newDir = Vec2i.Create(0, -1)
        ElseIf .IsKeyHeld(Keys.Down) Or .IsKeyHeld(Keys.S) Then
            Set newDir = Vec2i.Create(0, 1)
        End If
    End With
    
    If (newDir.X + snakeDirection.X <> 0) Or (newDir.Y + snakeDirection.Y <> 0) Then
        Set snakeDirection = newDir
    End If
End Sub

Sub TriggerGameOver()
    gameOver = True
    sndDeath.Play
    bgmMainTheme.Stop
End Sub

Sub Render(g, dt)
    Dim i, rect, text, segment, segmentRect, alpha
    g.Clear Color.Black
    
    If Not gameOver Then
        Set rect = Recti.Create(0, 0, GRID_WIDTH * CELL_SIZE, GRID_HEIGHT * CELL_SIZE)
        rect.DrawOutline g, 1
        For i = snake.Count - 1 To 0 Step -1
            Set segment = snake(i)
            Set segmentRect = Recti.Create( _
                segment.X * CELL_SIZE, segment.Y * CELL_SIZE, _
                CELL_SIZE - 1, CELL_SIZE - 1)
            
            If i = 0 Then
                segmentRect.DrawFilled g, Color.GreenYellow
                DrawEyes g, segmentRect
            Else
                alpha = 255 - (i * 15)
                If alpha < 128 Then alpha = 128
                segmentRect.DrawFilled g, Color.FromArgb(alpha, 0, 200, 0)
            End If
        Next
        
        imgRedApple.Draw g, food.X * CELL_SIZE, food.Y * CELL_SIZE
        text = "Score: " & score
        fntGame.DrawText g, text, 10, GRID_HEIGHT * CELL_SIZE + 10, Color.White, 15
    Else
        fntGame.DrawText g, "GAME OVER!", 230, 250, Color.Red, 24
        fntGame.DrawText g, "Final Score: " & score, 230, 300, Color.White, 15
        fntGame.DrawText g, "Press SPACE to restart", 200, 350, Color.Gray, 15
    End If
End Sub

Sub DrawEyes(g, headRect)
    Const EYE_SIZE = 3
    Const EYE_OFFSET_X = 3
    Const EYE_OFFSET_Y = 4

    Dim leftEye, rightEye
    Set leftEye = Recti.Create( _
        headRect.X + EYE_OFFSET_X, headRect.Y + EYE_OFFSET_Y, EYE_SIZE, EYE_SIZE _
    )
    Set rightEye = Recti.Create( _
        headRect.X + headRect.Width - EYE_OFFSET_X - EYE_SIZE, _
        headRect.Y + EYE_OFFSET_Y, EYE_SIZE, EYE_SIZE _
    )
    leftEye.DrawFilled g, Color.Black
    rightEye.DrawFilled g, Color.Black
End Sub