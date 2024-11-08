package main

import "core:os"
import "core:fmt"
import libc "core:c/libc"

BUILD_CMD:       cstring = "odin build source -out:./dest/Ray_Casting_Demo.exe"
QUICK_RUN_CMD:   cstring = "odin run source -out:./dest/Ray_Casting_Demo.exe"
DEBUG_BUILD_CMD: cstring = "odin build source -debug -out:./dest/Ray_Casting_Demo.exe -pdb-name:./dest/Ray_Casting_Demo.pdb"

main :: proc() {
    if !os.exists("./dest") { os.make_directory("./dest") }

    if (len(os.args) > 1) {
        if str_cmp(os.args[1], "run") {
            libc.system(QUICK_RUN_CMD)     
        } else if str_cmp(os.args[1], "debug") {
            libc.system(DEBUG_BUILD_CMD)
        } else {
            fmt.println("Ray_Casting_Demo-build.exe ??Unknown argument")
        }
    } else {
        libc.system(BUILD_CMD)  
    }
}

str_cmp :: proc(s1: string, s2: string) -> bool {
    if len(s1) != len(s2) { return false }

    for i in 0..<len(s1) {
        if (s1[i] != s2[i]) { return false }
    }

    return true
}
