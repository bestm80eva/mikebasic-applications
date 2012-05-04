;#########Information-Area#########################
;IOPL language interpreter for MikeOS
;Created by Joshua Beck
;Licenced under the GNU General Public Licence
;Version 0.3

; The tabs may look wierd unless you use a monospaced font.

;#########API-Linker###############################
os_run_iopl:
	mov word [start], ax
	mov word [loc], ax
	add bx, ax
	mov word [end], bx
	mov word [os_stack], sp

init_iopl:
	mov ax, 0
	mov cx, 26
	mov di, byte_variables
	.clear_byte_var:
	stosb
	loop .clear_byte_var

	mov cx, 26
	.clear_word_var:
	stosw
	loop .clear_word_var
	
	mov cx, 640
	.clear_text_var:
	stosb
	loop .clear_text_var
	
	mov byte [text_colour], 7
	mov byte [set_page], 0
	mov byte [out_page], 0
	

;#########Command-Processing-Area##################
command_loader:
	call get_command		; Get the command

	mov si, cmd_type		; Check what type it is and jump to a section
	
	mov di, if_prefix
	call os_string_compare
	jc if_commands

	mov di, in_prefix
	call os_string_compare
	jc in_commands

	mov di, info_prefix
	call os_string_compare
	jc info_line

	mov di, out_prefix
	call os_string_compare
	jc out_commands
	
	mov di, set_prefix
	call os_string_compare
	jc set_commands
	
	mov di, prog_prefix
	call os_string_compare
	jc prog_commands
	
	jmp invalid_command_starter
	
in_commands:
	mov si, cmd			; We have checked the prefix, now the suffix
	
	mov di, text_cmd
	call os_string_compare
	jc cmd_in_text

	cmp di, char_cmd
	call os_string_compare
	jc cmd_in_char
	
	jmp invalid_command_ender

if_commands:
	mov si, cmd
	
	mov di, text_cmd
	call os_string_compare
	jc cmd_if_text
	
	mov di, char_cmd
	call os_string_compare
	jc cmd_if_char
	
	jmp invalid_command_ender

out_commands:
        mov si, cmd
        
        mov di, text_cmd
        call os_string_compare
        jc cmd_out_text

	mov di, char_cmd
	call os_string_compare
	jc cmd_out_char
        
	jmp invalid_command_ender
	
set_commands:
	mov si, cmd
	
	mov di, text_cmd
	call os_string_compare
	jc cmd_set_text
	
	mov di, char_cmd
	call os_string_compare
	jc cmd_set_char

	jmp invalid_command_ender
	
prog_commands:
	mov si, cmd
	
	mov di, end_cmd
	call os_string_compare
	jc program_end
	jmp invalid_command_ender
	
info_line:
	mov word si, [loc]

.find_end:
	cmp byte [si], 10
	je .end_line
	inc si
	jmp .find_end
	
.end_line:
	inc si
	mov word [loc], si
	jmp command_loader
	
;#########Command-Action-Area######################

;===========
;==IN-CHAR==
;===========
cmd_in_char:
	mov ah, 8
	mov bx, [out_page]
	int 10h
	
	mov cl, ah
	
	mov bh, 0
	mov bl, al
	call set_parameter
	
	mov bh, 0
	mov bl, cl
	call set_parameter
	
	jmp command_loader
	
	
;=============
;==IN-NUMBER==
;=============
	;mov ax, 
	
	
;===========
;==IN-TEXT==
;===========

cmd_in_text:
	call get_parameter

	cmp al, [text_var]
	jne invalid_parameter

	mov di, bx		; Storage Location
	    
	mov ah, 09		; Video parameters
	mov bh, [set_page]
	mov bl, [text_colour]
	mov cx, 1
	call os_get_cursor_pos
	
	mov si, 0		; Character Number
.input:
	call os_wait_for_key
	
	cmp ax, 4BE0h
	je .move_left
	
	cmp al, 8		; Is it backspace?
	je .backspace
	
	cmp al, 13		; Is it enter?
	je .end

	cmp si, 63		; Make sure we are not past the maximum length
	je .input
	
	cmp ax, 4DE0h
	je .move_right
	
				; Not a special key
	mov ah, 09
	int 10h 		; Put character on screen
	
	stosb			; Store it

	inc dl			; Move cursor
	
	inc si			; Character Marker
	
	cmp dl, 79
	jg .newline
.movecursor:
	call os_move_cursor
	jmp .input

.newline:
	mov dl, 0
	inc dh
	jmp .movecursor
.oldline:
	mov dl, 80		; column 79 on the previous line (will be decreased)
	dec dh

	jmp .backspace2
	
.backspace:
	cmp si, 0		; don't go past start
	je .input
	
	cmp dl, 0		; did we go past the first character on the line?
	je .oldline

.backspace2:
	mov al, 32		
	
	dec si

	dec di
	stosb
	dec di

	dec dl
	call os_move_cursor
	mov ah, 9
	int 10h
	
	jmp .input
	
.move_left:
	cmp di, 0
	je .input
	
	dec si
	dec di
	dec di
	
	cmp dl, 0
	je .old_line2
	dec dl
	call os_move_cursor
	jmp .input
	
.old_line2:
	mov dl, 79
	dec dh
	
	call os_move_cursor
	jmp .input

.move_right:
	inc di
	dec si
	
	cmp dl, 79
	je .new_line2
	inc dl
.move_right2:
	call os_move_cursor
	
	jmp .input
	
.new_line2:
	mov dl, 0
	inc dh
	
	jmp .move_right2
	
.end:
	call os_print_newline
	mov al, 0
	stosb
	
	jmp command_loader
	

;===========
;==IF-CHAR==
;===========
cmd_if_char:
	mov ah, 8
	mov bh, [out_page]
	int 10h
	
	mov cx, ax
	call get_parameter
	cmp cx, bx
	
	je command_loader
	
	mov si, [loc]
	
	call jump_eol
	jmp command_loader

	
;===========
;==IF-TEXT==
;===========
cmd_if_text:
	call get_parameter
	
	mov cx, bx
	
	call get_parameter
	
	mov si, bx
	mov di, cx
	
	call os_string_compare
	jc command_loader
	
	call jump_eol
	jmp command_loader


;============
;==OUT-CHAR==
;============
cmd_out_char:
	call cursor_symbol

	call get_parameter
	mov al, bl
	
	mov ah, 9
	mov byte bh, [out_page]
	mov byte bl, [text_colour]
	mov cx, 1
	
	int 0x10
	
	jmp command_loader
	
	
;============
;==OUT-TEXT==
;============
cmd_out_text:
	call get_parameter
        
	mov si, bx
	
	call os_get_cursor_pos
        
	mov ah, 9			; VideoBIOS parameters
	mov bh, [out_page]
	mov bl, [text_colour]
	mov cx, 1

.text_loop:
	lodsb
	
	cmp al, 10
	je .newline
	
	cmp al, 0
	je command_loader
	
	int 10h				; we have all the data we need
	
	cmp dl, 79			; is the cursor at the end of the line?
	je .newline
	
	inc dl				; move cursor forward
	call os_move_cursor
	
	jmp .text_loop
        
.newline:
	inc dh
	mov dl, 0
	call os_move_cursor
	jmp .text_loop
	
;============
;==SET-CHAR==
;============
cmd_set_char:
	call get_direction_flag		; get an arrow parameter, returns 0 for forwards (>) and 1 for backwards (<)

	cmp al, 1			; if it was backwards set a new cursor position otherwise, retrieve it.
	je .set_pos

.get_pos:
	call os_get_cursor_pos		; MikeOS API to retrieve cursor position to DH,DL
	
	mov bh, 0			; set first parameter to the row
	mov bl, dh
	call set_parameter
	
	mov bh, 0			; set the second to the column
	mov bl, dl
	call set_parameter
	
	mov bh, 0
	mov byte bl, [text_colour]
	call set_parameter
	
	jmp command_loader		; load the next command
	
.set_pos:
	call get_parameter		; the first parameter will be the row
	mov dh, bl
	
	call get_parameter		; the second will be the column
	mov dl, bl
	
	cmp dh, 24			; verify it's not off the screen
	jg .invalid
	cmp dl, 79
	jg .invalid

	call os_move_cursor		; save time by using MikeOS API for cursor movement
	
	call get_parameter
	mov bh, 0
	mov byte [text_colour], bl
	
	jmp command_loader		; load next command

.invalid:
	mov si, msg_bad_cursor_position	; outputs like: "Woops! You can't move the cursor to row 40 column 60"
	call os_print_string
	mov si, row_word
	call os_print_string
	mov ah, 0
	mov al, dh
	call os_int_to_string
	mov si, ax
	call os_print_string
	mov si, column_word
	call os_print_string
	mov ah, 0
	mov al, dl
	call os_int_to_string
	mov si, ax
	call os_print_string
	jmp end_prog
.data:	
	row_word			db "row ", 0
	column_word			db " column ", 0
	
;============
;==SET-TEXT==
;============
cmd_set_text:
	call get_parameter
	
	mov cx, bx
	
	call get_parameter
	
	mov si, bx
	mov di, cx

	call os_string_copy
	
	jmp command_loader

;============
;==PROG-END==
;============
program_end:
	call os_print_newline
	mov si, program_end_message
	call os_print_string
	jmp end_prog

;#########Internal-Routines-Area###################

get_command:
	mov word di, cmd_type
	mov bx, 4
	add word bx, cmd_type
	mov word si, [loc]
	
.get_type:
	lodsb

	cmp al, 32		; skip over spaces
	je .get_type
	
	cmp al, 10		; skip over line feeds
	je .get_type
	
	cmp al, '-'
	je .end_type
	
	cmp al, 0
	je found_null

	stosb
	
	cmp di, bx
	jg invalid_command_starter

	jmp .get_type

.end_type:
	mov al, 0
	stosb

	mov word [loc], si
	
	mov ax, cmd_type
	call os_string_uppercase
	
	mov word di, cmd
	mov bx, 14
	add bx, cmd_type
	mov word si, [loc]
	
.get_cmd:
	lodsb
	
	cmp al, ' '
	je .end_cmd
	
	cmp al, 10
	je .end_cmd
	
	cmp al, 0
	je found_null
	
	stosb

	cmp di, bx
	jg invalid_command_ender
	
	jmp .get_cmd
	
.end_cmd:
	mov word [loc], si
	
	mov al, 0
	stosb
	
	mov ax, cmd
	call os_string_uppercase
	
	ret
	
get_parameter:
	mov word si, [loc]
	lodsb

	cmp al, 0
	je found_null
	
	cmp al, ':'
	je get_data_block
	
	cmp al, '#'
	je get_text_var
	
	cmp al, '!'
	je get_byte_var
	
	cmp al, '%'
	je get_word_var
	
	cmp al, '$'
	je get_num_constant
	
	cmp al, '&'
	je get_hex_constant
	
	jmp .none

.none:
	mov bx, 0
.loop:
	lodsb
	
	cmp al, 32
	je .done
	
	cmp al, 10
	je .done
	
	jmp .loop
.done:
	mov byte al, [unknown]
	ret

get_data_block:
	mov word di, current_text		; text buffer
	mov bx, 63				; maximum length
	add bx, di
	
	.copy:					; semi-colin's end text blocks
	lodsb
	cmp al, ';'
	je .end_text
        stosb
	jmp .copy
	
	.end_text:
	
	inc si
	mov word [loc], si

	mov al, 0
	stosb
	
        mov word bx, current_text
        
	mov byte al, [data_block]
	ret

get_text_var:
	lodsb
	mov bl, al
	
	cmp bl, 65
	jl invalid_var
	
	cmp bl, 106
	jg invalid_var
	
	cmp bl, 96
	jg .is_lowercase

	.find_var:
	cmp bl, 74
	jg invalid_var
	
	inc si
	mov word [loc], si

	mov si, text_variables		; Calculate the start of the variable
	mov ax, 64
	mul bl
	add si, ax
	mov bx, si
	
	mov byte al, [text_var]		; Set variable type
	
	ret

	.is_lowercase:
	sub bl, 32
	jmp .find_var
	
get_byte_var:
	inc word [loc]			; Move to the next character, get character
	lodsb
	mov ah, 0
	
	cmp al, 65			; Make sure it's a valid letter
	jl invalid_var
	
	cmp al, 122
	jg invalid_var
	
	cmp al, 96			; Make sure it's capital
	jg .is_lowercase
	
	.find_var:
	cmp al, 90
	jg invalid_var
	
	mov bh, al			; Store variable letter to BH
	
	mov si, byte_variables		; Find value, store it to BL
	sub al, 65
	add si, ax
	lodsb
	mov bl, al
	
	mov byte al, [byte_var]		; Set type to byte variable
	mov ah, bh
	mov bh, 0
	
	inc word [loc]			; Move past next letter (for next parameter)
	ret
	
.is_lowercase:				; If it's lowercase convert to capital
	sub al, 32
	jmp .find_var
	
get_word_var:
	inc word [loc]
	lodsb
	
	cmp al, 65
	jl invalid_var
	
	cmp al, 122
	jg invalid_var
	
	cmp al, 96
	jg .is_lowercase
	
	.find_var:
	cmp al, 90
	jg invalid_var
	
	mov byte [.tmp], al
	
	mov si, word_variables
	sub al, 65
	add si, ax
	lodsw
	mov bx, ax
	
	mov byte al, [byte_var]
	mov byte ah, [.tmp]
	
	inc word [loc]
	ret

.is_lowercase:
	sub al, 32
	jmp .find_var
.data:
	.tmp			db 0
	
get_num_constant:
	mov di, .tmp_string

.get_number_string:
	lodsb
	
	cmp al, 32
	je .end_of_number
	
	cmp al, 10
	je .end_of_number
	
	cmp al, 48
	jl .nan
	
	cmp al, 57
	jg .nan
	
	stosb
	jmp .get_number_string

.end_of_number:	
	mov al, 0
	stosb
	
	mov word [loc], si

	mov word si, .tmp_string
	call os_string_to_int
	
	mov bx, ax
	mov ax, [fixed_number]
	
	ret
	
.nan:
	mov si, msg_invalid_number
	jmp error_msg
.data:
	.tmp_string		times 6 db 0
	
get_hex_constant:
	mov bx, 0		; BX will collect the number

.find_number:
	lodsb			
	
	cmp al, 32
	je .done
	
	cmp al, 10
	je .done
	
	cmp al, '0'		; figure out value of character
	jl .invalid
	
	cmp al, 'f'
	jg .invalid
	
	cmp al, '9'
	jle .is_number
	
	cmp al, 'a'
	jge .is_lowercase
	
	cmp al, 'F'
	jg .invalid
	
	cmp al, 'A'
	jl .invalid
	
	cmp al, 'A'
	jge .is_capital
	
	jmp .invalid
.got_digit:	
	shl bx, 4		; move the last hex character up
	add bl, al		; add the new one
	jmp .find_number	; find the rest
.done:
	mov ax, [hex_number]
	mov word [loc], si
	ret
	
.is_number:			; these translate ASCII to the hexdecimal value
	sub al, 48
	jmp .got_digit
	
.is_capital:
	sub al, 55
	jmp .got_digit
	
.is_lowercase:
	sub al, 87
	jmp .got_digit
	
.invalid:			; for exception characters
	mov si, msg_invalid_hex
	jmp error_msg
	
	
set_parameter:
	mov word si, [loc]
	lodsb

	cmp al, 0
	je found_null
	
	cmp al, ':'
	je .bad_output
	
	cmp al, '#'
	je set_text_var
	
	cmp al, '!'
	je set_byte_var
	
	cmp al, '%'
	je set_word_var
	
	cmp al, '$'
	je .bad_output
	
	cmp al, '&'
	je .bad_output
	
	jmp get_parameter.none
	
.bad_output:
	mov si, msg_output_constant
	jmp error_msg

set_text_var:
	lodsb
	
	cmp al, 65
	jl invalid_var
	
	cmp al, 106
	jg invalid_var
	
	cmp al, 96
	jg .is_lowercase

	.find_var:
	cmp al, 74
	jg invalid_var
	
	inc si
	mov word [loc], si
	
	mov word [.tmp], bx
	
	mov di, text_variables		; Calculate the start of the variable
	mov bx, 64
	mul bl
	add di, ax
	
	mov word si, [.tmp]
	call os_string_copy
	
	ret

	.is_lowercase:
	sub bl, 32
	jmp .find_var
	
	.tmp				dw 0
	
set_byte_var:
	inc word [loc]			; Move to the next character, get character
	lodsb
	mov ah, 0
	
	cmp al, 65			; Make sure it's a valid letter
	jl invalid_var
	
	cmp al, 122
	jg invalid_var
	
	cmp al, 96			; Make sure it's capital
	jg .is_lowercase
	
	.find_var:
	cmp al, 90
	jg invalid_var
	

	mov di, byte_variables	; Find location to save to
	sub al, 65
	add di, ax
	mov al, bl			; Save the lower byte
	stosb
	
	inc word [loc]			; Move past next letter (for next parameter)
	ret
	
.is_lowercase:				;If it's lowercase convert to capital
	sub al, 32
	jmp .find_var
	
set_word_var:
	inc word [loc]
	lodsb
	
	cmp al, 65
	jl invalid_var
	
	cmp al, 122
	jg invalid_var
	
	cmp al, 96
	jg .is_lowercase
	
	.find_var:
	cmp al, 90
	jg invalid_var
	
	mov byte [.tmp], al
	
	mov di, word_variables
	sub al, 65
	add di, ax
	mov ax, bx
	stosw
	
	inc word [loc]
	ret

.is_lowercase:
	sub al, 32
	jmp .find_var
.data:
	.tmp			db 0
	
	
jump_eol:
	mov word si, [loc]
.find_eol:
	cmp byte [si], 10
	je .found_eol
	
	cmp byte [si], ':'
	je .find_eob
	
	inc si
	jmp .find_eol
	
.find_eob:
	inc si
	
	cmp byte [si], ';'
	jne .find_eob
	
	inc si
	jmp .find_eol
	
.found_eol:
	inc si
	inc si
	mov word [loc], si
	ret

cursor_symbol:
	; Use this to intepret	a character '-','+' or '=' to determine cursor movement
	push ax
	push dx
	push si
	
	mov word si, [loc]
	lodsb
	cmp al, '+'
	je .move_forward
	
	cmp al, '-'
	je .move_backward
	
	cmp al, '='
	jne .bad_symbol

	jmp .end
	
.bad_symbol:
	mov si, msg_bad_symbol
	jmp error_msg
	
.move_forward:
	call os_get_cursor_pos
	inc dl
	cmp dl, 80
	je .move_newline
	call os_move_cursor
	jmp .end
	
.move_newline:
	inc dh
	mov dl, 0
	call os_move_cursor
	jmp .end
	
.move_backward:
	call os_get_cursor_pos
	cmp dl, 0
	je .move_oldline
	dec dl
	call os_move_cursor
	jmp .end
	
.move_oldline:
	dec dh
	mov dl, 0
	call os_move_cursor
	
.end:
	lodsb
	mov word [loc], si
	pop si
	pop dx
	pop ax
	ret
	
get_direction_flag:
	mov word si, [loc]
	lodsb
	
	cmp al, '>'
	je .forward
	
	cmp al, '<'
	je .backward
	
	mov si, msg_expected_direction
	jmp error_msg
	
.forward:
	lodsb
	mov al, 0
	mov word [loc], si
	ret

	
.backward:
	lodsb
	mov al, 1
	mov word [loc], si
	ret
	
	
end_prog:
	call os_print_newline
        mov si, press_key_message	; Print "Press any key to continue..." and wait for a key before ending
        call os_print_string
        call os_wait_for_key
	mov word sp, [os_stack]
	ret
	
;#########Error-Handling###########################
found_null:
	mov si, msg_found_null
	jmp error_msg
	
invalid_parameter:
        mov si, msg_invalid_parameter
        jmp error_msg

invalid_var:
	mov si, msg_invalid_variable
	jmp error_msg
	
invalid_command_starter:
	mov si, msg_invalid_command_starter
	call os_print_string
	mov si, cmd_type
	call os_print_string
	jmp end_prog
	
invalid_command_ender:
	mov si, msg_invalid_command_ender
	call os_print_string
	mov si, cmd_type
	call os_print_string
	mov si, msg_invalid_command_ender2
	call os_print_string
	mov si, cmd
	call os_print_string
	jmp end_prog
	
error_msg:
	call os_print_newline
        call os_print_string
        call os_print_newline
        mov si, msg_program_error
        call os_print_string
	jmp end_prog
        
;#########Data-Area################################

data:
	os_stack			dw 0				; save the stack in case there's a error in a subroutine
	start				dw 0				
	loc 				dw 0				; current program location, place to retrieve data from
	end				dw 0
	program_line			dw 0				; line number, used for error messages
	byte_variables			times 26 	db 0		; 26 one-byte variables
	word_variables			times 26 	dw 0		; 26 two-byte variables (52 bytes)
	text_variables			times 640 	db 0		; 10 strings * 64 characters each
	cmd_type			times 6 	db 0		; command type (IN,OUT,SET,PROG,IF,IFN,INFO)
	cmd				times 10 	db 0		; commands (TEXT, PIXAL, FILE, CHAR, END etc)
        current_text    		times 200 	db 0

.command_types:
	if_prefix			db "IF", 0
	in_prefix			db "IN", 0
	info_prefix			db "INFO", 0
	out_prefix			db "OUT", 0
	prog_prefix			db "PROG", 0
	set_prefix			db "SET", 0

.commands:
	char_cmd			db "CHAR", 0
	number_cmd2			db "NUMBER", 0
	text_cmd			db "TEXT", 0
	pixal_cmd			db "PIXAL", 0
	file_cmd			db "FILE", 0
	end_cmd2			db "END", 0

.variable_types:
	unknown				db 0
	text_var			db 1
	byte_var			db 2
	word_var			db 3
	data_block			db 4
	fixed_number			db 5
	hex_number			db 6

.settings:
        out_page			db 0				; video page to output to
	set_page			db 0				; video page being viewed
	text_colour			db 7				; start text colour at white
	
.errors:				; Error messages, at one point in time these were serious/technical, that's boring.
	msg_invalid_command_starter	db "You can't start a command with: ", 0
	msg_invalid_command_ender	db "You can't match: ", 0
	msg_invalid_command_ender2	db " with: ", 0
	msg_invalid_number		db "Oops! There's a problem with that number.", 0
	msg_invalid_hex			db "Oops! There's a problem with that hexdecimal.", 0
	msg_output_constant		db "Oops! We wanted a variable and got a constant", 0
	msg_bad_symbol			db "Oops! You needed a cursor symbol (+,-,=).", 0
	msg_bad_cursor_position		db "Sorry, you can't move the cursor to ", 0
	msg_expected_direction		db "Oops! You need a direction < or >.", 0
	
        msg_invalid_parameter 		db "Oops! We need a parameter", 0
        msg_invalid_variable		db "Woops! That character is out of range.", 0
        msg_program_error		db "Program stopped.  :-(", 0
        msg_found_null			db "Unexpected end of program.  :-O", 0
        
.messages:				; Messages that don't involve errors.
	program_end_message		db "Program complete. :-)", 0
	press_key_message		db "Press any key to continue...", 0
