REM >>>>MIKEBASIC-PLUS-PLUS-LIBRARY<<<
MOVE 0 0
PRINT "This is a library and not for direct use!"
END
boxsave:
  j = 64610
  for y = 8 to 17
    move 20 y
    for x = 20 to 59
      move x y
      curschar w
      poke w j
      print " ";
      j = j + 1
    next x
  next y
return

boxrest:
  j = 64610
  for y = 8 to 17
    for x = 20 to 59
      move x y
      peek w j
      print chr w ;
      j = j + 1
    next x
  next y
return

OPENBOX:
  POKE V 65418
  POKE J 65419
  POKE W 65420
  POKE X 65421
  POKE Y 65422
  GOSUB BOXSAVE
  IF C < 0 THEN C = 7
  IF C > 15 THEN C = 7
  H = H * 16
  H = H + C
  CURSOR OFF
  INK C
  MOVE 22 9
  PRINT $T
  GOSUB ANIOPEN
  GOSUB BOX
  MOVE 22 9
  PRINT $T
  PEEK V 65418
RETURN

CLOSEBOX:
  GOSUB ANICLOSE
  INK 7
  H = H / 16
  GOSUB BOXSAVE
  PEEK J 65419
  PEEK W 65420
  PEEK X 65421
  PEEK Y 65422
  CURSOR OFF
RETURN
  
aniclose:
  if $y = "DISABLE" then return
  j = 176
  gosub blockbox
  pause 1
  j = 177
  gosub blockbox
  pause 1
  j = 178
  gosub blockbox
  pause 1
  j = 219
  gosub blockbox
  pause 1
  return
aniopen:
  if $y = "DISABLE" then return
  j = 219
  gosub blockbox
  pause 1
  j = 178
  gosub blockbox
  pause 1
  j = 177 
  gosub blockbox
  pause 1
  j = 176
  gosub blockbox
  pause 1
  return
anistart:
  if $y = "DISABLE" then return
  j = 176
  gosub blockscr
  pause 1
  j = 177
  gosub blockscr
  pause 1
  j = 178
  gosub blockscr
  pause 1
  j = 219
  gosub blockscr
  pause 1
  j = 178
  gosub blockscr
  j = 219
  gosub blockbor
  pause 2
  j = 177
  gosub blockscr
  j = 219
  gosub blockbor
  pause 2
  j = 176
  gosub blockscr
  j = 219
  gosub blockbor
  pause 2
  j = 0
  gosub blockscr
  move 2 1
  print $t
  j = 219
  gosub blockbor
  pause 2
  j = 178
  gosub blockbor
  pause 1
  j = 177
  gosub blockbor
  pause 1
  j = 176
  gosub blockbor
  return
aniend:
  if $y = "DISABLE" then return
  j = 176
  gosub blockscr
  pause 1
  j = 177
  gosub blockscr
  pause 1
  j = 178
  gosub blockscr
  pause 1
  j = 219
  gosub blockscr
  pause 5
  j = 178
  gosub blockscr
  pause 1
  j = 177
  gosub blockscr
  pause 1
  j = 176
  gosub blockscr
  pause 1
  j = 0
  gosub blockscr
  pause 1
return

ancitext:
  ink c
  poke x 65431
ancitex2:
  if x > w then y = y + 1
  if x > w then peek x 65431
  if x > 78 then y = y + 1
  if x > 78 then peek x 65431
  if y > 23 then return
  move x y
  peek j v
  if j = 0 then return
  if j = 1 then v = v + 1
  if j = 1 then goto ancitex2
  if j = 7 then j = 255
  if j = 10 then y = y + 1
  if j = 10 then peek x 65431
  if j = 10 then v = v + 1
  if j = 10 then goto ancitex2
  print chr j ;
  x = x + 1
  v = v + 1
goto ancitex2

pictotxt:
  for x = 0 to 19
    for y = 0 to 76
      peek w v
      if w = 0 then w = 32
      poke w v
      v = v + 1
    next y
    poke 10 v
    v = v + 1
    poke 1 v
    v = v + 1
    poke 1 v
    v = v + 1
  next x
return

ASKBOX:
  GOSUB OPENBOX
  print $5
  move 22 12
  print $6
  move 22 13
  print $7
  move 22 14
  print $8
  move 22 15
  print $9
  move 27 16
  print "--Yes--        --No--"
  poke 0 65423
  gosub askdraw
  askloop:
    waitkey j
    if j = 3 then gosub swleft
    if j = 4 then gosub swright
    if j = 13 then goto askend
  goto askloop
askend:
  peek v 65423
  j = v
  if j = 0 then v = 1
  if j = 1 then v = 0
  GOSUB CLOSEBOX
  return
swleft:
  peek v 65423
  if v = 0 then return
  if v = 1 then v = 0
  poke v 65423
  gosub askdraw
  return
swright:
  peek v 65423
  if v = 1 then return
  if v = 0 then v = 1
  poke v 65423
  gosub askdraw
  return
askdraw:
  move 26 16
  if v = 0 then ink h
  if v = 1 then ink c
  print "--Yes--"
  move 41 16
  if v = 0 then ink c
  if v = 1 then ink h
  print "--No--"
return

MESBOX:
  GOSUB OPENBOX
  move 22 11
  print $5
  move 22 12
  print $6
  move 22 13
  print $7
  move 22 14 
  print $8
  move 22 15
  print $9
  move 22 16
  print "Press any key to continue..."
  waitkey j
  GOSUB CLOSEBOX
return

INPBOX:
  GOSUB OPENBOX
  move 22 12
  print $5
  move 22 13
  print $6
  move 22 14
  print ">"
  move 23 14
  cursor on
  $i = ""
  if v = 1 then input $I
  if v = 0 then input v
  GOSUB CLOSEBOX
return

ERRBOX:
  $J = $T
  $T = "Error"
  GOSUB OPENBOX
  move 22 12
  print $E
  move 22 14
  print "Press any key to continue."
  cursor on
  move 48 14
  waitkey j
  if k = 27 then gosub endprog
  GOSUB CLOSEBOX
  $T = $J
return

DINBOX:
  GOSUB OPENBOX
  print $5
  move 22 12
  print ">"
  move 23 12
  cursor on
  if v = 0 then input a
  if v = 1 then input $7
  move 22 13
  print $6
  move 22 14
  print ">"
  move 23 14
  if v = 0 then input b
  if v = 1 then input $8
  GOSUB CLOSEBOX
return

NUMBOX:
  GOSUB OPENBOX
  if $5 = "" then goto numboxa
  move 22 11
  print $5
  move 22 12
  print a
  numboxa:
  if $c = "" then goto numboxb
  move 22 13
  print $6
  move 22 14
  print b
  numboxb:
  move 22 16
  print "Press any key to continue..."
  waitkey j
  GOSUB CLOSEBOX
return

REFRESH:
  cls
  gosub border
  gosub title
return

ENDPROG:
  z = 7
  gosub aniend
  cls
  cursor on
end

blockbor:
  INK Z
  for x = 0 to 79
    move x 0
    PRINT CHR J
    move x 2
    PRINT CHR J
    move x 24
    PRINT CHR J
  next x
  for x = 1 to 23
    move 0 x
    PRINT CHR J
    move 79 x
    PRINT CHR J
  next x
return

BORDER:
  J = 0
  Y = 0
  FOR W = 1 TO 2
    FOR X = 0 TO 2
      MOVE X Y
      READ BORDERDATA J V
      PRINT CHR V
      J = J + 1
    NEXT X
    Y = 79
  NEXT W
  J = 186
  FOR Y = 3 TO 23
    MOVE 0 Y
    PRINT CHR J
    MOVE 79 Y
    PRINT CHR J
  NEXT Y
  J = 205
  FOR X = 1 TO 78
    MOVE X 0
    PRINT CHR J
    MOVE X 2
    PRINT CHR J
    MOVE X 79
    PRINT CHR J
  NEXT X
  BORDERDATA:
  218 179 195 191 179 180

BLOCKSCR:
  INK Z
  FOR X = 0 to 79
    FOR Y = 0 to 24
      MOVE X Y
      PRINT CHR J
    NEXT Y
  NEXT X
RETURN

SETTITLE:
  POKE Z 65439 
  Y = & $T
  FOR X = 65440 TO 65514
    PEEK W X
    POKE W Y
    Y = Y + 1
  NEXT X
RETURN

TITLE:
  PEEK J 65439
  INK J
  MOVE 2 1
  FOR X = 65440 TO 65514
    PEEK J X
    PRINT CHR J ;
  NEXT X
RETURN

BLOCKBOX:
  INK T
  FOR X = 8 TO 17
    MOVE 20 X
    PRINT CHR J
  NEXT X
  FOR X = 21 TO 58
    MOVE X 8
    PRINT CHR J
    MOVE X 10
    PRINT CHR J
    MOVE X 17
    PRINT CHR J
  NEXT X
  FOR X = 8 TO 17
    MOVE 59 X
    PRINT CHR J
  NEXT X
RETURN

BOX:
  INK T
  W = 1
  X = 20
  FOR J = 1 TO 2
    FOR Y = 8 TO 11
      MOVE X Y
      READ BORDERDATA W V
      PRINT CHR V
      W = W + 1
    NEXT Y
    X = 59
  NEXT J
  V = 186
  FOR Y = 12 TO 16
    MOVE 20 Y
    PRINT CHR V
    MOVE 59 Y
    PRINT CHR V
  NEXT Y
  MOVE 20 17
  V = 192
  PRINT CHR V
  MOVE 59 17
  V = 217
  PRINT CHR V
  V = 205
  FOR X = 21 TO 58
    MOVE X 8
    PRINT CHR V
    MOVE X 10
    PRINT CHR V
    MOVE X 17
    PRINT CHR V
  NEXT X
  INK 7
  move 21 9
  print "                                      "
  for x = 11 to 16
    move 21 x
    print "                                      "
  next x
RETURN

arrayget:
  if $v = "a" then j = 0
  if $v = "b" then j = 100
  if $v = "c" then j = 200
  if $v = "d" then j = 300
  j = j + 65000
  if $v = "a" then w = a
  if $v = "b" then w = b
  if $v = "c" then w = c
  if $v = "d" then w = d
  if w > 99 then $e = "Array over maximum"
  if w < 0 then $e = "Number below zero"
  if w > 99 then goto errbox
  if w < 0 then goto errbox
  j = j + w
  peek v j
  return
arrayput:
  if $v = "a" then j = 0
  if $v = "b" then j = 100
  if $v = "c" then j = 200
  if $v = "d" then j = 300
  j = j + 65000
  if $v = "a" then w = a
  if $v = "b" then w = b
  if $v = "c" then w = c
  if $v = "d" then w = d
  if w > 99 then $e = "Array over maximum"
  if w < 0 then $e = "Number below zero"
  if w > 99 then goto errbox
  if w < 0 then goto errbox
  j = j + w
  poke v j
  return
xput:
  $e = "XPUT: invalid location!"
  if e < 0 then goto errbox
  if e > 8096 then goto errbox
  j = 32767 - e
  poke v j
  return
xget:
  $e = "XGET: invalid location!"
  if e < 0 then goto errbox
  if e > 8096 then goto errbox
  j = 32767 - e
  peek v j
  return
loadbox:
  poke v 65434
  u = 11453
  findend:
    u = u + 1
    peek v u
    if v > 0 then goto findend
  u = u - 2
  poke 0 65435
  poke 1 65436
  peek w 65437
  poke 0 65438
  gosub boxsave
  move 22 9
  print $t
  gosub aniopen
  gosub box
  move 22 9
  print $t
  menufunc:
    poke 0 65424
    if v < 6 then gosub menua
    if v = 6 then gosub loadback
    if v = 6 then poke 0 65438
rem    if v = 6 then gosub lbhelper
    if v = 6 then goto menufunc
    if v = 7 then gosub loadforw
    if v = 7 then poke 4 65438
rem    if v = 7 then gosub lbhelper
    if v = 7 then goto menufunc
  poke 0 65436
  x = s
  y = r
  peek v 65434
  load $i v
  $e = "File not found! Has disk changed?"
  j = r
  v = s
  r = y
  s = x
  if j = 1 then gosub errbox
  gosub aniclose
  gosub boxrest
  return 
lbhelper:
  poke 1 65424
  poke w 65438
  if w > 4 then gosub loadint
  if w > 4 then gosub menuloop
  return
menubox:
  gosub boxsave
  move 22 9
  print $t
  gosub aniopen
  gosub box
  move 22 9
  print $t
  poke 0 65436
  poke 0 65438
  menufun2:
    gosub menua
    if v < 6 then goto menufun3
    if v = 6 then poke 0 65438
    if v = 7 then poke 4 65438
  goto menufun2
  menufun3:
  poke v 65432
  gosub aniclose
  gosub boxrest  
  peek v 65432
  return
menua:
  peek j 65436
  if j = 1 then goto loadint
  move 22 11
  print $b
  move 22 12
  print $c
  move 22 13
  print $e
  move 22 14
  print $f
  move 22 15
  print $g
  loadret:
  move 22 16
  print "Press enter to select."
  poke c 65525
  peek w 65438
  w = w + 11
  y = 9
  for x = 22 to 58
    gosub colour
  next x
  for y = 11 to 16
    for x = 22 to 58
      gosub colour
      if w = y then gosub highlight
    next x
  next y
  w = w - 11
  menuloop:
    waitkey j
    x = 0
    v = 0
    if j = 1 then gosub menublan
    if j = 1 then w = w - 1
    if w < 0 then x = 1
    if x = 1 then w = 5 
    if x = 1 then goto refafter
    if j = 1 then poke w 65438
    if j = 1 then gosub menuchan
    if j = 1 then goto menuloop
    if j = 2 then gosub menublan
    if j = 2 then w = w + 1
    if w > 4 then x = 2
    if x = 2 then w = 6
    if x = 2 then goto refafter
    if j = 2 then poke w 65438
    if j = 2 then gosub menuchan
    if j = 2 then goto menuloop
    if j = 13 then goto refaftr2
    if j = 27 then gosub endprog
  goto menuloop
  refaftr3:
    peek w 65438
    w = w + 11
    move 23 w
    $i = "            "
    x = & $i
    y = 23
    getfilen:
      move y w
      curschar j
      if j < 33 then poke 0 x
      if j < 33 then return
      poke j x
      x = x + 1
      y = y + 1
      goto getfilen
  refaftr2:
    peek w 65436
    if w = 1 then gosub refaftr3
    peek w 65438
    v = w + 1
    return
  refafter:
    poke w 65438
    for y = 11 to 16
      move 21 y
      for x = 21 to 58
        print " ";
      next x
    next y
    peek w 65438
    if w = 4 then gosub menuchan
    if w = 6 then gosub menuchan
    v = w + 1
    return
  menublan:
    poke c 65525
    for y = 11 to 16
      for x = 22 to 58
        move x y
        curschar v
        poke v 65520
        call 65515
      next x
    next y
    return
  menuchan:
    poke w 65433
    peek w 65436
    if w = 1 then goto chanload
    peek w 65433
    if w = 6 then w = 4
    if w = 5 then w = 0
    poke w 65433
    chanload:
    peek w 65433
    w = w + 11
    v = h * 16
    v = v + c
    poke v 65525
    for y = 11 to 16
      for x = 22 to 58
        if w = y then move x y
        if w = y then curschar v
        if w = y then poke v 65520
        if w = y then call 65515
      next x
    next y
    w = w - 11
    peek w 65438
    return
loadint:
  move 22 9
  print "Select a file to load..."
  w = 0
  peek j 65435
  j = j + 11454
  x = 23
  y = 11
  move x y
  fncon:
    move x y
    peek i j
    if i = 0 then goto lintret
    print chr i
    if j > u then goto loadover
    if j > u then gosub loadback
    if j > u then goto lintret
    if i = ',' then w = w + 1
    if i = ',' then move x y
    if i = ',' then print " "
    if i = ',' then x = 22
    if i = ',' then y = y + 1
    if w = 5 then goto lintret  
    x = x + 1
    j = j + 1
  goto fncon
  lintret:
    peek j 65424
    if j = 0 then goto loadret
    if j = 1 then return
  return
loadover:
  gosub loadback
  poke u 65435
  goto loadret
loadforw:
  x = 0 
  j = 0
  peek j 65435
  j = j + 11454
  lmfc:
    peek x j
    j = j + 1
    if x = 44 then j = j - 11454
    if x = 44 then poke j 65435
    if x = 44 then return
  goto lmfc
loadback:
  x = 0
  j = 0
  y = 0
  peek j 65435
  j = j + 11454
  lmbc:
    peek x j
    j = j - 1
    if x = 0 then j = 11008
    if x = 0 then poke j 65435
    if x = 0 then return
    if j < 0 then y = 3
    if y = 3 then j = 0
    if y = 3 then poke 0 65435
    if y = 3 then return
    if x = ',' then y = y + 1
    if y = 2 then j = j - 11454
    if y = 2 then j = j + 2
    if y = 2 then poke j 65435
    if y = 2 then return
  goto lmbc
