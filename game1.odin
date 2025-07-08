package game

import rl "vendor:raylib"

main :: proc(){
	rl.InitWindow(1280, 720, "Game1")
	player_pos :=rl.Vector2 {640, 320}
	player_vel: rl.Vector2
	player_grounded: bool
	player := rl.LoadTexture("player.png")

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(rl.GRAY)

		if rl.IsKeyDown(.A) {
			player_vel.x = -400
		} else if rl.IsKeyDown(.D) {
			player_vel.x = +400
		} else {player_vel.x = 0
		}

		player_vel += 2000 * rl.GetFrameTime()

		if player_grounded && rl.IsKeyPressed(.SPACE) {
			player_vel.y = -600
			player_grounded = false
		}

		if player_pos.y > f32(rl.GetScreenHeight()) - 64 {
			player_pos.y = f32(rl.GetScreenHeight()) -64
			player_grounded = true
		}

		player_pos += player_vel * rl.GetFrameTime()

		rl.DrawTextureV(player, {720, 320}, rl.WHITE)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}