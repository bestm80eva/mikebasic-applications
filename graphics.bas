rem MikeBASIC Graphics Library (gfxlib.bas)
rem Version 1.0
rem Created by Joshua Beck
rem Released under the GNU General Public Licence revision 3
rem Load this before any other libraries.
rem Send any questions, comments, bugs or feature requests to:
rem mikeosdeveloper@gmail.com

print "This is a library and not for direct use!"
end

set_pixal:
  poke v 64041
  pokeint x 64038
  poke y 64040
  call  64012
return

get_pixal:
  pokeint x 64038
  poke y 64040
  call 64023
  peek v 64041
return

horizontal_line:
  poke v 64041
  poke y 64040
  for x = x to w
    pokeint x 64038
    call 64012
  next x
return

vertical_line:
  poke v 64041
  pokeint x 64038
  for y = x to w
    poke y 64040
    call 64012
  next y
return

box_filled:
  poke v 64041
  for x = x to w
    pokeint x 64038
    for y = y to z
      poke y 64040
      call 64012
    next y
  next x
return
       
graphics_mode:
  y = 64000
  for x = 1 to 12
    read graphics_asm x y
    y = y + 1
  next x
  call 64000
  for x = 1 to 40
    read pixal_asm x y
    y = y + 1
  next x
return
  
text_mode:
  y = 64000
  for x = 1 to 12
    read graphics_asm x y
    y = y + 1
  next x
  poke 3 64003
  x = 2000
  pokeint x 64007
  call 64000
return

graphics_asm:
  180 0 176 19 205 16 184 0 160 142 192 195
  
pixal_asm:
  232 19 0 139 30 40 0 38 137 28 195 232 8 0 38 139 28 137 30 40 0 195 161 39 
  0 187 64 1 247 227 137 189 3 54 39 0 195 0 0 0 0
