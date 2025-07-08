package game

import rl "vendor:raylib"

main :: proc(){
	rl.InitWindow(1280, 720, "Game1")
	rl.InitAudioDevice()
	
	player_pos := rl.Vector2 {640, 320}
	player_vel: rl.Vector2
	player_grounded: bool
	player := rl.LoadTexture("player.png")
	
	// Load sounds
	jump_sound := rl.LoadSound("jump.wav")
	walk_sound := rl.LoadSound("walk.wav")
	
	// Movement parameters
	max_speed: f32 = 400
	acceleration: f32 = 1500
	friction: f32 = 1200
	
	// Sound timing
	walk_timer: f32 = 0
	walk_interval: f32 = 0.3  // Play walk sound every 0.3 seconds

	for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.GRAY)
		rl.DrawTextureV(player, player_pos, rl.WHITE)

        // Handle horizontal movement with acceleration/deceleration
        dt := rl.GetFrameTime()
        walk_timer += dt
        
        is_moving := false
        
        if rl.IsKeyDown(.A) {
            // Accelerate left
            player_vel.x -= acceleration * dt
            if player_vel.x < -max_speed {
                player_vel.x = -max_speed
            }
            is_moving = true
        } else if rl.IsKeyDown(.D) {
            // Accelerate right
            player_vel.x += acceleration * dt
            if player_vel.x > max_speed {
                player_vel.x = max_speed
            }
            is_moving = true
        } else {
            // Apply friction when no input
            if player_vel.x > 0 {
                player_vel.x -= friction * dt
                if player_vel.x < 0 {
                    player_vel.x = 0
                }
            } else if player_vel.x < 0 {
                player_vel.x += friction * dt
                if player_vel.x > 0 {
                    player_vel.x = 0
                }
            }
        }
        
        // Play walking sound
        if is_moving && player_grounded && abs(player_vel.x) > 50 && walk_timer >= walk_interval {
            rl.PlaySound(walk_sound)
            walk_timer = 0
        }

        // Apply gravity
        if !player_grounded {
            player_vel.y += 2000 * rl.GetFrameTime()
        }

        // Jump logic (only when grounded)
        if rl.IsKeyDown(.SPACE) && player_grounded {
            player_vel.y = -600
            player_grounded = false
            rl.PlaySound(jump_sound)
        }

        // Update position based on velocity
        player_pos.x += player_vel.x * dt
        player_pos.y += player_vel.y * dt

        // Ground collision
        if player_pos.y >= f32(rl.GetScreenHeight()) - 64 {
            player_grounded = true
            player_vel.y = 0
            player_pos.y = f32(rl.GetScreenHeight()) - 64
        } else {
            player_grounded = false
        }
		
        rl.EndDrawing()
    }
    
    // Clean up
    rl.UnloadSound(jump_sound)
    rl.UnloadSound(walk_sound)
    rl.UnloadTexture(player)
    rl.CloseAudioDevice()
    rl.CloseWindow()
}