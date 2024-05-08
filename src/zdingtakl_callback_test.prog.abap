*&---------------------------------------------------------------------*
*& Report ZDINGTAKL_CALLBACK_TEST
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zdingtakl_callback_test.
DATA:token          TYPE string,
     encodingAesKey TYPE string,
     key            TYPE string,
     dingCrypto     TYPE REF TO zcl_dingtalk_callback_crypto,
     dingCryptode   TYPE REF TO zcl_dingtalk_callback_crypto,
     content        TYPE string.
TYPES: BEGIN OF t_JSON1,
         msg_signature TYPE string,
         timeStamp     TYPE string,
         nonce         TYPE string,
         encrypt       TYPE string,
       END OF t_JSON1.
DATA:wa_callback TYPE t_JSON1.

START-OF-SELECTION.
  token = 'OA4FgkdsWiz9wgjNbrsQLtga3sgqFXtn'.
  encodingAesKey = 'nnIITQn7r1s6Sa8avyqaJbJaHMO1wkBQWv5mFlHBMMN'.
  key = 'dinge9jdnvholvqayvgc'.
  content =
`R1dcGSzNmicbPdvN9LEvZjVymtupB/gzbyHUjO`
&& `NEAqD/Dz4TAMBluEEE63AgTkKOIupWkDDchB0lYjc/NwfC3TtA`
&& `ZzaQxyiYXwIOBxTpbaoBfHZv56D6KCj5Z1nsxhJ2eex8xxaXi6`
&& `qYkt43LFIQ6GucBs8Qweba4YRHeDFNOCKilIhUC51oz/I6l4vT`
&& `vQ8IZNEJ3cqz90ljwvw9WLhMeZIfrIEKwwDeqwMm+rfWniZxbt`
&& `JKNOQyd22wmkt5VMy9lYUZ/FwnVjVVGntpn1SNxhYZnQHreUfv`
&& `SRTRWrG12bU=`
  .
  "解密
  CREATE OBJECT dingcryptode
    EXPORTING
      token          = token
      encodingaeskey = encodingAesKey
      key            = key.

  CALL METHOD dingcryptode->getdecryptmsg
    EXPORTING
      msg_signature  = 'dfed76058e7c44bd1646f6097f9c2b4ec9130d7d'
      timestamp      = '1714666890493'
      nonce          = 'PLzmxjod'
      content        = content
    RECEIVING
      text           = DATA(text)
    EXCEPTIONS
      valueerror     = 1
      contentx_error = 2
      valueerror2    = 3
      valueerror3    = 4
      OTHERS         = 5.
  IF sy-subrc <> 0.
*   Implement suitable error handling here
  ENDIF.

  " 加密  01.05.2024 21:16:12 by kkw
*  CREATE OBJECT dingcrypto
*    EXPORTING
*      token          = token
*      encodingaeskey = encodingAesKey
*      key            = key.
**  content = `{"msg_signature":"f4665ac39b201546a5173b7c367f9154c81bb99f",` &&
**   `"encrypt":"c9ZHGXo0pkmWzWe24ax8bzbPaETpZ2P3o1nFfCoFB5o453Oxe/8s8WX18u06DffcDVzi89i4ai1EKb8Zdn8/8dm9dhe/28oXQmeqxrqee4G+7LXk5djwWin1Hy3OZzPT","timeStamp":"1714567295073","nonce":"pNmkHYHj"}`.
*  CALL METHOD dingcrypto->getencryptedmap
*    EXPORTING
*      content = `{"EventType":"checkkkkk_url"}`
*    RECEIVING
*      res     = DATA(res).
*  WRITE:/ |加密前字符串：{ `{"EventType":"checkkkkk_url"}` }|.
*  WRITE:/ |加密后字符串：{ res }|.
*  /ui2/cl_json=>deserialize( EXPORTING json = res  pretty_name = /ui2/cl_json=>pretty_mode-low_case CHANGING data = wa_callback ).
*
*  CREATE OBJECT dingcryptode
*    EXPORTING
*      token          = token
*      encodingaeskey = encodingAesKey
*      key            = key.
*
*  CALL METHOD dingcryptode->getdecryptmsg
*    EXPORTING
*      msg_signature  = wa_callback-msg_signature
*      timestamp      = wa_callback-timestamp
*      nonce          = wa_callback-nonce
*      content        = wa_callback-encrypt
*    RECEIVING
*      text           = DATA(text)
*    EXCEPTIONS
*      valueerror     = 1
*      contentx_error = 2
*      valueerror2    = 3
*      valueerror3    = 4
*      OTHERS         = 5.
*  IF sy-subrc <> 0.
**   Implement suitable error handling here
*  ENDIF.
*  WRITE:/ |解密后字符串：{ text }|.
**  BREAK-POINT.
