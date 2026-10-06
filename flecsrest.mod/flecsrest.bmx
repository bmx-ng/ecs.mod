' Copyright (c) 2026 Bruce A Henderson
' 
' Permission is hereby granted, free of charge, to any person obtaining a copy
' of this software and associated documentation files (the "Software"), to deal
' in the Software without restriction, including without limitation the rights
' to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
' copies of the Software, and to permit persons to whom the Software is
' furnished to do so, subject to the following conditions:
' 
' The above copyright notice and this permission notice shall be included in
' all copies or substantial portions of the Software.
' 
' THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
' IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
' FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
' AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
' LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
' OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
' THE SOFTWARE.

SuperStrict

Rem
bbdoc: Optional HTTP REST server support for Ecs.Flecs.
End Rem
Module Ecs.FlecsRest

ModuleInfo "Version: 1.00"
ModuleInfo "License: MIT"
ModuleInfo "Copyright: flecs - 2025 Sander Mertens"
ModuleInfo "Copyright: BlitzMax wrapper - 2026 Bruce A Henderson"

ModuleInfo "CC_OPTS: -std=c99"

Import Ecs.Flecs

?win32
Import "-lws2_32"
?

Import "../flecs.mod/flecs/include/*.h"
Import "../flecs.mod/flecs/src/addons/http/http.c"
Import "../flecs.mod/flecs/src/addons/rest.c"
Import "glue.c"

Extern
	Function bmx_ecs_enable_rest_server(worldPtr:Byte Ptr, port:Int)
End Extern

Rem
bbdoc: Enables the REST server for an ECS world.
about: The REST server allows remote inspection and queries over HTTP. Repeated calls are safe; the module is imported only once for each world.
End Rem
Function EnableRestServer(world:TEcsWorld, port:Int = 27750)
	If Not world Then Throw "ECS world cannot be Null"
	bmx_ecs_enable_rest_server(world.worldPtr, port)
End Function
