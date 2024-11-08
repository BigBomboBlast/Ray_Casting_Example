package main

import "layer"

Color_Pixel :: proc(x: int, y: int, color: u32le) {

    if (!Within(x, 0, 319) || !Within(y, 0, 179)) { return } // out of bounds

    index: int = (y * layer.BMP_WIDTH + x) // formula to map 2d coordinates to 1d pixel array
    screen := layer.Get_Screen()
    screen[index] = color
}

Draw_Rectangle :: proc(
    x: int, y: int, 
    width: int, height: int, 
    color: u32le
) {

    for i:=0; i<height; i+=1 {
        for j:=0; j<width; j+=1 {
            Color_Pixel(x+j, y+i, color)
        }
    }
}

Clear_Screen :: proc(color: u32le) {
    Draw_Rectangle(0, 0, layer.BMP_WIDTH, layer.BMP_HEIGHT, color)
}

Draw_Tilemap :: proc(
    tiles: []int,
    row_tile_count: int, 
    column_tile_count: int, 
    tile_width: int, 
    tile_height: int, 
    color: u32le
) {
    x := 0
    y := 0
    for i:=0; i<column_tile_count; i+=1 {
        for j:=0; j<row_tile_count; j+=1 {

            index: int = (i * row_tile_count + j)
            if tiles[index] > 0 { Draw_Rectangle(x, y, tile_width, tile_height, color) }
            x += tile_width
        }
        x = 0
        y += tile_height
    }
}

Draw_Line :: proc(
    x0: int, y0: int, 
    x1: int, y1: int, 
    color: u32le
) {
    x := x0
    y := y0
    dx := Abs(x1 - x0)
    sx := 1 if x0 < x1 else -1
    dy := -Abs(y1 - y0)
    sy := 1 if y0 < y1 else -1
    error := dx + dy

    for {
        Color_Pixel(x, y, color)
        if x == x1 && y == y1 { break }
        e2 := 2 * error
        if e2 >= dy {
            error += dy
            x += sx
        }
        if e2 <= dx {
            error += dx
            y += sy
        }
    }
} 

Length_Dir_Draw_Line :: proc(
    x: int, y: int, 
    length: int, dir: int, 
    color: u32le
) {
    rad := Rad((dir % 360 + 360) % 360)
    x1: f64 = f64(x) + f64(length) * Cos(rad)
    y1: f64 = f64(y) + f64(length) * Sin(rad)
    Draw_Line(x, y, Round(x1), Round(y1), color)  
}





















