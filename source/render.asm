



;proc RenderPostTime, .html, .time
;.dtime dq ?
;.DateTime TDateTime
;begin
;
;        stdcall StrCat, [.html], '<div class="posttime">'
;
;        mov     eax, [.time]
;        cdq
;
;        mov     dword [.dtime], eax
;        mov     dword [.dtime+4], edx
;
;        lea     eax, [.dtime]
;        lea     edx, [.DateTime]
;        stdcall TimeToDateTime, eax, edx
;        stdcall DateTimeToStr, edx, 0
;
;        stdcall StrCat, [.html], eax
;        stdcall StrDel, eax
;
;
;        stdcall StrCat, [.html], '</div>'  ; div.posttime
;
;        return
;endp


;sqlUserInfo text 'select U.nick, (select count() from Posts P where P.userID=U.id) as postcount from Users as U where U.id=?'
;
;
;proc RenderUserInfo, .html, .Uid
;.stmt dd ?
;begin
;        pushad
;
;        lea     eax, [.stmt]
;        cinvoke sqlitePrepare_v2, [hMainDatabase], sqlUserInfo, sqlUserInfo.length, eax, 0
;
;        cinvoke sqliteBindInt, [.stmt], 1, [.Uid]
;
;        cinvoke sqliteStep, [.stmt]
;        cmp     eax, SQLITE_ROW
;        je      .user_ok
;
;        stdcall StrCat, [.html], '<div class="usernull">NULL user</div>'
;        jmp     .finish
;
;.user_ok:
;        stdcall StrCat, [.html], '<div class="username">'
;
;        cinvoke sqliteColumnText, [.stmt], 0
;        stdcall StrCat, [.html], eax
;
;        stdcall StrCat, [.html], '</div>'  ; div.username
;
;        stdcall StrCat, [.html], '<div class="userpcnt">'
;
;        cinvoke sqliteColumnInt, [.stmt], 1
;        stdcall NumToStr, eax, ntsDec or ntsUnsigned
;
;        stdcall StrCat, [.html], eax
;        stdcall StrDel, eax
;
;        stdcall StrCat, [.html], '</div>'  ; div.userpcnt
;
;.finish:
;        cinvoke sqliteFinalize, [.stmt]
;        popad
;        return
;endp




sqlGetTemplate text "select template from templates where id = ?"


proc StrCatTemplate, .hString, .strTemplateID, .sql_statement, .p_special
.stmt dd ?
.free dd ?
begin
        pushad
        and     [.free], 0

        lea     eax, [.stmt]
        cinvoke sqlitePrepare_v2, [hMainDatabase], sqlGetTemplate, sqlGetTemplate.length+1, eax, 0

        stdcall StrLen, [.strTemplateID]
        mov     ecx, eax
        stdcall StrPtr, [.strTemplateID]

        cinvoke sqliteBindText, [.stmt], 1, eax, ecx, SQLITE_STATIC
        cinvoke sqliteStep, [.stmt]
        cmp     eax, SQLITE_ROW
        je      .get_template


        stdcall StrDupMem, "templates/"
        stdcall StrCat, eax, [.strTemplateID]
        stdcall StrCharCat, eax, ".tpl"
        push    eax

        stdcall LoadBinaryFile, eax
        stdcall StrDel ; from the stack
        jc      .error

;        OutputValue "Template from file. Length:", ecx, 10, -1

        mov     [.free], eax
        mov     esi, eax
        and     dword [eax+ecx], 0
        jmp     .outer


.get_template:

        cinvoke sqliteColumnText, [.stmt], 0
        mov     esi, eax

.outer:
        mov     ebx, esi

.inner:
        mov     cl, [esi]
        inc     esi

        test    cl, cl
        jz      .found

        cmp     cl, '$'
        jne     .inner

.found:
        mov     eax, esi
        sub     eax, ebx
        dec     eax

        stdcall StrCatMem, [.hString], ebx, eax

        test    cl, cl
        jz      .end_of_template

        mov     ebx, esi

.varname:
        mov     cl, [esi]
        inc     esi

        test    cl, cl
        jz      .found_var

        cmp     cl, '$'
        jne     .varname

.found_var:
        mov     edx, esi
        sub     edx, ebx
        dec     edx

        stdcall StrCatColumnByName, [.hString], ebx, edx, [.sql_statement], [.p_special]

        test    cl, cl
        jnz     .outer

.end_of_template:

        cinvoke sqliteFinalize, [.stmt]

        stdcall FreeMem, [.free]
        popad
        return

.error:
;        DebugMsg "Error read template!"

        stdcall StrCat, [.hString], "Unknown template!"
        jmp     .end_of_template

endp





proc StrCatColumnByName, .string, .pname, .len, .statement, .p_special
.i dd ?
.formatted dd ?
begin
        pushad

        stdcall StrNew
        mov     edi, eax
        stdcall StrCatMem, edi, [.pname], [.len]

; first check for special names

        stdcall StrCompNoCase, edi, "special:timestamp"
        jc      .cat_timestamp

        stdcall StrCompNoCase, edi, "special:environment"
        jc      .cat_environment

        stdcall StrCompNoCase, edi, "special:username"
        jc      .cat_username

        stdcall StrCompNoCase, edi, "special:loglink"
        jc      .cat_loglink

        stdcall StrCompNoCase, edi, "special:edit_tools"
        jc      .cat_edit_tools

        stdcall StrCompNoCase, edi, "special:referer"
        jc      .cat_referer

        cmp     [.statement], 0
        je      .finish

        stdcall StrMatchPatternNoCase, "case:*", edi
        jc      .cat_case

        mov     [.formatted], 0

        stdcall StrMatchPatternNoCase, "minimag:*", edi
        jnc     .process_columns

        or      [.formatted], 1

        stdcall StrSplit, edi, 8
        stdcall StrDel, edi
        mov     edi, eax
        jmp     .process_columns


.process_columns:

        call    .get_column_number
        jnc     .finish

        cinvoke sqliteColumnText, [.statement], [.i]
        test    eax, eax
        jz      .finish

        cmp     [.formatted], 0
        je      .add_field_direct

        stdcall StrDupMem, eax
        stdcall FormatPostText, eax
        jmp     .add_field


.add_field_direct:
        stdcall StrEncodeHTML, eax

.add_field:
        stdcall StrCat, [.string], eax
        stdcall StrDel, eax

.finish:
        stdcall StrDel, edi
        popad
        return



.get_column_number:

        cinvoke sqliteColumnCount, [.statement]
        mov     ebx, eax
        and     [.i], 0

.loop:
        cmp     [.i], ebx
        jae     .not_found

        cinvoke sqliteColumnName, [.statement], [.i]
        stdcall StrCompNoCase, eax, edi
        jc      .found

        inc     [.i]
        jmp     .loop

.not_found:     ; here CF=0
.found:         ; here CF=1
        retn


;..................................................................
.cat_referer:
        mov     esi, [.p_special]
        stdcall ValueByName, [esi+TSpecialParams.params], "HTTP_REFERER"
        jc      .root

        mov     ebx, eax

        stdcall ValueByName, [esi+TSpecialParams.params], "HTTP_HOST"
        jc      .root

        push    eax

        stdcall StrLen, eax
        mov     ecx, eax

        stdcall StrPos, ebx     ; pattern from the stack
        test    eax, eax
        jz      .root

        add     ecx, eax

        stdcall StrMatchPatternNoCase, "/message/*", ecx
        jc      .root

        stdcall StrMatchPatternNoCase, "/sqlite*", ecx
        jc      .root

        stdcall StrMatchPatternNoCase, "/post*", ecx
        jc      .root

        stdcall StrMatchPatternNoCase, "/edit/*", ecx
        cmp     eax, ecx
        je      .root

        stdcall StrEncodeHTML, ecx
        stdcall StrCat, [.string], eax
        stdcall StrDel, eax
        jmp     .finish

.root:
        stdcall StrCharCat, [.string], "/"
        jmp     .finish

;..................................................................

.cat_edit_tools:
        pushad

        mov     esi, [.p_special]
        test    esi, esi
        jz      .end_tools

;        OutputValue "User permissions:", [esi+TSpecialParams.userStatus], 16, 8

        test    [esi+TSpecialParams.userStatus], permEditAll or permAdmin
        jnz     .do_insert_tools

        test    [esi+TSpecialParams.userStatus], permEditOwn
        jz      .end_tools

        mov     edi, .colUserID
        call    .get_column_number
        jnc     .end_tools

        cinvoke sqliteColumnInt, [.statement], [.i]
        cmp     eax, [esi+TSpecialParams.userID]
        jne     .end_tools

.do_insert_tools:
        mov     edi, .colPostID
        call    .get_column_number
        jnc     .end_tools

        cinvoke sqliteColumnText, [.statement], [.i]
        mov     edi, eax

        stdcall StrCat, [.string], '<a class="edit_btn" href="/edit/'
        stdcall StrCat, [.string], edi
        stdcall StrCat, [.string], '"><img class="edit_icon" src="/images/edit_gray.svg"></a><a class="del_btn" href="/delete/'
        stdcall StrCat, [.string], edi
        stdcall StrCat, [.string], '"><img class="del_icon" src="/images/del_gray.svg"></a>'


.end_tools:
        popad
        jmp     .finish


.colUserID db "userID", 0
.colPostID db "id", 0

;..................................................................


.cat_case:

        stdcall StrSplit, edi, 5
        stdcall StrDel, edi
        mov     edi, eax

        stdcall StrSplitList, edi, '|', TRUE
        mov     esi, eax

        cmp     [esi+TArray.count], 3
        jb      .end_case

        stdcall StrCopy, edi, [esi+TArray.array]

        call    .get_column_number
        jnc     .end_case

        cinvoke sqliteColumnInt, [.statement], [.i]
        mov     ecx, [esi+TArray.count]
        sub     ecx, 2

        cmp     eax, ecx
        jbe     @f
        mov     eax, ecx
@@:
        stdcall StrCat, [.string], [esi+TArray.array+4*eax+4]

.end_case:
        stdcall ListFree, esi, StrDel

        jmp     .finish


;..................................................................



.cat_timestamp:

        mov     esi, [.p_special]

        stdcall StrCat, [.string], '<p class="timestamp">Script runtime: '

        stdcall GetTimestampHiRes
        sub     eax, [esi+TSpecialParams.start_time]

        stdcall NumToStr, eax, ntsDec or ntsUnsigned
        mov     edx, eax

        stdcall StrLen, eax
        sub     eax, 3
        jns     .point_ok

        neg     eax
        inc     eax

.zero_loop:
        stdcall StrCharInsert, edx, " ", 0
        dec     eax
        jnz     .zero_loop

        inc     eax

.point_ok:
        stdcall StrCharInsert, edx, ".", eax

        stdcall StrCat, [.string], edx
        stdcall StrDel, edx

        stdcall StrCat, [.string], txt ' ms</p>'

        jmp     .finish


;..................................................................


.cat_environment:
; this is only for special purposes.

if defined options.DebugWeb & options.DebugWeb

;        DebugMsg "Special:environment!"


        mov     esi, [.p_special]
        mov     edx, [esi+TSpecialParams.params]

        xor     ecx, ecx

.loop_env:
        cmp     ecx, [edx+TArray.count]
        jae     .show_post

        stdcall StrEncodeHTML, [edx+TArray.array+8*ecx]
        stdcall StrCat,     [.string], eax
        stdcall StrDel, eax

        stdcall StrCharCat, [.string], " = "

        stdcall StrEncodeHTML, [edx+TArray.array+8*ecx+4]
        stdcall StrCat,     [.string], eax
        stdcall StrDel, eax
        stdcall StrCharCat, [.string], $0a0d

        inc     ecx
        jmp     .loop_env

.show_post:
        mov     eax, [esi+TSpecialParams.post]
        test    eax, eax
        jz      .finish

        stdcall StrCat, [.string], <13, 10, 13, 10, "<<<<< Follows the POST data: >>>>>", 13, 10>
        stdcall StrCat, [.string], [esi+TSpecialParams.post]
        stdcall StrCat, [.string], <13, 10, "<<<<< Here ends the post data >>>>>", 13, 10>

        jmp     .finish

else
        jmp     .finish

end if



;..................................................................



.cat_username:
        mov     esi, [.p_special]
        mov     edx, [esi+TSpecialParams.userName]
        test    edx, edx
        jz      .finish

        stdcall StrCat, [.string], edx
        jmp     .finish


;..................................................................


.cat_loglink:

        mov     esi, [.p_special]
        mov     edx, [esi+TSpecialParams.userName]
        test    edx, edx
        jz      .login

; log out:

        stdcall StrEncodeHTML, edx

        stdcall StrCat, [.string], '<a class="logout" href="/logout/">Logout</a> ( <b>'
        stdcall StrCat, [.string], eax
        stdcall StrDel, eax
        stdcall StrCat, [.string], '</b> )'
        jmp     .common


.login:
        stdcall StrCat, [.string], '<a class="login" href="/login/">Login</a>'
        stdcall StrCat, [.string], '<span class="separator"></span><a class="register" href="/register/">Register</a>'

.common:
        jmp     .finish


endp







proc FormatPostText, .hText

.result TMarkdownResults

begin
        lea     eax, [.result]

        stdcall StrCatTemplate, [.hText], "minimag_suffix", 0, 0
        stdcall TranslateMarkdown, [.hText], FixMiniMagLink, 0, eax

        stdcall StrDel, [.hText]
        stdcall StrDel, [.result.hIndex]
        stdcall StrDel, [.result.hKeywords]
        stdcall StrDel, [.result.hDescription]

        mov     eax, [.result.hContent]
        return
endp



proc FixMiniMagLink, .ptrLink, .ptrBuffer
begin
        pushad

        mov     edi, [.ptrBuffer]
        mov     esi, [.ptrLink]
        cmp     byte [esi], '#'
        je      .finish         ; it is internal link

.start_loop:
        lodsb
        cmp     al, $0d
        je      .not_absolute
        cmp     al, $0a
        je      .not_absolute
        cmp     al, ']'
        je      .not_absolute
        test    al,al
        jz      .not_absolute

        cmp     al, 'A'
        jb      .found
        cmp     al, 'Z'
        jbe     .start_loop

        cmp     al, 'a'
        jb      .found
        cmp     al, 'z'
        jb      .start_loop

.found:
        cmp     al, ':'
        jne     .not_absolute

        mov     ecx, [.ptrLink]
        sub     ecx, esi

        cmp     ecx, -11
        jne     .not_js

        cmp     dword [esi+ecx], "java"
        jne     .not_js

        cmp     dword [esi+ecx+4], "scri"
        jne     .not_js

        cmp     word [esi+ecx+8], "pt"
        jne     .not_js

.add_https:
        mov     dword [edi], "http"
        mov     dword [edi+4], "s://"
        lea     edi, [edi+8]
        jmp     .protocol_ok

.not_js:
        cmp     dword [esi+ecx], "http"
        jne     .add_https

.not_absolute:
.protocol_ok:
        mov     esi, [.ptrLink]

; it is absolute URL, exit
.finish:
        mov     [esp+4*regEAX], edi     ; return the end address.
        mov     [esp+4*regEDX], esi     ; return the start of the link.
        popad
        return
endp





proc StrSlugify, .hString
begin
        stdcall Utf8ToAnsi, [.hString], KOI8R
        push    eax
        stdcall StrCyrillicFix, eax
        stdcall StrDel ; from the stack

        stdcall StrMaskBytes, eax, $0, $7f
        stdcall StrLCase2, eax

        stdcall StrConvertWhiteSpace, eax, " "
        stdcall StrConvertPunctuation, eax

        stdcall StrCleanDupSpaces, eax
        stdcall StrClipSpacesR, eax
        stdcall StrClipSpacesL, eax

        stdcall StrConvertWhiteSpace, eax, "_"

        return
endp



proc StrConvertWhiteSpace, .hString, .toChar
begin
        pushad

        stdcall StrLen, [.hString]
        mov     ecx, eax
        jecxz   .finish

        stdcall StrPtr, [.hString]
        mov     esi, eax

        mov     edx, [.toChar]

.loop:
        mov     al, [esi]
        cmp     al, " "
        ja      .next

        mov     [esi], dl

.next:
        inc     esi
        loop    .loop

.finish:
        popad
        return
endp


proc StrConvertPunctuation, .hString
begin
        pushad

        stdcall StrLen, [.hString]
        mov     ecx, eax
        jecxz   .finish

        stdcall StrPtr, [.hString]
        mov     esi, eax

.loop:
        mov     al, [esi]
        cmp     al, "a"
        jb      .not_letter
        cmp     al, "z"
        jbe     .next

.not_letter:
        cmp     al, "0"
        jb      .convert
        cmp     al, "9"
        jbe     .next

.convert:
        mov     byte [esi], " "

.next:
        inc     esi
        loop    .loop

.finish:
        popad
        return
endp



proc StrMaskBytes, .hString, .orMask, .andMask
begin
        pushad

        stdcall StrLen, [.hString]
        mov     ecx, eax
        jecxz   .finish

        stdcall StrPtr, [.hString]
        mov     esi, eax

        mov     dl, byte [.orMask]
        mov     dh, byte [.andMask]

.loop:
        mov     al, [esi]
        or      al, dl
        and     al, dh
        mov     [esi], al
        inc     esi
        loop    .loop

.finish:
        popad
        return
endp




proc StrCyrillicFix, .hString
begin
        pushad

        stdcall StrNew
        mov     edi, eax

        stdcall StrPtr, [.hString]
        mov     esi, eax

.loop:
        movzx   eax, byte [esi]
        inc     esi

        test    al, al
        jz      .finish

        mov     ebx, eax

        cmp     bl, $e0
        jb      .less

        sub     bl, $20

.less:
        cmp     bl, $c0
        jb      .cat

        sub     bl, $db
        and     bl, $1f
        cmp     bl, 5
        ja      .cat

        mov     eax, [.table+4*ebx]

.cat:
        stdcall StrCharCat, edi, eax
        jmp     .loop


.finish:
        mov     [esp+4*regEAX], edi
        popad
        return

.table  dd      "sh"    ; sh
        dd      "e"
        dd      "sht"
        dd      "ch"
        dd      "a"
        dd      "yu"

endp





proc StrMakeRedirect, .hString, .hWhere
begin
        push    eax

        cmp     [.hString], 0
        jne     @f

        stdcall StrNew
        mov     [esp], eax
        mov     [.hString], eax

@@:
        stdcall StrInsert,  [.hString], <"Status: 302 Found", 13, 10>, 0
        stdcall StrPtr, [.hString]
        add     eax, [eax+string.len]
        cmp     word [eax-2], $0a0d
        je      @f
        stdcall StrCharCat, [.hString], $0a0d
@@:
        stdcall StrCat,     [.hString], "Location: "
        stdcall StrCat,     [.hString], [.hWhere]
        stdcall StrCharCat, [.hString], $0a0d0a0d

        pop     eax
        return
endp
