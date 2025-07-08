package game

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import rl "vendor:raylib"

Block :: struct {
    x, y, width, height: f32,
}

Level :: struct {
    blocks: [dynamic]Block,
}

Editor_Mode :: enum {
    EDIT,
    PLAY,
}

main :: proc() {
    rl.InitWindow(1280, 720, "Level Editor")
    rl.SetTargetFPS(60)
    
    // Editor state
    mode := Editor_Mode.EDIT
    level: Level
    level.blocks = make([dynamic]Block)
    
    // Block being placed
    block_size: f32 = 64
    placing_block := false
    start_pos: rl.Vector2
    
    // Player (for testing)
    player_pos := rl.Vector2{100, 100}
    player_vel: rl.Vector2
    player_grounded := false
    
    // Movement parameters
    max_speed: f32 = 400
    acceleration: f32 = 1500
    friction: f32 = 1200
    
    for !rl.WindowShouldClose() {
        mouse_pos := rl.GetMousePosition()
        
        if mode == .EDIT {
            // Edit mode controls
            if rl.IsMouseButtonPressed(.LEFT) {
                placing_block = true
                start_pos = mouse_pos
            }
            
            if rl.IsMouseButtonReleased(.LEFT) && placing_block {
                // Create block from start to current position
                min_x := min(start_pos.x, mouse_pos.x)
                max_x := max(start_pos.x, mouse_pos.x)
                min_y := min(start_pos.y, mouse_pos.y)
                max_y := max(start_pos.y, mouse_pos.y)
                
                // Make sure block is at least minimum size
                width := max(max_x - min_x, 32)
                height := max(max_y - min_y, 32)
                
                block := Block{
                    x = min_x,
                    y = min_y,
                    width = width,
                    height = height,
                }
                append(&level.blocks, block)
                placing_block = false
            }
            
            // Delete block on right click
            if rl.IsMouseButtonPressed(.RIGHT) {
                for i := len(level.blocks) - 1; i >= 0; i -= 1 {
                    block := level.blocks[i]
                    if mouse_pos.x >= block.x && mouse_pos.x <= block.x + block.width &&
                       mouse_pos.y >= block.y && mouse_pos.y <= block.y + block.height {
                        ordered_remove(&level.blocks, i)
                        break
                    }
                }
            }
            
            // Clear all blocks
            if rl.IsKeyPressed(.C) {
                clear(&level.blocks)
            }
            
            // Save level
            if rl.IsKeyPressed(.S) {
                save_level(&level, "level.txt")
                fmt.println("Level saved!")
            }
            
            // Load level
            if rl.IsKeyPressed(.L) {
                load_level(&level, "level.txt")
                fmt.println("Level loaded!")
            }
            
            // Switch to play mode
            if rl.IsKeyPressed(.SPACE) {
                mode = .PLAY
                player_pos = rl.Vector2{100, 100}
                player_vel = rl.Vector2{0, 0}
                player_grounded = false
            }
        } else {
            // Play mode - same movement code as your main game
            dt := rl.GetFrameTime()
            
            if rl.IsKeyDown(.A) {
                player_vel.x -= acceleration * dt
                if player_vel.x < -max_speed {
                    player_vel.x = -max_speed
                }
            } else if rl.IsKeyDown(.D) {
                player_vel.x += acceleration * dt
                if player_vel.x > max_speed {
                    player_vel.x = max_speed
                }
            } else {
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
            
            // Apply gravity
            if !player_grounded {
                player_vel.y += 2000 * dt
            }
            
            // Jump
            if rl.IsKeyPressed(.W) && player_grounded {
                player_vel.y = -600
                player_grounded = false
            }
            
            // Update position
            player_pos.x += player_vel.x * dt
            player_pos.y += player_vel.y * dt
            
            // Simple collision with blocks
            player_rect := rl.Rectangle{player_pos.x, player_pos.y, 32, 32}
            player_grounded = false
            
            for &block in level.blocks {
                block_rect := rl.Rectangle{block.x, block.y, block.width, block.height}
                
                if rl.CheckCollisionRecs(player_rect, block_rect) {
                    // Simple collision resolution
                    if player_vel.y > 0 && player_pos.y < block.y {
                        // Landing on top
                        player_pos.y = block.y - 32
                        player_vel.y = 0
                        player_grounded = true
                    } else if player_vel.y < 0 && player_pos.y > block.y {
                        // Hit from below
                        player_pos.y = block.y + block.height
                        player_vel.y = 0
                    } else if player_vel.x > 0 {
                        // Hit from left
                        player_pos.x = block.x - 32
                        player_vel.x = 0
                    } else if player_vel.x < 0 {
                        // Hit from right
                        player_pos.x = block.x + block.width
                        player_vel.x = 0
                    }
                }
            }
            
            // Ground collision
            if player_pos.y >= f32(rl.GetScreenHeight()) - 32 {
                player_grounded = true
                player_vel.y = 0
                player_pos.y = f32(rl.GetScreenHeight()) - 32
            }
            
            // Switch back to edit mode
            if rl.IsKeyPressed(.ESCAPE) {
                mode = .EDIT
            }
        }
        
        // Drawing
        rl.BeginDrawing()
        rl.ClearBackground(rl.RAYWHITE)
        
        // Draw blocks
        for block in level.blocks {
            rl.DrawRectangle(i32(block.x), i32(block.y), i32(block.width), i32(block.height), rl.BROWN)
            rl.DrawRectangleLines(i32(block.x), i32(block.y), i32(block.width), i32(block.height), rl.DARKBROWN)
        }
        
        // Draw player (only in play mode)
        if mode == .PLAY {
            rl.DrawRectangle(i32(player_pos.x), i32(player_pos.y), 32, 32, rl.BLUE)
        }
        
        // Draw block being placed
        if mode == .EDIT && placing_block {
            min_x := min(start_pos.x, mouse_pos.x)
            max_x := max(start_pos.x, mouse_pos.x)
            min_y := min(start_pos.y, mouse_pos.y)
            max_y := max(start_pos.y, mouse_pos.y)
            
            width := max(max_x - min_x, 32)
            height := max(max_y - min_y, 32)
            
            rl.DrawRectangle(i32(min_x), i32(min_y), i32(width), i32(height), rl.GRAY)
            rl.DrawRectangleLines(i32(min_x), i32(min_y), i32(width), i32(height), rl.DARKGRAY)
        }
        
        // Draw UI
        if mode == .EDIT {
            rl.DrawText("EDIT MODE", 10, 10, 20, rl.BLACK)
            rl.DrawText("Left Click + Drag: Place block", 10, 40, 16, rl.DARKGRAY)
            rl.DrawText("Right Click: Delete block", 10, 60, 16, rl.DARKGRAY)
            rl.DrawText("C: Clear all blocks", 10, 80, 16, rl.DARKGRAY)
            rl.DrawText("S: Save level", 10, 100, 16, rl.DARKGRAY)
            rl.DrawText("L: Load level", 10, 120, 16, rl.DARKGRAY)
            rl.DrawText("SPACE: Test level", 10, 140, 16, rl.DARKGRAY)
        } else {
            rl.DrawText("PLAY MODE", 10, 10, 20, rl.BLACK)
            rl.DrawText("A/D: Move, W: Jump", 10, 40, 16, rl.DARKGRAY)
            rl.DrawText("ESC: Back to edit", 10, 60, 16, rl.DARKGRAY)
        }
        
        rl.EndDrawing()
    }
    
    delete(level.blocks)
    rl.CloseWindow()
}

save_level :: proc(level: ^Level, filename: string) {
    builder := strings.builder_make()
    defer strings.builder_destroy(&builder)
    
    for block in level.blocks {
        fmt.sbprintf(&builder, "%.2f,%.2f,%.2f,%.2f\n", block.x, block.y, block.width, block.height)
    }
    
    os.write_entire_file(filename, transmute([]u8)strings.to_string(builder))
}

load_level :: proc(level: ^Level, filename: string) {
    data, ok := os.read_entire_file(filename)
    if !ok {
        fmt.println("Could not read level file")
        return
    }
    defer delete(data)
    
    clear(&level.blocks)
    
    content := string(data)
    lines := strings.split(content, "\n")
    defer delete(lines)
    
    for line in lines {
        if len(line) == 0 do continue
        
        parts := strings.split(line, ",")
        defer delete(parts)
        
        if len(parts) != 4 do continue
        
        x, x_ok := strconv.parse_f32(parts[0])
        y, y_ok := strconv.parse_f32(parts[1])
        width, w_ok := strconv.parse_f32(parts[2])
        height, h_ok := strconv.parse_f32(parts[3])
        
        if x_ok && y_ok && w_ok && h_ok {
            block := Block{x, y, width, height}
            append(&level.blocks, block)
        }
    }
}