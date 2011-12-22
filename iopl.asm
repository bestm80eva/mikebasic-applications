;#########Information-Area#########################
;IOPL language interpreter for MikeOS
;Created by Joshua Beck
;Licenced under the GNU General Public Licence
;Version 0.1


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
	
	mov di, in_command
	call os_string_compare
	jc near in_commands

	mov di, out_command
	call os_string_compare
	jc near out_commands
	
	mov di, set_command
	call os_string_compare
	jc near set_commands
	
	mov di, prog_command
	call os_string_compare
	jc near prog_commands
	
	jmp invalid_command_starter
	
in_commands:
	mov si, cmd			; We have checked the prefix, now the suffix
	
	mov di, text_cmd
	call os_string_compare
	jc in_text
		
	jmp invalid_command_ender

out_commands:
        mov si, cmd
        
        mov di, text_cmd
        call os_string_compare
        jc out_text
        
	jmp invalid_command_ender
	
set_commands:
	mov si, cmd
	
	mov di, text_cmd
	call os_string_compare
	jc set_text
	jmp invalid_command_ender
	
prog_commands:
	mov si, cmd
	
	mov di, end_cmd
	call os_string_compare
	jc program_end
	jmp invalid_command_ender
	
;#########Command-Action-Area######################

;=============
;IN-TEXT
;=============

in_text:
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
	
;============
;==OUT_TEXT==
;============
out_text:
        call get_parameter
        cmp al, [text_var]
        jne invalid_parameter
        
        mov bp, bx

        mov ax, bx
	call os_string_length
        mov cx, ax
        
        call os_get_cursor_pos
        
        mov ah, 13h
        mov al, 1
        mov bh, [out_page]
        mov bl, [text_colour]
        int 10h
        
       	jmp command_loader
        
;============
;==SET_TEXT==
;============
set_text:
	call get_parameter
	cmp al, [text_var]
;	jne invalid_parameter
	
	mov cx, bx
	
	call get_parameter
	cmp al, [data_block]
;	jne invalid_parameter
	
	mov si, bx
	mov di, cx

	call os_string_copy
	
	jmp command_loader

;============
;==PROG_END==
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
	mov bx, 10
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
	
	jmp .none

.none:
	mov byte al, [unknown]
	mov bx, 0
	ret

get_data_block:
	inc si
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
	inc word [loc]

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
	
	mov si, text_variables		; Calculate the start of the variable
	mov ax, 64
	mul bl
	add si, ax
	mov bx, si
	
	mov byte al, [text_var]		; Set variable type
	
	inc word [loc]
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
	.tmp		db 0
	
end_prog:
	call os_print_newline
        mov si, press_key_message	; Print "Press any key to continue..." and wait for a key before ending
        call os_print_string
        call os_wait_for_key
        call os_print_newline
	mov word sp, [os_stack]
	ret
	
;#########Error-Handling###########################
found_null:
	mov si, msg_found_null
	jmp error_msg
	
invalid_parameter:
        mov si, invalid_parameter_message
        jmp error_msg

invalid_var:
	mov si, invalid_variable_message
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
        mov si, program_error_message
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
	if_command	db "IF", 0
	in_command	db "IN", 0
	info_command	db "INFO", 0
	out_command	db "OUT", 0
	prog_command	db "PROG", 0
	set_command	db "SET", 0

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

.settings:
        out_page	db 0
	set_page	db 0
	text_colour	db 7
	
.errors:
	msg_invalid_command_starter	db "Invalid start of command: ", 0
	msg_invalid_command_ender	db "Invalid end of command: ", 0
        invalid_parameter_message 	db "Invalid parameter type", 0
        invalid_variable_message	db "Invalid variable letter", 0
        program_error_message		db "Program stopped.", 0
        msg_found_null			db "Unexpected end of program.", 0
        
.messages:
	program_end_message		db "Program complete.", 0
	press_key_message		db "Press any key to continue...", 0
