# Completed 5/1/2026
# Author: miscroV
# A functioning basic HTTP Webserver writing in amd64 assembly. 
# Only basic functionality implemented. 
# EXTREMELY INSECURE. DO NOT RUN ON PUBLIC SERVERS.

.intel_syntax noprefix
.global _start

_start:

main:                                        # int main() {
  mov rbp, rsp                               #
  sub rsp, 8                                 #  int connect_fd [rbp-8]
  sub rsp, 8                                 #  int server_fd [rbp-16]
  sub rsp, 16                                #
  xor rax, rax                               #
  .l8:                                       #
  cmp rax, 32                                #
  jge .b8                                    #
    mov qword ptr [rbp+rax-32], 0x00000000   #
    add rax, 4                               #
  jmp .l8                                    #
  .b8:                                       #
  mov word ptr  [rsp  ], 2                   # 
  mov word ptr  [rsp+2], 0x5000              # 
  mov dword ptr [rsp+4], 0                   # 
  mov qword ptr [rsp+8], 0                   #  sockadder_in sock = {sin_family: AF_INET, sin_port: 80, sin_adder: 0.0.0.0} [rbp-32] 
                                             # 
  mov rdx, 0                                 # 
  mov rsi, 1                                 # 
  mov rdi, 2                                 # 
  mov rax, 41                                #
  syscall                                    # 
  mov [rbp-16], rax                          #   server_fd = socket(AF_INET, SOCK_STREAM, 0)
                                             # 
  mov rdx, 16                                # 
  lea rsi, [rbp-32]                          # 
  mov rdi, [rbp-16]                          # 
  mov rax, 49                                # 
  syscall                                    #   bind(server_fd, sock, 16) 
                                             #
  mov rsi, 0                                 # 
  mov rdi, [rbp-16]                          # 
  mov rax, 50                                #
  syscall                                    #   listen(server_fd, 0)
                                             #
  .l1:                                       #   # server
                                             #   while (true) {
  mov rdx, 0                                 #
  mov rsi, 0                                 #
  mov rdi, [rbp-16]                          #
  mov rax, 43                                #
  syscall                                    #
  mov [rbp-8], rax                           #     connect_fd = accept(server_fd, NULL, NULL)
                                             #
  mov rax, 57                                #
  syscall                                    #     
  cmp rax, 0                                 #     if ( fork() == 0 ) {
  jne .if1                                   #
    mov rdi, [rbp-16]                        #
    mov rax, 3                               #
    syscall                                  #       close(server_fd)
                                             #
    mov rdi, [rbp-8]                         #
    call handle_request                      #       handle_request(connect_fd)
                                             #
    mov rdi, [rbp-8]                         #
    mov rax, 3                               #
    syscall                                  #       close(connect_fd)
                                             #
    mov rdi, 0                               #
    mov rax, 60                              #
    syscall                                  #       exit(0)
  .if1:                                      #     }
                                             #
  mov rdi, [rbp-8]                           #
  mov rax, 3                                 #
  syscall                                    #     close(connect_fd)
                                             #   }
  jmp .l1                                    # 

                                             # /**
                                             #  * Handles GET and POST requests from a supplied connect_fd socket file descriptor. 
                                             #  * Closes the connection after 1 request. 
                                             #  * streams files larger than 512 bytes.
                                             # **/
handle_request:                              # void handle_request(connect_fd) {
  push rbp                                   #                              
  mov rbp, rsp                               #                              
                                             #
  sub rsp, 8   # [rbp-8]                     #   int connect_fd = connect_fd
  mov [rbp-8], rdi                           #
  sub rsp, 8  # [rbp-16]                     #   int f_fd
  sub rsp, 8  # [rbp-24]                     #   int header_len = 0;
  sub rsp, 8  # [rbp-32]                     #   int read_len;
                                             #
  sub rsp, 32 # [rbp-64]                     #
  mov qword ptr [rsp+0 ], 0x50545448         #
  mov qword ptr [rsp+4 ], 0x302e312f         # 
  mov qword ptr [rsp+8 ], 0x30303220         #
  mov qword ptr [rsp+12], 0x0d4b4f20         # 
  mov qword ptr [rsp+16], 0x000a0d0a         #   str success = "HTTP/1.0 200 OK\r\n\r\n" # Non dynamic return header. len = 19
                                             #                                             #
  sub rsp, 32 # [rbp-96]                     #
  mov qword ptr [rsp   ], 0x50545448         #
  mov qword ptr [rsp+4 ], 0x302e312f         #
  mov qword ptr [rsp+8 ], 0x30303420         #
  mov qword ptr [rsp+12], 0x44414220         #
  mov qword ptr [rsp+16], 0x51455220         #
  mov qword ptr [rsp+20], 0x54534555         #
  mov qword ptr [rsp+24], 0x0a0d0a0d         #   str error = "HTTP/1.0 400 BAD REQUEST\r\n\r\n" # Non dynamic fail header. len = 32
                                             #
  sub rsp, 256 # [rbp-352]                   #   str *header_buf [256] # defines max length of headers
  sub rsp, 256 # [rbp-608]                   #   str *temp_buf [256]   # used for stat_struct and file_str
  sub rsp, 512 # [rbp-1120]                  #   str *read_buf [512]   # used for all read and write buffering
                                             #
  mov rax, 256                               # 
  .l6:                                       #
  cmp rax, 1120                              #
  jge .b6                                    #
  mov qword ptr [rbp+rax], 0x00000000        #
  add rax, 4                                 #
  jmp .l6                                    #    
  .b6:                                       #  # clear the buffers
                                             #
  mov rdx, 512                               # 
  lea rsi, [rbp-1120]                        # 
  mov rdi, [rbp-8]                           # 
  mov rax, 0                                 # 
  syscall                                    # 
  mov [rbp-32], rax                          #   read_len = read(connect_fd, read_buf, sizeof(read_buf))
                                             # 
  mov rdx, 256                               # 
  lea rsi, [rbp-1120]                        # 
  lea rdi, [rbp-352]                         # 
  call parse_headers                         # 
  mov [rbp-24], rax                          # 
                                             #   header_len = parse_headers(header_buf, read_buf, sizeof(header_buf))
  mov rdx, 256                               # 
  lea rsi, [rbp-352]                         # 
  lea rdi, [rbp-608]                         # 
  call parse_file                            #   parse_file(temp_buf, read__buf, sizeof(temp_buf))
                                             #   
  lea rdi, [rbp-352]                         #
  call parse_method                          #
                                             # 
  cmp rax, 0                                 #
  je .GET                                    #
  cmp rax, 1                                 #
  je .POST                                   #   switch parse_method(header_buf):
                                             #   default:
  mov rdx, 28                                #   
  lea rsi, [rbp-96]                          # 
  mov rdi, [rbp-8]                           # 
  mov rax, 1                                 # 
  syscall                                    #     write(connect_fd, error, sizeof(error)) # return succes to user
                                             # 
  xor rax, rax                               # 
  add rsp, 1120                              # 
  mov rsp, rbp                               #     return
  pop rbp                                    # 
  ret                                        # 
  .GET:                                      #   0: #GET
  mov rsi, 0                                 #
  lea rdi, [rbp-608]                         #
  mov rax, 2                                 #
  syscall                                    #
  mov [rbp-16], rax                          #     f_fd = open(*temp_buf, O_RDONLY) 
                                             #
  lea rsi, [rbp-608]                         #
  mov rdi, [rbp-16]                          #
  mov rax, 5                                 #
  syscall                                    #     fstat(f_fd, temp_buf)
                                             #
  mov rdx, 19                                #
  lea rsi, [rbp-64]                          # 
  mov rdi, [rbp-8]                           #
  mov rax, 1                                 # 
  syscall                                    #    write(connect_fd, success, 19)
                                             #
  xor rcx, rcx                               #    int total_bytes_written = 0, file_bytes [rbp-560]
  .l16:                                      #    do {
  mov rdx, 512                               #
  lea rsi, [rbp-1120]                        #
  mov rdi, [rbp-16]                          #
  mov rax, 0                                 #
  syscall                                    #      bytes_read = read(f_fd, read_buf, sizeof(read_buf))                          
                                             #
  mov rdx, rax                               #
  lea rsi, [rbp-1120]                        #
  mov rdi, [rbp-8]                           #
  mov rax, 1                                 #
  syscall                                    #      bytes_written = write(connect_fd, read_buf, bytes_read)
                                             #
  add rbx, rax                               #      total_bytes_written += bytes_written
                                             #
  cmp rcx, [rbp-560]                         #
  jl .l16                                    #    } while ( total_bytes_written < file_bytes)
                                             #
  mov rdi, [rbp-16]                          # 
  mov rax, 3                                 # 
  syscall                                    #    close(f_fd)
                                             #
  xor rax, rax                               # 
  add rsp, 1120                              # 
  mov rsp, rbp                               #    return
  pop rbp                                    # 
  ret                                        # 
                                             #
  .POST:                                     #   1:  # POST
                                             #   
  mov rdx, 0777                              #
  mov rsi, 65 # O_WRONLY                     # 
  lea rdi, [rbp-608]                         # 
  mov rax, 2                                 # 
  syscall                                    # 
  mov [rbp-16], rax                          #     f_fd =  open(*tmp_buf, O_WRONLY|O_CREAT, 0777) 
                                             # 
  mov rdx, [rbp-32]                          # 
  mov rsi, [rbp-24]                          # 
  sub rdx, rsi                               #
  lea rsi, [rbp+rsi-1120]                    # 
  mov rdi, [rbp-16]                          # 
  mov rax, 1                                 # 
  syscall                                    #     write(f_fd, read_buf[header_len], read_len - header_len) # write remaining of first read
                                             # 
  cmp qword ptr [rbp-32], 512                #     if (read_len >= sizeof(read_buf) { # if there is more to write after initial, stream to file. 
  jl .if3                                    # 
    .l2:                                     # 
    mov rdx, 512                             # 
    lea rsi, [rbp-1120]                      # 
    mov rdi, [rbp-16]                        # 
    mov rax, 0                               # 
    syscall                                  # 
    cmp rax, 0                               #       while (int i = read(connect_fd, read_buf, sizeof(read_buf)) != 0) { 
    je .b2                                   # 
      mov rdx, rax                           # 
      lea rsi, [rbp-1120]                    # 
      mov rdi, [rbp-16]                      # 
      mov rax, 1                             # 
      syscall                                #          write(f_fd, read_buf, i)
    jmp .l2                                  #       }
    .b2:                                     #     }
  .if3:                                      #   
                                             #
                                             #
  mov rdi, [rbp-16]                          # 
  mov rax, 3                                 # 
  syscall                                    #     close(f_fd)
                                             #
  mov rdx, 19                                # 
  lea rsi, [rbp-64]                          # 
  mov rdi, [rbp-8]                           # 
  mov rax, 1                                 # 
  syscall                                    #     write(connect_fd, success, sizeof(success)) # return succes to user
                                             # 
  xor rax, rax                               # 
  add rsp, 1120                              # 
  mov rsp, rbp                               #     return
  pop rbp                                    # }
  ret                                        # 

                                             # /**
                                             #  * Parse the headers of an HTTP request into a buffer 'header_buf'
                                             #  * Returns length of str read into header_buf
                                             # **/
parse_headers:                               # int parse_headers(header_buf, read_buf, sizeof(header_buf)) {
  push rbp                                   #    
  mov rbp, rsp                               #   int i = 0
                                             #
  xor rax, rax                               #   while (i < sizeof(header_buf)) {
  .l3:                                       #  
  cmp rax, rdx                               #     
  jge .b3                                    #   
                                             # 
  mov cl, [rsi+rax]                          #       header_buf[i] = read_buf[i]
  mov [rdi+rax], cl                          #
  cmp rax, 4                                 #    if i < 4 : continue
  jl .c3                                     #    
  cmp byte ptr [rsi+rax  ], 0x0a             #    if ( (read_buf[i] == '\n') && 
  jne .c3                                    #        
  cmp byte ptr [rsi+rax-1], 0x0d             #         (read_buf[i-1] == '\r') &&
  jne .c3                                    # 
  cmp byte ptr [rsi+rax-2], 0x0a             #         (read_buf[i-2] == '\n') &&
  jne .c3                                    #
  cmp byte ptr [rsi+rax-3], 0x0d             #         (read_buf[i-3] == '\r')) {
  jne .c3                                    #     
    jmp .b3                                  #       break;
  .c3:                                       #     }
  inc rax                                    # 
  jmp .l3                                    #   i++
  .b3:                                       #
                                             #   }
  inc rax                                    #   i++
  mov rsp, rbp                               #   
  pop rbp                                    #
  ret                                        # }

                                             # /**
                                             #  * parse method (up to 32 bytes) and return a method int:
                                             #  * GET = 0, POST = 1, OTHER = -1
                                             # **/
parse_method:                                # int parse_method(*header_buf) {
  push rbp                                   #
  mov rbp, rsp                               #
                                             #
                                             #   if header_buf.startswith('GET ') {
  cmp byte ptr [rdi], 'G'                    #
  jne .if25                                  #
  cmp byte ptr [rdi+1], 'E'                  #
  jne .if25                                  #
  cmp byte ptr [rdi+2], 'T'                  #
  jne .if25                                  #
    mov rax, 0                               #   return 0
    jmp .ret_parse_method                    #   }
  .if25:                                     #   elif header_buf.startswith('POST') {
  cmp byte ptr [rdi], 'P'                    # 
  jne .if26                                  #
  cmp byte ptr [rdi+1], 'O'                  #
  jne .if26                                  # 
  cmp byte ptr [rdi+2], 'S'                  #
  jne .if26                                  #
  cmp byte ptr [rdi+3], 'T'                  # 
  jne .if26                                  #
    mov rax, 1                               # 
    jmp .ret_parse_method                    #   return 1
  .if26:                                     #   }
  mov rax, -1                                # return -1
  .ret_parse_method:                         # 
  mov rsp, rbp                               # }
  pop rbp                                    #
  ret                                        #

                                             # /**
                                             #  * Parse the file from an HTTP Header block. 
                                             #  * returns length of the file name.
                                             # **/
parse_file:                                  # # int parse_file(file_buf, header_buf, sizeof(header_buf));
  push rbp                                   # 
  mov rbp, rsp                               # # rdi = file_buf
                                             # #rsi = request_buf
  push rdx                                   # (rbp-8)
                                             #
  xor rax, rax                               # #rdx = buf_size
  .l4:                                       # int i = 0
  cmp rax, [rbp-8]                           # while ( request_buf[i] != ' ' ) {
  jge .ret                                   #   if ( i >= request_buf_size) {  
  cmp byte ptr [rsi+rax], 0x20               #     return
  je .b4                                     #   }
    inc rax                                  #   i++
  jmp .l4                                    # }
  .b4:                                       # 
  inc rax                                    #
                                             # # rdi = file_buf, rsi=request_buf, rax=i, rdx=j, cl= char
  xor rdx, rdx                               #
  .l5:                                       # int j = 0
  cmp rax, [rbp-8]                           # while (request_buf[i] != ' ') {
  jge .ret                                   #   if ( i >= request_buf_size) {
  cmp byte ptr [rsi+rax], 0x20               #     return
  je .b5                                     #   }
    mov cl, [rsi+rax]                        #   file_buf[j] = request_buf[i]
    mov byte ptr [rdi+rdx], cl               # 
    inc rax                                  #   i++
    inc rdx                                  #   j++ 
  jmp .l5                                    # }
  .b5:                                       #
                                             #
  inc rax                                    #
  mov byte ptr [rdi+rax], 0x00               # file_buf[j] = NUL
  sub rax, rdx                               # return (i-j) # len_of_file
                                             #
  .ret:                                      #
  mov rsp, rbp                               # }
  pop rbp                                    # 
  ret                                        # 



