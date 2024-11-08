package layer

import win "core:sys/windows"
import "base:runtime"

TARGET_FPS :: 60
FREQ: win.LARGE_INTEGER 
BMP_WIDTH :: 320
BMP_HEIGHT :: 180

// "dib" stands for DEVICE-INDEPENDANT-BITMAP, all we need to get it rendered in a window is:
// the windows BITMAPINFO struct, the array of pixels itself, and the pointer to the data
dib_info: win.BITMAPINFO
dib_data: [BMP_HEIGHT*BMP_WIDTH]u32le
dib_ptr:  rawptr

EXIT_FLAG: bool = false

Get_Screen :: proc() -> ^[BMP_WIDTH * BMP_HEIGHT]u32le {
    return &dib_data
}

// this caused me an unnatural amount of frustration
// but also education. Pain really is the best teacher
// TODO: make this return a pointer to a proper array - support variable lengths
Window_Title_to_Bullsh_Windows_String :: proc(cstr: cstring) -> [^]u16 {

    cstr_ptr := transmute([^]u8)cstr
    @(static) mem: [50]u16

    for i in 0..<len(cstr) {
        mem[i] = u16(cstr_ptr[i])
    }
    mem[len(cstr)] = 0;

    result: [^]u16 = raw_data(&mem)
    return result
}

Windows_Do_Stuff :: proc(window_title: cstring, Callback: proc()) {
    win.QueryPerformanceFrequency(&FREQ)
    // my understanding is that OS scheduler will only wake things up in certain intervals
    // so you set that interval to be 1 millisecond, that way win.Sleep wont be for more than 1 ms
    sleep_is_granular: bool = win.timeBeginPeriod(1) == win.TIMERR_NOERROR

    instance := win.HINSTANCE(win.GetModuleHandleA(nil))
    assert(instance != nil, "WINAPI PROBLEM! Could not get current instance")
    class_name := win.L("Ray_Casting_Demo-Class") 
    background_brush: win.HBRUSH = win.CreateSolidBrush(win.RGB(142, 145, 251))
    class := win.WNDCLASSW {
        lpfnWndProc = Main_Window_Callback,
        lpszClassName = class_name,
        hInstance = instance,
        hbrBackground = background_brush,
    }

    registered_class := win.RegisterClassW(&class)
    assert(registered_class != 0, "WINAPI PROBLEM! Failed to register class")
   
    Init_DIB()

    window := win.CreateWindowExW(
        0,
        class_name,
        Window_Title_to_Bullsh_Windows_String(window_title),
        win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE,
        win.CW_USEDEFAULT, win.CW_USEDEFAULT, win.CW_USEDEFAULT, win.CW_USEDEFAULT,
        nil, 
        nil,
        instance,
        nil,
    )

    assert(window != nil, "WINAPI PROBLEM! Window creation failed....")

    target_seconds: f32 = 1.0 / f32(TARGET_FPS)
    for !EXIT_FLAG {
        
        frame_time_start: win.LARGE_INTEGER = Get_Time()

        msg: win.MSG
        for win.PeekMessageW(&msg, nil, 0, 0, win.PM_REMOVE) {
            win.TranslateMessage(&msg)
            win.DispatchMessageW(&msg)
        }

        device_context: win.HDC = win.GetDC(window)
        client_rect: win.RECT
        win.GetClientRect(window, &client_rect)
        win_width: i32 = client_rect.right - client_rect.left
        win_height: i32 = client_rect.bottom - client_rect.top
        Callback()
        Put_DIB_On_Win(device_context, win_width, win_height)
        win.ReleaseDC(window, device_context)

        frame_time_end: win.LARGE_INTEGER = Get_Time()
        frame_time: f32 = Get_Seconds(frame_time_start, frame_time_end)

        // halt event loop to enforce consistent 60 fps
        if frame_time < target_seconds {
            if sleep_is_granular {
                sleep_ms: win.DWORD = win.DWORD(1000.0 * (target_seconds - frame_time))
                if (sleep_ms > 0) {
                    win.Sleep(sleep_ms)
                }
            }

            for frame_time < target_seconds {
                frame_time = Get_Seconds(frame_time_start, Get_Time())
            }
        }
    }
    return
}

Main_Window_Callback :: proc "stdcall" (
    window: win.HWND, 
    msg: win.UINT, 
    wparam: win.WPARAM,
    lparam: win.LPARAM
) -> win.LRESULT {

    context = runtime.default_context()

    switch (msg) {

        case win.WM_DESTROY: {

            EXIT_FLAG = true
            win.PostQuitMessage(0)
        }

        case win.WM_SIZE: {
            // resize events are handled with, quite literal, perfection
            win.InvalidateRect(window, nil, true)
            return 0
        }

        case win.WM_PAINT: {

            ps: win.PAINTSTRUCT
            device_context: win.HDC = win.BeginPaint(window, &ps)
            defer win.EndPaint(window, &ps)

            client_rect: win.RECT
            win.GetClientRect(window, &client_rect)

            win_width: i32 = client_rect.right - client_rect.left
            win_height: i32 = client_rect.bottom - client_rect.top

            Put_DIB_On_Win(device_context, win_width, win_height)

            return 0
        }
    }
    return win.DefWindowProcW(window, msg, wparam, lparam)
}

Init_DIB :: proc() {

    dib_info.bmiHeader.biSize = size_of(dib_info.bmiHeader)
    dib_info.bmiHeader.biWidth = BMP_WIDTH
    dib_info.bmiHeader.biHeight = -BMP_HEIGHT
    dib_info.bmiHeader.biPlanes = 1
    dib_info.bmiHeader.biBitCount = 32
    dib_info.bmiHeader.biCompression = win.BI_RGB
    dib_ptr = raw_data(&dib_data)
}

Put_DIB_On_Win :: proc(device_context: win.HDC, win_width: i32, win_height: i32) {

    width_scale_factor := f64(win_width/BMP_WIDTH)
    height_scale_factor := f64(win_height/BMP_HEIGHT)
    scaled_width := i32(BMP_WIDTH * width_scale_factor)
    scaled_height := i32(BMP_HEIGHT * height_scale_factor)

    scaled_dest_x: i32 = (win_width - scaled_width) / 2
    scaled_dest_y: i32 = (win_height - scaled_height) / 2

    win.StretchDIBits(
        device_context,
        scaled_dest_x, scaled_dest_y, scaled_width, scaled_height,
        0, 0, BMP_WIDTH, BMP_HEIGHT,
        dib_ptr,
        &dib_info,
        win.DIB_RGB_COLORS, win.SRCCOPY
    )
}

Get_Seconds :: proc(start: win.LARGE_INTEGER, end: win.LARGE_INTEGER) -> f32 { 
    return (f32(end - start)) / f32(FREQ)
}

Get_Time :: proc() -> win.LARGE_INTEGER {
    result: win.LARGE_INTEGER
    win.QueryPerformanceCounter(&result)
    return result
}
