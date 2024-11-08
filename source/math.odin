package main

PI :: 3.14159265358979323846
TAYLOR_SERIES_TERMS :: 10 // THIS CANNOT BE CHANGED, FACTORIALS GET UNCONTROLLABLE *ALMOST INSTANTLY*

Within :: proc(num: int, min: int, max: int) -> bool {

    if (num > max) { return false }
    if (num < min) { return false }
    return true
}

Abs :: proc(num: int) -> int {

    if (num < 0) { return num * -1 }
    return num
}

Abs_f :: proc(num: f64) -> f64 {

    if (num < 0.0) { return num * -1.0 }
    return num
}

Rad :: proc(degrees: int) -> f64 {
    return f64(degrees) * (PI / 180.0)
}

Round :: proc(num: f64) -> int {

    casted := int(num)
    diff := num - f64(casted)

    if (diff < 0.5) { return int(num) }
        
    rest := 1.0 - diff
    return int(num + rest + 0.1) // add 0.1 to ensure it goes over, because idk how floats work loool
}

Factorial :: proc(num: int) -> int {

    result := 1
    for i:=1; i<=num; i+=1 {
        result *= i
    }
    return result 
}

Pow :: proc(base: f64, exp: int) -> f64 {

    result := 1.0
    for i:=0; i<exp; i+=1 {
        result *= base
    }
    return result
}

Sqrt :: proc(num: int) -> f64 { 

    if num < 0 { return 0.0 }

    result := f64(num)
    prec: f64 = 0.00001

    for i:=0; i<100; i+=1 {
        new: f64 = 0.5 * (result + f64(num) / result)
        if (Abs_f(result - new) < prec) {
            break;
        }
        result = new
    }

    return result
}

Sin :: proc(num: f64) -> f64 {

    result: f64 = num
    for i:=1; i<TAYLOR_SERIES_TERMS; i+=1 {
        result += Pow(-1, i) * (Pow(num, i * 2 + 1) / f64(Factorial(i * 2 + 1)))
    }
    return result
}

Cos :: proc(num: f64) -> f64 {

    result: f64 = 1.0
    for i:=1; i<TAYLOR_SERIES_TERMS; i+=1 {
        result += Pow(-1, i) * (Pow(num, i * 2) / f64(Factorial(i * 2)))
    }
    return result
}

Dist :: proc(x0: int, y0: int, x1: int, y1: int) -> int {

    dx := f64(x1 - x0)
    dy := f64(y1 - y0)
    dist := Sqrt(int(Pow(dx, 2) + Pow(dy, 2)))
    return int(dist)
}
