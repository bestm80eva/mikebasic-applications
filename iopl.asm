;#########Information-Area#########################
;IOPL language interpreter for MikeOS
;Created by Joshua Beck
;Licenced under the GNU General Public Licence
;Version 0.2


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
		
	jmp invalid_command_ender

if_commands:
	mov si, cmd
	
	mov di, text_cmd
	call os_string_compare
	jc cmd_if_text
	
	jmp invalid_command_ender

out_commands:
        mov si, cmd
        
        mov di, text_cmd
        call os_string_compare
        jc cmd_out_text
        
	jmp invalid_command_ender
	
set_commands:
	mov si, cmd
	
	mov di, text_cmd
	call os_string_compare
	jc cmd_set_text
	
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
	
	cmp ax, 4B00h
	je .move_left
	
	cmp al, 8		; Is it backspace?
	je .backspace
	
	cmp al, 13		; Is it enter?
	je .end

	cmp si, 63		; Make sure we are not past the maximum length
	je .input
	
	cmp ax, 4D00h
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
	
	mov word si, [loc]
	
.diff:
	cmp byte [si], 10
	inc si
	je command_loader
	jmp .diff

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
	
	cmp al, ';'
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
	mov byte al, [unknown]
	mov bx, 0
	ret

get_data_block:
	mov word di, current_text	; text buffer
	mov bx, 63			; maximum length
	add bx, di
	
	.copy:				; semi-colin's start and end text blocks
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
	
.is_lowercase:				;If it's lowercase convert to capital
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
	je .get_number_string

.end_of_number:	
	mov al, 0
	stosb
	
	inc si
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
	os_stack	dw 0
	start		dw 0
	loc 		dw 0
	end		dw 0
	byte_variables	times 26 db 0		; 26 one-byte variables
	word_variables	times 26 dw 0		; 26 two-byte variables (52 bytes)
	text_variables	times 640 db 0		; 10 strings * 64 characters each
	cmd_type	times 6 db 0		; command type (IN,OUT,SET,PROG,IF,IFN,INFO)
	cmd		times 10 db 0		; commands (TEXT, PIXAL, FILE, CHAR, END etc)
        current_text    times 200 db 0

.command_types:
	if_prefix	db "IF", 0
	in_prefix	db "IN", 0
	info_prefix	db "INFO", 0
	out_prefix	db "OUT", 0
	prog_prefix	db "PROG", 0
	set_prefix	db "SET", 0

.commands:
	text_cmd	db "TEXT", 0
	pixal_cmd	db "PIXAL", 0
	file_cmd	db "FILE", 0
	end_cmd2	db "END", 0

.variable_types:
	unknown		db 0			; Type specifications, used to check variable type easily
	text_var	db 1			; i.e. "cmp al, [byte_var]
	byte_var	db 2
	word_var	db 3
	data_block	db 4
	fixed_number	db 5
	hex_number	db 6

.settings:
        out_page	db 0
	set_page	db 0
	text_colour	db 7
	
.errors:
	msg_invalid_command_starter	db "Invalid start of command: ", 0
	msg_invalid_command_ender	db "Invalid end of command: ", 0
	msg_invalid_number		db "Non-numerical character in numerical constant!"
	
        msg_invalid_parameter 		db "Invalid parameter type", 0
        msg_invalid_variable		db "Invalid variable letter", 0
        msg_program_error		db "Program stopped.", 0
        msg_found_null			db "Unexpected end of program.", 0
        
.messages:
	program_end_message		db "Program complete.", 0
	press_key_message		db "Press any key to continue...", 0
