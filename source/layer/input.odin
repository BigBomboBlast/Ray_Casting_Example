package layer

import win "core:sys/windows"

previous_key_states: [300]bool

// USE THIS REFERENCE TO ADD MORE: [https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes]
KEY_W       :: 0x57
KEY_A       :: 0x41
KEY_S       :: 0x53
KEY_D       :: 0x44
MB_LEFT     :: 0x02
MB_RIGHT    :: 0x01
KEY_LEFT    :: 0x25
KEY_RIGHT   :: 0x27
KEY_UP      :: 0x26
KEY_DOWN    :: 0x28
KEY_ESC     :: 0x1b

Is_Key_Held :: proc(key_code: i32) -> bool {

    return (u16(win.GetKeyState(key_code)) & 0x8000) != 0
}

Is_Key_Pressed :: proc(key_code: i32) -> bool {

    pressed: bool
    if Is_Key_Held(key_code) && previous_key_states[key_code] == false {
        pressed = true
    }
    if previous_key_states[key_code] == true {
        pressed = false
    }
    
    previous_key_states[key_code] = Is_Key_Held(key_code)
    return pressed
}

Get_WASD_Direction :: proc() -> (int, int) {

    x_dir := int(Is_Key_Held(KEY_D)) - int(Is_Key_Held(KEY_A))
    y_dir := int(Is_Key_Held(KEY_S)) - int(Is_Key_Held(KEY_W))
    return x_dir, y_dir
}
