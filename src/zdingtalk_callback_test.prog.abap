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

AT SELECTION-SCREEN OUTPUT.
  btxt1 = '数据条件'(t01).
  btxt2 = '功能选择'(t01).

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
  FREE dingcrypto.
  CREATE OBJECT dingcrypto
    EXPORTING
      token          = p_token
      encodingaeskey = p_AesKey
      key            = p_key.
  CALL METHOD dingcrypto->getencryptedmap
    EXPORTING
      content = p_cont
    RECEIVING
      res     = DATA(res).
  WRITE:/ |加密前字符串：{ p_cont }|.
  WRITE:/ |加密后字符串：{ res }|.

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
  ENDIF.
  WRITE:/ |解密后字符串：{ text }|.
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
  FREE dingcrypto.
  CREATE OBJECT dingcrypto
    EXPORTING
      token          = p_token
      encodingaeskey = p_AesKey
      key            = p_key.
  CLEAR wa_callback.
  /ui2/cl_json=>deserialize( EXPORTING json = p_cont pretty_name = /ui2/cl_json=>pretty_mode-low_case CHANGING data = wa_callback ).
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
  ENDIF.
  WRITE:/ |解密前字符串：{ p_cont }|.
  WRITE:/ |解密后字符串：{ text }|.
ENDFORM.
