package main

import "layer"
import "core:fmt"

TILEMAP: []int = {
    1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 1, 1,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0,
    0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0,
    0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0,
    0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0,
    0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1,
}
TILE_SIZE :: 20
ROW_TILE_COUNT :: 16
COLUMN_TILE_COUNT :: 9
PLAYER_FOV :: 64

Tile_Collision :: proc(tiles: []int, x: int, y: int) -> bool {

    if x < 0 || y < 0 { return false }
    if x >= layer.BMP_WIDTH || y >= layer.BMP_HEIGHT { return false }

    tile_pos_x: int = x / TILE_SIZE 
    tile_pos_y: int = y / TILE_SIZE

    index: int = (tile_pos_y * ROW_TILE_COUNT + tile_pos_x)
    return tiles[index] != 0
}

Ray_Cast :: proc(
    x: int, y: int, 
    length: int, dir: int,
) -> (int, int) {

    rad := Rad((dir % 360 + 360) % 360)
    x1: int = Round(f64(x) + f64(length) * Cos(rad))
    y1: int = Round(f64(y) + f64(length) * Sin(rad))

    dx := x1 - x
    dy := y1 - y
    step := Abs(dx) > Abs(dy) ? Abs(dx) : Abs(dy)

    // THE KEY PART
    x_incr: f64 = f64(dx)/f64(step)
    y_incr: f64 = f64(dy)/f64(step)
    // it follows the path because `x` will step the same length as `y` (or vice-versa whichever distance was more)
    // `x_incr` and `y_incr` are less than 1. This only really works because it's floating point

    xf := f64(x)
    yf := f64(y)

    for i:=0; i<step; i+=1 {
        xf += x_incr
        yf += y_incr

        if Tile_Collision(TILEMAP, Round(xf), Round(yf)) {
            return Round(xf), Round(yf)
        }
    }

    return Round(xf), Round(yf)
}

// TODO:  
//       OBTAIN FRAME RATE SOMEHOW
Game_Callback :: proc() {
    
    @(static) player_x: int = 110
    @(static) player_y: int = 50
    @(static) view_direction: int = 0
    @(static) render_mode: bool = false // true is raycasting false is top down
    @(static) ray_lengths: [PLAYER_FOV]int
    @(static) ray_angles: [PLAYER_FOV]int
    @(static) ray_coll_x: [PLAYER_FOV]int
    @(static) ray_coll_y: [PLAYER_FOV]int

    player_x_dir, player_y_dir: int = layer.Get_WASD_Direction()

    // super ez collision handling, just revert the position
    // you have to do it for x and y positions separately to avoid sticky walls
    // However this only really works because there is no speed, we just moving by 1 pixel per frame
    old_x_pos := player_x
    player_x += player_x_dir
    if Tile_Collision(TILEMAP, player_x + 2, player_y + 2) { // add 2 for collisions with PLAYER CENTER
        player_x = old_x_pos                                 // not TOP LEFT
    }
    old_y_pos := player_y
    player_y += player_y_dir
    if Tile_Collision(TILEMAP, player_x + 2, player_y + 2) {
        player_y = old_y_pos
    }

    view_direction += int(layer.Is_Key_Held(layer.KEY_RIGHT)) - int(layer.Is_Key_Held(layer.KEY_LEFT))

    if layer.Is_Key_Pressed(layer.KEY_ESC) { 
        render_mode = !render_mode 
    }

    for i:=-(PLAYER_FOV / 2); i<PLAYER_FOV/2; i+=1 {

        ray_point_x, ray_point_y := Ray_Cast(player_x + 2, player_y + 2, 100, view_direction + i)
        ray_lengths[i + (PLAYER_FOV / 2)] = Dist(player_x + 2, player_y + 2, ray_point_x, ray_point_y)
        ray_angles[i + (PLAYER_FOV / 2)] = view_direction + i
        ray_coll_x[i + (PLAYER_FOV / 2)] = ray_point_x
        ray_coll_y[i + (PLAYER_FOV / 2)] = ray_point_y
    }

    Clear_Screen(0)

    if !render_mode {
        Draw_Tilemap(TILEMAP, ROW_TILE_COUNT, COLUMN_TILE_COUNT, TILE_SIZE, TILE_SIZE, 0x00ff00)
        Draw_Rectangle(player_x, player_y, 5, 5, 0xff0000)
        for i:=0; i<PLAYER_FOV; i+=1 {
            Length_Dir_Draw_Line(player_x + 2, player_y + 2, ray_lengths[i], ray_angles[i], 0xfe5000)
        }
    } else {

    }

}

main :: proc() {

    layer.Windows_Do_Stuff("Cooking in Progress...", Game_Callback);
}


