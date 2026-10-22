"""Run Lua 5.4 verification with the locally installed shared library."""
import ctypes
import pathlib
import sys

lua = ctypes.CDLL('liblua5.4.so.0')
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
lua.lua_close.argtypes = [ctypes.c_void_p]
root = pathlib.Path(__file__).resolve().parents[1]
state = lua.luaL_newstate()
lua.luaL_openlibs(state)
try:
    for path in root.rglob('*.lua'):
        rc = lua.luaL_loadfilex(state, str(path).encode(), None)
        if rc:
            raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
        lua.lua_settop(state, 0)
        print('Syntax OK:', path)
    for filename in sys.argv[1:]:
        rc = lua.luaL_loadfilex(state, filename.encode(), None)
        if rc == 0:
            rc = lua.lua_pcallk(state, 0, 0, 0, 0, None)
        if rc:
            raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
finally:
    lua.lua_close(state)
