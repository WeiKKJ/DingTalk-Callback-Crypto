*&---------------------------------------------------------------------*
*& Report ZDINGTAKL_CALLBACK_TEST
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zdingtalk_callback_test.
DATA:dingCrypto     TYPE REF TO zcl_dingtalk_callback_crypto.
TYPES: BEGIN OF t_JSON1,
         msg_signature TYPE string,
         timeStamp     TYPE string,
         nonce         TYPE string,
         encrypt       TYPE string,
       END OF t_JSON1.
DATA:wa_callback TYPE t_JSON1.
DATA:str TYPE string.
DATA:tab TYPE TABLE OF char100.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE btxt2.
  PARAMETERS:p1 RADIOBUTTON GROUP prd2 DEFAULT 'X' USER-COMMAND ss1,
             p2 RADIOBUTTON GROUP prd2.
SELECTION-SCREEN END OF BLOCK b2.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE btxt1.
  PARAMETERS p_token TYPE string LOWER CASE MEMORY ID p_token.
  PARAMETERS p_AesKey TYPE string LOWER CASE MEMORY ID p_AesKey.
  PARAMETERS p_key TYPE string LOWER CASE MEMORY ID p_key.
  PARAMETERS p_cont TYPE string LOWER CASE MEMORY ID p_cont.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK blk3 WITH FRAME TITLE t03.
  SELECTION-SCREEN SKIP 1.
  SELECTION-SCREEN COMMENT /2(79) text10.
  SELECTION-SCREEN ULINE /2(50).

SELECTION-SCREEN END OF BLOCK blk3.

AT SELECTION-SCREEN OUTPUT.
  btxt1 = '数据条件'(t01).
  btxt2 = '功能选择'(t01).

INITIALIZATION.
  t03 = '说明'.
  text10 = '报文如果很长的话，不要在筛选屏幕填入，请通过剪切板复制要加、解密的报文后执行本功能'.


START-OF-SELECTION.
  IF p1 = 'X'.
    PERFORM p1.
  ELSEIF p2 = 'X'.
    PERFORM p2.
  ENDIF.

*&---------------------------------------------------------------------*
*& Form p1
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM p1 .
  CLEAR:str,tab.
  IF p_cont IS INITIAL.
    CALL METHOD cl_gui_frontend_services=>clipboard_import
      IMPORTING
        data                 = tab
        length               = DATA(len)
      EXCEPTIONS
        cntl_error           = 1
        error_no_gui         = 2
        not_supported_by_gui = 3
        OTHERS               = 4.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    LOOP AT tab ASSIGNING FIELD-SYMBOL(<tab>).
      str = |{ str }{ <tab> }|.
    ENDLOOP.
  ELSE.
    str = p_cont.
  ENDIF.
  CHECK str IS NOT INITIAL.

  FREE:dingcrypto.
  CREATE OBJECT dingcrypto
    EXPORTING
      token          = p_token
      encodingaeskey = p_AesKey
      key            = p_key.
  TRY.
      CALL METHOD dingcrypto->getencryptedmap
        EXPORTING
          content = str
        RECEIVING
          res     = DATA(res).
    CATCH cx_root INTO DATA(exception).
      DATA(etext) = exception->if_message~get_text( ).
      MESSAGE s000(oo) WITH etext DISPLAY LIKE 'E'.
      RETURN.
  ENDTRY.
  CLEAR wa_callback.
  /ui2/cl_json=>deserialize( EXPORTING json = res pretty_name = /ui2/cl_json=>pretty_mode-low_case CHANGING data = wa_callback ).
  CALL METHOD dingcrypto->getdecryptmsg
    EXPORTING
      msg_signature         = wa_callback-msg_signature
      timestamp             = wa_callback-timestamp
      nonce                 = wa_callback-nonce
      content               = wa_callback-encrypt
    RECEIVING
      text                  = DATA(text)
    EXCEPTIONS
      signature_check_error = 1
      contentx_error        = 2
      padding_error         = 3
      appkey_error          = 4
      OTHERS                = 5.
  IF sy-subrc <> 0.
*   Implement suitable error handling here
    text = `{` && |"发生了异常":|.
    CASE sy-subrc.
      WHEN 1.
        text = |{ text }"signature_check_error"|.
      WHEN 2.
        text = |{ text }"contentx_error"|.
      WHEN 3.
        text = |{ text }"padding_error"|.
      WHEN 4.
        text = |{ text }"appkey_error"|.
      WHEN OTHERS.
        text = |{ text }"others_error"|.
    ENDCASE.
    text = text && `}`.
  ENDIF.

  cl_demo_output=>new(
    )->begin_section( `加密前字符串：`
    )->write_text( str
    )->next_section( `加密后字符串：`
    )->write_json( res
    )->next_section( `解密后字符串：`
    )->write_text( text
    )->end_section(
    )->display( ).
ENDFORM.
*&---------------------------------------------------------------------*
*& Form p2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM p2 .
  CLEAR:str,tab.
  IF p_cont IS INITIAL.
    CALL METHOD cl_gui_frontend_services=>clipboard_import
      IMPORTING
        data                 = tab
        length               = DATA(len)
      EXCEPTIONS
        cntl_error           = 1
        error_no_gui         = 2
        not_supported_by_gui = 3
        OTHERS               = 4.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    LOOP AT tab ASSIGNING FIELD-SYMBOL(<tab>).
      str = |{ str }{ <tab> }|.
    ENDLOOP.
  ELSE.
    str = p_cont.
  ENDIF.
  CHECK str IS NOT INITIAL.

  FREE dingcrypto.
  CREATE OBJECT dingcrypto
    EXPORTING
      token          = p_token
      encodingaeskey = p_AesKey
      key            = p_key.

  CLEAR wa_callback.
  /ui2/cl_json=>deserialize( EXPORTING json = str pretty_name = /ui2/cl_json=>pretty_mode-low_case CHANGING data = wa_callback ).
  CALL METHOD dingcrypto->getdecryptmsg
    EXPORTING
      msg_signature         = wa_callback-msg_signature
      timestamp             = wa_callback-timestamp
      nonce                 = wa_callback-nonce
      content               = wa_callback-encrypt
    RECEIVING
      text                  = DATA(text)
    EXCEPTIONS
      signature_check_error = 1
      contentx_error        = 2
      padding_error         = 3
      appkey_error          = 4
      OTHERS                = 5.
  IF sy-subrc <> 0.
*   Implement suitable error handling here
    text = `{` && |"发生了异常":|.
    CASE sy-subrc.
      WHEN 1.
        text = |{ text }"signature_check_error"|.
      WHEN 2.
        text = |{ text }"contentx_error"|.
      WHEN 3.
        text = |{ text }"padding_error"|.
      WHEN 4.
        text = |{ text }"appkey_error"|.
      WHEN OTHERS.
        text = |{ text }"others_error"|.
    ENDCASE.
    text = text && `}`.
  ENDIF.

  cl_demo_output=>new(
    )->begin_section( `解密前字符串：`
    )->write_text( str
    )->next_section( `解密后字符串：`
    )->write_json( text
    )->end_section(
    )->display( ).
ENDFORM.
