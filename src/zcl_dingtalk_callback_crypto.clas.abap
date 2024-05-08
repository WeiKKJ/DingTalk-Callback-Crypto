class ZCL_DINGTALK_CALLBACK_CRYPTO definition
  public
  final
  create public .

public section.

  methods CONSTRUCTOR
    importing
      value(TOKEN) type STRING
      value(ENCODINGAESKEY) type STRING
      value(KEY) type STRING .
  methods GENERATESIGNATURE
    importing
      value(NONCE) type STRING
      value(TIMESTAMP) type STRING
      value(MSG_ENCRYPT) type STRING
    returning
      value(SIGN) type STRING .
  methods GETDECRYPTMSG
    importing
      value(MSG_SIGNATURE) type STRING
      value(TIMESTAMP) type STRING
      value(NONCE) type STRING
      value(CONTENT) type STRING
    returning
      value(TEXT) type STRING
    exceptions
      SIGNATURE_CHECK_ERROR
      CONTENTX_ERROR
      PADDING_ERROR
      APPKEY_ERROR .
  methods ENCRYPT
    importing
      value(CONTENT) type STRING
    returning
      value(ENCRYPTCONTENT) type STRING .
  methods GENERATERANDOMKEY
    importing
      value(SIZE) type I default 16
    returning
      value(NONCE) type STRING .
  methods LENGTH
    importing
      value(CONTENT) type STRING
    returning
      value(MSG_LENX) type XSTRING .
  methods GETENCRYPTEDMAP
    importing
      value(CONTENT) type STRING
    returning
      value(RES) type STRING .
protected section.
private section.

  data TOKEN type STRING .
  data ENCODINGAESKEY type STRING .
  data KEY type STRING .
  data AESKEY type XSTRING .
ENDCLASS.



CLASS ZCL_DINGTALK_CALLBACK_CRYPTO IMPLEMENTATION.


  METHOD constructor.
    me->encodingAesKey = encodingAesKey.
    me->key = key.
    me->token = token  .
    DATA(b64data) = |{ encodingAesKey }=|.
    " 解密 encodingAesKey 03.05.2024 00:41:17 by kkw
    CALL FUNCTION 'SSFC_BASE64_DECODE'
      EXPORTING
        b64data                  = b64data
*       B64LENG                  =
*       B_CHECK                  =
      IMPORTING
        bindata                  = me->aesKey
      EXCEPTIONS
        ssf_krn_error            = 1
        ssf_krn_noop             = 2
        ssf_krn_nomemory         = 3
        ssf_krn_opinv            = 4
        ssf_krn_input_data_error = 5
        ssf_krn_invalid_par      = 6
        ssf_krn_invalid_parlen   = 7
        OTHERS                   = 8.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
  ENDMETHOD.


  METHOD encrypt.
    DATA:encryptcontentx TYPE xstring,
         content_temp    TYPE string,
         contentx_temp   TYPE xstring.
    " 16位随机字符串
    CALL METHOD me->generaterandomkey
      EXPORTING
        size  = 16
      RECEIVING
        nonce = DATA(randomkey).
    " 16位随机字符串转xstring
    CLEAR:contentx_temp.
    CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
      EXPORTING
        text   = randomkey
*       MIMETYPE       = ' '
*       ENCODING       =
      IMPORTING
        buffer = contentx_temp
      EXCEPTIONS
        failed = 1
        OTHERS = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
    content_temp = contentx_temp.

    " 4位内容长度
    CALL METHOD me->length
      EXPORTING
        content  = content
      RECEIVING
        msg_lenx = DATA(msg_lenx).
    content_temp = |{ content_temp }{ msg_lenx }|.
    " 返回报文转xstring  03.05.2024 00:47:09 by kkw
    CLEAR:contentx_temp.
    CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
      EXPORTING
        text   = content
*       MIMETYPE       = ' '
*       ENCODING       =
      IMPORTING
        buffer = contentx_temp
      EXCEPTIONS
        failed = 1
        OTHERS = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
    content_temp = |{ content_temp }{ contentx_temp }|.
*    " key转xstring
    CLEAR:contentx_temp.
    CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
      EXPORTING
        text   = me->key
*       MIMETYPE       = ' '
*       ENCODING       =
      IMPORTING
        buffer = contentx_temp
      EXCEPTIONS
        failed = 1
        OTHERS = 2.
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
    content_temp = |{ content_temp }{ contentx_temp }|.
    " 将string转为xstring  03.05.2024 00:49:20 by kkw
    contentx_temp = content_temp.
    " aes的偏移量  03.05.2024 00:49:52 by kkw
    DATA(ivx) = me->aesKey(16).
    " 加密  03.05.2024 00:50:10 by kkw
    CALL METHOD zcl_aes_utility=>encrypt_xstring
      EXPORTING
        i_key                   = me->aesKey
        i_data                  = contentx_temp
        i_initialization_vector = ivx
        i_padding_standard      = zcl_byte_padding_utility=>mc_padding_standard_pkcs_7
        i_encryption_mode       = zcl_aes_utility=>mc_encryption_mode_cbc
      IMPORTING
        e_data                  = encryptcontentx.
    " base64编码  03.05.2024 00:50:27 by kkw
    CALL FUNCTION 'SCMS_BASE64_ENCODE_STR'
      EXPORTING
        input  = encryptcontentx
      IMPORTING
        output = encryptcontent.
  ENDMETHOD.


  METHOD generaterandomkey.
    DATA:alphabet(114).
    DATA:output(40).

    CONCATENATE 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
                'abcdefghijklmnopqrstuvwxyz'
                'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
                '0123456789'
                INTO alphabet.

    CALL FUNCTION 'RSEC_GENERATE_PASSWORD'
      EXPORTING
        alphabet      = alphabet
        output_length = size
      IMPORTING
        output        = output
      EXCEPTIONS
        some_error    = 1.
    nonce = output.
  ENDMETHOD.


  METHOD GENERATESIGNATURE.
    DATA:lt_string TYPE TABLE OF string,
         signList  TYPE string.
    DATA(v) = msg_encrypt.
    INSERT INITIAL LINE INTO TABLE lt_string ASSIGNING FIELD-SYMBOL(<lt_string>).
    <lt_string> = nonce.
    UNASSIGN <lt_string>.
    INSERT INITIAL LINE INTO TABLE lt_string ASSIGNING <lt_string>.
    <lt_string> = timestamp.
    UNASSIGN <lt_string>.
    INSERT INITIAL LINE INTO TABLE lt_string ASSIGNING <lt_string>.
    <lt_string> = me->token.
    UNASSIGN <lt_string>.
    INSERT INITIAL LINE INTO TABLE lt_string ASSIGNING <lt_string>.
    <lt_string> = v.
    UNASSIGN <lt_string>.
*    signList = ''.join(sorted([nonce, timestamp, token, v])).
    SORT lt_string.
    LOOP AT lt_string ASSIGNING <lt_string>.
      signList = signList && <lt_string>.
    ENDLOOP.

    SHIFT signList LEFT DELETING LEADING space.

    TRY.
        CALL METHOD cl_abap_message_digest=>calculate_hash_for_char
          EXPORTING
            if_algorithm  = 'SHA1'
            if_data       = signList
*           if_length     = 0
          IMPORTING
            ef_hashstring = sign
*           ef_hashxstring   =
*           ef_hashb64string =
*           ef_hashx      =
          .
        TRANSLATE sign TO LOWER CASE.
      CATCH cx_abap_message_digest.
        RETURN.
    ENDTRY.

  ENDMETHOD.


  METHOD getdecryptmsg.
    DATA:contentx TYPE xstring,
         test     TYPE xstring,
         pad      TYPE i, "填充位数
         x4       TYPE i, "msg长度
         signs    TYPE string.
    " 校验计算后的sign值是否和query参数的msg_signature一致  03.05.2024 01:03:55 by kkw
    CALL METHOD me->generatesignature
      EXPORTING
        nonce       = nonce
        timestamp   = timestamp
        msg_encrypt = content
      RECEIVING
        sign        = DATA(sign).
    TRANSLATE sign TO LOWER CASE.
    IF sign NE msg_signature.
      RAISE signature_check_error.
    ENDIF.
    "  BASE64解密请求报文 03.05.2024 01:05:27 by kkw
    CALL FUNCTION 'SSFC_BASE64_DECODE'
      EXPORTING
        b64data                  = content
*       B64LENG                  =
*       B_CHECK                  =
      IMPORTING
        bindata                  = contentx
      EXCEPTIONS
        ssf_krn_error            = 1
        ssf_krn_noop             = 2
        ssf_krn_nomemory         = 3
        ssf_krn_opinv            = 4
        ssf_krn_input_data_error = 5
        ssf_krn_invalid_par      = 6
        ssf_krn_invalid_parlen   = 7
        OTHERS                   = 8.
    IF sy-subrc <> 0.
      RAISE contentx_error.
    ENDIF.
    DATA(ivx) = me->aesKey(16).
    " aes解密请求报文  03.05.2024 01:06:56 by kkw
    zcl_aes_utility=>decrypt_xstring(
      EXPORTING
        i_key                   = me->aesKey
        i_data                  = contentx
        i_initialization_vector = ivx
        i_encryption_mode       = zcl_aes_utility=>mc_encryption_mode_cbc
    IMPORTING
      e_data                  = test ).
****    DATA(text_test) = cl_abap_codepage=>convert_from( EXPORTING source = test ).

    DATA(xlen) = xstrlen( test ) - 1." 先不判断等于0的情况  01.05.2024 02:15:51 by kkw
    " xstring最后一位的十进制值代表填充位数  01.05.2024 02:13:38 by kkw
    pad = test+xlen(1).
    IF pad > 32.
      RAISE padding_error.
    ENDIF.
    DATA(ff) = xlen - pad + 1.
    test = test(ff).    " 去掉填充值后的值  01.05.2024 02:14:39 by kkw
    x4 = test+16(4)." 代表的是 msg长度 01.05.2024 02:20:46 by kkw
*    DATA(test16x) = test(16).
*    DATA(test16) = cl_abap_codepage=>convert_from( EXPORTING source = test16x ).
    DATA(textx) = test+20(x4).
    DATA(signi) = 20 + x4." appkey开始的位置 01.05.2024 02:22:36 by kkw
    DATA(signx) = test+signi." appkey的xstring  01.05.2024 02:25:07 by kkw
    signs = cl_abap_codepage=>convert_from( EXPORTING source = signx ).
    IF signs NE me->key.
      RAISE appkey_error.
    ENDIF.

    CLEAR text.
    text = cl_abap_codepage=>convert_from( EXPORTING source = textx ).

*    iv = self.aesKey[:16]  ##初始向量
*         aesDecode = aes.new(self.aesKey, aes.mode_cbc, iv)
*    decodeRes = aesDecode.decrypt(content)
*    #pad = int(binascii.hexlify(decodeRes[-1]),16)
*    pad = int(decodeRes[-1])
*    IF pad > 32:
*    RAISE ValueError('Input is not padded or padding is corrupt')
*    decodeRes = decodeRes[:-pad]
*    l = struct.unpack('!i', decodeRes[16:20])[0]
*    ##获取去除初始向量，四位msg长度以及尾部corpid
*    nl = len(decodeRes)
*
*    IF decodeRes[(20+l):].decode() != self.key:
*    raise ValueError('corpId 校验错误')
*    return decodeRes[20:(20+l)].decode()
  ENDMETHOD.


  METHOD getencryptedmap.
    DATA:stamp      TYPE timestampl,
         stamp_char TYPE char22.
    "加密消息体
    CALL METHOD me->encrypt
      EXPORTING
        content        = content
      RECEIVING
        encryptcontent = DATA(encryptContent).
    "时间戳
    GET TIME STAMP FIELD stamp.
    stamp_char = stamp.
    CALL METHOD cl_pco_utility=>convert_abap_timestamp_to_java
      EXPORTING
        iv_date      = CONV #( stamp_char(8) )
        iv_time      = CONV #( stamp_char+8(6) )
        iv_msec      = CONV #( stamp_char+15(3) )
      IMPORTING
        ev_timestamp = DATA(timestamp).
    "随机数
    CALL METHOD me->generaterandomkey
*      EXPORTING
*        size   = 16
      RECEIVING
        nonce = DATA(nonce).
    "消息体签名
    CALL METHOD me->generatesignature
      EXPORTING
        nonce       = nonce
        timestamp   = timestamp
        msg_encrypt = encryptContent
      RECEIVING
        sign        = DATA(sign).

    res = `{"msg_signature":"` && sign && `","encrypt":"` && encryptContent && `","timeStamp":"` && timestamp && `","nonce":"` && nonce && `"}`.
  ENDMETHOD.


  METHOD length.
    DATA:lx TYPE x LENGTH 4.
    DATA(l) = strlen( content ).
    lx = l.
    msg_lenx = lx.
  ENDMETHOD.
ENDCLASS.
